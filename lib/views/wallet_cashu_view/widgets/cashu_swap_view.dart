import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_selection_dropdown.dart';

class CashuSwapView extends HookWidget {
  const CashuSwapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<CashuWalletManagerCubit>().state;
    final walletsState = context.watch<WalletsManagerCubit>().state;
    final walletMints = state.walletMints;
    final fromMintUrl = useState(state.activeMint);

    final internalWallets = walletsState.wallets.values.toList();

    final isWalletMode = useState(false);

    final toIdState = useState(isWalletMode.value && internalWallets.isNotEmpty
        ? internalWallets.first.id
        : (walletMints.firstWhere(
            (m) => m != fromMintUrl.value,
            orElse: () => '',
          )));

    final fromMint = state.mints[fromMintUrl.value];
    final toWallet = walletsState.wallets[toIdState.value];

    final amountController = useTextEditingController();
    final amountText = useValueListenable(amountController).text;

    useEffect(() {
      if (internalWallets.isNotEmpty && toIdState.value.isEmpty) {
        isWalletMode.value = true;
        toIdState.value = internalWallets.first.id;
      }
      return null;
    }, [internalWallets.isNotEmpty]);

    final isValidAmount = useMemoized(() {
      final val = int.tryParse(amountText) ?? 0;
      return val > 0 && val <= (fromMint?.balance ?? 0);
    }, [amountText, fromMint?.balance]);

    return Container(
      width: double.infinity,
      height: 90.h,
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
      child: Column(
        children: [
          ModalBottomSheetAppbar(
            title: context.t.swapTokens,
            isBack: false,
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Column(
                spacing: kDefaultPadding / 2,
                children: [
                  _buildAmountInput(context, amountController, amountText),
                  _buildSwapSelectors(
                    context,
                    fromMintUrl,
                    walletMints,
                    state,
                    toIdState,
                    isWalletMode,
                    internalWallets,
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          ),
          _buildActionButtons(
            context,
            isValidAmount,
            toWallet,
            fromMintUrl,
            amountText,
            toIdState,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(
    BuildContext context,
    TextEditingController amountController,
    String amountText,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: Theme.of(context).textTheme.displayLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).dividerColor,
                  ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: kDefaultPadding / 4,
            children: [
              Text(
                'SATS',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (amountText.isNotEmpty && int.tryParse(amountText) != null)
                Builder(
                  builder: (context) {
                    final amountInSats = int.parse(amountText);
                    final amountInUsd =
                        walletManagerCubit.getBtcInFiatFromAmount(amountInSats);
                    return Text(
                      '~ \$${amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2)} ${walletManagerCubit.state.activeCurrency.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).highlightColor,
                          ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapSelectors(
    BuildContext context,
    ValueNotifier<String> fromMintUrl,
    List<String> walletMints,
    CashuWalletManagerState state,
    ValueNotifier<String> toIdState,
    ValueNotifier<bool> isWalletMode,
    List<WalletModel> internalWallets,
  ) {
    return Stack(
      children: [
        Column(
          spacing: kDefaultPadding / 2,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kDefaultPadding / 4,
              children: [
                Text(
                  context.t.from,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                CashuSelectionDropdown<String>(
                  value: fromMintUrl.value,
                  hint: context.t.selectMint,
                  items: walletMints.map((mintUrl) {
                    final mint = state.mints[mintUrl];
                    return CashuDropdownItem<String>(
                      value: mintUrl,
                      label: mint?.info?.name ?? mintUrl.split('://').last,
                      icon: mint?.info?.iconUrl,
                      assetIcon: Images.cashu,
                      balance: mint?.balance,
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      fromMintUrl.value = value;
                    }
                  },
                ),
              ],
            ),
            // To Mint/Wallet
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kDefaultPadding / 4,
              children: [
                Text(
                  internalWallets.isNotEmpty
                      ? isWalletMode.value
                          ? context.t.toLightning
                          : context.t.toMint
                      : context.t.to,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Row(
                  spacing: kDefaultPadding / 4,
                  children: [
                    Expanded(
                      child: CashuSelectionDropdown<String>(
                        value: toIdState.value,
                        hint: isWalletMode.value
                            ? context.t.wallet
                            : context.t.selectMint,
                        items: isWalletMode.value
                            ? internalWallets.map((wallet) {
                                return CashuDropdownItem<String>(
                                  value: wallet.id,
                                  label: wallet.lud16.isNotEmpty
                                      ? wallet.lud16
                                      : (wallet is AlbyConnectModel
                                          ? 'Alby Wallet'
                                          : 'NWC Wallet'),
                                  assetIcon: wallet is AlbyConnectModel
                                      ? FeatureIcons.alby
                                      : FeatureIcons.nwc,
                                );
                              }).toList()
                            : walletMints.map((mintUrl) {
                                final mint = state.mints[mintUrl];
                                return CashuDropdownItem<String>(
                                  value: mintUrl,
                                  label: mint?.info?.name ??
                                      mintUrl.split('://').last,
                                  icon: mint?.info?.iconUrl,
                                  assetIcon: Images.cashu,
                                  balance: mint?.balance,
                                );
                              }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            toIdState.value = value;
                          }
                        },
                      ),
                    ),
                    if (internalWallets.isNotEmpty)
                      CustomIconButton(
                        onClicked: () {
                          HapticFeedback.mediumImpact();
                          final newVal = !isWalletMode.value;
                          isWalletMode.value = newVal;
                          if (newVal) {
                            if (internalWallets.isNotEmpty) {
                              toIdState.value = internalWallets.first.id;
                            }
                          } else {
                            toIdState.value = walletMints.firstWhere(
                              (m) => m != fromMintUrl.value,
                              orElse: () => '',
                            );
                          }
                        },
                        iconColor: kTransparent,
                        icon: !isWalletMode.value
                            ? FeatureIcons.nwc
                            : FeatureIcons.zap,
                        widget: !isWalletMode.value
                            ? null
                            : Image.asset(
                                Images.cashu,
                                width: 20,
                                height: 20,
                              ),
                        size: 20,
                        borderRadius: kDefaultPadding / 2,
                        vd: 2.5,
                        borderWidth: 2,
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Positioned.fill(
          child: Align(
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Material(
                borderRadius: BorderRadius.circular(300),
                elevation: 10,
                child: CustomIconButton(
                  onClicked: isWalletMode.value
                      ? () {}
                      : () {
                          HapticFeedback.mediumImpact();
                          final temp = fromMintUrl.value;
                          fromMintUrl.value = toIdState.value;
                          toIdState.value = temp;
                        },
                  icon: FeatureIcons.swap,
                  backgroundColor: Theme.of(context).cardColor,
                  iconColor: isWalletMode.value
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).primaryColorDark,
                  borderWidth: 0.5,
                  borderColor: Theme.of(context).dividerColor,
                  size: 20,
                  vd: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isValidAmount,
    WalletModel? toWallet,
    ValueNotifier<String> fromMintUrl,
    String amountText,
    ValueNotifier<String> toIdState,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom +
            MediaQuery.of(context).viewInsets.bottom +
            kDefaultPadding / 2,
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        top: kDefaultPadding / 2,
      ),
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          Expanded(
            child: SendOptionsButton(
              onClicked: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              title: context.t.cancel.capitalizeFirst(),
              icon: FeatureIcons.closeRaw,
              borderColor: kRed,
              textColor: kRed,
              backgroundColor: kRed.withValues(alpha: 0.1),
            ),
          ),
          Expanded(
            child: SendOptionsButton(
              onClicked: () async {
                HapticFeedback.mediumImpact();
                if (isValidAmount) {
                  bool success = false;
                  if (toWallet != null) {
                    success = await context
                        .read<CashuWalletManagerCubit>()
                        .payLightningAddress(
                          mintUrl: fromMintUrl.value,
                          lightningAddress: toWallet.lud16,
                          amount: int.parse(amountText),
                        );
                  } else {
                    success = await context
                        .read<CashuWalletManagerCubit>()
                        .swapTokens(
                          fromMintUrl: fromMintUrl.value,
                          toMintUrl: toIdState.value,
                          amount: int.parse(amountText),
                        );
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    YNavigator.presentPage(
                      nostrRepository.ctx,
                      (_) => CashuOperationSuccessView(
                        amount: int.parse(amountText),
                        title: nostrRepository.ctx.t.swapSuccessful,
                        mintUrl: toIdState.value,
                      ),
                    );
                  }
                } else {
                  BotToastUtils.showError(context.t.invalidAmount);
                }
              },
              title: context.t.swapTokens.capitalizeFirst(),
              icon: FeatureIcons.zapFilled,
            ),
          ),
        ],
      ),
    );
  }
}
