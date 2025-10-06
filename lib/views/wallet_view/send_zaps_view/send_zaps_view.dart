// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../logic/wallets_manager_cubit/wallets_manager_cubit.dart';
import '../../../models/article_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import 'send_amount_set.dart';
import 'send_tips_invoice.dart';
import 'send_zaps_results.dart';

/// Widget for handling zap payments with multiple flow states
class SendZapsView extends HookWidget {
  const SendZapsView({
    super.key,
    required this.isZapSplit,
    required this.metadata,
    required this.zapSplits,
    this.eventId,
    this.aTag,
    this.pollOption,
    this.onSuccess,
    this.onFailure,
    this.valMax,
    this.valMin,
    this.initialVal,
    this.lnbc,
  });

  final bool isZapSplit;
  final Metadata metadata;
  final List<ZapSplit> zapSplits;
  final String? lnbc;
  final String? eventId;
  final String? aTag;
  final String? pollOption;
  final Function(String, int)? onSuccess;
  final Function(String)? onFailure;
  final num? valMax;
  final num? valMin;
  final num? initialVal;

  @override
  Widget build(BuildContext context) {
    // Initialize metadata for all zap splits
    _initializeZapSplitMetadata();

    // State management
    final sendZapViewType = useState(_getInitialViewType());
    final lnbcValue = useState(lnbc);
    final resultData = useState<Map<String, dynamic>>({});
    final useDefaultWallet = useState(_shouldUseDefaultWallet());

    // Effects
    _setupEffects(useDefaultWallet);

    return BlocBuilder<WalletsManagerCubit, WalletsManagerState>(
      builder: (context, state) => _buildContainer(
        context: context,
        sendZapViewType: sendZapViewType,
        lnbcValue: lnbcValue,
        resultData: resultData,
        useDefaultWallet: useDefaultWallet,
      ),
    );
  }

  /// Initialize metadata for all zap split recipients
  void _initializeZapSplitMetadata() {
    for (final zapSplit in zapSplits) {
      metadataCubit.requestMetadata(zapSplit.pubkey);
    }
  }

  /// Determine the initial view type based on whether we have an invoice
  SendZapViewType _getInitialViewType() {
    return lnbc == null ? SendZapViewType.amount : SendZapViewType.invoice;
  }

  /// Determine if we should use the default wallet
  bool _shouldUseDefaultWallet() {
    final state = walletManagerCubit.state;
    return state.useDefaultWallet ||
        (!state.useDefaultWallet && !state.hasWallets);
  }

  /// Setup hooks effects
  void _setupEffects(ValueNotifier<bool> useDefaultWallet) {
    useEffect(
      () {
        walletManagerCubit.requestBalance();
        return () => walletManagerCubit.resetInvoice();
      },
      [],
    );
  }

  /// Build the main container
  Widget _buildContainer({
    required BuildContext context,
    required ValueNotifier<SendZapViewType> sendZapViewType,
    required ValueNotifier<String?> lnbcValue,
    required ValueNotifier<Map<String, dynamic>> resultData,
    required ValueNotifier<bool> useDefaultWallet,
  }) {
    return Container(
      width: double.infinity,
      height: 90.h,
      padding: MediaQuery.of(context).viewInsets.copyWith(
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
          ),
      decoration: _buildContainerDecoration(context),
      child: Column(
        children: [
          const ModalBottomSheetHandle(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              child: _getCurrentWidget(
                context: context,
                type: sendZapViewType,
                lnbcValue: lnbcValue,
                resultData: resultData,
                useDefaultWallet: useDefaultWallet,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build container decoration
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.5,
      ),
    );
  }

  /// Get the current widget based on view type
  Widget _getCurrentWidget({
    required BuildContext context,
    required ValueNotifier<SendZapViewType> type,
    required ValueNotifier<String?> lnbcValue,
    required ValueNotifier<Map<String, dynamic>> resultData,
    required ValueNotifier<bool> useDefaultWallet,
  }) {
    switch (type.value) {
      case SendZapViewType.amount:
        return _buildAmountWidget(
            type, lnbcValue, resultData, useDefaultWallet);
      case SendZapViewType.invoice:
        return _buildInvoiceWidget(
            type, lnbcValue, resultData, useDefaultWallet);
      case SendZapViewType.result:
        return _buildResultWidget(type, resultData);
    }
  }

  /// Build the amount setting widget
  Widget _buildAmountWidget(
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<String?> lnbcValue,
    ValueNotifier<Map<String, dynamic>> resultData,
    ValueNotifier<bool> useDefaultWallet,
  ) {
    return SendAmountSet(
      metadata: metadata,
      isZapSplit: isZapSplit,
      zapSplits: zapSplits,
      eventId: eventId,
      aTag: aTag,
      pollOption: pollOption,
      onSuccess: (data) => _handleAmountSuccess(data, type, resultData),
      onFailure: (message) => _handleFailure(message, type, resultData),
      onInvoiceGenerated: (invoice) =>
          _handleInvoiceGenerated(invoice, type, lnbcValue),
      valMax: valMax,
      valMin: valMin,
      initialVal: initialVal,
      lnbc: lnbcValue.value,
      useDefaultWallet: useDefaultWallet,
    );
  }

  /// Build the invoice widget
  Widget _buildInvoiceWidget(
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<String?> lnbcValue,
    ValueNotifier<Map<String, dynamic>> resultData,
    ValueNotifier<bool> useDefaultWallet,
  ) {
    return SendZapsUsingInvoice(
      invoice: lnbcValue.value!,
      user: metadata,
      onSwitchToSend:
          lnbc == null ? () => type.value = SendZapViewType.amount : null,
      onFailure: (message) => _handleFailure(message, type, resultData),
      useDefaultWallet: useDefaultWallet,
      onSuccess: (amount) => _handleInvoiceSuccess(amount, type, resultData),
    );
  }

  /// Build the result widget
  Widget _buildResultWidget(
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<Map<String, dynamic>> resultData,
  ) {
    return SendZapsResult(
      data: resultData.value,
      onSwitchToSend: () => _handleSwitchToSend(type),
    );
  }

  /// Handle successful amount setting
  void _handleAmountSuccess(
    Map<String, dynamic> data,
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<Map<String, dynamic>> resultData,
  ) {
    final preimage = data['preimage'];
    final amount = data['amount'];

    if (preimage != null && amount != null) {
      onSuccess?.call(preimage, amount);
    }

    resultData.value = _createSuccessResult(data);
    type.value = SendZapViewType.result;
  }

  /// Handle successful invoice payment
  void _handleInvoiceSuccess(
    int amount,
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<Map<String, dynamic>> resultData,
  ) {
    resultData.value = _createSuccessResult({
      'preimage': '',
      'amount': amount,
    });

    onSuccess?.call('', amount);
    type.value = SendZapViewType.result;
  }

  /// Handle failure cases
  void _handleFailure(
    String message,
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<Map<String, dynamic>> resultData,
  ) {
    onFailure?.call(message);
    resultData.value = _createFailureResult(message);
    type.value = SendZapViewType.result;
  }

  /// Handle invoice generation
  void _handleInvoiceGenerated(
    String invoice,
    ValueNotifier<SendZapViewType> type,
    ValueNotifier<String?> lnbcValue,
  ) {
    lnbcValue.value = invoice;
    type.value = SendZapViewType.invoice;
  }

  /// Handle switching back to send view
  void _handleSwitchToSend(ValueNotifier<SendZapViewType> type) {
    type.value =
        lnbc == null ? SendZapViewType.amount : SendZapViewType.invoice;
  }

  /// Create success result data
  Map<String, dynamic> _createSuccessResult(Map<String, dynamic> data) {
    return {
      ...data,
      'success': true,
      'ln': metadata.lud16.isNotEmpty ? metadata.lud16 : null,
    };
  }

  /// Create failure result data
  Map<String, dynamic> _createFailureResult(String message) {
    return {
      'success': false,
      'message': message,
      'ln': metadata.lud16.isNotEmpty ? metadata.lud16 : null,
    };
  }
}
