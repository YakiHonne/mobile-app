// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final Map<String, String> keyMap;
  final Map<String, bool> privateKeys;
  final Map<String, bool> externalKeys;
  final Map<String, ExternalKeyType> externalKeysType;
  final Map<String, AppClientModel> appClients;
  final bool refreshSettingData;
  final SettingData? settingsData;

  const SettingsState({
    required this.keyMap,
    required this.privateKeys,
    required this.externalKeys,
    required this.externalKeysType,
    required this.appClients,
    required this.refreshSettingData,
    this.settingsData,
  });

  @override
  List<Object> get props => [
        keyMap,
        privateKeys,
        externalKeys,
        externalKeysType,
        refreshSettingData,
        appClients,
      ];

  SettingsState copyWith({
    Map<String, String>? keyMap,
    Map<String, bool>? privateKeys,
    Map<String, bool>? externalKeys,
    Map<String, ExternalKeyType>? externalKeysType,
    Map<String, AppClientModel>? appClients,
    bool? refreshSettingData,
    SettingData? settingsData,
  }) {
    return SettingsState(
      keyMap: keyMap ?? this.keyMap,
      privateKeys: privateKeys ?? this.privateKeys,
      externalKeys: externalKeys ?? this.externalKeys,
      externalKeysType: externalKeysType ?? this.externalKeysType,
      appClients: appClients ?? this.appClients,
      refreshSettingData: refreshSettingData ?? this.refreshSettingData,
      settingsData: settingsData ?? this.settingsData,
    );
  }
}
