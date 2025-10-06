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
    );
  }
}
