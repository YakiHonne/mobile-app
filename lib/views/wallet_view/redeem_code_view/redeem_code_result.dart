import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/utils.dart';
import '../send_zaps_view/send_tips_invoice.dart';

/// Widget for displaying zap payment results (success or failure)
class RedeemCodeResults extends HookWidget {
  const RedeemCodeResults({
    super.key,
    required this.onSwitchToOptions,
    required this.data,
  });

  final Function() onSwitchToOptions;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isSuccessful = data['status'] as bool;
    final resultCode = data['resultCode'] as String;
    final amount = data['amount'] as num?;
    final animationController = useAnimationController(
      upperBound: isSuccessful ? 0.70 : 1,
      duration: const Duration(milliseconds: 500),
    );

    return Column(
      children: [
        _buildActionButtons(isSuccessful),
        Expanded(
          child: FadeIn(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: kDefaultPadding,
              children: [
                _buildAnimationIcon(isSuccessful, animationController),
                _buildContent(
                  context: context,
                  result: isSuccessful,
                  resultCode: resultCode,
                  amount: amount,
                ),
                const SizedBox(
                  height: kToolbarHeight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the action buttons at the top
  Widget _buildActionButtons(bool isSuccessful) {
    return SendActionsButtons(
      onSwitchToSend: isSuccessful ? null : onSwitchToOptions,
    );
  }

  /// Build the Lottie animation icon
  Widget _buildAnimationIcon(
    bool result,
    AnimationController animationController,
  ) {
    return Lottie.asset(
      result ? LottieAnimations.redeemCode : LottieAnimations.failure,
      height: result ? 20.h : 10.h,
      fit: BoxFit.contain,
      frameRate: const FrameRate(60),
      repeat: false,
      controller: animationController,
      onLoaded: (composition) {
        animationController
          ..duration = composition.duration * (result ? 0.7 : 1)
          ..forward();
      },
    );
  }

  /// Build success content layout
  Widget _buildContent({
    required BuildContext context,
    required bool result,
    required String resultCode,
    required num? amount,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding / 4,
      children: [
        _buildContentTitle(
          context,
          result ? context.t.congratulations : context.t.redeemingFailed,
        ),
        _buildContentMessage(context, resultCode),
        if (amount != null) _buildContentAmount(context, amount),
      ],
    );
  }

  /// Build success message text
  Widget _buildContentTitle(BuildContext context, String text) {
    return Text(
      text,
      style: _getTitleTextStyle(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContentAmount(BuildContext context, num amount) {
    return Text(
      context.t.satsEarned(amount: amount),
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContentMessage(BuildContext context, String resultCode) {
    String message = '';

    switch (resultCode) {
      case 'missingCode':
        message = context.t.missingCode.capitalizeFirst();
      case 'missingPubkey':
        message = context.t.missingPubkey;
      case 'invalidPubkey':
        message = context.t.invalidPubkey;
      case 'missingLightningAddress':
        message = context.t.missingLightningAddress;
      case 'invalidLightningAddress':
        message = context.t.invalidLightningAddress;
      case 'codeNotFound':
        message = context.t.codeNotFound;
      case 'codeBeingRedeemed':
        message = context.t.codeBeingRedeemed;
      case 'codeAlreadyRedeemed':
        message = context.t.codeAlreadyRedeemed;
      case 'paymentFailed':
        message = context.t.redeemFailed;
      case 'codeRedeemed':
        message = context.t.redeemCodeSuccess;
      default:
        message = context.t.redeemFailed;
    }

    return Text(
      message,
      style: _getHighlightTextStyle(context),
      textAlign: TextAlign.center,
    );
  }

  TextStyle _getTitleTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w700,
        );
  }

  /// Get highlight text style
  TextStyle _getHighlightTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          color: Theme.of(context).highlightColor,
        );
  }
}
