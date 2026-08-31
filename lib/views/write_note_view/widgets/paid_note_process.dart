import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/content_published_modal.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/modal_sheet_container.dart';

enum _SheetView { initial, invoice, paying }

class PaidNoteProcess extends HookWidget {
  const PaidNoteProcess({
    super.key,
    required this.checkZap,
  });

  final bool checkZap;

  int get _effectiveSats {
    if (subscriptionCubit.isPremium) {
      return 0;
    }
    if (subscriptionCubit.isBasic) {
      return 400;
    }
    return 800;
  }

  int get _effectivePoints {
    if (subscriptionCubit.isPremium) {
      return 0;
    }
    if (subscriptionCubit.isBasic) {
      return 400;
    }
    return 800;
  }

  bool get _canPayWithPoints =>
      !subscriptionCubit.isPremium &&
      pointsManagementCubit.state.consumablePoints >= _effectivePoints;

  bool _hasPayOptions(WalletsManagerState wallets) =>
      wallets.hasSelectedWallet || _hasExternalWallet(wallets);

  /// Whether a usable external wallet is configured for hand-off.
  bool _hasExternalWallet(WalletsManagerState walletsState) =>
      walletsState.defaultExternalWallet.isNotEmpty &&
      wallets.containsKey(walletsState.defaultExternalWallet);

  String _invoiceComment(Event event) {
    return encodeGiftToken({
      'pubkey': currentSigner?.getPublicKey() ?? '',
      'note_id': event.id,
    });
  }

  void _goBack(BuildContext context, ValueNotifier<_SheetView> view) {
    context.read<WalletsManagerCubit>().resetInvoice();
    context.read<WriteNoteCubit>().resetVerification();
    view.value = _SheetView.initial;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final view = useState(_SheetView.initial);
    final usePoints = useState(_canPayWithPoints);

    useEffect(
      () {
        final walletsCubit = context.read<WalletsManagerCubit>();
        final noteCubit = context.read<WriteNoteCubit>();
        // Resumed flow (unpaid note from dashboard): start waiting right away
        // — the stream answers `paid` immediately if the invoice already
        // settled.
        if (checkZap &&
            _hasPayOptions(context.read<WalletsManagerCubit>().state)) {
          noteCubit.verifyAndPublish();
        }
        // Closing the sheet must leave no stale invoice/verification behind.
        return () {
          walletsCubit.resetInvoice();
          noteCubit.resetVerification();
        };
      },
      [checkZap],
    );

    return BlocListener<WriteNoteCubit, WriteNoteState>(
      listenWhen: (previous, current) =>
          previous.verification != current.verification,
      listener: (context, state) {
        if (state.verification == PaidNoteVerification.published) {
          final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
          final rootCtx = YNavigator.navigatorKey.currentContext ??
              nostrRepository.currentContext();

          Navigator.pop(context);
          if (!checkZap && Navigator.canPop(rootCtx)) {
            Navigator.pop(rootCtx);
          }

          if (event != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final rootContext = YNavigator.navigatorKey.currentContext ??
                  nostrRepository.currentContext();
              if (rootContext.mounted) {
                showContentPublishedModalSheet(
                  rootContext,
                  event: DetailedNoteModel.fromEvent(event),
                  contentType: AppContentType.note,
                  isPaid: true,
                );
              }
            });
          }
        }
      },
      child: ModalSheetContainer(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.40,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) =>
              BlocBuilder<WriteNoteCubit, WriteNoteState>(
            builder: (context, state) {
              if (state.verification == PaidNoteVerification.published) {
                return const SizedBox.shrink();
              }

              return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
                builder: (context, wallets) {
                  return Column(
                    children: [
                      _header(context, view),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 10.w : kDefaultPadding,
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: switch (view.value) {
                                _SheetView.initial => _initialBody(
                                    context,
                                    wallets,
                                    state,
                                    usePoints,
                                  ),
                                _SheetView.invoice =>
                                  _invoiceBody(context, wallets, state),
                                _SheetView.paying => _payingBody(
                                    context,
                                    usePoints,
                                    state,
                                  ),
                              },
                            ),
                          ),
                        ),
                      ),
                      _bottomNavBar(
                        context,
                        view,
                        wallets,
                        state,
                        usePoints,
                        isTablet,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    ValueNotifier<_SheetView> view,
  ) {
    final canGoBack = view.value != _SheetView.initial;
    final title = switch (view.value) {
      _SheetView.initial => context.t.payPublish,
      _SheetView.invoice => context.t.invoice,
      _SheetView.paying => context.t.lightning,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        const Center(child: ModalBottomSheetHandle()),
        const SizedBox(height: kDefaultPadding / 4),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: canGoBack
                    ? AppIconButton(
                        icon: LucideIcons.chevronLeft,
                        onClicked: () => _goBack(context, view),
                      )
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).primaryColorDark,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 45),
            ],
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
      ],
    );
  }

  // ============================================================
  // Bodies
  // ============================================================

  Widget _initialBody(
    BuildContext context,
    WalletsManagerState wallets,
    WriteNoteState state,
    ValueNotifier<bool> usePoints,
  ) {
    final noPayOptions =
        !_hasPayOptions(wallets) && !(usePoints.value && _canPayWithPoints);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _amountDisplay(context, true, !usePoints.value),
        const SizedBox(height: kDefaultPadding / 2),
        _noteContainer(context),
        const SizedBox(height: kDefaultPadding),
        if (noPayOptions)
          _noWalletNotice(context)
        else
          _statusRow(context, state),
      ],
    );
  }

  /// Persistent notice shown when neither an in-app nor an external wallet is
  /// available — waiting would be pointless.
  Widget _noWalletNotice(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(
          LucideIcons.circleAlert,
          size: 18.w,
          color: kRed,
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Flexible(
          child: Text(
            context.t.paidNoteNoExternalWallet.capitalizeFirst(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: kRed,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _invoiceBody(
    BuildContext context,
    WalletsManagerState wallets,
    WriteNoteState state,
  ) {
    final hasInvoice = wallets.isLnurlAvailable && wallets.lnurl.isNotEmpty;
    final qrSide = 80.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: qrSide,
          height: qrSide,
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Colors.white,
          ),
          child: hasInvoice
              ? QrImageView(
                  data: wallets.lnurl,
                  dataModuleStyle: const QrDataModuleStyle(
                    color: kBlack,
                    dataModuleShape: QrDataModuleShape.circle,
                  ),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: kBlack,
                  ),
                )
              : Center(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColorDark,
                    size: 42,
                  ),
                ),
        ),
        const SizedBox(height: kDefaultPadding),
        _statusRow(context, state),
      ],
    );
  }

  Widget _payingBody(
    BuildContext context,
    ValueNotifier<bool> usePoints,
    WriteNoteState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _amountDisplay(context, true, !usePoints.value),
        const SizedBox(height: kDefaultPadding),
        _statusRow(context, state),
      ],
    );
  }

  Widget _amountDisplay(BuildContext context, bool satsAvailable, bool isSats) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          (isSats ? _effectiveSats : _effectivePoints).toString(),
          style: theme.textTheme.displayMedium!.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          isSats ? 'SATS' : context.t.points.toUpperCase(),
          style: theme.textTheme.displaySmall!.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _noteContainer(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: theme.cardColor,
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Text(
        context.t.payPublishNote.capitalizeFirst(),
        style: theme.textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Live payment status under the content: mirrors the raw SSE events
  /// (`waiting` → spinner hint, `unpaid` → red notice once the stream died)
  /// plus the publishing step.
  Widget _statusRow(BuildContext context, WriteNoteState state) {
    final theme = Theme.of(context);
    final verification = state.verification;

    if (verification == PaidNoteVerification.idle) {
      return const SizedBox.shrink();
    }

    final String label;
    var showSpinner = false;

    switch (verification) {
      case PaidNoteVerification.verifying:
        showSpinner = true;
        label = state.paymentStatus == 'paid'
            ? context.t.paidNotePublishing
            : context.t.paidNoteWaitingPayment;
      case PaidNoteVerification.publishing:
        showSpinner = true;
        label = context.t.paidNotePublishing;
      case PaidNoteVerification.awaitingConfirm:
        label = context.t.invoiceNotPayed.capitalizeFirst();
      case PaidNoteVerification.published:
      case PaidNoteVerification.idle:
        return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kDefaultPadding / 2,
      children: [
        if (showSpinner) ...[
          SpinKitCircle(
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ] else ...[
          const AppIcon(
            LucideIcons.circleAlert,
            size: 20,
            color: kRed,
          ),
        ],
        Text(
          label,
          style: theme.textTheme.labelMedium!.copyWith(
            color: showSpinner ? theme.hintColor : kRed,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================================
  // Bottom actions
  // ============================================================

  Widget _bottomNavBar(
    BuildContext context,
    ValueNotifier<_SheetView> view,
    WalletsManagerState wallets,
    WriteNoteState state,
    ValueNotifier<bool> usePoints,
    bool isTablet,
  ) {
    final verification = state.verification;

    Widget? actions;

    switch (view.value) {
      case _SheetView.initial:
        if (verification == PaidNoteVerification.awaitingConfirm) {
          actions = _checkPayment(context);
        } else if (verification == PaidNoteVerification.idle) {
          final canPayWithPoints = _canPayWithPoints;
          final payWithPoints = canPayWithPoints && usePoints.value;

          // Points selected: the only action is Pay.
          Widget primary;
          if (payWithPoints) {
            primary = const SizedBox(
              width: double.infinity,
              child: _PointsButton(),
            );
          } else if (!_hasPayOptions(wallets)) {
            // No wallet to pay from — only the invoice route remains (it can
            // still be paid from another device/app).
            primary = SizedBox(
              width: double.infinity,
              child: _getInvoice(context, view),
            );
          } else {
            primary = Row(
              spacing: kDefaultPadding / 4,
              children: [
                Expanded(child: _getInvoice(context, view)),
                Expanded(child: _pay(context, wallets, view)),
              ],
            );
          }

          actions = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Method toggle sits on top of the buttons, only when there are
              // enough points to actually pay with.
              if (canPayWithPoints) ...[
                _MethodPicker(usePoints: usePoints),
                const SizedBox(height: kDefaultPadding / 2),
              ],
              primary,
            ],
          );
        }
      case _SheetView.invoice:
        if (verification == PaidNoteVerification.awaitingConfirm) {
          actions = Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(child: _copyInvoice(context, wallets)),
              Expanded(child: _checkPayment(context)),
            ],
          );
        } else {
          actions = SizedBox(
            width: double.infinity,
            child: _copyInvoice(context, wallets),
          );
        }
      case _SheetView.paying:
        if (verification == PaidNoteVerification.awaitingConfirm) {
          actions = _checkPayment(context);
        }
    }

    return Container(
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: kDefaultPadding / 2 + MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
          horizontal: isTablet ? 10.w : 0,
        ),
        child: actions ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _checkPayment(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SendOptionsButton(
        onClicked: () => context.read<WriteNoteCubit>().checkPaymentStatus(),
        title: context.t.checkPaymentStatus,
        icon: LucideIcons.refreshCw,
      ),
    );
  }

  Widget _copyInvoice(
    BuildContext context,
    WalletsManagerState wallets,
  ) {
    return SendOptionsButton(
      onClicked: () {
        Clipboard.setData(ClipboardData(text: wallets.lnurl));
        BotToastUtils.showSuccess(context.t.invoiceCopied.capitalizeFirst());
      },
      title: context.t.copy.capitalizeFirst(),
      icon: FeatureIcons.copy,
    );
  }

  Widget _pay(
    BuildContext context,
    WalletsManagerState wallets,
    ValueNotifier<_SheetView> view,
  ) {
    return SendOptionsButton(
      onClicked: () {
        final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
        if (event == null || !context.mounted) {
          return;
        }

        final walletsCubit = context.read<WalletsManagerCubit>();
        final hasInternalWallet = walletsCubit.state.hasSelectedWallet;
        final hasExternalWallet = _hasExternalWallet(walletsCubit.state);

        // No in-app wallet and nothing to hand off to — stop the payment wait
        // and fall back to the sheet's initial screen.
        if (!hasInternalWallet && !hasExternalWallet) {
          BotToastUtils.showError(
            context.t.paidNoteNoExternalWallet.capitalizeFirst(),
          );
          _goBack(context, view);
          return;
        }

        // Watch for settlement while the wallet pays — once it settles the
        // note publishes itself.
        context.read<WriteNoteCubit>().verifyAndPublish();

        view.value = _SheetView.paying;

        walletsCubit.handleWalletZap(
          sats: _effectiveSats,
          user: Metadata.empty().copyWith(
            lud16: nostrRepository.yakihonneWallet,
            pubkey: yakihonneHex,
          ),
          comment: _invoiceComment(event),
          eventId: event.id,
          onFinished: (_) {},
          onSuccess: (_) {},
          onFailure: (message) {
            // The payment couldn't be handed off (e.g. the external wallet is
            // missing) — stop waiting and return to the initial screen.
            BotToastUtils.showError(message);
            if (context.mounted) {
              _goBack(context, view);
            }
          },
        );
      },
      title: context.t.pay,
      icon: FeatureIcons.zaps,
      isLoading: !wallets.isLoading ? null : true,
    );
  }

  Widget _getInvoice(
    BuildContext context,
    ValueNotifier<_SheetView> view,
  ) {
    return SendOptionsButton(
      onClicked: () async {
        final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
        if (event == null || !context.mounted) {
          return;
        }

        view.value = _SheetView.invoice;

        // Watch for the settlement as soon as an invoice exists, so an
        // external wallet payment is detected without any extra tap.
        context.read<WriteNoteCubit>().verifyAndPublish();

        await context.read<WalletsManagerCubit>().generateZapInvoice(
              sats: _effectiveSats,
              user: Metadata.empty().copyWith(
                lud16: nostrRepository.paidNoteWallet,
              ),
              comment: _invoiceComment(event),
              eventId: event.id,
              onFailure: (message) {
                BotToastUtils.showError(message);
                _goBack(context, view);
              },
            );
      },
      title: context.t.getInvoice,
      icon: FeatureIcons.note,
    );
  }
}

class _PointsButton extends HookWidget {
  const _PointsButton();

  @override
  Widget build(BuildContext context) {
    final isPaying = useState(false);

    return SendOptionsButton(
      onClicked: isPaying.value
          ? () {}
          : () {
              isPaying.value = true;
              context.read<WriteNoteCubit>().redeemPointsAndPublish(
                (msg) {
                  isPaying.value = false;
                  BotToastUtils.showError(msg);
                },
              );
            },
      title: context.t.pay,
      icon: FeatureIcons.zap,
      isLoading: isPaying.value ? true : null,
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.usePoints});
  final ValueNotifier<bool> usePoints;

  @override
  Widget build(BuildContext context) {
    return FluidCardContainer(
      borderRadius: kDefaultPadding / 2,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
            label: context.t.pricing_toggle_sats,
            selected: !usePoints.value,
            onTap: () => usePoints.value = false,
          ),
          _Tab(
            label: context.t.points.capitalizeFirst(),
            selected: usePoints.value,
            onTap: () => usePoints.value = true,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2 - 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : theme.highlightColor,
            ),
          ),
        ),
      ),
    );
  }
}
