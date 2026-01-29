import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/dotted_container.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_selection_dropdown.dart';

class CashuDepositView extends HookWidget {
  const CashuDepositView({super.key});

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    final selectedWalletId = useState<String?>(null);
    final generatedInvoice = useState<String?>(null);
    final quoteId = useState<String?>(null);
    final amountInSats = useState(0);

    final walletsState = context.watch<WalletsManagerCubit>().state;
    final availableWallets = walletsState.wallets.values
        .where((w) => w is NostrWalletConnectModel || w is AlbyConnectModel)
        .toList();

    useEffect(() {
      amountController.addListener(() {
        amountInSats.value = int.tryParse(amountController.text) ?? 0;
      });
      return null;
    }, []);

    useEffect(() {
      if (availableWallets.isNotEmpty && selectedWalletId.value == null) {
        selectedWalletId.value = availableWallets.first.id;
      }
      return null;
    }, [availableWallets]);

    // Effect to poll/listen to invoice status if quoteId is set
    useEffect(() {
      if (quoteId.value != null && generatedInvoice.value != null) {
        // Start listening to status via WebSocket
        final timerFuture =
            context.read<CashuWalletManagerCubit>().listenToQuoteStatus(
          quoteId.value!,
          int.parse(amountController.text),
          onPaid: () {
            if (context.mounted) {
              YNavigator.pop(context);
              YNavigator.presentPage(
                nostrRepository.ctx,
                (_) => CashuOperationSuccessView(
                  amount: int.parse(amountController.text),
                  title: nostrRepository.ctx.t.depositSuccess,
                  mintUrl: cashuWalletManagerCubit.state.activeMint,
                ),
              );
            }
          },
        );

        return () {
          timerFuture.then((subscription) => subscription?.cancel());
        };
      }
      return null;
    }, [quoteId.value]);

    Future<void> generateInvoice() async {
      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        BotToastUtils.showError(context.t.invalidAmount);
        return;
      }

      final result =
          await context.read<CashuWalletManagerCubit>().createDepositQuote(
                amount,
              );

      if (result != null) {
        generatedInvoice.value = result['invoice'];
        quoteId.value = result['quote'];
      }
    }

    Future<void> payWithNwc() async {
      final amount = int.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        BotToastUtils.showError(context.t.invalidAmount);
        return;
      }

      if (selectedWalletId.value == null) {
        BotToastUtils.showError('No wallet selected');
        return;
      }

      // 1. Create quote
      final result =
          await context.read<CashuWalletManagerCubit>().createDepositQuote(
                amount,
              );

      if (result != null && context.mounted) {
        // 2. Pay invoice
        final success =
            await context.read<CashuWalletManagerCubit>().payMintQuoteWithNwc(
                  result['invoice'],
                  result['quote'],
                  selectedWalletId.value!,
                );

        if (success && context.mounted) {
          YNavigator.pop(context);
          YNavigator.presentPage(
            nostrRepository.ctx,
            (_) => CashuOperationSuccessView(
              amount: amount,
              title: nostrRepository.ctx.t.paymentSucceeded,
              mintUrl: cashuWalletManagerCubit.state.activeMint,
            ),
          );
        }
      }
    }

    final cashuState = context.watch<CashuWalletManagerCubit>().state;
    final walletMints = cashuState.walletMints;

    final secondaryButtonStyle = TextButton.styleFrom(
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );

    final showWalletSelection =
        availableWallets.isNotEmpty && generatedInvoice.value == null;

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
            title: context.t.deposit,
            isBack: false,
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: FadeIn(
                key: ValueKey(generatedInvoice.value == null),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: kDefaultPadding,
                  children: [
                    if (generatedInvoice.value == null)
                      _buildInputState(
                        context,
                        walletMints,
                        cashuState,
                        amountController,
                        amountInSats,
                        showWalletSelection,
                        selectedWalletId,
                        availableWallets,
                      )
                    else
                      _buildInvoiceState(
                        context,
                        generatedInvoice.value!,
                        amountController.text,
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(
            context,
            generatedInvoice,
            quoteId,
            amountController,
            availableWallets,
            secondaryButtonStyle,
            payWithNwc,
            generateInvoice,
          ),
        ],
      ),
    );
  }

  Widget _buildInputState(
    BuildContext context,
    List<String> walletMints,
    CashuWalletManagerState cashuState,
    TextEditingController amountController,
    ValueNotifier<int> amountInSats,
    bool showWalletSelection,
    ValueNotifier<String?> selectedWalletId,
    List<WalletModel> availableWallets,
  ) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
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
                    hintStyle:
                        Theme.of(context).textTheme.displayLarge!.copyWith(
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
                    if (amountInSats.value > 0)
                      Builder(
                        builder: (context) {
                          final amountInUsd = walletManagerCubit
                              .getBtcInFiatFromAmount(amountInSats.value);
                          return Text(
                            '~ \$${amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2)} ${walletManagerCubit.state.activeCurrency.toUpperCase()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
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
          ),
          if (showWalletSelection)
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
                  value: selectedWalletId.value,
                  hint: context.t.wallet,
                  items: availableWallets.map((wallet) {
                    String label = '';
                    if (wallet.lud16.isNotEmpty) {
                      label = wallet.lud16;
                    } else if (wallet is NostrWalletConnectModel) {
                      label = wallet.relay.split('://').last;
                    } else {
                      label = 'Alby Wallet';
                    }

                    return CashuDropdownItem<String>(
                      value: wallet.id,
                      label: label,
                      assetIcon: wallet is NostrWalletConnectModel
                          ? FeatureIcons.nwc
                          : FeatureIcons.alby,
                    );
                  }).toList(),
                  onChanged: (value) => selectedWalletId.value = value,
                ),
              ],
            ),
          if (walletMints.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kDefaultPadding / 4,
              children: [
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  context.t.to,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                CashuSelectionDropdown<String>(
                  value: cashuState.activeMint,
                  hint: context.t.selectMint,
                  items: walletMints.map((mintUrl) {
                    final mint = cashuState.mints[mintUrl];
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
                      context
                          .read<CashuWalletManagerCubit>()
                          .setActiveMint(value);
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceState(
    BuildContext context,
    String invoice,
    String amount,
  ) {
    return Expanded(
      child: Column(
        spacing: kDefaultPadding / 2,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.t.scanPay,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(kDefaultPadding),
            ),
            child: QrImageView(
              data: invoice,
              size: 55.w,
              padding: EdgeInsets.zero,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$amount Sats',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: kDefaultPadding / 2),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: invoice),
                  );
                  BotToastUtils.showSuccess(
                    context.t.invoiceCopied,
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t.waitingPayment,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: kDefaultPadding / 2),
              SpinKitCircle(
                color: Theme.of(context).primaryColorDark,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ValueNotifier<String?> generatedInvoice,
    ValueNotifier<String?> quoteId,
    TextEditingController amountController,
    List<WalletModel> availableWallets,
    ButtonStyle secondaryButtonStyle,
    VoidCallback payWithNwc,
    VoidCallback generateInvoice,
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
      child: Column(
        spacing: kDefaultPadding / 2,
        children: [
          if (generatedInvoice.value == null)
            Row(
              spacing: kDefaultPadding / 4,
              children: [
                Expanded(
                  child: SendOptionsButton(
                    onClicked: () {
                      HapticFeedback.mediumImpact();
                      YNavigator.pop(context);
                    },
                    title: context.t.cancel.capitalizeFirst(),
                    icon: FeatureIcons.closeRaw,
                    borderColor: kRed,
                    textColor: kRed,
                    backgroundColor: kRed.withValues(alpha: 0.1),
                  ),
                ),
                if (availableWallets.isNotEmpty)
                  Expanded(
                    child: SendOptionsButton(
                      onClicked: () {
                        HapticFeedback.mediumImpact();
                        payWithNwc();
                      },
                      title: context.t.deposit,
                      icon: FeatureIcons.zapFilled,
                    ),
                  ),
                Expanded(
                  child: SendOptionsButton(
                    onClicked: () {
                      HapticFeedback.mediumImpact();
                      generateInvoice();
                    },
                    title: context.t.invoice.capitalizeFirst(),
                    icon: FeatureIcons.addNote,
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final success = await context
                      .read<CashuWalletManagerCubit>()
                      .checkDepositQuoteStatus(
                    quoteId.value!,
                    int.parse(amountController.text),
                    onPaid: () {
                      if (context.mounted) {
                        YNavigator.pop(context);
                        YNavigator.presentPage(
                          nostrRepository.ctx,
                          (_) => CashuOperationSuccessView(
                            amount: int.parse(amountController.text),
                            title: nostrRepository.ctx.t.paymentSucceeded,
                            mintUrl: cashuWalletManagerCubit.state.activeMint,
                          ),
                        );
                      }
                    },
                  );

                  if (!success) {
                    BotToastUtils.showError('Payment not detected yet');
                  }
                },
                style: secondaryButtonStyle,
                child: Text(
                  'Check Payment Status',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  generatedInvoice.value = null;
                  quoteId.value = null;
                },
                style: secondaryButtonStyle,
                child: Text(
                  context.t.cancel.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
