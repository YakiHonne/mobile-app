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

class PaidNoteProcess extends HookWidget {
  const PaidNoteProcess({
    super.key,
    required this.checkZap,
  });

  final bool checkZap;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final isZapConfirmed = useState<bool?>(null);

    useEffect(
      () {
        final walletsCubit = context.read<WalletsManagerCubit>();

        if (checkZap) {
          final event = context.read<WriteNoteCubit>().toBeSubmittedEvent;
          if (event != null) {
            NostrFunctionsRepository.checkPayment(
              event.id,
              skipDelay: true,
            ).then((value) {
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.40,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Center(child: ModalBottomSheetHandle()),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Center(
              child: Text(
                context.t.payPublish.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Expanded(
              child: _informationColumn(context, isTablet),
            ),
            _bottomNavBar(context, isTablet, isZapConfirmed),
          ],
        ),
      ),
    );
  }

  Widget _informationColumn(
    BuildContext context,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
        horizontal: isTablet ? 10.w : kDefaultPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nostrRepository.flashNewsPrice.toInt().toString(),
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            'SATS',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
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
                    return const Center(
                      child: SearchLoading(),
                    );
                  } else if (isZapConfirmed.value ?? false) {
                    return Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        _confirm(lightningState, context),
                      ],
                    );
                  } else if (!lightningState.isLnurlAvailable) {
                    return SizedBox(
                      width: double.infinity,
                      child: Row(
                        spacing: kDefaultPadding / 4,
                        children: [
                          _getInvoice(lightningState, context),
                          _pay(lightningState, context),
                          _confirm(lightningState, context),
                        ],
                      ),
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
        onClicked: () {
          context.read<WalletsManagerCubit>().resetInvoice();
        },
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
          Clipboard.setData(
            ClipboardData(
              text: lightningState.lnurl,
            ),
          );

          BotToastUtils.showSuccess(
            context.t.invoiceCopied.capitalizeFirst(),
          );
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
            () {
              YNavigator.popToRoot(context);
            },
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
            builder: (context) {
              return AlertDialog(
                content: Container(
                  width: width,
                  height: width,
                  padding: const EdgeInsets.all(
                    kDefaultPadding / 4,
                  ),
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
              );
            },
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
                  sats: nostrRepository.flashNewsPrice.toInt(),
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
                          () => YNavigator.popToRoot(
                            context,
                          ),
                        );
                  },
                  onFailure: (message) {
                    BotToastUtils.showError(
                      message,
                    );
                  },
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
                  sats: nostrRepository.flashNewsPrice.toInt(),
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
                  onFailure: (message) {
                    BotToastUtils.showError(
                      message,
                    );
                  },
                );
          }
        },
        title: context.t.getInvoice,
        icon: FeatureIcons.note,
        isLoading: !lightningState.isLoading ? null : true,
      ),
    );
  }
}
