import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/cashu/models/cashu_encoded_token.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../settings_view/widgets/keys_view.dart';
import '../../wallet_view/send_view/send_main_view.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/response_snackbar.dart';

class CashuTokenDetailsView extends HookWidget {
  const CashuTokenDetailsView({
    super.key,
    required this.token,
    required this.onRefresh,
  });

  final CashuEncodedToken token;
  final Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final status = useState<String?>(token.status);
    final isRedeeming = useState(false);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalBottomSheetAppbar(
            title: context.t.eCash,
            isBack: false,
          ),
          Column(
            children: [
              const SizedBox(height: kDefaultPadding),
              const SizedBox(height: kDefaultPadding),
              _buildTokenHeader(context),
              const SizedBox(height: kDefaultPadding),
              _buildQrCode(),
              const SizedBox(height: kDefaultPadding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: DottedContainer(
                  title: context.t.copyToken,
                  value: token.encodedToken,
                  onClicked: () {
                    Clipboard.setData(ClipboardData(text: token.encodedToken));
                    BotToastUtils.showSuccess(context.t.copy);
                  },
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              _buildActionButtons(context, status, isRedeeming),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${token.amount}',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
        ),
        const SizedBox(width: kDefaultPadding / 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'sats',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: QrImageView(
        data: token.encodedToken,
        size: 50.w,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ValueNotifier<String?> status,
    ValueNotifier<bool> isRedeeming,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          Expanded(
            child: SendOptionsButton(
              onClicked: () {
                showCupertinoDeletionDialogue(
                  context: context,
                  title: context.t.deleteToken,
                  description: context.t.deleteTokenDesc,
                  buttonText: context.t.delete.capitalizeFirst(),
                  onDelete: () {
                    cashuWalletManagerCubit.deleteCreatedToken(token);
                    onRefresh();
                    YNavigator.pop(context);
                  },
                );
              },
              title: context.t.delete.capitalizeFirst(),
              icon: FeatureIcons.trash,
              backgroundColor: kRed.withValues(alpha: 0.1),
              textColor: kRed,
              borderColor: kTransparent,
            ),
          ),
          Expanded(
            child: SendOptionsButton(
              onClicked: status.value == CashuEncodedToken.SPENT
                  ? () {}
                  : status.value == CashuEncodedToken.UNSPENT
                      ? () async {
                          if (isRedeeming.value) {
                            return;
                          }

                          isRedeeming.value = true;
                          final success = await cashuWalletManagerCubit
                              .redeemToken(token.encodedToken);
                          isRedeeming.value = false;

                          if (success && context.mounted) {
                            status.value = CashuEncodedToken.SPENT;
                            cashuWalletManagerCubit.markTokenAsSpent(token);
                            onRefresh();
                          }
                        }
                      : () async {
                          final isSpendable =
                              await cashuWalletManagerCubit.checkTokenStatus(
                            token.encodedToken,
                          );

                          if (isSpendable != null) {
                            status.value = isSpendable
                                ? CashuEncodedToken.UNSPENT
                                : CashuEncodedToken.SPENT;

                            if (status.value == CashuEncodedToken.SPENT) {
                              cashuWalletManagerCubit.markTokenAsSpent(token);
                              onRefresh();
                            }
                          }
                        },
              title: status.value == CashuEncodedToken.SPENT
                  ? context.t.alreadySpent
                  : status.value == CashuEncodedToken.UNSPENT
                      ? context.t.claim
                      : context.t.checkStatus,
              icon: status.value == CashuEncodedToken.UNSPENT
                  ? FeatureIcons.downloadCloud
                  : status.value == CashuEncodedToken.SPENT
                      ? FeatureIcons.verified
                      : FeatureIcons.refresh,
              textColor: status.value == CashuEncodedToken.UNSPENT
                  ? kWhite
                  : status.value == CashuEncodedToken.SPENT
                      ? kGreen
                      : Theme.of(context).primaryColorDark,
              backgroundColor: status.value == CashuEncodedToken.UNSPENT
                  ? Theme.of(context).primaryColor
                  : status.value == CashuEncodedToken.SPENT
                      ? kGreen.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
              borderColor: status.value == CashuEncodedToken.UNSPENT
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : status.value == CashuEncodedToken.SPENT
                      ? kGreen.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }
}
