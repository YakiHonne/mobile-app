import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../common/common_regex.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/animated_components/glass_button.dart';
import '../../widgets/modal_with_blur.dart';
import '../receive_view/receive_generate_invoice.dart';
import '../redeem_code_view/redeem_code_view.dart';
import '../send_view/qr_code_scanner.dart';
import '../send_view/send_main_view.dart';
import 'wallet_options_view.dart';

class WallatBalanceContainer extends StatelessWidget {
  const WallatBalanceContainer({
    super.key,
    required this.setOption,
  });

  final Function(InternalWalletTransactionOption) setOption;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: Column(
            children: [
              _redeemButton(),
              _content(context, state),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Builder(builder: (context) {
                const size = 100.0;

                return Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _receive(context, size),
                        const SizedBox(
                          width: kDefaultPadding / 2,
                        ),
                        _send(context, size),
                      ],
                    ),
                    _qr(context),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Positioned _qr(BuildContext context) {
    return Positioned.fill(
      child: Align(
        child: GestureDetector(
          onTap: () {
            YNavigator.pushPage(
              context,
              (context) => const QrCodeView(),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 8,
              ),
            ),
            child: SvgPicture.asset(
              FeatureIcons.qr,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _send(BuildContext context, double size) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          YNavigator.pushPage(
            context,
            (context) => const SendMainView(),
          );
          HapticFeedback.mediumImpact();
        },
        child: Container(
          decoration: BoxDecoration(
            color: kMainColor,
            borderRadius: BorderRadius.circular(size / 6),
          ),
          height: size,
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 45,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(context.t.send.capitalizeFirst()),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _receive(BuildContext context, double size) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          YNavigator.pushPage(
            context,
            (context) => const ReceiveGenerateInvoice(),
          );
          HapticFeedback.mediumImpact();
        },
        child: Container(
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(size / 6),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_downward_rounded,
                size: 45,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(context.t.receive.capitalizeFirst()),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _content(BuildContext context, WalletsManagerState state) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.t.balance.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              SvgPicture.asset(
                FeatureIcons.sats,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Flexible(
            child: Text(
              '${state.balance != -1 ? state.balance : 'N/A'}',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: kMainColor,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          PullDownButton(
            routeTheme: PullDownMenuRouteTheme(
              backgroundColor: Theme.of(context).cardColor,
            ),
            itemBuilder: (context) {
              final textStyle = Theme.of(context).textTheme.labelLarge;

              return [
                ...currencies.entries.map(
                  (e) {
                    return PullDownMenuItem.selectable(
                      onTap: () {
                        walletManagerCubit.setActiveFiat(e.key);
                      },
                      title: e.key.toUpperCase(),
                      selected: state.activeCurrency == e.key,
                      iconWidget: Text(e.value),
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: textStyle,
                      ),
                    );
                  },
                )
              ];
            },
            buttonBuilder: (context, showMenu) => GestureDetector(
              onTap: showMenu,
              behavior: HitTestBehavior.translucent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    '\$${state.isWalletHidden ? '*****' : state.balanceInFiat == -1 ? 'N/A' : state.balanceInFiat.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    state.activeCurrency.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  SvgPicture.asset(
                    FeatureIcons.arrowDown,
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final wallet = state.wallets[state.selectedWalletId];
              bool hasMatch = false;

              try {
                hasMatch = emailRegExp.hasMatch(wallet!.lud16);
              } catch (_) {
                hasMatch = false;
              }

              return hasMatch
                  ? _lightningAddress(wallet, context)
                  : const SizedBox.shrink();
            },
          )
        ],
      ),
    );
  }

  Column _lightningAddress(WalletModel? wallet, BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text: wallet!.lud16,
              ),
            );

            BotToastUtils.showSuccess(
              context.t.lnCopied.capitalizeFirst(),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 4,
              ),
              color: Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.t.copyLn.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                SvgPicture.asset(
                  FeatureIcons.copy,
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BlocBuilder<WalletsManagerCubit, WalletsManagerState> _redeemButton() {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return GlassButton(
          onTap: () {
            HapticFeedback.mediumImpact();

            if (state.wallets.isNotEmpty) {
              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return const RedeemCodeView();
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            } else {
              showBlurredModal(
                context: context,
                view: const WalletOptions(),
              );
            }
          },
        );
      },
    );
  }
}
