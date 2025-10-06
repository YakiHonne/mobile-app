import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/zaps/zap.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../common/common_regex.dart';
import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/global_keys.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/widgets/export_wallets.dart';
import '../../wallet_view/widgets/wallet_options_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/modal_with_blur.dart';
import '../../widgets/response_snackbar.dart';
import 'settings_text.dart';
import 'zaps_configurations.dart';

class PropertyWallets extends HookWidget {
  PropertyWallets({
    super.key,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Wallets view');
  }

  final gK = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    final isWalletListCollapsed = useState(true);
    final defaultZapAmountController = useTextEditingController(
      text: getCurrentUserDefaultZapAmount().toString(),
    );

    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.wallets.capitalizeFirst(),
          ),
          body: BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
            builder: (context, lState) {
              final wallets = lState.wallets.entries.toList();

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: ListView(
                  children: [
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    Text(
                      context.t.settingsWalletDesc,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    const Divider(
                      height: kDefaultPadding * 1.5,
                      thickness: 0.5,
                    ),
                    _wallets(context, lState, wallets),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    TitleDescriptionComponent(
                      title: context.t.defaultZapAmount.capitalizeFirst(),
                      description: context.t.defaultZapDesc,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    _textfield(defaultZapAmountController, context),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    _oneTapZap(context, state),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    TitleDescriptionComponent(
                      title: context.t.externalWallet.capitalizeFirst(),
                      description:
                          context.t.externalWalletDesc.capitalizeFirst(),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 1.5,
                    ),
                    ExternalWalletContainer(
                      isWalletListCollapsed: isWalletListCollapsed,
                    ),
                    const SizedBox(height: kDefaultPadding),
                    _alwaysUseExternal(),
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _alwaysUseExternal() {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: TitleDescriptionComponent(
                title: context.t.alwaysUseExternal,
                description: context.t.alwaysUseExternalDesc.capitalizeFirst(),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                value: state.useDefaultWallet,
                activeTrackColor: kMainColor,
                onChanged: (isToggled) {
                  walletManagerCubit.setUseDefaultWallet(isToggled);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Row _oneTapZap(BuildContext context, PropertiesState state) {
    return Row(
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.oneTapZap.capitalizeFirst(),
            description: context.t.enableZapDesc,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: state.enableOneTapZap,
            activeTrackColor: kMainColor,
            onChanged: (isToggled) {
              context.read<PropertiesCubit>().setOneTapZap(isToggled);
            },
          ),
        ),
      ],
    );
  }

  TextFormField _textfield(
      TextEditingController defaultZapAmountController, BuildContext context) {
    return TextFormField(
      controller: defaultZapAmountController,
      style: Theme.of(context).textTheme.bodyMedium,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final pubkey = currentSigner?.getPublicKey();
        if (pubkey != null) {
          final v = int.tryParse(value) ?? 0;

          if (v > 0) {
            nostrRepository.defaultZapAmounts[pubkey] = v;

            localDatabaseRepository.setDefaultZapAmount(
              ts: nostrRepository.defaultZapAmounts,
            );
          } else {
            nostrRepository.defaultZapAmounts[pubkey] = defaultZapamount;

            localDatabaseRepository.setDefaultZapAmount(
              ts: nostrRepository.defaultZapAmounts,
            );
          }
        }
      },
    );
  }

  Padding _wallets(BuildContext context, WalletsManagerState lState,
      List<MapEntry<String, WalletModel>> wallets) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Column(
        children: [
          Row(
            spacing: kDefaultPadding / 4,
            children: [
              Expanded(
                child: TitleDescriptionComponent(
                  title: context.t.manageWallets.capitalizeFirst(),
                  description: context.t.manageWalletsDesc,
                ),
              ),
              TextButton(
                onPressed: () {
                  showBlurredModal(
                    context: context,
                    view: const WalletOptions(),
                  );
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                  backgroundColor: Theme.of(context).cardColor,
                ),
                child: Text(
                  context.t.add.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          if (lState.wallets.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                color: Theme.of(context).cardColor,
              ),
              padding: const EdgeInsets.all(kDefaultPadding / 4),
              child: ListView.separated(
                shrinkWrap: true,
                primary: false,
                separatorBuilder: (context, index) => const Divider(
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];

                  return walletBox(wallet, lState);
                },
                itemCount: wallets.length,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  final wallets = walletManagerCubit.getUserWallets(
                    true,
                  );

                  exportWalletToUserDirectory(wallets);
                },
                child: Text(context.t.export),
              ),
            )
          ],
        ],
      ),
    );
  }

  Builder walletBox(
      MapEntry<String, WalletModel> wallet, WalletsManagerState lState) {
    return Builder(
      builder: (context) {
        final isAlby = wallet.value is AlbyConnectModel;
        bool linked = false;

        if (nostrRepository.currentMetadata.lud16.isNotEmpty) {
          linked = nostrRepository.currentMetadata.lud16 == wallet.value.lud16;
        } else if (nostrRepository.currentMetadata.lud06.isNotEmpty) {
          final l06 = Zap.getLnurlFromLud16(wallet.value.lud16);
          linked = nostrRepository.currentMetadata.lud06 == l06;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding / 4,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                wallet.value.kind == 1 ? FeatureIcons.nwc : FeatureIcons.alby,
                width: 20,
                height: 20,
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Text(
                  wallet.value.lud16,
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (wallet.value.id != lState.selectedWalletId) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                IconButton(
                  onPressed: () {
                    walletManagerCubit.setSelectedWallet(
                      wallet.value.id,
                      () {},
                    );
                  },
                  style: IconButton.styleFrom(
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                  icon: SvgPicture.asset(
                    FeatureIcons.repost,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
              if (wallet.value.id == lState.selectedWalletId) ...[
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Opacity(
                  opacity: lState.selectedWalletId == wallet.key ? 1 : 0,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
              ],
              _pulldownButton(context, linked, wallet, isAlby),
            ],
          ),
        );
      },
    );
  }

  PullDownButton _pulldownButton(BuildContext context, bool linked,
      MapEntry<String, WalletModel> wallet, bool isAlby) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          if (!linked)
            PullDownMenuItem(
              title: context.t.linkWallet.capitalizeFirst(),
              onTap: () {
                if (emailRegExp.hasMatch(wallet.value.lud16)) {
                  showCupertinoCustomDialogue(
                    context: context,
                    title: context.t.linkWallet.capitalizeFirst(),
                    description: context.t.linkWalletDesc.capitalizeFirst(),
                    buttonText: context.t.link.capitalizeFirst(),
                    buttonTextColor: kGreen,
                    onClicked: () {
                      YNavigator.pop(context);
                      walletManagerCubit.linkWallet(
                        wallet.value,
                      );
                    },
                  );
                } else {
                  BotToastUtils.showError(
                    context.t.noLnInNwc.capitalizeFirst(),
                  );
                }
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget: SvgPicture.asset(
                FeatureIcons.link,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
          PullDownMenuItem(
            title: context.t.copyLn.capitalizeFirst(),
            onTap: () {
              final w = wallet.value;

              Clipboard.setData(
                ClipboardData(
                  text: w.lud16,
                ),
              );

              BotToastUtils.showSuccess(
                context.t.lnCopied.capitalizeFirst(),
              );
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.copy,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          if (!isAlby) ...[
            PullDownMenuItem(
              title: context.t.copyNwc.capitalizeFirst(),
              onTap: () {
                final w = wallet.value as NostrWalletConnectModel;

                Clipboard.setData(
                  ClipboardData(
                    text: w.connectionString,
                  ),
                );

                BotToastUtils.showSuccess(
                  context.t.nwcCopied.capitalizeFirst(),
                );
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget: SvgPicture.asset(
                FeatureIcons.copy,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
            PullDownMenuItem(
              title: context.t.export.capitalizeFirst(),
              onTap: () {
                showBlurredModal(
                  context:
                      GlobalKeys.navigatorKey.currentState!.overlay!.context,
                  isDismissable: false,
                  view: ExportWalletOnCreation(
                    wallet: wallet.value as NostrWalletConnectModel,
                  ),
                );
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
              iconWidget: SvgPicture.asset(
                FeatureIcons.export,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
          PullDownMenuItem(
            title: context.t.deleteWallet.capitalizeFirst(),
            onTap: () {
              showCupertinoDeletionDialogue(
                context: context,
                title: context.t.deleteWallet.capitalizeFirst(),
                description: context.t.deleteWalletDesc.capitalizeFirst(),
                buttonText: context.t.delete.capitalizeFirst(),
                toBeCopied: wallet.value is NostrWalletConnectModel
                    ? (wallet.value as NostrWalletConnectModel).connectionString
                    : null,
                onDelete: () {
                  walletManagerCubit.removeWallet(
                    wallet.key,
                    () {},
                  );

                  YNavigator.pop(context);
                },
              );
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            isDestructive: true,
            iconWidget: SvgPicture.asset(
              FeatureIcons.trash,
              height: 20,
              width: 20,
              colorFilter: const ColorFilter.mode(
                kRed,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => CustomIconButton(
        backgroundColor: Theme.of(context).cardColor,
        onClicked: showMenu,
        size: 16,
        vd: -2,
        icon: FeatureIcons.more,
      ),
    );
  }
}
