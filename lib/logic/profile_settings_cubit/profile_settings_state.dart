// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'profile_settings_cubit.dart';

class ProfileSettingsState extends Equatable {
  final String nip05;
  final String lud16;
  final String lud6;
  final String name;
  final String displayName;
  final String description;
  final String website;
  final bool refresh;
  final String bannerLink;
  final String imageLink;
  final String pubkey;
  final bool isUploading;

  /// Username already claimed on the account. Non-empty means the Yaki username
  /// row is settled and read-only — a claimed name cannot be changed.
  final String username;

  /// Live availability of whatever is typed in the username field.
  final AddressStatus usernameStatus;

  /// NIP-05 name owned on the account, bare (no `@yakihonne.com`).
  final String accountNip05;
  final bool accountNip05Active;

  /// Server's reason for the last failed claim, surfaced under the field.
  final String identityError;
  final bool isClaiming;

  const ProfileSettingsState({
    required this.nip05,
    required this.lud16,
    required this.lud6,
    required this.name,
    required this.displayName,
    required this.description,
    required this.website,
    required this.refresh,
    required this.bannerLink,
    required this.imageLink,
    required this.pubkey,
    required this.isUploading,
    this.username = '',
    this.usernameStatus = AddressStatus.unchecked,
    this.accountNip05 = '',
    this.accountNip05Active = false,
    this.identityError = '',
    this.isClaiming = false,
  });

  @override
  List<Object> get props => [
        nip05,
        lud16,
        lud6,
        name,
        displayName,
        description,
        website,
        refresh,
        bannerLink,
        imageLink,
        pubkey,
        isUploading,
        username,
        usernameStatus,
        accountNip05,
        accountNip05Active,
        identityError,
        isClaiming,
      ];

  ProfileSettingsState copyWith({
    String? nip05,
    String? lud16,
    String? lud6,
    String? name,
    String? displayName,
    String? description,
    String? website,
    bool? refresh,
    String? bannerLink,
    String? imageLink,
    String? pubkey,
    bool? isUploading,
    String? username,
    AddressStatus? usernameStatus,
    String? accountNip05,
    bool? accountNip05Active,
    String? identityError,
    bool? isClaiming,
  }) {
    return ProfileSettingsState(
      nip05: nip05 ?? this.nip05,
      lud16: lud16 ?? this.lud16,
      lud6: lud6 ?? this.lud6,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      website: website ?? this.website,
      refresh: refresh ?? this.refresh,
      bannerLink: bannerLink ?? this.bannerLink,
      imageLink: imageLink ?? this.imageLink,
      pubkey: pubkey ?? this.pubkey,
      isUploading: isUploading ?? this.isUploading,
      username: username ?? this.username,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      accountNip05: accountNip05 ?? this.accountNip05,
      accountNip05Active: accountNip05Active ?? this.accountNip05Active,
      identityError: identityError ?? this.identityError,
      isClaiming: isClaiming ?? this.isClaiming,
    );
  }
}
