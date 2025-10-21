import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class PaidNoteProcess extends HookWidget {
  const PaidNoteProcess({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    useEffect(
      () {
        return walletManagerCubit.resetInvoice;
      },
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
            _bottomNavBar(context, isTablet),
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
                  color: kMainColor,
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
          const SizedBox(height: kDefaultPadding),
          BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
            builder: (context, state) {
              if (state.confirmPayment) {
                return TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                  ),
                  onPressed: () {
                    context.read<WriteNoteCubit>().submitEvent(
                      () {
                        YNavigator.popToRoot(context);
                      },
                    );
                  },
                  child: const Text(
                    'Confirm payment',
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomNavBar(
    BuildContext context,
    bool isTablet,
  ) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
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
                  if (!lightningState.isLnurlAvailable) {
                    return SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          _getInvoice(lightningState, context),
                          const SizedBox(
                            width: kDefaultPadding / 4,
                          ),
                          _pay(lightningState, context),
                        ],
                      ),
                    );
                  } else {
                    return Row(
                      children: [
                        _qrCode(context, lightningState),
                        const SizedBox(
                          width: kDefaultPadding / 4,
                        ),
                        _copy(lightningState, context),
                        IconButton(
                          onPressed: () {
                            context.read<WalletsManagerCubit>().resetInvoice();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
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

  Expanded _copy(WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
        ),
        onPressed: () {
          Clipboard.setData(
            ClipboardData(
              text: lightningState.lnurl,
            ),
          );

          BotToastUtils.showSuccess(
            context.t.invoiceCopied.capitalizeFirst(),
          );
        },
        icon: SvgPicture.asset(
          FeatureIcons.copy,
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            kWhite,
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          context.t.copy.capitalizeFirst(),
        ),
      ),
    );
  }

  Expanded _qrCode(BuildContext context, WalletsManagerState lightningState) {
    return Expanded(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                icon: QrImageView(
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
                title: Text(
                  context.t.scanQrCode.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).primaryColorLight,
                      ),
                ),
                backgroundColor: Theme.of(context).primaryColorDark,
              );
            },
          );
        },
        icon: SvgPicture.asset(
          FeatureIcons.qr,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        label: Text(
          context.t.qrCode.capitalizeFirst(),
        ),
      ),
    );
  }

  Expanded _pay(WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: AbsorbPointer(
        absorbing: lightningState.isLoading,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
          ),
          onPressed: () async {
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
          icon: lightningState.isLoading
              ? const SizedBox.shrink()
              : SvgPicture.asset(
                  FeatureIcons.zaps,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
          label: lightningState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kWhite,
                  ),
                )
              : Text(
                  context.t.pay.capitalizeFirst(),
                ),
        ),
      ),
    );
  }

  Expanded _getInvoice(
      WalletsManagerState lightningState, BuildContext context) {
    return Expanded(
      child: AbsorbPointer(
        absorbing: lightningState.isLoading,
        child: TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
          ),
          onPressed: () async {
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
          child: lightningState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kWhite,
                  ),
                )
              : Text(
                  context.t.getInvoice.capitalizeFirst(),
                ),
        ),
      ),
    );
  }
}
