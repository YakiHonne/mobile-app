import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/qr_scanner_modal.dart';
import 'cashu_operation_success_view.dart';
import 'cashu_selection_dropdown.dart';

class CashuRedeemView extends HookWidget {
  const CashuRedeemView({super.key, this.encodedToken});

  final String? encodedToken;

  @override
  Widget build(BuildContext context) {
    final cashuState = context.watch<CashuWalletManagerCubit>().state;
    final tokenController = useTextEditingController(text: encodedToken);
    final tokenData = useState<Map<String, dynamic>?>(null);
    final isProcessing = useState(false);
    final selectedMint = useState<String?>(
        cashuState.activeMint.isEmpty ? null : cashuState.activeMint);
    final issuingMintInfo = useState<MintInfo?>(null);

    void parseToken() {
      final token = tokenController.text.trim();
      if (token.isEmpty) {
        BotToastUtils.showError(context.t.invalidToken);
        return;
      }

      final decoded =
          context.read<CashuWalletManagerCubit>().decodeToken(token);
      if (decoded == null) {
        BotToastUtils.showError(context.t.invalidToken);
        return;
      }

      tokenData.value = decoded;

      final mintUrl = decoded['mint'] as String;
      if (!cashuState.walletMints.contains(mintUrl)) {
        context
            .read<CashuWalletManagerCubit>()
            .getMintInfo(mintUrl)
            .then((info) {
          issuingMintInfo.value = info;
        });
      } else {
        issuingMintInfo.value = cashuState.mints[mintUrl]?.info;
      }
    }

    useEffect(() {
      if (encodedToken != null && encodedToken!.isNotEmpty) {
        // Ensure the controller has the text before parsing
        tokenController.text = encodedToken!;
        parseToken();
      }
      return null; // No cleanup needed
    }, [encodedToken]); // Run when encodedToken changes

    return Container(
      width: double.infinity,
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
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalBottomSheetAppbar(
            title: context.t.redeemEcash,
            isBack: false,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token input section
                if (tokenData.value == null)
                  _buildInputSection(
                    context,
                    tokenController,
                    parseToken,
                  )
                else
                  _buildDetailsSection(
                    context,
                    tokenData,
                    cashuState,
                    selectedMint,
                    issuingMintInfo.value,
                    tokenController,
                    isProcessing,
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(
    BuildContext context,
    TextEditingController tokenController,
    VoidCallback parseToken,
  ) {
    return Column(
      children: [
        Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  hintText: context.t.pasteToken,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final data = await Clipboard.getData('text/plain');

                      if (data?.text != null) {
                        tokenController.text = data!.text!;
                        parseToken();
                      }
                    },
                  ),
                ),
              ),
            ),
            CustomIconButton(
              onClicked: () {
                HapticFeedback.mediumImpact();
                YNavigator.presentPage(
                  context,
                  (context) => QrScannerModal(
                    onValue: (value) {
                      YNavigator.presentPage(
                        context,
                        (context) => CashuRedeemView(
                          encodedToken: value,
                        ),
                      );
                    },
                  ),
                );
              },
              icon: FeatureIcons.qr,
              size: 20,
              backgroundColor: Theme.of(context).cardColor,
              borderRadius: kDefaultPadding / 1.5,
              vd: 2.5,
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding / 2),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: parseToken,
            child: Text(
              context.t.verifyToken,
              style: const TextStyle(
                color: kWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    ValueNotifier<Map<String, dynamic>?> tokenData,
    CashuWalletManagerState cashuState,
    ValueNotifier<String?> selectedMint,
    MintInfo? issuingMintInfo,
    TextEditingController tokenController,
    ValueNotifier<bool> isProcessing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.to,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: kDefaultPadding / 3),
        CashuSelectionDropdown<String>(
          value: selectedMint.value,
          hint: context.t.selectMint,
          items: cashuState.walletMints.map((mintUrl) {
            final mint = cashuState.mints[mintUrl];
            return CashuDropdownItem<String>(
              value: mintUrl,
              label: mint?.info?.name ?? mintUrl,
              icon: mint?.info?.iconUrl,
              assetIcon: Images.cashu,
            );
          }).toList(),
          onChanged: (value) {
            selectedMint.value = value;
          },
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.details.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: kDefaultPadding / 3),
        SizedBox(
          width: double.infinity,
          child: _buildDetailCard(
            context,
            label: context.t.issuingMint,
            value: tokenData.value!['mint'],
            icon: issuingMintInfo?.iconUrl,
            trailing: !cashuState.walletMints.contains(tokenData.value!['mint'])
                ? CustomIconButton(
                    onClicked: () async {
                      HapticFeedback.mediumImpact();
                      final success = await context
                          .read<CashuWalletManagerCubit>()
                          .updateMintList(tokenData.value!['mint'],
                              checkBeforeUpdate: true);

                      if (success) {
                        selectedMint.value = tokenData.value!['mint'];
                      }
                    },
                    icon: FeatureIcons.addRaw,
                    size: 17,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  )
                : null,
          ),
        ),
        if (tokenData.value!['memo'] != null &&
            tokenData.value!['memo'] != '') ...[
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: _buildDetailCard(
              context,
              label: context.t.memo,
              value: tokenData.value!['memo'],
            ),
          ),
        ],
        const SizedBox(height: kDefaultPadding / 4),
        Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: _buildDetailCard(
                context,
                label: context.t.amount,
                value: '${tokenData.value!['amount']} sats',
              ),
            ),
            Expanded(
              child: _buildDetailCard(
                context,
                label: context.t.proofs,
                value: '${tokenData.value!['proofs']}',
              ),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding),
        SizedBox(
          width: double.infinity,
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              CustomIconButton(
                onClicked: () {
                  HapticFeedback.mediumImpact();
                  tokenData.value = null;
                  tokenController.clear();
                },
                icon: FeatureIcons.arrowLeft,
                size: 20,
                backgroundColor: Theme.of(context).cardColor,
                borderRadius: kDefaultPadding / 2,
                vd: 1,
              ),
              Expanded(
                child: TextButton(
                  onPressed: isProcessing.value || selectedMint.value == null
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          isProcessing.value = true;
                          final success = await context
                              .read<CashuWalletManagerCubit>()
                              .redeemToken(
                                tokenController.text.trim(),
                                targetMintUrl: selectedMint.value,
                              );
                          isProcessing.value = false;
                          if (context.mounted) {
                            if (success) {
                              YNavigator.pop(context);
                              YNavigator.presentPage(
                                context,
                                (_) => CashuOperationSuccessView(
                                  amount: tokenData.value!['amount'],
                                  title: context.t.tokenRedeemed,
                                  mintUrl: selectedMint.value,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(
                    context.t.redeemToken,
                    style: const TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String label,
    required String value,
    String? icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        if (icon != null)
                          CommonThumbnail(
                            image: icon,
                            assetUrl: Images.cashu,
                            width: 25,
                            height: 25,
                            isRound: true,
                          ),
                        Expanded(
                          child: Text(
                            value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }
}
