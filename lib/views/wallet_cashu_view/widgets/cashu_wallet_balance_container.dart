import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/common_regex.dart';
import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/currency_selector_button.dart';
import '../../widgets/qr_scanner_modal.dart';
import 'cashu_pay_view.dart';
import 'cashu_receive_view.dart';
import 'cashu_redeem_view.dart';
import 'cashu_send_view.dart';
import 'cashu_swap_view.dart';

class CashuWallatBalanceContainer extends StatelessWidget {
  const CashuWallatBalanceContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: Column(
            children: [
              _content(context, state),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _actions(
                context: context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actions({
    required BuildContext context,
  }) {
    return IntrinsicHeight(
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          Expanded(
            child: _actionButton(
              context: context,
              title: context.t.receive,
              icon: FeatureIcons.arrowDown,
              onTap: () {
                YNavigator.presentPage(
                  context,
                  (context) => const CashuReceiveView(),
                );
              },
            ),
          ),
          Expanded(
            child: _actionButton(
              context: context,
              title: context.t.swap,
              icon: FeatureIcons.swapMintLightning,
              onTap: () {
                YNavigator.presentPage(
                  context,
                  (context) => const CashuSwapView(),
                );
              },
            ),
          ),
          Expanded(
            child: _actionButton(
              context: context,
              title: context.t.qrCode,
              icon: FeatureIcons.qr,
              onTap: () {
                YNavigator.presentPage(
                  context,
                  (context) => QrScannerModal(
                    onValue: (value) {
                      if (value.startsWith('cashu')) {
                        YNavigator.presentPage(
                          context,
                          (context) => CashuRedeemView(
                            encodedToken: value,
                          ),
                        );
                      } else {
                        final val = value.toLowerCase();

                        if (val.startsWith('lnbc') ||
                            val.startsWith('lnurl') ||
                            emailRegExp.hasMatch(val)) {
                          YNavigator.presentPage(
                            context,
                            (context) => CashuPayView(
                              input: value,
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _actionButton(
              context: context,
              title: context.t.send,
              icon: FeatureIcons.arrowUp,
              onTap: () {
                YNavigator.presentPage(
                  context,
                  (context) => const CashuSendView(),
                );
              },
              setColor: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String title,
    required String icon,
    required VoidCallback onTap,
    bool setColor = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: setColor
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          spacing: kDefaultPadding / 4,
          children: [
            SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                setColor ? kWhite : Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: setColor ? kWhite : Theme.of(context).highlightColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _content(BuildContext context, CashuWalletManagerState state) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: kDefaultPadding,
            children: [
              _buildWalletBalance(context, state),
              SizedBox(
                width: 30.w,
                child: Divider(
                  height: 0,
                  color: Theme.of(context).primaryColorDark,
                  thickness: 2,
                ),
              ),
              _buildMintBalance(context, state),
              _buildCopyMintUrl(context, state),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalance(
      BuildContext context, CashuWalletManagerState cashuState) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, walletsState) {
        final rate = walletManagerCubit.btcInFiat[walletsState.activeCurrency];
        final balanceInFiat = (cashuState.balance != -1 && rate != null)
            ? (cashuState.balance / 100000000) * rate
            : -1.0;

        return Column(
          children: [
            Text(
              context.t.walletBalance,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            Row(
              spacing: kDefaultPadding / 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${cashuState.balance != -1 ? cashuState.balance : 'N/A'}',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                Text(
                  'sats',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).highlightColor,
                      ),
                )
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            CurrencySelectorButton(
              activeCurrency: walletsState.activeCurrency,
              balanceInFiat: balanceInFiat,
              isWalletHidden: walletsState.isWalletHidden,
              onCurrencyChanged: (currency) {
                walletManagerCubit.setActiveFiat(currency);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMintBalance(
      BuildContext context, CashuWalletManagerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.mintBalance,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Row(
          spacing: kDefaultPadding / 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.balance != -1 ? state.activeMintBalance : 'N/A'}',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
            Text(
              'sats',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).highlightColor,
                  ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildCopyMintUrl(
      BuildContext context, CashuWalletManagerState state) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(
          ClipboardData(
            text: state.activeMint,
          ),
        );

        BotToastUtils.showSuccess(
          context.t.mintHasBeenCopied.capitalizeFirst(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 4,
          ),
          color: Theme.of(context).cardColor,
        ),
        width: 50.w,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                state.activeMint,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
    );
  }
}
