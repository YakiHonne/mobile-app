part of 'cashu_wallet_manager_cubit.dart';

class CashuWalletManagerState extends Equatable {
  const CashuWalletManagerState({
    required this.activeMint,
    required this.balance,
    required this.mints,
    required this.walletMints,
    required this.activeMintBalance,
    required this.recommendedMints,
    this.isInitializing = false,
  });

  final String activeMint;
  final int balance;
  final int activeMintBalance;
  final List<String> walletMints;
  final Map<String, IMint> mints;
  final List<MintInfo> recommendedMints;
  final bool isInitializing;

  @override
  List<Object> get props => [
        activeMint,
        balance,
        mints,
        activeMintBalance,
        recommendedMints,
        walletMints,
        isInitializing,
      ];

  CashuWalletManagerState copyWith({
    String? activeMint,
    int? balance,
    Map<String, IMint>? mints,
    List<String>? walletMints,
    int? activeMintBalance,
    List<MintInfo>? recommendedMints,
    bool? isInitializing,
  }) {
    return CashuWalletManagerState(
      activeMint: activeMint ?? this.activeMint,
      balance: balance ?? this.balance,
      mints: mints ?? this.mints,
      walletMints: walletMints ?? this.walletMints,
      activeMintBalance: activeMintBalance ?? this.activeMintBalance,
      recommendedMints: recommendedMints ?? this.recommendedMints,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}
