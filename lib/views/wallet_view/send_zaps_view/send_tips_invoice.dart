// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import 'send_multi_wallet_selector.dart';

class SendZapsUsingInvoice extends HookWidget {
  // ========================
  // PROPERTIES & CONSTRUCTOR
  // ========================

  final String invoice;
  final ValueNotifier<bool> useDefaultWallet;
  final Function(int) onSuccess;
  final Function(String) onFailure;
  final Function()? onSwitchToSend;
  final Metadata? user;

  const SendZapsUsingInvoice({
    super.key,
    required this.invoice,
    required this.useDefaultWallet,
    required this.onSuccess,
    required this.onFailure,
    this.onSwitchToSend,
    this.user,
  });

  // ========================
  // MAIN BUILD METHOD
  // ========================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButtons(context),
        Expanded(child: _buildScrollableContent(context)),
        _buildWalletSelector(useDefaultWallet),
        _buildPaymentButton(context),
      ],
    );
  }

  // ========================
  // SCROLLABLE CONTENT SECTION
  // ========================

  Widget _buildScrollableContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: kDefaultPadding,
              children: [
                _buildQrCodeSection(context),
                _buildAmountDisplay(context),
                _buildLnbcBox(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================
  // QR CODE SECTION
  // ========================

  Widget _buildQrCodeSection(BuildContext context) {
    return Container(
      width: 70.w,
      height: 70.w,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: _buildQrCodeDecoration(context),
      child: _buildQrCodeImage(context),
    );
  }

  Widget _buildLnbcBox(BuildContext context) {
    return DottedCopyContainer(
      lnurl: invoice,
    );
  }

  BoxDecoration _buildQrCodeDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding),
      border: Border.all(
        color: Theme.of(context).primaryColorDark,
        width: 5,
      ),
    );
  }

  Widget _buildQrCodeImage(BuildContext context) {
    return QrImageView(
      data: invoice,
      dataModuleStyle: QrDataModuleStyle(
        color: Theme.of(context).primaryColorDark,
        dataModuleShape: QrDataModuleShape.circle,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.circle,
        color: Theme.of(context).primaryColorDark,
      ),
    );
  }

  // ========================
  // AMOUNT DISPLAY SECTION
  // ========================

  Widget _buildAmountDisplay(BuildContext context) {
    final amount = _getInvoiceAmount();
    final amountInUsd = _getAmountInUsd(amount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSatsAmount(context, amount),
        const SizedBox(height: kDefaultPadding / 4),
        _buildUsdAmount(context, amountInUsd),
      ],
    );
  }

  Widget _buildSatsAmount(BuildContext context, int amount) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${amount != -1 ? amount : 'N/A'}',
          style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: kMainColor,
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

  Widget _buildUsdAmount(BuildContext context, double amountInUsd) {
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

  // ========================
  // WALLET SELECTOR SECTION
  // ========================

  Widget _buildWalletSelector(
    ValueNotifier<bool> useDefaultWallet,
  ) {
    return Column(
      children: [
        MultiWalletSelector(
          useDefaultWallet: useDefaultWallet,
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
      ],
    );
  }

  // ========================
  // PAYMENT BUTTON SECTION
  // ========================

  Widget _buildPaymentButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
      ),
      child: SizedBox(
        width: double.infinity,
        child: _buildPaymentButtonWithBloc(context),
      ),
    );
  }

  Widget _buildPaymentButtonWithBloc(BuildContext context) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _handlePaymentButtonPress(),
            style: _buildButtonStyle(context),
            child: _buildButtonChild(context, state.isLoading),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SendActionsButtons(
      onSwitchToSend: onSwitchToSend,
    );
  }

  ButtonStyle _buildButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );
  }

  Widget _buildButtonChild(BuildContext context, bool isLoading) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? _buildLoadingIndicator()
          : _buildPaymentButtonInnerContent(context),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SpinKitCircle(
      key: ValueKey(2),
      color: kWhite,
      size: 20,
    );
  }

  Widget _buildPaymentButtonInnerContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey(1),
      spacing: kDefaultPadding / 4,
      children: [
        _buildPaymentIcon(context),
        _buildPaymentText(context),
      ],
    );
  }

  Widget _buildPaymentIcon(BuildContext context) {
    return SvgPicture.asset(
      FeatureIcons.zapFilled,
      width: 15,
      height: 15,
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildPaymentText(BuildContext context) {
    return Text(
      key: const ValueKey(1),
      context.t.pay.capitalizeFirst(),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  // ========================
  // BUSINESS LOGIC METHODS
  // ========================

  Future<void> _handlePaymentButtonPress() async {
    await walletManagerCubit.sendUsingInvoice(
      invoice: MapEntry(invoice, null),
      removeSuccess: true,
      user: user,
      onSuccess: _handlePaymentSuccess,
      onFailure: onFailure,
      onFinished: (_) {},
      useDefaultWallet: useDefaultWallet.value,
    );
  }

  void _handlePaymentSuccess() {
    final amount = _getInvoiceAmount();

    if (amount == -1) {
      return;
    }

    onSuccess.call(amount);
  }

  // ========================
  // UTILITY METHODS
  // ========================

  int _getInvoiceAmount() {
    return getlnbcValue(invoice).toInt();
  }

  double _getAmountInUsd(int amount) {
    return walletManagerCubit.getBtcInUsdFromAmount(amount);
  }
}

class SendActionsButtons extends StatelessWidget {
  const SendActionsButtons({
    super.key,
    required this.onSwitchToSend,
  });

  final Function()? onSwitchToSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (onSwitchToSend != null)
          RotatedBox(
            quarterTurns: 1,
            child: CustomIconButton(
              onClicked: onSwitchToSend!,
              icon: FeatureIcons.arrowDown,
              size: 15,
              vd: -1,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ),
        CustomIconButton(
          onClicked: () async {
            YNavigator.pop(context);
          },
          icon: FeatureIcons.closeRaw,
          size: 15,
          vd: -1,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}

class DottedCopyContainer extends StatelessWidget {
  const DottedCopyContainer({
    super.key,
    required this.lnurl,
    this.message,
  });

  final String lnurl;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
          ClipboardData(text: lnurl),
        );

        BotToastUtils.showSuccess(
          message ?? context.t.invoiceCopied.capitalize(),
        );
      },
      child: DottedBorder(
        color: Theme.of(context).dividerColor,
        strokeCap: StrokeCap.round,
        borderType: BorderType.rRect,
        radius: const Radius.circular(kDefaultPadding / 2),
        dashPattern: const [4],
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Row(
            spacing: kDefaultPadding / 2,
            children: [
              Expanded(
                child: Text(
                  lnurl,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SvgPicture.asset(
                FeatureIcons.copy,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).highlightColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
