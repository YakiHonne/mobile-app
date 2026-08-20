import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/modal_sheet_container.dart';

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

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isZapConfirmed = useState<bool?>(null);
    final usePoints = useState(_canPayWithPoints);
    final isPayingWithPoints = useState(false);

    useEffect(
      () {
        final walletsCubit = context.read<WalletsManagerCubit>();
        if (checkZap) {
          final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
          if (event != null) {
            NostrFunctionsRepository.checkPayment(event.id, skipDelay: true)
                .then((value) {
              if (context.mounted) {
                isZapConfirmed.value = value;
              }
            });
          } else {
            isZapConfirmed.value = false;
          }
        } else {
          isZapConfirmed.value = false;
        }
        return walletsCubit.resetInvoice;
      },
      [checkZap],
    );

    return ModalSheetContainer(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.40,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Center(child: ModalBottomSheetHandle()),
            const SizedBox(height: kDefaultPadding / 4),
            Center(
              child: Text(
                context.t.payPublish.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            Expanded(
              child: _informationColumn(context, isTablet, usePoints),
            ),
            _bottomNavBar(
              context,
              isTablet,
              isZapConfirmed,
              usePoints,
              isPayingWithPoints,
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationColumn(
    BuildContext context,
    bool isTablet,
    ValueNotifier<bool> usePoints,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
        horizontal: isTablet ? 10.w : kDefaultPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Payment method selector — only shown when points are available
          if (_canPayWithPoints) ...[
            _MethodPicker(usePoints: usePoints),
            const SizedBox(height: kDefaultPadding),
          ],
          // Cost display
          Text(
            usePoints.value
                ? _effectivePoints.toString()
                : _effectiveSats.toString(),
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            usePoints.value ? context.t.points.toUpperCase() : 'SATS',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Text(
              context.t.payPublishNote.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavBar(
    BuildContext context,
    bool isTablet,
    ValueNotifier<bool?> isZapConfirmed,
    ValueNotifier<bool> usePoints,
    ValueNotifier<bool> isPayingWithPoints,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Center(
        child: BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
          builder: (context, lightningState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: kDefaultPadding / 4,
                horizontal: isTablet ? 10.w : 0,
              ),
              child: Builder(
                builder: (context) {
                  if (isZapConfirmed.value == null) {
                    return const Center(child: SearchLoading());
                  }

                  if (isZapConfirmed.value ?? false) {
                    return Row(
                      spacing: kDefaultPadding / 4,
                      children: [_confirm(lightningState, context)],
                    );
                  }

                  // Points payment flow
                  if (usePoints.value) {
                    return SizedBox(
                      width: double.infinity,
                      child: _payWithPoints(context, isPayingWithPoints),
                    );
                  }

                  // Lightning payment flow
                  if (!lightningState.isLnurlAvailable) {
                    return Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        _getInvoice(lightningState, context),
                        _pay(lightningState, context),
                        _confirm(lightningState, context),
                      ],
                    );
                  } else {
                    return Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        _cancelInvoice(context),
                        _qrCode(context, lightningState),
                        _copy(lightningState, context),
                        _confirm(lightningState, context),
                      ],
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Expanded _cancelInvoice(BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () => context.read<WalletsManagerCubit>().resetInvoice(),
        title: context.t.cancel.capitalizeFirst(),
        icon: FeatureIcons.closeRaw,
        textColor: kRed,
        borderColor: kRed,
      ),
    );
  }

  Expanded _copy(WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          Clipboard.setData(ClipboardData(text: lightningState.lnurl));
          BotToastUtils.showSuccess(context.t.invoiceCopied.capitalizeFirst());
        },
        title: context.t.copy.capitalizeFirst(),
        icon: FeatureIcons.copy,
      ),
    );
  }

  Expanded _confirm(WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          context.read<WriteNoteCubit>().submitEvent(
                () => YNavigator.popToRoot(context),
              );
        },
        title: context.t.confirmPayment,
        icon: FeatureIcons.zap,
        isLoading: !lightningState.isLoading ? null : true,
      ),
    );
  }

  Expanded _qrCode(BuildContext context, WalletsManagerState lightningState) {
    final width =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 50.w : 70.w;
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Container(
                width: width,
                height: width,
                padding: const EdgeInsets.all(kDefaultPadding / 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 5,
                  ),
                ),
                child: QrImageView(
                  data: lightningState.lnurl,
                  dataModuleStyle: QrDataModuleStyle(
                    color: Theme.of(context).primaryColorDark,
                    dataModuleShape: QrDataModuleShape.circle,
                  ),
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ),
              title: Text(
                context.t.scanQrCode.capitalizeFirst(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: kBlack),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Theme.of(context).primaryColorDark,
            ),
          );
        },
        title: context.t.qrCode,
        icon: FeatureIcons.qr,
      ),
    );
  }

  Expanded _pay(WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () {
          final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
          if (event != null && context.mounted) {
            context.read<WalletsManagerCubit>().handleWalletZap(
                  sats: _effectiveSats,
                  user: Metadata.empty().copyWith(
                    lud16: nostrRepository.yakihonneWallet,
                    pubkey: yakihonneHex,
                  ),
                  comment: context.t
                      .userSubmittedPaidNote(
                        name: nostrRepository.currentMetadata.name.isNotEmpty
                            ? nostrRepository.currentMetadata.name
                            : 'unknown',
                      )
                      .capitalizeFirst(),
                  eventId: event.id,
                  onFinished: (invoice) {},
                  onSuccess: (invoice) {
                    context.read<WriteNoteCubit>().submitEvent(
                          () => YNavigator.popToRoot(context),
                        );
                  },
                  onFailure: (message) => BotToastUtils.showError(message),
                );
          }
        },
        title: context.t.pay,
        icon: FeatureIcons.zaps,
        isLoading: !lightningState.isLoading ? null : true,
      ),
    );
  }

  Expanded _getInvoice(
      WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: SendOptionsButton(
        onClicked: () async {
          final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
          if (event != null && context.mounted) {
            context.read<WalletsManagerCubit>().generateZapInvoice(
                  sats: _effectiveSats,
                  user: Metadata.empty().copyWith(
                    lud16: nostrRepository.yakihonneWallet,
                    pubkey: yakihonneHex,
                  ),
                  comment: context.t
                      .userSubmittedPaidNote(
                        name: nostrRepository.currentMetadata.name.isNotEmpty
                            ? nostrRepository.currentMetadata.name
                            : 'unknown',
                      )
                      .capitalizeFirst(),
                  eventId: event.id,
                  onFailure: (message) => BotToastUtils.showError(message),
                );
          }
        },
        title: context.t.getInvoice,
        icon: FeatureIcons.note,
        isLoading: !lightningState.isLoading ? null : true,
      ),
    );
  }

  Widget _payWithPoints(
    BuildContext context,
    ValueNotifier<bool> isPayingWithPoints,
  ) {
    return SendOptionsButton(
      onClicked: isPayingWithPoints.value
          ? () {}
          : () {
              context.read<WriteNoteCubit>().redeemPointsAndPublish(
                    () => YNavigator.popToRoot(context),
                    (msg) => BotToastUtils.showError(msg),
                  );
            },
      title: context.t.points_pay_with_points,
      icon: FeatureIcons.zap,
      isLoading: isPayingWithPoints.value ? true : null,
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
