import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/utils.dart';
import 'send_tips_invoice.dart';

/// Widget for displaying zap payment results (success or failure)
class SendZapsResult extends StatelessWidget {
  const SendZapsResult({
    super.key,
    required this.onSwitchToSend,
    required this.data,
  });

  final VoidCallback onSwitchToSend;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final isSuccess = data['success'] as bool;

    return Column(
      children: [
        _buildActionButtons(),
        Expanded(
          child: FadeIn(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: kDefaultPadding,
              children: [
                _buildAnimationIcon(isSuccess),
                if (isSuccess)
                  _buildSuccessContent(context)
                else
                  _buildFailureContent(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the action buttons at the top
  Widget _buildActionButtons() {
    return SendActionsButtons(
      onSwitchToSend: onSwitchToSend,
    );
  }

  /// Build the Lottie animation icon
  Widget _buildAnimationIcon(bool isSuccess) {
    return Lottie.asset(
      isSuccess ? LottieAnimations.success : LottieAnimations.failure,
      height: isSuccess ? 13.h : 10.h,
      fit: BoxFit.contain,
      frameRate: const FrameRate(60),
      repeat: false,
    );
  }

  /// Build success content layout
  Widget _buildSuccessContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding,
      children: [
        _buildSuccessMessage(context),
        if (data['amount'] != null) _buildAmountDisplay(context),
        if (data['message'] != null)
          _buildMessageText(context, data['message']),
        if (data['ln'] != null) _buildLightningAddress(context),
      ],
    );
  }

  /// Build failure content layout
  Widget _buildFailureContent(BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 4,
      children: [
        _buildFailureMessage(context),
        if (data['message'] != null)
          _buildMessageText(context, data['message']),
      ],
    );
  }

  /// Build success message text
  Widget _buildSuccessMessage(BuildContext context) {
    return Text(
      context.t.paymentSucceeded.capitalizeFirst(),
      style: _getHighlightTextStyle(context),
      textAlign: TextAlign.center,
    );
  }

  /// Build failure message text
  Widget _buildFailureMessage(BuildContext context) {
    return Text(
      context.t.paymentFailed.capitalizeFirst(),
      style: _getHighlightTextStyle(context),
      textAlign: TextAlign.center,
    );
  }

  /// Build amount display with BTC and USD values
  Widget _buildAmountDisplay(BuildContext context) {
    final amount = data['amount'];
    final amountInUsd = walletManagerCubit.getBtcInFiatFromAmount(amount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSatsAmount(context, amount),
        const SizedBox(height: kDefaultPadding / 4),
        _buildUsdAmount(context, amountInUsd),
      ],
    );
  }

  /// Build the sats amount row
  Widget _buildSatsAmount(BuildContext context, dynamic amount) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatAmount(amount),
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
    );
  }

  /// Build the USD amount row
  Widget _buildUsdAmount(BuildContext context, dynamic amountInUsd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '~ \$${_formatUsdAmount(amountInUsd)}',
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

  /// Build lightning address section
  Widget _buildLightningAddress(BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 4,
      children: [
        Text(
          context.t.lightningAddress.capitalizeFirst(),
          style: _getHighlightTextStyle(context),
          textAlign: TextAlign.center,
        ),
        Text(
          data['ln'],
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build message text widget
  Widget _buildMessageText(BuildContext context, String message) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  /// Get highlight text style
  TextStyle _getHighlightTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).highlightColor,
        );
  }

  /// Format amount for display
  String _formatAmount(dynamic amount) {
    return amount != -1 ? amount.toString() : 'N/A';
  }

  /// Format USD amount for display
  String _formatUsdAmount(dynamic amountInUsd) {
    return amountInUsd == -1 ? 'N/A' : amountInUsd.toStringAsFixed(2);
  }
}
