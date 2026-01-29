import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../common/common_regex.dart';
import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/qr_scanner_modal.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_selection_dropdown.dart';

class CashuPayView extends HookWidget {
  const CashuPayView({super.key, this.input});

  final String? input;

  @override
  Widget build(BuildContext context) {
    // Controllers
    final payAmountController = useTextEditingController();
    final toInputController = useTextEditingController(text: input);
    final memoController = useTextEditingController();

    useListenable(toInputController);
    final isInvoice = toInputController.text.toLowerCase().startsWith('lnbc');

    final amountInSatsPay = useState(0);

    // Common State
    final cashuState = context.watch<CashuWalletManagerCubit>().state;
    final walletMints = cashuState.walletMints;

    final selectedMintUrl = useState(cashuState.activeMint);
    final activeMintBalance =
        cashuState.mints[selectedMintUrl.value]?.balance ?? 0;

    // Listeners
    useEffect(() {
      payAmountController.addListener(() {
        amountInSatsPay.value = int.tryParse(payAmountController.text) ?? 0;
      });
      return null;
    }, []);

    final step = useState(0);

    // Payment Logic
    Future<void> onPay() async {
      final amount = amountInSatsPay.value;
      final input = toInputController.text.trim();

      if (input.isEmpty) {
        BotToastUtils.showError('Please enter an invoice or address');
        return;
      }

      if (input.toLowerCase().startsWith('lnbc')) {
        final invoiceAmount = getlnbcValue(input).toInt();
        final success =
            await context.read<CashuWalletManagerCubit>().payInvoice(
                  invoice: input,
                  mintUrl: selectedMintUrl.value,
                );
        if ((success ?? false) && context.mounted) {
          YNavigator.pop(context);
          YNavigator.presentPage(
              nostrRepository.ctx,
              (_) => CashuOperationSuccessView(
                    amount: invoiceAmount,
                    title: nostrRepository.ctx.t.paymentSucceeded,
                    mintUrl: selectedMintUrl.value,
                  ));
        }
      } else if (input.contains('@') ||
          input.toLowerCase().startsWith('lnurl')) {
        if (step.value == 0) {
          // Validate address/lnurl (basic check already done by split logic)
          // Move to next step
          step.value = 1;
          return;
        }

        if (amount <= 0) {
          BotToastUtils.showError(context.t.invalidAmount);
          return;
        }

        final success =
            await context.read<CashuWalletManagerCubit>().payLightningAddress(
                  lightningAddress: input,
                  amount: amount,
                  mintUrl: selectedMintUrl.value,
                  message: memoController.text,
                );

        if (success && context.mounted) {
          YNavigator.pop(context);
          YNavigator.presentPage(
              nostrRepository.ctx,
              (_) => CashuOperationSuccessView(
                    amount: amount,
                    title: nostrRepository.ctx.t.paymentSucceeded,
                    mintUrl: selectedMintUrl.value,
                  ));
        }
      } else {
        BotToastUtils.showError('Invalid input');
      }
    }

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
            title: context.t.lightningNetwork,
            isBack: false,
          ),
          _buildContent(
            context,
            selectedMintUrl,
            walletMints,
            cashuState,
            activeMintBalance,
            toInputController,
            payAmountController,
            memoController,
            isInvoice,
            step,
          ),
          _buildActionButtons(
            context,
            onPay,
            step,
            isInvoice,
            toInputController,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ValueNotifier<String> selectedMintUrl,
    List<String> walletMints,
    CashuWalletManagerState cashuState,
    int activeMintBalance,
    TextEditingController toInputController,
    TextEditingController payAmountController,
    TextEditingController memoController,
    bool isInvoice,
    ValueNotifier<int> step,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          children: [
            Expanded(
              child: _buildPayTab(
                context,
                toInputController,
                payAmountController,
                memoController,
                activeMintBalance,
                isInvoice,
                step,
              ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
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
                  value: selectedMintUrl.value,
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
                      selectedMintUrl.value = value;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Future<void> Function() onPay,
    ValueNotifier<int> step,
    bool isInvoice,
    TextEditingController toInputController,
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
                if (step.value == 1) {
                  step.value = 0;
                } else {
                  YNavigator.pop(context);
                }
              },
              title: step.value == 1
                  ? context.t.back.capitalizeFirst()
                  : context.t.cancel.capitalizeFirst(),
              icon: step.value == 1
                  ? FeatureIcons.arrowLeft
                  : FeatureIcons.closeRaw,
              borderColor: step.value == 1 ? null : kRed,
              textColor: step.value == 1 ? null : kRed,
              backgroundColor:
                  step.value == 1 ? null : kRed.withValues(alpha: 0.1),
            ),
          ),
          if (step.value == 0)
            Expanded(
              child: SendOptionsButton(
                onClicked: () {
                  HapticFeedback.mediumImpact();
                  YNavigator.presentPage(
                    context,
                    (context) => QrScannerModal(
                      onValue: (value) {
                        final val = value.toLowerCase();

                        if (val.startsWith('lnbc') ||
                            val.startsWith('lnurl') ||
                            emailRegExp.hasMatch(val)) {
                          toInputController.text = val;
                        }
                      },
                    ),
                  );
                },
                title: context.t.scanQrCode.capitalizeFirst(),
                icon: FeatureIcons.qr,
              ),
            ),
          Expanded(
            child: SendOptionsButton(
              onClicked: () {
                HapticFeedback.mediumImpact();
                onPay();
              },
              title: (isInvoice || step.value == 1
                      ? context.t.pay
                      : context.t.next)
                  .capitalizeFirst(),
              icon: isInvoice || step.value == 1
                  ? FeatureIcons.zapFilled
                  : FeatureIcons.arrowRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayTab(
    BuildContext context,
    TextEditingController inputController,
    TextEditingController amountController,
    TextEditingController memoController,
    int maxBalance,
    bool isInvoice,
    ValueNotifier<int> step,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  spacing: kDefaultPadding / 8,
                  children: [
                    if (step.value == 0) ...[
                      Text(
                        context.t.typeManualDesc,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextField(
                        controller: inputController,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        decoration: InputDecoration(
                          hintText: 'john.doe@yakihonne.com',
                          hintStyle:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
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
                    ] else ...[
                      Text(
                        inputController.text,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                if (isInvoice) ...[
                  const SizedBox(height: kDefaultPadding),
                  Builder(
                    builder: (context) {
                      final amount = getlnbcValue(inputController.text).toInt();
                      return _invoiceAmountDisplay(context, amount);
                    },
                  ),
                ] else if (step.value == 1) ...[
                  const SizedBox(height: kDefaultPadding),
                  _amountInput(context, amountController, maxBalance),
                  const SizedBox(height: kDefaultPadding),
                  _memoInput(context, memoController),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _amountInput(
      BuildContext context, TextEditingController controller, int maxBalance) {
    return Column(
      children: [
        TextField(
          controller: controller,
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
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: kDefaultPadding / 4,
          children: [
            Text(
              'SATS',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (int.tryParse(controller.text) != null &&
                int.parse(controller.text) > 0)
              Builder(
                builder: (context) {
                  final amount = int.parse(controller.text);
                  final amountInUsd =
                      walletManagerCubit.getBtcInFiatFromAmount(amount);
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
        if (maxBalance > 0) const SizedBox(height: kDefaultPadding / 2),
        if (maxBalance > 0)
          Text(
            '(Max: $maxBalance)',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
      ],
    );
  }

  Widget _memoInput(BuildContext context, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        hintText: context.t.memoOptional,
        hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).dividerColor,
            ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _invoiceAmountDisplay(BuildContext context, int amount) {
    return Column(
      children: [
        Text(
          amount.toString(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: kDefaultPadding / 4,
          children: [
            Text(
              'SATS',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Builder(
              builder: (context) {
                final amountInUsd =
                    walletManagerCubit.getBtcInFiatFromAmount(amount);
                if (amountInUsd == -1) {
                  return Text(
                    'N/A',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).highlightColor,
                        ),
                  );
                }
                return Text(
                  '~ \$${amountInUsd.toStringAsFixed(2)} ${walletManagerCubit.state.activeCurrency.toUpperCase()}',
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
    );
  }
}
