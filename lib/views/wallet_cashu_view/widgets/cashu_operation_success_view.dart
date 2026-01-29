import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Actually utils.dart is already imported line 7. Checks for kWhite/kBlack logic.
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart'; // Ensure kWhite is available or import it
import '../../settings_view/widgets/keys_view.dart';
import '../../widgets/dotted_container.dart';

class CashuOperationSuccessView extends StatelessWidget {
  const CashuOperationSuccessView({
    super.key,
    required this.amount,
    required this.title,
    this.mintUrl,
    this.token,
  });

  final int amount;
  final String title;
  final String? mintUrl;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final closeButton = TextButton(
      onPressed: () async {
        YNavigator.popToRoot(context);
      },
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Text(
        context.t.close.capitalizeFirst(),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );

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
            title: title,
            isBack: false,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: Column(
              children: [
                FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing:
                        token != null ? kDefaultPadding / 2 : kDefaultPadding,
                    children: [
                      _buildSuccessAnimation(),
                      _buildAmountDetails(context),
                      if (mintUrl != null)
                        Column(
                          spacing: kDefaultPadding / 4,
                          children: [
                            Text(
                              context.t.to.capitalizeFirst(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context).highlightColor,
                                  ),
                            ),
                            Text(
                              mintUrl!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      if (token != null) _buildTokenDetails(context),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: closeButton,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Lottie.asset(
      LottieAnimations.success,
      height: token != null ? 8.h : 13.h,
      fit: BoxFit.contain,
      frameRate: const FrameRate(60),
      repeat: false,
    );
  }

  Widget _buildAmountDetails(BuildContext context) {
    return Builder(
      builder: (context) {
        final amountInUsd = walletManagerCubit.getBtcInFiatFromAmount(amount);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: kDefaultPadding / 4,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$amount',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
                Text(
                  'sats',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '~ \$${amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  ' ${walletManagerCubit.state.activeCurrency.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTokenDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: kDefaultPadding),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(kDefaultPadding),
            ),
            child: QrImageView(
              data: token!,
              size: 45.w,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          DottedContainer(
            title: context.t.copyToken,
            value: token!,
            onClicked: () {
              Clipboard.setData(
                ClipboardData(text: token!),
              );

              BotToastUtils.showSuccess(
                context.t.copyToken,
              );
            },
          ),
        ],
      ),
    );
  }
}
