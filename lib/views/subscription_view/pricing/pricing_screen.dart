// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../logic/metadata_cubit/metadata_cubit.dart';
import '../../../models/app_models/pricing_plan_model.dart';
import '../../../models/points_system_models.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import 'widgets/lightning_invoice_sheet.dart';
import 'widgets/plan_card.dart';
import 'widgets/pricing_hero.dart';
import 'widgets/subscription_success_view.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isLn = false;
  bool _isPoints = false;
  String? _loadingPlanId;
  bool _restoringPurchases = false;
  PointsEligibility? _eligibility;
  List<PricingPlan> _plans = [];
  bool _plansLoading = true;

  StreamSubscription<List<PurchaseDetails>>? _iapSub;
  final Map<String, ProductDetails> _iapProducts = {};
  PurchaseDetails? _activeAndroidPurchase;

  bool get _useIap => kIapEnabled;

  // Ensures the backend account exists before any checkout path runs —
  // mirrors yaki_pro's routing-level auth gate, scoped to this screen since
  // mobile-app's Nostr sign-in has no backend round-trip of its own.
  // isSystemLoggedIn (a session flag) isn't a substitute: it only means
  // "/login succeeded at some point," not "the account still exists now"
  // (e.g. after a backend reset/migration). Started once in initState and
  // awaited everywhere checkout can be triggered, so it's a single in-flight
  // call, not a re-fetch per tap.
  late final Future<void> _accountSessionFuture;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
    _fetchEligibility();
    _accountSessionFuture = _ensureAccountSession();
  }

  Future<void> _ensureAccountSession() async {
    if (currentSigner?.canSign() ?? false) {
      await HttpFunctionsRepository.loginToAppSystem();
    }
  }

  Future<void> _fetchPlans() async {
    final result = await HttpFunctionsRepository.getSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plans = result;
        _plansLoading = false;
      });
    }
    if (_useIap) {
      startIap();
    }
  }

  Future<void> _fetchEligibility() async {
    try {
      final result = await HttpFunctionsRepository.getSubscriptionEligibility();
      if (mounted) {
        setState(() => _eligibility = result);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  Future<void> startIap() async {
    final available = await InAppPurchase.instance.isAvailable();
    lg.i('[IAP] available: $available');
    _iapSub = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (_) {},
    );

    _queryIapProducts();
  }

  Future<void> _queryIapProducts() async {
    final ids =
        _plans.map((p) => p.iapProductId).where((id) => id.isNotEmpty).toSet();
    final response = await InAppPurchase.instance.queryProductDetails(ids);
    lg.i('[IAP] found: ${response.productDetails.map((p) {
      return p.id;
    })}');
    lg.i('[IAP] not found: ${response.notFoundIDs}');
    if (response.error != null) {
      lg.i('[IAP] error: ${response.error}');
    }
    if (mounted) {
      setState(() {
        for (final p in response.productDetails) {
          _iapProducts[p.id] = p;
        }
      });
    }
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      lg.i(purchase.status);
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final pubkey = currentSigner?.getPublicKey() ?? '';
          final platform = Platform.isIOS ? 'ios' : 'android';
          final receipt = Platform.isIOS
              ? purchase.verificationData.serverVerificationData
              : purchase.verificationData.serverVerificationData;

          lg.i(
              '[IAP] receipt length=${receipt.length} prefix=${receipt.substring(0, receipt.length.clamp(0, 40))}');

          // Covers store-redelivered transactions that fire independent of
          // a checkout tap (e.g. billing reconnect on screen open) — same
          // account-session gate as _checkout, reusing the one in-flight call.
          await _accountSessionFuture;

          final validated =
              await HttpFunctionsRepository.subscriptionValidateIap(
            platform: platform,
            receipt: receipt,
            productId: purchase.productID,
            pubkey: pubkey,
          );

          // Always complete with the store to clear the purchase from the queue.
          try {
            await InAppPurchase.instance.completePurchase(purchase);
          } catch (e) {
            lg.i('[IAP] completePurchase error: $e');
          }

          // StoreKit/Play redeliver existing (and even cancelled/expired)
          // transactions on every billing reconnect (e.g. just opening this
          // screen), not only on a fresh buy or explicit "Restore" tap.
          // _loadingPlanId holds the plan code (e.g. "basic"), not the
          // store product id, so resolve it via iapProductId to compare.
          final wasUserInitiated = _restoringPurchases ||
              _plans.any((p) =>
                  p.plan == _loadingPlanId &&
                  p.iapProductId == purchase.productID);

          if (validated != null) {
            if (Platform.isAndroid) {
              _activeAndroidPurchase = purchase;
            }
            // Only show the success screen for a purchase the user actually
            // just tapped, otherwise silently sync status.
            await subscriptionCubit.refreshStatus();
            if (mounted) {
              setState(() => _loadingPlanId = null);
              if (wasUserInitiated) {
                final plan = _plans.firstWhere(
                  (p) => p.plan == (validated['plan'] as String? ?? ''),
                  orElse: () => _plans.firstWhere(
                    (p) => p.iapProductId == purchase.productID,
                    orElse: () => _plans.last,
                  ),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionSuccessView(
                      planName: plan.name,
                      price: '${plan.price}${plan.period}',
                    ),
                  ),
                );
              }
            }
          } else {
            // Backend validation failed — payment was taken but subscription not activated.
            // Restore purchases will retry validation on next open.
            if (mounted) {
              setState(() => _loadingPlanId = null);
              // Silent for passive replays the user didn't trigger — a stale
              // queued transaction failing validation isn't an error to them.
              if (wasUserInitiated) {
                BotToastUtils.showError(t.pricing_error_checkout);
              }
            }
          }

        case PurchaseStatus.error:
          // Apple/Google require every transaction observed on the queue to
          // be finished, even failed ones — otherwise it stays stuck and
          // blocks new purchases of the same product with
          // storekit_duplicate_product_object.
          try {
            await InAppPurchase.instance.completePurchase(purchase);
          } catch (e) {
            lg.i('[IAP] completePurchase error: $e');
          }
          if (mounted) {
            setState(() => _loadingPlanId = null);
            BotToastUtils.showError(t.pricing_error_checkout);
          }

        case PurchaseStatus.canceled:
          try {
            await InAppPurchase.instance.completePurchase(purchase);
          } catch (e) {
            lg.i('[IAP] completePurchase error: $e');
          }
          if (mounted) {
            setState(() => _loadingPlanId = null);
          }
      }
    }
  }

  Future<void> _checkout(PricingPlan plan) async {
    setState(() => _loadingPlanId = plan.plan);
    try {
      await _accountSessionFuture;
      if (_isPoints) {
        await _checkoutPoints(plan);
      } else if (_useIap) {
        await _checkoutIap(plan);
      } else if (_isLn) {
        await _checkoutLightning(plan);
      } else {
        await _checkoutStripe(plan);
      }
    } catch (e) {
      lg.i('[IAP] checkout failed: $e');
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(e.toString());
      }
    }
  }

  Future<void> _checkoutPoints(PricingPlan plan) async {
    try {
      final redeemed =
          await HttpFunctionsRepository.redeemSubscriptionWithPoints(plan.plan);
      if (!redeemed) {
        if (mounted) {
          setState(() => _loadingPlanId = null);
          BotToastUtils.showError(context.t.points_insufficient);
        }
        return;
      }
      await subscriptionCubit.refreshStatus();
      unawaited(pointsManagementCubit.getRecentStats());
      _fetchEligibility();
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showSuccess(context.t.pricing_points_success);
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.pricing_error_checkout,
        );
      }
    }
  }

  Future<void> _checkoutIap(PricingPlan plan) async {
    final status = subscriptionCubit.state.subscriptionStatus;
    if (status != null &&
        status.active &&
        status.lastPaymentMethod == 'stripe') {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(t.pricing_error_stripe_active);
      }
      return;
    }

    final product = _iapProducts[plan.iapProductId];

    if (product == null) {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(t.pricing_error_checkout);
      }
      return;
    }

    final oldPurchase = _activeAndroidPurchase;
    final isAndroidPlanSwitch = Platform.isAndroid &&
        oldPurchase != null &&
        oldPurchase.productID != product.id;

    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: isAndroidPlanSwitch
          ? GooglePlayPurchaseParam(
              productDetails: product,
              changeSubscriptionParam: ChangeSubscriptionParam(
                oldPurchaseDetails: oldPurchase as GooglePlayPurchaseDetails,
                replacementMode: ReplacementMode.withTimeProration,
              ),
            )
          : PurchaseParam(productDetails: product),
    );
  }

  Future<void> _checkoutStripe(PricingPlan plan) async {
    final url = await HttpFunctionsRepository.subscriptionGetLink(
      planId: plan.plan,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loadingPlanId = null);
    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      BotToastUtils.showError(context.t.pricing_error_checkout);
    }
  }

  Future<void> _checkoutLightning(PricingPlan plan) async {
    // Lightning payment happens against an external LNURL address, outside
    // yaki-api — nothing server-side can block the sats from being spent.
    // Warn here so a user with a still-renewing Stripe/IAP subscription
    // doesn't pay twice for the same period.
    final status = subscriptionCubit.state.subscriptionStatus;
    if (status != null &&
        status.active &&
        (status.lastPaymentMethod == 'stripe' ||
            status.lastPaymentMethod == 'iap')) {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        BotToastUtils.showError(t.pricing_error_other_active);
      }
      return;
    }

    final lnAddr = dotenv.env['YAKIPRO_LIGHTNING_ADDR'] ?? '';
    if (lnAddr.isEmpty) {
      setState(() => _loadingPlanId = null);
      BotToastUtils.showError(context.t.pricing_error_ln_not_configured);
      return;
    }

    final pubkey = currentSigner?.getPublicKey() ?? '';
    final lnurlp = await HttpFunctionsRepository.lnurlpFetch(lnAddr);
    if (!mounted) {
      return;
    }
    if (lnurlp == null) {
      BotToastUtils.showError(context.t.pricing_error_ln_fetch);
      return;
    }

    final callback = lnurlp['callback'] as String?;
    if (callback == null) {
      BotToastUtils.showError(context.t.pricing_error_ln_invalid);
      return;
    }

    final comment = jsonEncode({'plan': plan.plan, 'pubkey': pubkey});
    final invoice = await HttpFunctionsRepository.lnurlpInvoice(
      callback: callback,
      amountSats: plan.satsRaw,
      comment: comment,
    );
    if (!mounted) {
      return;
    }
    if (invoice == null) {
      BotToastUtils.showError(context.t.pricing_error_ln_invoice);
      return;
    }

    setState(() => _loadingPlanId = null);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LightningInvoiceSheet(
        invoice: invoice,
        planName: plan.name,
        sats: plan.sats,
        pubkey: pubkey,
        onPaid: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          subscriptionCubit.refreshStatus();
        },
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() => _restoringPurchases = true);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      if (mounted) {
        BotToastUtils.showError(t.pricing_error_checkout);
      }
    } finally {
      if (mounted) {
        setState(() => _restoringPurchases = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final pubkey = currentSigner?.getPublicKey() ?? '';
    final plans = _plans;
    final userPlan = subscriptionCubit.state.subscriptionStatus?.plan ?? '';
    final lastPaymentMethod =
        subscriptionCubit.state.subscriptionStatus?.lastPaymentMethod ?? '';
    final isActivePaidSub =
        (subscriptionCubit.state.subscriptionStatus?.active ?? false) &&
            !(subscriptionCubit.state.subscriptionStatus?.inTrial ?? true);
    final isWebManaged = _useIap &&
        isActivePaidSub &&
        lastPaymentMethod != 'iap' &&
        lastPaymentMethod != 'points';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<MetadataCubit, MetadataState>(
                bloc: metadataCubit,
                builder: (context, metaState) {
                  final meta = metaState.metadataCache[pubkey];
                  final picture = meta?.picture ?? '';
                  final displayName = meta?.displayName ?? '';
                  final name =
                      (displayName.isNotEmpty ? displayName : meta?.name) ?? '';
                  return PricingHeroHeader(
                    picture: picture,
                    name: name,
                    pubkey: pubkey,
                    isLn: _isLn,
                    isPoints: _isPoints,
                    onToggleLn: _useIap
                        ? null
                        : (v) => setState(() {
                              _isLn = v;
                              if (v) {
                                _isPoints = false;
                              }
                            }),
                    onTogglePoints: (!_useIap && _eligibility != null)
                        ? (v) => setState(() {
                              _isPoints = v;
                              if (v) {
                                _isLn = false;
                              }
                            })
                        : null,
                    onClose: () => Navigator.of(context).pop(),
                  );
                },
              ),
            ),
            if (isWebManaged)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    kDefaultPadding,
                    kDefaultPadding,
                    0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kDefaultPadding * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  ),
                  child: Text(
                    context.t.pricing_web_managed,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.primaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (_plansLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding * 2),
                  child: Center(
                      child: SpinKitCircle(
                          color: theme.primaryColorDark, size: 32)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding, kDefaultPadding, kDefaultPadding, 0),
                sliver: SliverList.separated(
                  itemCount: plans.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: kDefaultPadding / 2),
                  itemBuilder: (context, i) {
                    final plan = plans[i];
                    final isCurrent = isActivePaidSub && userPlan == plan.plan;
                    final isUpgrade = isActivePaidSub &&
                        plan.plan == 'premium' &&
                        userPlan == 'basic';
                    final pointsEligible = _isPoints &&
                        (_eligibility?.eligibleFor(plan.plan) ?? false);
                    final pointsCost = _eligibility?.costFor(plan.plan) ?? 0;
                    return PlanCard(
                      plan: plan,
                      isLn: !_useIap && _isLn,
                      isPoints: _isPoints,
                      pointsCost: pointsCost,
                      pointsEligible: pointsEligible,
                      isLoading: _loadingPlanId == plan.plan,
                      anyLoading: _loadingPlanId != null,
                      isCurrent: isCurrent,
                      isUpgrade: isUpgrade,
                      onCheckout:
                          (isWebManaged || (_isPoints && !pointsEligible))
                              ? null
                              : () => _checkout(plan),
                    );
                  },
                ),
              ),
            if (_useIap)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    kDefaultPadding / 2,
                    kDefaultPadding,
                    0,
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: _restoringPurchases ? null : _restorePurchases,
                      child: _restoringPurchases
                          ? SpinKitCircle(color: theme.primaryColor, size: 16)
                          : Text(
                              context.t.pricing_restore_purchases,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding,
                  bottomPad + kDefaultPadding,
                ),
                child: Text(
                  context.t.pricing_footer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
