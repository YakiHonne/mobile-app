// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'wallets_manager_cubit.dart';

@immutable
class WalletsManagerState extends Equatable {
  final int selectedIndex;
  final String lnurl;
  final bool isLnurlAvailable;
  final bool isLoading;
  final bool confirmPayment;
  final Map<String, String?> invoices;
  final bool areInvoicesAvailable;
  final num toBeZappedValue;
  final bool refresh;
  final Map<String, WalletModel> wallets;
  final String selectedWalletId;
  final int balance;
  final int maxAmount;
  final String defaultExternalWallet;
  final List<WalletTransactionModel> transactions;
  final bool isLoadingTransactions;
  final UpdatingState transactionsState;
  final bool shouldPopView;
  final double balanceInUSD;
  final bool isWalletHidden;
  final bool useDefaultWallet;

  const WalletsManagerState({
    required this.selectedIndex,
    required this.lnurl,
    required this.areInvoicesAvailable,
    required this.isLnurlAvailable,
    required this.isLoading,
    required this.confirmPayment,
    required this.invoices,
    required this.toBeZappedValue,
    required this.refresh,
    required this.wallets,
    required this.selectedWalletId,
    required this.balance,
    required this.maxAmount,
    required this.defaultExternalWallet,
    required this.transactions,
    required this.isLoadingTransactions,
    required this.transactionsState,
    required this.shouldPopView,
    required this.balanceInUSD,
    required this.isWalletHidden,
    required this.useDefaultWallet,
  });

  // Factory constructor for initial state
  factory WalletsManagerState.initial() {
    return const WalletsManagerState(
      selectedIndex: -1,
      lnurl: '',
      areInvoicesAvailable: false,
      isLnurlAvailable: false,
      isLoading: false,
      confirmPayment: false,
      invoices: {},
      toBeZappedValue: 0,
      refresh: false,
      wallets: {},
      selectedWalletId: '',
      balance: -1,
      maxAmount: -1,
      defaultExternalWallet: 'satoshi',
      transactions: [],
      isLoadingTransactions: false,
      transactionsState: UpdatingState.idle,
      shouldPopView: true,
      balanceInUSD: -1,
      isWalletHidden: false,
      useDefaultWallet: false,
    );
  }

  // Helper getters
  bool get hasWallets => wallets.isNotEmpty;
  bool get hasSelectedWallet =>
      selectedWalletId.isNotEmpty && wallets.containsKey(selectedWalletId);
  bool get hasBalance => balance >= 0;
  bool get hasValidBalance => balance > 0;
  WalletModel? get selectedWallet => wallets[selectedWalletId];
  bool get isNWCWallet => selectedWallet is NostrWalletConnectModel;
  bool get isAlbyWallet => selectedWallet is AlbyConnectModel;

  WalletsManagerState copyWith({
    int? selectedIndex,
    String? lnurl,
    bool? isLnurlAvailable,
    bool? isLoading,
    bool? confirmPayment,
    Map<String, String?>? invoices,
    bool? areInvoicesAvailable,
    num? toBeZappedValue,
    bool? refresh,
    Map<String, WalletModel>? wallets,
    String? selectedWalletId,
    int? balance,
    int? maxAmount,
    String? defaultExternalWallet,
    List<WalletTransactionModel>? transactions,
    bool? isLoadingTransactions,
    UpdatingState? transactionsState,
    bool? shouldPopView,
    double? balanceInUSD,
    bool? isWalletHidden,
    bool? useDefaultWallet,
  }) {
    return WalletsManagerState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lnurl: lnurl ?? this.lnurl,
      isLnurlAvailable: isLnurlAvailable ?? this.isLnurlAvailable,
      isLoading: isLoading ?? this.isLoading,
      confirmPayment: confirmPayment ?? this.confirmPayment,
      invoices: invoices ?? this.invoices,
      areInvoicesAvailable: areInvoicesAvailable ?? this.areInvoicesAvailable,
      toBeZappedValue: toBeZappedValue ?? this.toBeZappedValue,
      refresh: refresh ?? this.refresh,
      wallets: wallets ?? this.wallets,
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
      balance: balance ?? this.balance,
      maxAmount: maxAmount ?? this.maxAmount,
      defaultExternalWallet:
          defaultExternalWallet ?? this.defaultExternalWallet,
      transactions: transactions ?? this.transactions,
      isLoadingTransactions:
          isLoadingTransactions ?? this.isLoadingTransactions,
      transactionsState: transactionsState ?? this.transactionsState,
      shouldPopView: shouldPopView ?? this.shouldPopView,
      balanceInUSD: balanceInUSD ?? this.balanceInUSD,
      isWalletHidden: isWalletHidden ?? this.isWalletHidden,
      useDefaultWallet: useDefaultWallet ?? this.useDefaultWallet,
    );
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        lnurl,
        isLnurlAvailable,
        isLoading,
        confirmPayment,
        invoices,
        areInvoicesAvailable,
        toBeZappedValue,
        refresh,
        wallets,
        selectedWalletId,
        balance,
        maxAmount,
        defaultExternalWallet,
        transactions,
        transactionsState,
        shouldPopView,
        balanceInUSD,
        isWalletHidden,
        useDefaultWallet,
      ];
}
