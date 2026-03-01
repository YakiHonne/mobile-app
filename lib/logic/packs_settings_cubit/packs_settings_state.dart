part of 'packs_settings_cubit.dart';

class PacksSettingsState extends Equatable {
  const PacksSettingsState({
    required this.packs,
    required this.starterPacks,
    required this.isLoading,
  });

  final Map<String, PacksModel> packs;
  final Map<String, bool> starterPacks;
  final bool isLoading;

  @override
  List<Object> get props => [
        packs,
        isLoading,
        starterPacks,
      ];

  PacksSettingsState copyWith({
    Map<String, PacksModel>? packs,
    bool? isLoading,
    Map<String, bool>? starterPacks,
  }) {
    return PacksSettingsState(
      packs: packs ?? this.packs,
      isLoading: isLoading ?? this.isLoading,
      starterPacks: starterPacks ?? this.starterPacks,
    );
  }
}
