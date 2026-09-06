import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_models/pricing_plan_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';

part 'checkout_state.dart';

enum CheckoutPhase {
  paying,
  handedOff,
  failed,
  success,

  /// The user backed out (store sheet cancelled, or invoice sheet dismissed
  /// unpaid). The screen pops on this — a cubit can't navigate.
  cancelled,
}

enum CheckoutMethod { iap, stripe, lightning }

/// Backend verdict on a store receipt. Deliberately not collapsed into
/// pass/fail — the restore screen and the checkout screen say different things
/// about each rejection.
enum IapValidation { valid, otherAccount, anotherActive, invalid }

/// Sends a receipt to the backend and finishes the transaction with the store,
/// then reports the verdict. Owns no UI state, so both the checkout flow and
/// the restore flow can share it.
///
/// The transaction is finished either way — an unfinished one blocks every
/// later purchase of the same product, and a rejected receipt is no exception.
Future<IapValidation> validateIapPurchase(PurchaseDetails purchase) async {
  lg.i(
    '[IAP] validating ${purchase.productID} status=${purchase.status.name} '
    'id=${purchase.purchaseID} source=${purchase.verificationData.source} '
    'receipt=${purchase.verificationData.serverVerificationData.length}B',
  );

  var outcome = IapValidation.invalid;
  final sw = Stopwatch()..start();
  final validated = await HttpFunctionsRepository.subscriptionValidateIap(
    platform: Platform.isIOS ? 'ios' : 'android',
    receipt: purchase.verificationData.serverVerificationData,
    productId: purchase.productID,
    pubkey: currentSigner?.getPublicKey() ?? '',
    onReceiptOwnedByOtherAccount: () => outcome = IapValidation.otherAccount,
    onAnotherSubscriptionActive: () => outcome = IapValidation.anotherActive,
  );
  if (validated != null) {
    outcome = IapValidation.valid;
  }

  final validateMs = sw.elapsedMilliseconds;

  await ackIapPurchase(purchase);

  lg.i(
    '[IAP] validated ${purchase.productID} -> ${outcome.name} '
    'in ${validateMs}ms',
  );
  return outcome;
}

/// Finishes a transaction with the store. Never throws — a failed
/// acknowledgement must not take down the flow that called it.
Future<void> ackIapPurchase(PurchaseDetails purchase) async {
  try {
    await InAppPurchase.instance.completePurchase(purchase);
  } catch (e) {
    lg.i('[IAP] completePurchase error: $e');
  }
}

/// Owns a single plan purchase end to end: the store/Stripe/Lightning call and
/// the phase it settles into. Route-scoped, not global — while it lives it is
/// the sole `purchaseStream` listener, so outcomes are attributed to [plan]
/// directly instead of being guessed from the product id.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required this.plan,
    required this.method,
    this.accountSession,
  }) : super(const CheckoutState()) {
    if (method == CheckoutMethod.iap) {
      _iapSub = InAppPurchase.instance.purchaseStream.listen(
        _handlePurchaseUpdate,
        onError: (_) {
          if (_awaitingTap) {
            _fail(t.pricing_error_store);
          }
        },
      );
    }
  }

  final PricingPlan plan;
  final CheckoutMethod method;

  final Future<void>? accountSession;

  StreamSubscription<List<PurchaseDetails>>? _iapSub;
  PurchaseDetails? _androidPurchase;
  Timer? _stuck;

  bool _awaitingTap = false;

  /// A Play plan switch is in flight, so the outgoing plan's purchase is
  /// expected on the stream alongside the new one. Without this, an unrelated
  /// renewal landing mid-checkout is announced as a plan switch.
  bool _switching = false;

  final Set<String> _preTapIds = {};

  Future<void> _snapshotPendingTransactions() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      final pending = await SKPaymentQueueWrapper().transactions();
      _preTapIds.addAll(
        pending.map((t) => t.transactionIdentifier).nonNulls,
      );
      lg.i('[IAP] pre-tap queue: ${_preTapIds.length} unfinished');
    } catch (e) {
      lg.i('[IAP] pre-tap queue snapshot FAILED, replays will pass: $e');
    }
  }

  @override
  Future<void> close() async {
    _stuck?.cancel();
    await _iapSub?.cancel();
    // A batch mid-validation still has a transaction to finish with the store;
    // dropping it here would leave it unfinished and block the next purchase of
    // the same product. `_emit` already no-ops once closed.
    await _processing;
    return super.close();
  }

  void _emit(CheckoutState next) {
    if (next.phase != CheckoutPhase.paying) {
      _stuck?.cancel();
      // The charge is settled — anything arriving now is a replay or a
      // renewal, not this user's tap.
      // ponytail: _succeed() awaits refreshStatus() before emitting, so the
      // gate stays open for that window. Close it earlier if a replay ever
      // lands inside it.
      _awaitingTap = false;
    }
    if (!isClosed) {
      emit(next);
    }
  }

  void _fail(String message) =>
      _emit(state.copyWith(phase: CheckoutPhase.failed, error: message));

  Future<void> _succeed() async {
    final sw = Stopwatch()..start();
    await subscriptionCubit.refreshStatus();
    final s = subscriptionCubit.state.subscriptionStatus;
    // Tells apart "validate was slow" from "status read came back stale":
    // if this is fast but plan is still the old one, the backend hasn't
    // applied the upgrade yet.
    lg.i(
      '[IAP] post-validate status in ${sw.elapsedMilliseconds}ms — '
      'want=${plan.plan} got=${s?.plan} active=${s?.active} '
      'pending=${s?.pendingPlan}',
    );
    _emit(state.copyWith(phase: CheckoutPhase.success));
  }

  Future<void> start() async {
    _lightningPaid = false;

    _emit(
      state.copyWith(
        phase: CheckoutPhase.paying,
        error: '',
        notice: '',
        clearInvoice: true,
      ),
    );
    try {
      await accountSession;
      switch (method) {
        case CheckoutMethod.iap:
          await _startIap();
        case CheckoutMethod.stripe:
          await _startStripe();
        case CheckoutMethod.lightning:
          await _startLightning();
      }
    } catch (e) {
      lg.i(e);
      _fail(e.toString());
    }
  }

  // -- IAP --

  Future<void> _startIap() async {
    await subscriptionCubit.refreshStatus();
    if (isClosed) {
      return;
    }

    final response = await InAppPurchase.instance.queryProductDetails({
      plan.iapProductId,
    });
    if (isClosed) {
      return;
    }
    final product = response.productDetails.firstOrNull;
    if (product == null) {
      // The three ways this fails look identical to the user but need
      // different fixes: a store/network error, a product id missing from
      // App Store Connect / Play Console, or a response that is simply empty.
      lg.i(
        '[IAP] no product for ${plan.iapProductId} — '
        'error=${response.error?.code}/${response.error?.message} '
        'notFound=${response.notFoundIDs} '
        'returned=${response.productDetails.length}',
      );
      _fail(t.pricing_error_product_unavailable);
      return;
    }

    final status = subscriptionCubit.state.subscriptionStatus;
    if (status != null &&
        status.active &&
        status.lastPaymentMethod == 'stripe') {
      _fail(t.pricing_error_stripe_active);
      return;
    }

    if (status != null && status.isActivePaidSub && status.plan == plan.plan) {
      _fail(t.pricing_error_iap_already_active);
      return;
    }

    // `active`, not `isActivePaidSub` — a Play free trial still has a real
    // purchase token, so a same-rail trial must take the plan-switch path.
    final activeIap =
        status != null && status.active && status.lastPaymentMethod == 'iap';

    if (activeIap && Platform.isAndroid && _androidPurchase == null) {
      await _recoverAndroidPurchase();
      if (isClosed) {
        return;
      }
      if (_androidPurchase == null) {
        _fail(t.pricing_error_iap_manage_in_other_app);
        return;
      }
    }

    final oldPurchase = _androidPurchase;
    final isAndroidPlanSwitch = Platform.isAndroid &&
        oldPurchase != null &&
        oldPurchase.productID != product.id;

    await _snapshotPendingTransactions();
    if (isClosed) {
      return;
    }

    _awaitingTap = true;
    _switching = isAndroidPlanSwitch;
    // ponytail: the paying phase is unpoppable, so a store that never answers
    // traps the user. One timeout, no retry ladder.
    _stuck?.cancel();
    _stuck = Timer(const Duration(seconds: 90), () {
      if (state.phase == CheckoutPhase.paying) {
        _fail(t.pricing_error_store);
      }
    });
    await _buy(
      isAndroidPlanSwitch
          ? GooglePlayPurchaseParam(
              productDetails: product,
              changeSubscriptionParam: ChangeSubscriptionParam(
                oldPurchaseDetails: oldPurchase as GooglePlayPurchaseDetails,
                replacementMode: ReplacementMode.withTimeProration,
              ),
            )
          : PurchaseParam(productDetails: product),
    );
    // Outcome arrives on the stream — stay in `paying`.
  }

  Future<void> _buy(PurchaseParam param) async {
    try {
      // The outcome still arrives on the stream, but a `false` here means the
      // sheet never opened — nothing will ever arrive, so don't wait 90s to
      // find that out.
      if (!await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: param)) {
        lg.i('[IAP] buyNonConsumable returned false for ${plan.iapProductId}');
        _fail(t.pricing_error_store);
      }
    } on PlatformException catch (e) {
      lg.i(e);
      if (e.code != 'storekit_duplicate_product_object') {
        rethrow;
      }
      lg.i('[IAP] duplicate product object for ${plan.iapProductId}, draining');
      await _drainQueueFor(plan.iapProductId);
      if (isClosed) {
        return;
      }
      try {
        if (!await InAppPurchase.instance
            .buyNonConsumable(purchaseParam: param)) {
          lg.i('[IAP] buyNonConsumable returned false after drain');
          _fail(t.pricing_error_store);
        }
      } catch (e) {
        lg.i('[IAP] buy failed after drain: $e');
        _fail(t.pricing_error_store);
      }
    }
  }

  Future<void> _drainQueueFor(String productId) async {
    const settled = {
      SKPaymentTransactionStateWrapper.purchased,
      SKPaymentTransactionStateWrapper.failed,
      SKPaymentTransactionStateWrapper.restored,
    };
    final queue = SKPaymentQueueWrapper();
    final List<SKPaymentTransactionWrapper> pending;
    try {
      pending = await queue.transactions();
    } catch (e) {
      lg.i('[IAP] queue read failed: $e');
      return;
    }

    for (final tx in pending) {
      if (tx.payment.productIdentifier != productId ||
          !settled.contains(tx.transactionState)) {
        continue;
      }
      try {
        await queue.finishTransaction(tx);
        // Snapshotted before the drain — left in, a re-delivery of this id
        // would read as a replay and swallow a purchase the user paid for.
        _preTapIds.remove(tx.transactionIdentifier);
        lg.i('[IAP] finished stale ${tx.transactionIdentifier}');
      } catch (e) {
        lg.i('[IAP] finish ${tx.transactionIdentifier} failed: $e');
      }
    }

    if (pending.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Asks Play to replay existing purchases so a plan switch can reference
  /// one. `restorePurchases()` resolves before the stream delivers, so poll
  /// briefly for [_handlePurchaseUpdate] to record what arrives.
  Future<void> _recoverAndroidPurchase() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      lg.i('[IAP] restorePurchases during plan switch failed: $e');
      return;
    }
    for (var i = 0; i < 20 && _androidPurchase == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Tail of the transaction-processing chain. The stream can deliver a second
  /// batch while the first is still awaiting the backend, and both mutate the
  /// same checkout state — so batches are queued behind each other rather than
  /// validated concurrently.
  Future<void> _processing = Future<void>.value();

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    _processing = _processing
        .then((_) => _processBatch(purchases))
        .catchError((Object e) => lg.i('[IAP] batch failed: $e'));
  }

  Future<void> _processBatch(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      // Play reports a cancel/error with no purchase attached, so the plugin
      // synthesises a PurchaseDetails with an empty productID. Nothing else
      // arrives without an id, so an empty one belongs to the tap in flight.
      // StoreKit always fills productID, so the leniency stays Android-only.
      final isThisPlan =
          _awaitingTap &&
          (purchase.productID == plan.iapProductId ||
              (Platform.isAndroid && purchase.productID.isEmpty));
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // `purchased` and `restored` carry different guarantees on each
          // store, so each side decides for itself what counts as this user's
          // purchase.
          if (Platform.isIOS) {
            await _handleIosSettled(purchase);
          } else {
            await _handleAndroidSettled(purchase);
          }

        case PurchaseStatus.error:
          // No identity to match on — Apple only fills transactionIdentifier
          // for purchased/restored, so a replayed failure can't be told from a
          // fresh one. Logged so a repro says which path killed the checkout.
          lg.i(
            '[IAP] error ${purchase.productID} awaitingTap=$_awaitingTap '
            'id=${purchase.purchaseID} err=${purchase.error}',
          );
          // Apple/Google require every observed transaction to be finished,
          // even failed ones, or it stays stuck in the queue.
          await ackIapPurchase(purchase);
          if (isThisPlan) {
            _fail(t.pricing_error_store);
          }

        case PurchaseStatus.canceled:
          lg.i(
            '[IAP] canceled ${purchase.productID} awaitingTap=$_awaitingTap '
            'id=${purchase.purchaseID}',
          );
          await ackIapPurchase(purchase);
          if (isThisPlan) {
            _emit(state.copyWith(phase: CheckoutPhase.cancelled));
          }
      }
    }
  }

  Future<void> _handleIosSettled(PurchaseDetails purchase) async {
    final isReplay =
        purchase.purchaseID != null && _preTapIds.contains(purchase.purchaseID);

    lg.i(
      '[IAP][ios] ${purchase.productID} want=${plan.iapProductId} '
      'status=${purchase.status.name} awaitingTap=$_awaitingTap '
      'id=${purchase.purchaseID} replay=$isReplay '
      'preTap=${_preTapIds.length}',
    );

    // Sent with this checkout's `product_id`, a foreign transaction fails the
    // backend's product check and surfaces as the user's purchase failing.
    if (isReplay || !_awaitingTap || purchase.productID != plan.iapProductId) {
      if (_awaitingTap && !isReplay) {
        lg.i(
          '[IAP][ios] SWALLOWED ${purchase.productID} mid-checkout for '
          '${plan.iapProductId} — wrong product, acknowledged not validated',
        );
      }
      await ackIapPurchase(purchase);
      return;
    }

    // ponytail: a genuine renewal minted mid-checkout isn't in the snapshot
    // and reaches here. Validating a renewal receipt is harmless, so it stays
    // uncaught.
    await _validate(purchase);
  }

  Future<void> _handleAndroidSettled(PurchaseDetails purchase) async {
    final isOtherProduct = purchase.productID != plan.iapProductId;

    if (!_awaitingTap || !isOtherProduct) {
      _androidPurchase = purchase;
    }

    lg.i(
      '[IAP][android] ${purchase.productID} want=${plan.iapProductId} '
      'status=${purchase.status.name} awaitingTap=$_awaitingTap '
      'switching=$_switching id=${purchase.purchaseID}',
    );

    if (!_awaitingTap || isOtherProduct) {
      await ackIapPurchase(purchase);

      if (_awaitingTap && _switching) {
        _emit(state.copyWith(notice: t.pricing_iap_switching_plan));
      }
      return;
    }

    await _validate(purchase);
  }

  /// Validates the transaction this checkout was waiting for and settles the
  /// checkout on the verdict. The validation itself lives in
  /// [validateIapPurchase] — only the mapping to checkout state is here.
  Future<void> _validate(PurchaseDetails purchase) async {
    switch (await validateIapPurchase(purchase)) {
      case IapValidation.valid:
        await _succeed();
      case IapValidation.otherAccount:
        _fail(t.pricing_restore_other_account);
      case IapValidation.anotherActive:
        _fail(t.pricing_error_iap_already_active);
      case IapValidation.invalid:
        _fail(t.pricing_error_validation);
    }
  }

  // -- Stripe --

  Future<void> _startStripe() async {
    final url = await HttpFunctionsRepository.subscriptionGetLink(
      planId: plan.plan,
    );
    if (isClosed) {
      return;
    }
    if (url == null) {
      _fail(t.pricing_error_checkout);
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    // Stripe is fire-and-forget — payment completes in the browser and the
    // webhook flips the subscription, so there's nothing here to wait on.
    // Terminal state with an exit rather than a spinner that never resolves.
    _emit(state.copyWith(phase: CheckoutPhase.handedOff));
  }

  // -- Lightning --

  Future<void> _startLightning() async {
    // Lightning pays an external LNURL address — nothing server-side can block
    // the sats. Warn before a still-renewing subscription is paid for twice.
    final status = subscriptionCubit.state.subscriptionStatus;
    if (status != null &&
        status.active &&
        (status.lastPaymentMethod == 'stripe' ||
            status.lastPaymentMethod == 'iap')) {
      _fail(t.pricing_error_other_active);
      return;
    }

    final lnAddr = dotenv.env['YAKIPRO_LIGHTNING_ADDR'] ?? '';
    if (lnAddr.isEmpty) {
      _fail(t.pricing_error_ln_not_configured);
      return;
    }

    final lnurlp = await HttpFunctionsRepository.lnurlpFetch(lnAddr);
    if (isClosed) {
      return;
    }
    final callback = lnurlp?['callback'] as String?;
    if (callback == null) {
      _fail(
        lnurlp == null ? t.pricing_error_ln_fetch : t.pricing_error_ln_invalid,
      );
      return;
    }

    // Captured once: the sheet must show the same pubkey the LNURL comment
    // was signed with, even if the account switches while the invoice is open.
    pubkey = currentSigner?.getPublicKey() ?? '';
    final invoice = await HttpFunctionsRepository.lnurlpInvoice(
      callback: callback,
      amountSats: plan.satsRaw,
      comment: jsonEncode({'plan': plan.plan, 'pubkey': pubkey}),
    );
    if (isClosed) {
      return;
    }
    if (invoice == null) {
      _fail(t.pricing_error_ln_invoice);
      return;
    }
    // The screen listens for this and opens the invoice sheet.
    _emit(state.copyWith(invoice: invoice));
  }

  String pubkey = '';

  /// Clears the pending invoice once the screen has opened the sheet for it —
  /// otherwise a later phase change re-triggers the listener and reopens it.
  void invoiceShown() => _emit(state.copyWith(clearInvoice: true));

  bool _lightningPaid = false;

  Future<void> lightningPaid() {
    // Set synchronously: [lightningDismissed] runs before the async refresh in
    // _succeed() lands, and would otherwise read the still-`paying` phase as
    // "closed without paying" and pop the screen.
    _lightningPaid = true;
    return _succeed();
  }

  /// Invoice sheet closed without paying — back to the plans.
  void lightningDismissed() {
    if (!_lightningPaid && state.phase == CheckoutPhase.paying) {
      _emit(state.copyWith(phase: CheckoutPhase.cancelled));
    }
  }
}
