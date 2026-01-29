import 'dart:convert';
import 'dart:developer';

import 'package:bip340/bip340.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../initializers.dart';
import '../../models/app_client_model.dart';
import '../../models/app_models/settings_data.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(
          const SettingsState(
            externalKeys: {},
            keyMap: {},
            privateKeys: {},
            refreshSettingData: false,
            appClients: {},
            externalKeysType: {},
          ),
        );

  Map<String, String> get keyMap => _keyMap;

  Map<String, bool> get keyIsPrivateMap => _keyIsPrivateMap;

  Map<String, bool> get keyIsExternalSignerMap => _keyIsExternalSignerMap;

  Map<String, ExternalKeyType> get externalKeysType => _externalKeysType;

  SettingData? _settingData;

  SettingData get settingData => _settingData!;

  int? get privateKeyIndex => _settingData!.privateKeyIndex;

  String get imageService => _settingData!.imageService;

  bool get backgroundService => _settingData!.backgroundService ?? true;

  bool get linkPreview => _settingData!.linkPreview ?? true;

  bool get useExternalBrowser => _settingData!.useExternalBrowser ?? true;

  bool? get videoPreview => _settingData!.videoPreview ?? true;

  bool? get imagePreview => _settingData!.imagePreview ?? true;

  bool? get gossip => _settingData!.gossip ?? false;

  bool get useCompactReplies => _settingData!.useCompactReplies;

  int? get themeColor => _settingData!.themeColor;

  int get followeesRelayMinCount =>
      _settingData!.followeesRelayMinCount ?? DEFAULT_FOLLOWEES_RELAY_MIN_COUNT;

  int get broadcastToInboxMaxCount =>
      _settingData!.broadcastToInboxMaxCount ??
      DEFAULT_BROADCAST_TO_INBOX_MAX_COUNT;

  final Map<String, String> _keyMap = {};

  final Map<String, bool> _keyIsPrivateMap = {};

  final Map<String, bool> _keyIsExternalSignerMap = {};

  final Map<String, ExternalKeyType> _externalKeysType = {};

  String? get key {
    if (_settingData!.privateKeyIndex != null && _keyMap.isNotEmpty) {
      return _keyMap[_settingData!.privateKeyIndex.toString()];
    }
    return null;
  }

  bool get isExternalSignerKey {
    return _keyIsExternalSignerMap[_settingData!.privateKeyIndex.toString()] ??
        false;
  }

  bool get isExternalSignerAmber {
    final type = _externalKeysType[_settingData!.privateKeyIndex.toString()];

    if (type == null) {
      return true;
    } else {
      return type == ExternalKeyType.Amber;
    }
  }

  bool isExternalSignerKeyIndex(int index) {
    return _keyIsExternalSignerMap[index.toString()] ?? false;
  }

  bool isExternalAmber(int index) {
    return _externalKeysType[index.toString()] == ExternalKeyType.Amber;
  }

  bool get isPrivateKey {
    return _keyIsPrivateMap[_settingData!.privateKeyIndex.toString()] ?? false;
  }

  bool isPrivateKeyIndex(int index) {
    return _keyIsPrivateMap[index.toString()] ?? false;
  }

  String? getSecretKey(String pubkey) {
    try {
      final keys = _keyMap.values;
      for (final k in keys) {
        final pk = Keychain.getPublicKey(k);
        if (pubkey == pk) {
          return k;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    final settingStr = localDatabaseRepository.getSettings();
    // await checkForUpdates();

    if (StringUtil.isNotBlank(settingStr)) {
      final jsonMap = json.decode(settingStr!);
      if (jsonMap != null) {
        final setting = SettingData.fromJson(jsonMap);
        _settingData = setting;
        _keyMap.clear();

        final data = await Future.wait([
          localDatabaseRepository.getKeysMap(),
          localDatabaseRepository.getKeysPrivacyStatus(),
          localDatabaseRepository.getKeysExternalStatus(),
          localDatabaseRepository.getExternalKeysType(),
        ]);

        final String? keyMapJson = data[0];

        final String? keyIsPrivateMapJson = data[1];

        final String? keyIsExternalSignerMapJson = data[2];

        final String? externalKeysTypeMapJson = data[3];

        if (StringUtil.isNotBlank(keyMapJson)) {
          try {
            final jsonKeyMap = jsonDecode(keyMapJson!);
            final isPrivateJsonKeyMap = keyIsPrivateMapJson != null
                ? jsonDecode(keyIsPrivateMapJson)
                : null;
            final isExternalJsonKeyMap = keyIsExternalSignerMapJson != null
                ? jsonDecode(keyIsExternalSignerMapJson)
                : null;
            final externalKeysTypeJsonKeyMap = externalKeysTypeMapJson != null
                ? jsonDecode(externalKeysTypeMapJson)
                : null;

            if (jsonKeyMap != null) {
              for (final entry
                  in (jsonKeyMap as Map<String, dynamic>).entries) {
                _keyMap[entry.key] = entry.value;

                _keyIsPrivateMap[entry.key] = isPrivateJsonKeyMap != null &&
                    isPrivateJsonKeyMap[entry.key];

                _keyIsExternalSignerMap[entry.key] =
                    isExternalJsonKeyMap != null &&
                        isExternalJsonKeyMap[entry.key];

                final isExternal = _keyIsExternalSignerMap[entry.key] ?? false;

                if (isExternal) {
                  final val = externalKeysTypeJsonKeyMap?[entry.key];

                  _externalKeysType[entry.key] =
                      ExternalKeyType.values.firstWhere(
                    (element) => element.name == val,
                    orElse: () => ExternalKeyType.Amber,
                  );
                }
              }
            }
          } catch (e) {
            log('secureStorage reading key KEYS_MAP jsonDecode error');
            log(e.toString());
          }
        }
        if (!isClosed) {
          emit(
            state.copyWith(
              externalKeys: _keyIsExternalSignerMap,
              keyMap: _keyMap,
              externalKeysType: _externalKeysType,
              privateKeys: _keyIsPrivateMap,
              settingsData: _settingData,
              refreshSettingData: !state.refreshSettingData,
            ),
          );
        }

        return;
      }
    }

    _settingData = SettingData();
  }

  // Future<void> checkForUpdates() async {
  //   final status = await updater.checkForUpdate();

  //   if (status == UpdateStatus.outdated) {
  //     try {
  //       await updater.update();
  //     } catch (error) {
  //       lg.i(error);
  //       return;
  //     }
  //   }
  // }

  Future<void> doLogin() async {
    BotToastUtils.showSuccess(
      t.loggingIn.capitalizeFirst(),
    );

    final c = BotToastUtils.showLoading();

    final String? key = this.key;
    final bool isPrivate = isPrivateKey;
    final String publicKey = isPrivate ? getPublicKey(key!) : key!;

    currentSigner = isExternalSignerKey
        ? isExternalSignerAmber
            ? AmberEventSigner(publicKey)
            : nostrRepository.remoteSigners[publicKey]
        : Bip340EventSigner(isPrivate ? key : null, publicKey);
    nc.setSigner(currentSigner);
    currentUserRelayList.pubkey = currentSigner!.getPublicKey();

    try {
      nostrRepository.setCurrentAppCustomizationFromCache(broadcast: true);
      nostrRepository.setCurrentUserDraft();
      AppInitializer.initRelays();
    } catch (e) {
      lg.i(e);
    }

    if (currentSigner?.canSign() ?? false) {
      pointsManagementCubit.login(
        onSuccess: () {},
      );

      nostrRepository.loadCurrentUserRelatedData();
    }

    appSettingsManagerCubit.loadAppSharedSettings();
    relayInfoCubit.initRelays();

    saveAndUpdate();
    c.call();
  }

  List<MapEntry<String, String>> getPrivateKeys() {
    return keyMap.entries
        .where(
          (item) => isPrivateKeyIndex(
            int.tryParse(item.key) ?? -1,
          ),
        )
        .toList();
  }

  Future<void> onLoginTap(int index, Function() onPop) async {
    if (privateKeyIndex != index) {
      BotToastUtils.showSuccess(
        t.loggingOut.capitalizeFirst(),
      );

      final c = BotToastUtils.showLoading();
      await nostrRepository.clearData();

      currentSigner = null;
      nc.setSigner(currentSigner);
      nostrRepository.setCurrentSignerState(null);
      privateKeyIndex = index;

      c.call();

      if (key != null) {
        doLogin();
        walletManagerCubit.switchWallets();
        cashuWalletManagerCubit.init();
        onPop.call();
      }

      appSettingsManagerCubit.loadAppSharedSettings();
      relayInfoCubit.initRelays();
    }
  }

  Future<void> onLogoutTap(
    int index, {
    bool routerBack = true,
    required Function() onPop,
  }) async {
    final oldIndex = privateKeyIndex;
    removeKey(index);

    if (oldIndex == index) {
      await nostrRepository.clearData();

      if (keyMap.isNotEmpty) {
        privateKeyIndex = int.tryParse(keyMap.keys.first);
        if (key != null) {
          doLogin();
          walletManagerCubit.switchWallets();
          cashuWalletManagerCubit.init();
        }
      } else {
        currentSigner = null;
        nc.setSigner(currentSigner);
        nostrRepository.setCurrentSignerState(null);
        appSettingsManagerCubit.loadAppSharedSettings();
        relayInfoCubit.initRelays();
      }
    }

    saveAndUpdate();

    if (routerBack) {
      onPop.call();
    }
  }

  Future<void> onAllLogout() async {
    BotToastUtils.showWarning(
      t.disconnecting.capitalizeFirst(),
    );
    final c = BotToastUtils.showLoading();

    localDatabaseRepository.setKeysMap(json.encode({}));
    privateKeyIndex = null;
    _keyIsExternalSignerMap.clear();
    _externalKeysType.clear();
    _keyIsPrivateMap.clear();
    _keyMap.clear();
    _settingData!.privateKeyIndex = null;

    await nostrRepository.clearData();

    currentSigner = null;
    nc.setSigner(currentSigner);
    nostrRepository.setCurrentSignerState(null);
    nostrRepository.setCurrentAppCustomizationFromCache(broadcast: true);
    nostrRepository.setCurrentUserDraft();
    appSettingsManagerCubit.loadAppSharedSettings();
    relayInfoCubit.initRelays();
    c.call();
    saveAndUpdate();
  }

  Future<int> addAndChangeKey(
    String key,
    bool isPrivate,
    bool isExternalSigner, {
    bool fetchData = false,
    ExternalKeyType externalKeyType = ExternalKeyType.Bunker,
    RemoteEventSigner? remoteSigner,
  }) async {
    int? findIndex;

    final entries = _keyMap.entries;

    for (final entry in entries) {
      if (entry.value == key) {
        findIndex = int.tryParse(entry.key);
        break;
      }
    }

    if (findIndex != null) {
      privateKeyIndex = findIndex;
      return findIndex;
    }

    await nostrRepository.clearData();

    for (var i = 0; i < 20; i++) {
      final index = i.toString();
      final pk = _keyMap[index];

      if (pk == null) {
        _keyMap[index] = key;
        _keyIsPrivateMap[index] = isPrivate;
        _keyIsExternalSignerMap[index] = isExternalSigner;
        if (isExternalSigner) {
          _externalKeysType[index] = externalKeyType;
        }

        _settingData!.privateKeyIndex = i;

        await localDatabaseRepository.setKeysMap(json.encode(_keyMap));

        await localDatabaseRepository.setKeysPrivacyStatus(
          json.encode(_keyIsPrivateMap),
        );

        await localDatabaseRepository.setKeysExternalStatus(
          json.encode(_keyIsExternalSignerMap),
        );

        final converted = _externalKeysType.map(
          (key, value) => MapEntry(key, value.name),
        );

        await localDatabaseRepository.setExternalKeysType(
          json.encode(converted),
        );

        saveAndUpdate(updateUI: fetchData);

        final publicKey = isPrivate ? getPublicKey(key) : key;

        currentSigner = isExternalSignerKey
            ? externalKeyType == ExternalKeyType.Bunker
                ? remoteSigner
                : AmberEventSigner(publicKey)
            : Bip340EventSigner(
                isPrivate ? key : null,
                publicKey,
              );

        if (currentSigner is RemoteEventSigner) {
          nostrRepository.addRemoteSigner(currentSigner! as RemoteEventSigner);
        }

        nc.setSigner(currentSigner);
        nostrRepository.setCurrentSignerState(currentSigner);

        if (fetchData) {
          nostrRepository.loadCurrentUserRelatedData();
          walletManagerCubit.switchWallets();
          cashuWalletManagerCubit.init();
        }

        appSettingsManagerCubit.loadAppSharedSettings();
        relayInfoCubit.initRelays();

        return i;
      }
    }

    return -1;
  }

  void removeKey(int index) {
    final indexStr = index.toString();
    _keyMap.remove(indexStr);

    localDatabaseRepository.setKeysMap(json.encode(_keyMap));

    if (_settingData!.privateKeyIndex == index) {
      if (_keyMap.isEmpty) {
        _settingData!.privateKeyIndex = null;
      } else {
        final keyIndex = _keyMap.keys.first;
        _settingData!.privateKeyIndex = int.tryParse(keyIndex);
      }
    }

    saveAndUpdate();
  }

  set settingData(SettingData o) {
    _settingData = o;
    saveAndUpdate();
  }

  set privateKeyIndex(int? o) {
    _settingData!.privateKeyIndex = o;
    saveAndUpdate();
  }

  set linkPreview(bool o) {
    _settingData!.linkPreview = o;
    saveAndUpdate();
  }

  set useExternalBrowser(bool o) {
    _settingData!.useExternalBrowser = o;
    saveAndUpdate();
  }

  set useCompactReplies(bool o) {
    _settingData!.useCompactReplies = o;
    saveAndUpdate();
  }

  set videoPreview(bool? o) {
    _settingData!.videoPreview = o;
    saveAndUpdate();
  }

  set imageService(String o) {
    _settingData!.imageService = o;
    saveAndUpdate();
  }

  set imagePreview(bool? o) {
    _settingData!.imagePreview = o;
    saveAndUpdate();
  }

  set backgroundService(bool? o) {
    _settingData!.backgroundService = o;
    saveAndUpdate();
    // initBackgroundService(backgroundService);
  }

  set gossip(bool? o) {
    _settingData!.gossip = o;
    saveAndUpdate();
  }

  set followeesRelayMinCount(int? o) {
    _settingData!.followeesRelayMinCount = o;
    saveAndUpdate();
  }

  set broadcastToInboxMaxCount(int? o) {
    _settingData!.broadcastToInboxMaxCount = o;
    saveAndUpdate();
  }

  Future<void> saveAndUpdate({bool updateUI = true}) async {
    _settingData!.updatedTime = DateTime.now().millisecondsSinceEpoch;
    final m = _settingData!.toJson();
    final jsonStr = json.encode(m);
    localDatabaseRepository.setSettings(jsonStr);
    if (!isClosed) {
      emit(
        state.copyWith(
          externalKeys: _keyIsExternalSignerMap,
          externalKeysType: _externalKeysType,
          keyMap: _keyMap,
          privateKeys: _keyIsPrivateMap,
          settingsData: _settingData,
          refreshSettingData: !state.refreshSettingData,
        ),
      );
    }
  }

  //* Apps clients

  Future<void> getAppClient(String client) async {
    try {
      if (client.startsWith(EventKind.APPLICATION_INFO.toString())) {
        final eventCoordinate = Nip33.getEventCoordinates(['a', client, '']);

        if (eventCoordinate != null &&
            state.appClients[eventCoordinate.identifier] != null) {
          return;
        }

        final appClients = Map<String, AppClientModel>.from(state.appClients);

        nc.doQuery(
          [
            Filter(
              kinds: [EventKind.APPLICATION_INFO],
              d: [eventCoordinate!.identifier],
            ),
          ],
          currentUserRelayList.writes,
          eventCallBack: (event, relay) {
            try {
              if (event.kind == EventKind.APPLICATION_INFO) {
                final appClient = AppClientModel.fromEvent(event);
                final oldAppClient = appClients[appClient.identifier];

                if (oldAppClient == null ||
                    oldAppClient.createdAt.compareTo(appClient.createdAt) < 1) {
                  appClients[appClient.identifier] = appClient;
                  if (appClients.isNotEmpty) {
                    if (!isClosed) {
                      emit(
                        state.copyWith(
                          appClients: appClients,
                        ),
                      );
                    }
                  }
                }
              }
            } catch (e, stack) {
              lg.i(stack);
              lg.i(e);
            }
          },
        );
      }
    } catch (e) {
      lg.i(e);
    }
  }

  Future<void> getYakiHonneApp() async {
    final appClients = Map<String, AppClientModel>.from(state.appClients);

    await nc.doQuery(
      [
        Filter(
          kinds: [EventKind.APPLICATION_INFO],
          authors: [yakihonneHex],
        ),
      ],
      currentUserRelayList.writes,
      timeOut: 1,
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.APPLICATION_INFO) {
          final appClient = AppClientModel.fromEvent(event);

          final oldAppClient = appClients[appClient.identifier];

          if (oldAppClient == null ||
              oldAppClient.createdAt.compareTo(appClient.createdAt) < 1) {
            appClients[appClient.identifier] = appClient;
          }
        }
      },
    );

    if (appClients.isNotEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            appClients: appClients,
          ),
        );
      }
    }
  }
}
