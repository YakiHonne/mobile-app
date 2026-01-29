import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/profile_picture.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_selection_dropdown.dart';

class CashuNutZapAmountView extends HookWidget {
  const CashuNutZapAmountView({
    super.key,
    required this.metadata,
  });

  final Metadata metadata;

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();
    final memoController = useTextEditingController();
    final amountInSats = useState(0);

    final cashuState = context.watch<CashuWalletManagerCubit>().state;
    final walletMints = cashuState.walletMints;
    final selectedMintUrl = useState(cashuState.activeMint);

    useEffect(() {
      if (!walletMints.contains(selectedMintUrl.value) &&
          walletMints.isNotEmpty) {
        selectedMintUrl.value = walletMints.first;
      }
      return null;
    }, [walletMints]);

    final activeMintBalance =
        cashuState.mints[selectedMintUrl.value]?.balance ?? 0;

    useEffect(() {
      amountController.addListener(() {
        amountInSats.value = int.tryParse(amountController.text) ?? 0;
      });
      return null;
    }, []);

    Future<void> onSendNutZap() async {
      final amount = amountInSats.value;

      if (amount <= 0) {
        BotToastUtils.showError(context.t.invalidAmount);
        return;
      }

      if (amount > activeMintBalance) {
        BotToastUtils.showError(context.t.insufficientFunds);
        return;
      }

      final success = await context.read<CashuWalletManagerCubit>().sendNutzap(
            pubkey: metadata.pubkey,
            amount: amount,
            mintUrl: selectedMintUrl.value,
            memo: memoController.text,
          );

      if (success && context.mounted) {
        YNavigator.pop(context); // Close search view
        YNavigator.pop(context); // Close send view
        YNavigator.presentPage(
          nostrRepository.ctx,
          (_) => CashuOperationSuccessView(
            amount: amount,
            title: nostrRepository.ctx.t.nutZapSent,
            mintUrl: selectedMintUrl.value,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      height: 85.h,
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
            title: context.t.nutZap,
            isBack: false,
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _amountInput(
                            context, amountController, activeMintBalance),
                        const SizedBox(height: kDefaultPadding),
                        _memoInput(context, memoController),
                      ],
                    ),
                  ),
                  _buildMintSelection(
                    context,
                    cashuState,
                    walletMints,
                    selectedMintUrl,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  _recipientTile(context),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom +
                  MediaQuery.of(context).viewInsets.bottom +
                  kDefaultPadding / 2,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
              top: kDefaultPadding / 2,
            ),
            child: _buildActionButtons(context, onSendNutZap),
          ),
        ],
      ),
    );
  }

  Widget _buildMintSelection(
    BuildContext context,
    CashuWalletManagerState cashuState,
    List<String> walletMints,
    ValueNotifier<String?> selectedMintUrl,
  ) {
    return Column(
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
    );
  }

  Widget _buildActionButtons(BuildContext context, VoidCallback onSendNutZap) {
    return Row(
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
        Expanded(
          child: SendOptionsButton(
            onClicked: () {
              HapticFeedback.mediumImpact();
              onSendNutZap();
            },
            title: context.t.pay.capitalizeFirst(),
            icon: FeatureIcons.zapFilled,
          ),
        ),
      ],
    );
  }

  Widget _recipientTile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 4,
      children: [
        Text(
          context.t.to,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        Container(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Row(
            spacing: kDefaultPadding / 2,
            children: [
              ProfilePicture2(
                image: metadata.picture,
                pubkey: metadata.pubkey,
                size: 30,
                padding: 0,
                strokeWidth: 0,
                strokeColor: kTransparent,
                onClicked: () {},
              ),
              Flexible(
                child: Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
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
}
