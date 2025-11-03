import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../widgets/external_wallets_list_view.dart';
import '../widgets/internal_wallets_list_view.dart';
import 'send_success_view.dart';

class SendUsingInvoice extends HookWidget {
  const SendUsingInvoice({super.key, required this.invoice});

  final String invoice;

  @override
  Widget build(BuildContext context) {
    final t = BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return TextButton(
          onPressed: () async {
            await walletManagerCubit.sendUsingInvoice(
              invoice: MapEntry(invoice, null),
              removeSuccess: true,
              onSuccess: () {
                final amount = getlnbcValue(invoice).toInt();

                if (amount == -1) {
                  BotToastUtils.showError(context.t.invalidInvoice);
                  return;
                }

                YNavigator.pushReplacement(
                  context,
                  SendSuccessView(
                    amount: amount,
                  ),
                );
              },
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            side: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !state.isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    key: const ValueKey(1),
                    spacing: kDefaultPadding / 4,
                    children: [
                      SvgPicture.asset(
                        FeatureIcons.zapFilled,
                        width: 15,
                        height: 15,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
                      Text(
                        key: const ValueKey(1),
                        context.t.pay.capitalizeFirst(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  )
                : const SpinKitCircle(
                    key: ValueKey(2),
                    color: kWhite,
                    size: 20,
                  ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.invoice.capitalize(),
      ),
      body: Builder(
        builder: (context) {
          final amount = getlnbcValue(invoice).toInt();
          final amountInUsd = walletManagerCubit.getBtcInFiatFromAmount(amount);

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _amountRow(amount, context),
                        const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                        _exchangeRow(amountInUsd, context),
                      ],
                    ),
                  ),
                ),
                const InternalWalletSelector(),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom +
                        kDefaultPadding / 2,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: t,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Row _exchangeRow(double amountInUsd, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '~ \$${amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          ' USD',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }

  Row _amountRow(int amount, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${amount != -1 ? amount : 'N/A'}',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: kMainColor,
              ),
        ),
        Text(
          'sats',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }
}

class InternalWalletSelector extends StatelessWidget {
  const InternalWalletSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        final wallet = state.wallets[state.selectedWalletId];
        final isNwc = wallet is NostrWalletConnectModel;
        final walletId = wallet?.lud16 ?? 'wallet';

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return const InternalWalletsListView();
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 25,
                  height: 25,
                  child: Center(
                    child: SvgPicture.asset(
                      isNwc ? FeatureIcons.nwc : FeatureIcons.alby,
                      width: 20,
                      height: 20,
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                Flexible(
                  child: Text(
                    walletId,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExternalWalletSelector extends StatelessWidget {
  const ExternalWalletSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        final wallet = wallets[state.defaultExternalWallet];

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return const ExternalWalletsListView();
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                    image: DecorationImage(
                      image: AssetImage(
                        wallets[state.defaultExternalWallet]!['icon']!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
                Flexible(
                  child: Text(
                    wallet?['name'] ?? 'External Wallet',
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                const SizedBox(
                  width: 25,
                  height: 25,
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
