import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:numeral/numeral.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/app_models/extended_model.dart';
import '../../../models/article_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';
import '../send_view/send_main_view.dart';
import 'send_multi_wallet_selector.dart';

/// Widget for setting zap amount with various input options and wallet selection
class SendAmountSet extends HookWidget {
  const SendAmountSet({
    super.key,
    required this.metadata,
    required this.isZapSplit,
    required this.zapSplits,
    required this.useDefaultWallet,
    this.eventId,
    this.aTag,
    this.pollOption,
    required this.onSuccess,
    required this.onFailure,
    required this.onInvoiceGenerated,
    this.valMax,
    this.valMin,
    this.initialVal,
    this.lnbc,
  });

  final bool isZapSplit;
  final Metadata metadata;
  final ValueNotifier<bool> useDefaultWallet;
  final List<ZapSplit> zapSplits;
  final String? lnbc;
  final String? eventId;
  final String? aTag;
  final String? pollOption;
  final Function(Map<String, dynamic>) onSuccess;
  final Function(String) onFailure;
  final Function(String) onInvoiceGenerated;
  final num? valMax;
  final num? valMin;
  final num? initialVal;

  @override
  Widget build(BuildContext context) {
    final currentMetadata = nostrRepository.currentMetadata;

    // State management
    final isUsingSats = useState(true);
    final isSending = useState(WalletSendingType.none);
    final amount = useState(_getInitialAmount());

    // Controllers
    final amountController =
        useTextEditingController(text: _getInitialAmount());
    final commentController = useTextEditingController();
    final pageController = usePageController(viewportFraction: 0.85);

    final focusNode = useFocusNode();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Small delay to let the widget tree settle before focusing
        Future.delayed(const Duration(milliseconds: 500), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
      });

      return null;
    }, []);

    return Column(
      children: [
        _buildHeader(context, currentMetadata),
        _buildMainContent(
          context,
          amountController,
          commentController,
          pageController,
          amount,
          isUsingSats,
          focusNode,
        ),
        if (_shouldShowMinMaxButtons())
          _buildMinMaxButtons(context, amount, amountController),
        _buildActionSection(
          context,
          isSending,
          amount,
          amountController,
          commentController,
        ),
      ],
    );
  }

  /// Get initial amount value
  String _getInitialAmount() {
    if (initialVal != null && initialVal != -1) {
      return initialVal.toString();
    }
    if (valMin != null && valMin != -1) {
      return valMin.toString();
    }
    return '1';
  }

  /// Check if min/max buttons should be shown
  bool _shouldShowMinMaxButtons() => valMax != null || valMin != null;

  /// Build header section based on zap type
  Widget _buildHeader(BuildContext context, dynamic currentMetadata) {
    if (isZapSplit) {
      return _buildZapSplitHeader(context);
    } else if (metadata.pubkey.isNotEmpty) {
      return _buildUserTransferHeader(context, currentMetadata);
    }
    return const SizedBox.shrink();
  }

  /// Build zap split header
  Widget _buildZapSplitHeader(BuildContext context) {
    return Text(
      context.t.zapSplits.capitalizeFirst(),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  /// Build user transfer header with profile pictures
  Widget _buildUserTransferHeader(
      BuildContext context, dynamic currentMetadata) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 3),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 1.5),
      decoration: _getHeaderDecoration(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 2,
        children: [
          _buildProfilePicture(currentMetadata.picture, currentMetadata.pubkey),
          const SizedBox(width: 45, child: ArrowAnimation()),
          _buildProfilePicture(metadata.picture, metadata.pubkey),
        ],
      ),
    );
  }

  /// Build profile picture widget
  Widget _buildProfilePicture(String picture, String pubkey) {
    return Center(
      child: ProfilePicture2(
        size: 22,
        image: picture,
        pubkey: pubkey,
        padding: 0,
        strokeWidth: 0,
        strokeColor: kTransparent,
        onClicked: () {},
      ),
    );
  }

  /// Get header decoration
  BoxDecoration _getHeaderDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      border: Border.all(color: Theme.of(context).dividerColor),
    );
  }

  /// Build main scrollable content
  Widget _buildMainContent(
    BuildContext context,
    TextEditingController amountController,
    TextEditingController commentController,
    PageController pageController,
    ValueNotifier<String> amount,
    ValueNotifier<bool> isUsingSats,
    FocusNode focusNode,
  ) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: kDefaultPadding / 2,
                children: [
                  _buildAmountInput(
                    context,
                    amountController,
                    amount,
                    focusNode,
                  ),
                  const SizedBox(height: kDefaultPadding / 2),
                  _buildCurrencyToggle(context, isUsingSats),
                  _buildConvertedAmount(context, amount, isUsingSats),
                  _buildDivider(),
                  _buildCommentInput(context, commentController),
                  _buildDivider(),
                  if (isZapSplit)
                    _buildZapSplitsList(context, pageController, amount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build divider widget
  Widget _buildDivider() {
    return SizedBox(
      width: 70.w,
      child: const Center(child: Divider(thickness: 0.5)),
    );
  }

  /// Build amount input field
  Widget _buildAmountInput(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<String> amount,
    FocusNode focusNode,
  ) {
    return TextFormField(
      focusNode: focusNode,
      controller: controller,
      onChanged: (value) => amount.value = value,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: _getAmountInputStyle(context),
      decoration: _getAmountInputDecoration(context),
    );
  }

  /// Get amount input text style
  TextStyle _getAmountInputStyle(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!.copyWith(
          fontWeight: FontWeight.w600,
          color: kMainColor,
        );
  }

  /// Get amount input decoration
  InputDecoration _getAmountInputDecoration(BuildContext context) {
    return InputDecoration(
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
    );
  }

  /// Build currency toggle button
  Widget _buildCurrencyToggle(
      BuildContext context, ValueNotifier<bool> isUsingSats) {
    return GestureDetector(
      onTap: () => isUsingSats.value = !isUsingSats.value,
      behavior: HitTestBehavior.translucent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: kDefaultPadding / 2,
        children: [
          Text(
            isUsingSats.value ? 'SATS' : 'USD',
            style: _getCurrencyToggleStyle(context),
          ),
          _buildCurrencyToggleIcon(context),
        ],
      ),
    );
  }

  /// Get currency toggle text style
  TextStyle _getCurrencyToggleStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
  }

  /// Build currency toggle icon
  Widget _buildCurrencyToggleIcon(BuildContext context) {
    return SvgPicture.asset(
      FeatureIcons.repost,
      width: 15,
      height: 15,
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }

  /// Build converted amount display
  Widget _buildConvertedAmount(
    BuildContext context,
    ValueNotifier<String> amount,
    ValueNotifier<bool> isUsingSats,
  ) {
    return Builder(
      builder: (context) {
        final convertedAmount =
            _calculateConvertedAmount(amount.value, isUsingSats.value);
        final currency = !isUsingSats.value ? 'SATS' : 'USD';

        return Text(
          '$convertedAmount $currency',
          style: _getConvertedAmountStyle(context),
        );
      },
    );
  }

  /// Calculate converted amount
  String _calculateConvertedAmount(String amountText, bool isUsingSats) {
    final textAmount = int.tryParse(amountText);
    if (textAmount == null) {
      return '0';
    }

    return isUsingSats
        ? walletManagerCubit
            .getBtcInUsdFromAmount(textAmount)
            .numeral(digits: 2)
        : walletManagerCubit
            .getUsdInBtcFromAmount(textAmount)
            .numeral(digits: 2);
  }

  /// Get converted amount text style
  TextStyle _getConvertedAmountStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).highlightColor,
        );
  }

  /// Build comment input field
  Widget _buildCommentInput(
      BuildContext context, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      style: _getCommentInputStyle(context),
      decoration: _getCommentInputDecoration(context),
    );
  }

  /// Get comment input text style
  TextStyle _getCommentInputStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
  }

  /// Get comment input decoration
  InputDecoration _getCommentInputDecoration(BuildContext context) {
    return InputDecoration(
      hintText: context.t.writeCommentOptional,
      hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).dividerColor,
          ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Build zap splits list
  Widget _buildZapSplitsList(
    BuildContext context,
    PageController pageController,
    ValueNotifier<String> amount,
  ) {
    return Column(
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
          builder: (context, state) => SizedBox(
            height: 130,
            child: PageView.builder(
              controller: pageController,
              itemBuilder: (context, index) => _buildZapSplitItem(
                context,
                zapSplits[index],
                amount,
                state,
              ),
              itemCount: zapSplits.length,
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
      ],
    );
  }

  /// Build individual zap split item
  Widget _buildZapSplitItem(
    BuildContext context,
    ZapSplit zap,
    ValueNotifier<String> amount,
    WalletsManagerState state,
  ) {
    return MetadataProvider(
      pubkey: zap.pubkey,
      search: false,
      child: (metadata, isNip05Valid) => Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 4),
        decoration: _getZapSplitItemDecoration(context),
        child: Column(
          children: [
            _buildZapSplitItemHeader(context, metadata, zap, amount),
            const SizedBox(height: kDefaultPadding / 2),
            _buildZapSplitContent(context, metadata, state, zap),
          ],
        ),
      ),
    );
  }

  /// Get zap split item decoration
  BoxDecoration _getZapSplitItemDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
    );
  }

  /// Build zap split item header
  Widget _buildZapSplitItemHeader(
    BuildContext context,
    Metadata metadata,
    ZapSplit zap,
    ValueNotifier<String> amount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildZapSplitProfilePicture(metadata),
        const SizedBox(width: kDefaultPadding / 2),
        _buildZapSplitUserInfo(context, metadata),
        _buildZapSplitAmount(context, zap, amount),
      ],
    );
  }

  /// Build zap split profile picture
  Widget _buildZapSplitProfilePicture(Metadata metadata) {
    return ProfilePicture2(
      size: 25,
      image: metadata.picture,
      pubkey: metadata.pubkey,
      padding: 0,
      strokeWidth: 0,
      strokeColor: kTransparent,
      onClicked: () {},
    );
  }

  /// Build zap split user info
  Widget _buildZapSplitUserInfo(BuildContext context, Metadata metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.splitZapsWith.capitalize(),
            style: _getZapSplitLabelStyle(context),
          ),
          Text(
            metadata.getName(),
            style: _getZapSplitUserNameStyle(context),
          ),
        ],
      ),
    );
  }

  /// Build zap split amount display
  Widget _buildZapSplitAmount(
    BuildContext context,
    ZapSplit zap,
    ValueNotifier<String> amount,
  ) {
    final zapAmount = getspecificZapValue(
      currentZapValue: num.tryParse(amount.value) ?? 0,
      zaps: zapSplits,
      currentZap: zap,
    );

    return Text(
      '$zapAmount Sats',
      style: _getZapSplitAmountStyle(context),
    );
  }

  /// Get zap split label text style
  TextStyle _getZapSplitLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).highlightColor,
        );
  }

  /// Get zap split user name text style
  TextStyle _getZapSplitUserNameStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: kRed,
        );
  }

  /// Get zap split amount text style
  TextStyle _getZapSplitAmountStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          color: kMainColor,
          fontWeight: FontWeight.w700,
        );
  }

  /// Build zap split content based on invoice status
  Widget _buildZapSplitContent(
    BuildContext context,
    Metadata metadata,
    WalletsManagerState state,
    ZapSplit zap,
  ) {
    if (!ExtendedMetadata.canBeZapped(metadata)) {
      return Text(context.t.useCannotBeZapped.capitalize());
    }

    if (!state.areInvoicesAvailable) {
      return _buildWaitingForInvoiceText(context);
    } else if (state.invoices[zap.pubkey] != null) {
      return _buildInvoiceContent(
          context, metadata, state.invoices[zap.pubkey]!);
    } else {
      return _buildInvoiceNotGeneratedText(context);
    }
  }

  /// Build waiting for invoice text
  Widget _buildWaitingForInvoiceText(BuildContext context) {
    return Text(
      context.t.waitingGenerationOfInvoice.capitalize(),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Build invoice not generated text
  Widget _buildInvoiceNotGeneratedText(BuildContext context) {
    return Text(
      context.t.userInvoiceNotGenerated.capitalize(),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Build invoice content with QR and copy buttons
  Widget _buildInvoiceContent(
    BuildContext context,
    Metadata metadata,
    String invoice,
  ) {
    return Column(
      children: [
        Text(
          context.t.userInvoiceGenerated(name: metadata.getName()).capitalize(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        _buildInvoiceActions(context, invoice),
      ],
    );
  }

  /// Build invoice action buttons
  Widget _buildInvoiceActions(BuildContext context, String invoice) {
    return Row(
      children: [
        Expanded(
          child: _buildQrCodeButton(context, invoice),
        ),
        const SizedBox(width: kDefaultPadding / 4),
        Expanded(
          child: _buildCopyInvoiceButton(context, invoice),
        ),
      ],
    );
  }

  /// Build QR code button
  Widget _buildQrCodeButton(BuildContext context, String invoice) {
    return TextButton.icon(
      onPressed: () => _showQrCodeDialog(context, invoice),
      icon: _buildQrCodeIcon(context),
      label: Text(
        context.t.qrCode.capitalize(),
        style: _getInvoiceButtonTextStyle(context),
      ),
      style: _getInvoiceButtonStyle(context),
    );
  }

  /// Build QR code icon
  Widget _buildQrCodeIcon(BuildContext context) {
    return SvgPicture.asset(
      FeatureIcons.qr,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }

  /// Build copy invoice button
  Widget _buildCopyInvoiceButton(BuildContext context, String invoice) {
    return TextButton(
      onPressed: () => _copyInvoiceToClipboard(context, invoice),
      style: _getInvoiceButtonStyle(context),
      child: Text(
        context.t.copyInvoice.capitalize(),
        style: _getInvoiceButtonTextStyle(context),
      ),
    );
  }

  /// Get invoice button text style
  TextStyle _getInvoiceButtonTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
          color: Theme.of(context).primaryColorDark,
        );
  }

  /// Get invoice button style
  ButtonStyle _getInvoiceButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Show QR code dialog
  void _showQrCodeDialog(BuildContext context, String invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: _buildQrCodeDialogContent(context, invoice),
        contentPadding: const EdgeInsets.all(kDefaultPadding / 2),
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  /// Build QR code dialog content
  Widget _buildQrCodeDialogContent(BuildContext context, String invoice) {
    return SizedBox(
      width: 70.w,
      height: 70.w + 25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQrCodeImage(context, invoice),
          Text(
            context.t.scanQrCode.capitalize(),
            style: _getQrCodeDialogTextStyle(context),
          ),
        ],
      ),
    );
  }

  /// Build QR code image
  Widget _buildQrCodeImage(BuildContext context, String invoice) {
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

  /// Get QR code dialog text style
  TextStyle _getQrCodeDialogTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: Theme.of(context).primaryColorDark,
        );
  }

  /// Copy invoice to clipboard
  void _copyInvoiceToClipboard(BuildContext context, String invoice) {
    Clipboard.setData(ClipboardData(text: invoice));
    BotToastUtils.showSuccess(context.t.invoiceCopied.capitalize());
  }

  /// Build min/max buttons section
  Widget _buildMinMaxButtons(
    BuildContext context,
    ValueNotifier<String> amount,
    TextEditingController amountController,
  ) {
    return Column(
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        Row(
          children: [
            Expanded(
              child: _buildMinButton(context, amount, amountController),
            ),
            const SizedBox(width: kDefaultPadding / 4),
            Expanded(
              child: _buildMaxButton(context, amount, amountController),
            ),
          ],
        ),
        const SizedBox(height: kDefaultPadding / 4),
      ],
    );
  }

  /// Build minimum value button
  Widget _buildMinButton(
    BuildContext context,
    ValueNotifier<String> amount,
    TextEditingController amountController,
  ) {
    return ValSatsContainer(
      onClicked: () => _setAmount(amountController, amount, valMin),
      isSelected: int.tryParse(amount.value) == valMin,
      title: context.t.minSats.capitalize(),
      val: _formatMinMaxValue(valMin),
    );
  }

  /// Build maximum value button
  Widget _buildMaxButton(
    BuildContext context,
    ValueNotifier<String> amount,
    TextEditingController amountController,
  ) {
    return ValSatsContainer(
      onClicked: () => _setAmount(amountController, amount, valMax),
      isSelected: int.tryParse(amount.value) == valMax,
      title: context.t.maxSats.capitalize(),
      val: _formatMinMaxValue(valMax),
    );
  }

  /// Set amount value
  void _setAmount(
    TextEditingController controller,
    ValueNotifier<String> amount,
    num? value,
  ) {
    if (value != null) {
      controller.text = value.toString();
      amount.value = value.toString();
    }
  }

  /// Format min/max value for display
  String _formatMinMaxValue(num? value) {
    return value == -1 ? 'N/A' : value?.toStringAsFixed(0) ?? 'N/A';
  }

  /// Build action section with wallet selector and buttons
  Widget _buildActionSection(
    BuildContext context,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + kDefaultPadding / 2,
      ),
      child: Column(
        spacing: kDefaultPadding / 4,
        children: [
          _buildWalletSelector(),
          _buildActionButtons(
            context,
            isSending,
            amount,
            amountController,
            commentController,
          ),
        ],
      ),
    );
  }

  /// Build wallet selector
  Widget _buildWalletSelector() {
    return MultiWalletSelector(useDefaultWallet: useDefaultWallet);
  }

  /// Build action buttons
  Widget _buildActionButtons(
    BuildContext context,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) {
    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) => Row(
        spacing: kDefaultPadding / 4,
        children: [
          if (!state.areInvoicesAvailable)
            Expanded(
              child: _buildInvoiceButton(
                context,
                state,
                isSending,
                amount,
                amountController,
                commentController,
              ),
            ),
          if (!isZapSplit || state.areInvoicesAvailable)
            Expanded(
              child: _buildSendButton(
                context,
                state,
                isSending,
                amount,
                amountController,
                commentController,
              ),
            ),
        ],
      ),
    );
  }

  /// Build invoice generation button
  Widget _buildInvoiceButton(
    BuildContext context,
    WalletsManagerState state,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) {
    final title = isZapSplit
        ? context.t.generateInvoices.capitalizeFirst()
        : context.t.invoice.capitalizeFirst();

    final isLoading = isSending.value == WalletSendingType.invoice
        ? true
        : isSending.value == WalletSendingType.send
            ? false
            : null;

    return SendOptionsButton(
      onClicked: () => _handleInvoiceButtonPress(
        context,
        isSending,
        amount,
        amountController,
        commentController,
      ),
      title: title,
      icon: FeatureIcons.qr,
      isLoading: isLoading,
    );
  }

  /// Build send payment button
  Widget _buildSendButton(
    BuildContext context,
    WalletsManagerState state,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) {
    final isLoading = isSending.value == WalletSendingType.send
        ? true
        : isSending.value == WalletSendingType.invoice
            ? false
            : null;

    return SendOptionsButton(
      onClicked: () => _handleSendButtonPress(
        context,
        state,
        isSending,
        amount,
        amountController,
        commentController,
      ),
      title: context.t.send,
      icon: FeatureIcons.send,
      isLoading: isLoading,
    );
  }

  /// Handle invoice button press
  Future<void> _handleInvoiceButtonPress(
    BuildContext context,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) async {
    isSending.value = WalletSendingType.invoice;

    await handleInvoiceButtonPress(
      context: context,
      amount: amount,
      amountTextEditingController: amountController,
      commentTextEditingController: commentController,
      metadata: metadata,
      onInvoiceGenerated: onInvoiceGenerated,
      isZapSplit: isZapSplit,
      onFailure: onFailure,
    );

    isSending.value = WalletSendingType.none;
  }

  /// Handle send button press
  Future<void> _handleSendButtonPress(
    BuildContext context,
    WalletsManagerState state,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) async {
    if (state.areInvoicesAvailable) {
      await _handleZapSplitSend(context, isSending);
    } else {
      await _handleRegularSend(
        context,
        isSending,
        amount,
        amountController,
        commentController,
      );
    }
  }

  /// Handle zap split send
  Future<void> _handleZapSplitSend(
    BuildContext context,
    ValueNotifier<WalletSendingType> isSending,
  ) async {
    if (!useDefaultWallet.value) {
      isSending.value = WalletSendingType.send;
    }

    context.read<WalletsManagerCubit>().handleWalletZapSplit(
          onFinished: () {
            isSending.value = WalletSendingType.none;
            YNavigator.pop(context);
          },
          onFailure: onFailure,
          onSuccess: (message) => onSuccess.call({'message': message}),
          useDefaultWallet: useDefaultWallet.value,
        );
  }

  /// Handle regular send
  Future<void> _handleRegularSend(
    BuildContext context,
    ValueNotifier<WalletSendingType> isSending,
    ValueNotifier<String> amount,
    TextEditingController amountController,
    TextEditingController commentController,
  ) async {
    isSending.value = WalletSendingType.send;

    await handlePaymentButtonPress(
      context: context,
      amount: amount,
      amountTextEditingController: amountController,
      commentTextEditingController: commentController,
      metadata: metadata,
      useExternalWallet: useDefaultWallet.value,
    );

    isSending.value = WalletSendingType.none;
  }

  // === BUSINESS LOGIC METHODS ===
  // (Keeping exactly the same as original for functionality preservation)

  Future<void> handleInvoiceButtonPress({
    required BuildContext context,
    required ValueNotifier<String> amount,
    required TextEditingController amountTextEditingController,
    required TextEditingController commentTextEditingController,
    required Metadata metadata,
    required bool isZapSplit,
    required Function(String)? onInvoiceGenerated,
    required Function(String)? onFailure,
  }) async {
    HapticFeedback.mediumImpact();

    final message = checkSats(
      valueTextController: amountTextEditingController,
      val: amount,
      context: context,
    );

    if (message != null) {
      onFailure?.call(message);
      return;
    }

    if (isZapSplit) {
      await context.read<WalletsManagerCubit>().getInvoices(
            currentZapValue: num.parse(amount.value),
            zapSplits: zapSplits,
            comment: commentTextEditingController.text,
            eventId: eventId,
            aTag: aTag,
            onFailure: onFailure,
          );
    } else {
      final completer = Completer<void>();

      context.read<WalletsManagerCubit>().generateZapInvoice(
            sats: int.parse(amount.value),
            user: metadata,
            comment: commentTextEditingController.text,
            eventId: eventId,
            onSuccess: (invoice) {
              onInvoiceGenerated?.call(invoice);
              completer.complete();
            },
            onFailure: (message) {
              onFailure?.call(message);
              completer.complete();
            },
          );

      return completer.future;
    }
  }

  Future<void> handlePaymentButtonPress({
    required BuildContext context,
    required ValueNotifier<String> amount,
    required TextEditingController amountTextEditingController,
    required TextEditingController commentTextEditingController,
    required Metadata metadata,
    required bool useExternalWallet,
  }) async {
    final completer = Completer<void>();
    HapticFeedback.mediumImpact();

    final message = checkSats(
      valueTextController: amountTextEditingController,
      val: amount,
      context: context,
    );

    if (message != null) {
      BotToastUtils.showError(message);
      return;
    }

    final parsedAmount = int.parse(amount.value);

    context.read<WalletsManagerCubit>().handleWalletZap(
          sats: parsedAmount,
          user: metadata,
          eventId: eventId,
          aTag: aTag,
          pollOption: pollOption,
          comment: commentTextEditingController.text,
          useExternalWallet: useExternalWallet,
          onFinished: (_) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onSuccess: (preimage) {
            onSuccess.call({
              'preimage': preimage,
              'amount': parsedAmount,
            });
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onFailure: (message) {
            onFailure.call(message);
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );

    return completer.future;
  }

  String? checkSats({
    required TextEditingController valueTextController,
    required ValueNotifier<String> val,
    required BuildContext context,
  }) {
    final sts = int.tryParse(valueTextController.text);

    if (sts == null || sts == 0) {
      valueTextController.text = '0';
      val.value = '0';
      return context.t.minimumOfOneRequired.capitalize();
    }

    final checkMax = valMax != null && valMax != -1 && sts > valMax!;
    final checkMin = valMin != null && valMin != -1 && sts < valMin!;

    if (checkMax || checkMin) {
      valueTextController.text = '0';
      val.value = '0';
      return context.t.valueBetweenMinMax.capitalize();
    }

    return null;
  }

  num getspecificZapValue({
    required num currentZapValue,
    required List<ZapSplit> zaps,
    required ZapSplit currentZap,
  }) {
    if (zaps.isEmpty) {
      return 0;
    }

    num total = 0;
    for (final zap in zaps) {
      total += zap.percentage;
    }

    if (total == 0) {
      return 0;
    } else {
      return ((currentZap.percentage * 100 / total).round()) *
          currentZapValue /
          100;
    }
  }
}

/// Container widget for min/max value selection
class ValSatsContainer extends StatelessWidget {
  const ValSatsContainer({
    super.key,
    required this.val,
    required this.isSelected,
    required this.title,
    required this.onClicked,
  });

  final String val;
  final bool isSelected;
  final String title;
  final VoidCallback onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: val == 'N/A' ? null : onClicked,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        decoration: _getContainerDecoration(context),
        child: Column(
          children: [
            Text(
              title,
              style: _getTitleStyle(context),
            ),
            Text(
              val,
              style: _getValueStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getContainerDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      border: Border.all(
        color: isSelected
            ? Theme.of(context).primaryColorDark
            : Theme.of(context).dividerColor,
      ),
      color: Theme.of(context).cardColor,
    );
  }

  TextStyle _getTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Theme.of(context).highlightColor,
        );
  }

  TextStyle _getValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w800,
        );
  }
}

/// Animated arrow widget for transfer indication
class ArrowAnimation extends HookWidget {
  const ArrowAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2, milliseconds: 500),
    )..repeat();

    final opacityAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
        ),
      ),
    );

    final positionAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1).animate(controller),
    );

    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            SizedBox(
              width: constraints.maxWidth,
              height: 34,
            ),
            Positioned(
              left: positionAnimation * (constraints.maxWidth * 0.5),
              top: 0,
              bottom: 0,
              child:
                  _buildAnimatedArrows(context, constraints, opacityAnimation),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedArrows(
    BuildContext context,
    BoxConstraints constraints,
    double opacity,
  ) {
    return SizedBox(
      width: constraints.maxWidth / 1.5,
      child: Opacity(
        opacity: opacity <= 0.5 ? opacity : 1 - opacity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 5,
                color: kDimGrey,
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 8,
                color: Theme.of(context).primaryColorDark,
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 5,
                color: kDimGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
