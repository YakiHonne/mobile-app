// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'logify_cubit.dart';

class LogifyState extends Equatable {
  final bool refresh;
  final String name;
  final String about;
  final Set<String> pubkeys;
  final List<String> interests;
  final String private;
  final String wallet;
  final String lightningAddress;
  final bool includeWallet;
  final bool isSettingAccount;
  final File? picture;
  final File? cover;

  const LogifyState({
    required this.refresh,
    required this.name,
    required this.about,
    required this.pubkeys,
    required this.interests,
    required this.private,
    required this.wallet,
    required this.includeWallet,
    required this.lightningAddress,
    required this.isSettingAccount,
    this.picture,
    this.cover,
  });

  @override
  List<Object> get props => [
        refresh,
        name,
        about,
        pubkeys,
        interests,
        private,
        wallet,
        includeWallet,
        lightningAddress,
        isSettingAccount,
      ];

  LogifyState copyWith({
    bool? refresh,
    String? name,
    String? about,
    Set<String>? pubkeys,
    List<String>? interests,
    String? private,
    String? wallet,
    String? lightningAddress,
    bool? includeWallet,
    bool? isSettingAccount,
    File? picture,
    File? cover,
  }) {
    return LogifyState(
      refresh: refresh ?? this.refresh,
      name: name ?? this.name,
      about: about ?? this.about,
      pubkeys: pubkeys ?? this.pubkeys,
      interests: interests ?? this.interests,
      private: private ?? this.private,
      wallet: wallet ?? this.wallet,
      lightningAddress: lightningAddress ?? this.lightningAddress,
      includeWallet: includeWallet ?? this.includeWallet,
      isSettingAccount: isSettingAccount ?? this.isSettingAccount,
      picture: picture ?? this.picture,
      cover: cover ?? this.cover,
    );
  }
}
