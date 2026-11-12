import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bip340/bip340.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/pomegranate/pomegranate.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../initializers.dart';
import '../../models/app_client_model.dart';
import '../../models/app_models/settings_data.dart';
import '../../repositories/account_storage_lock.dart';
import '../../repositories/account_storage_snapshot.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
      {bool? desktopStorageOverride,
      AccountSnapshotStore? accountStore,
      AccountStorageLock? accountStorageLock,
      void Function()? storageErrorHandler})
      : _desktopStorageOverride = desktopStorageOverride,
        _injectedAccountStore = accountStore,
        _injectedAccountStorageLock = accountStorageLock,
        _storageErrorHandler = storageErrorHandler,
        super(
          const SettingsState(
            externalKeys: {},
            keyMap: {},
            privateKeys: {},
            refreshSettingData: false,
            appClients: {},
            externalKeysType: {},
          ),
        );

  final bool? _desktopStorageOverride;
  final AccountSnapshotStore? _injectedAccountStore;
  final AccountStorageLock? _injectedAccountStorageLock;
  final void Function()? _storageErrorHandler;
  bool get _desktopStorage =>
      _desktopStorageOverride ?? (Platform.isWindows || Platform.isLinux);
  late AccountSnapshotStore _desktopStore;
  List<String> _desktopRemoteSigners = [];
  bool _accountMutationInProgress = false;
  bool _accountRestartRequired = false;

  /// Set when startup hit diverged or unreadable account data and the user
  /// must choose a recovery path. No write happens until that choice is made.
  AccountStorageRecoveryRequired? _pendingRecovery;
  AccountStorageRecoveryRequired? get pendingRecovery => _pendingRecovery;

  bool _beginAccountMutation() {
    if (!_desktopStorage) {
      return true;
    }
    if (_accountMutationInProgress ||
        _accountRestartRequired ||
        _pendingRecovery != null) {
      if (_storageErrorHandler != null) {
        _storageErrorHandler!();
      } else {
        BotToastUtils.showError(t.accountStorageSaveFailed, force: true);
      }
      return false;
    }
    _accountMutationInProgress = true;
    return true;
  }

  void _endAccountMutation() {
    if (_desktopStorage) {
      _accountMutationInProgress = false;
    }
  }

  String? get desktopRemoteSigners =>
      _desktopStorage ? jsonEncode(_desktopRemoteSigners) : null;

  Future<void> _initDesktopAccounts(SettingData setting) async {
    final storage = localDatabaseRepository.secureStorage;
    final lock = _injectedAccountStorageLock ??
        await DesktopAccountStorageLockFactory().create();
    final store = _injectedAccountStore ??
        AccountSnapshotStore(
          read: (key) => storage.read(key: key),
          write: (key, value) => storage.write(key: key, value: value),
          delete: (key) => storage.delete(key: key),
          lock: lock,
        );
    final AccountStorageSnapshot snapshot;
    try {
      snapshot = await store.load(legacyActiveIndex: setting.privateKeyIndex);
    } on AccountStorageRecoveryRequired catch (recovery) {
      _pendingRecovery = recovery;
      _desktopStore = store;
      _settingData = setting;
      rethrow;
    }
    _applyDesktopSnapshot(store, setting, snapshot);
    // Cleanup is resumable and never affects the saved snapshot; a failure
    // must not hide working accounts behind the recovery screen.
    try {
      await store.finishMigration();
    } catch (_) {
      // Legacy values stay in place and are checked on the next start.
    }
  }

  void _applyDesktopSnapshot(
    AccountSnapshotStore store,
    SettingData setting,
    AccountStorageSnapshot snapshot,
  ) {
    for (final signer in snapshot.remoteSigners) {
      RemoteEventSigner.fromJson(
        jsonString: signer,
        nc: nc,
        onAuth: (_, __) {},
      );
    }
    final keys = Map<String, String>.from(snapshot.keys);
    final privacy = Map<String, bool>.from(snapshot.privateKeys);
    final external = Map<String, bool>.from(snapshot.externalSigners);
    if (keys.keys
        .any((key) => int.tryParse(key) == null || !privacy.containsKey(key))) {
      throw const FormatException('Incomplete account privacy data');
    }
    final types = <String, ExternalKeyType>{};
    final setups = <String, PomSetup>{};
    for (final entry in snapshot.externalTypes.entries) {
      types[entry.key] = ExternalKeyType.values.firstWhere(
        (value) => value.name == entry.value,
        orElse: () => ExternalKeyType.Amber,
      );
    }
    for (final entry in snapshot.pomegranateSetups.entries) {
      setups[entry.key] = PomSetup.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
    if (snapshot.activeIndex != null &&
        !keys.containsKey(snapshot.activeIndex.toString())) {
      throw const FormatException('Invalid active account');
    }
    _keyMap
      ..clear()
      ..addAll(keys);
    _keyIsPrivateMap
      ..clear()
      ..addAll(privacy);
    _keyIsExternalSignerMap
      ..clear()
      ..addAll(external);
    _externalKeysType
      ..clear()
      ..addAll(types);
    _pomegranateSetups
      ..clear()
      ..addAll(setups);
    _desktopRemoteSigners = snapshot.remoteSigners;
    setting.privateKeyIndex = snapshot.activeIndex;
    _settingData = setting;
    _desktopStore = store;
    _pendingRecovery = null;
  }

  /// Resolves a startup recovery prompt by restoring the retained backup.
  ///
  /// Only valid when startup failed on a corrupt snapshot. The unreadable
  /// primary is quarantined, never deleted.
  Future<void> recoverFromBackup() async {
    final setting = _settingData ?? SettingData();
    final snapshot = await _desktopStore.restoreBackup();
    _applyDesktopSnapshot(_desktopStore, setting, snapshot);
    _accountRestartRequired = false;
  }

  /// Resolves a startup recovery prompt by keeping the saved accounts.
  ///
  /// Only valid when legacy values diverged. The conflicting legacy values are
  /// quarantined, never deleted.
  Future<void> recoverKeepSnapshot() async {
    final setting = _settingData ?? SettingData();
    final active = setting.privateKeyIndex;
    await _desktopStore.keepSnapshot(activeIndex: active);
    final snapshot =
        await _desktopStore.load(legacyActiveIndex: active);
    _applyDesktopSnapshot(_desktopStore, setting, snapshot);
    _accountRestartRequired = false;
  }

  /// Resolves a startup recovery prompt by adopting the legacy values.
  ///
  /// Refuses to replace saved accounts with an empty legacy store; the saved
  /// snapshot is retained as a backup.
  Future<void> recoverKeepLegacy() async {
    final setting = _settingData ?? SettingData();
    final snapshot = await _desktopStore.keepLegacy(
      legacyActiveIndex: setting.privateKeyIndex,
    );
    _applyDesktopSnapshot(_desktopStore, setting, snapshot);
    _accountRestartRequired = false;
  }

  Future<void> _saveDesktopAccounts({
    required Map<String, String> keys,
    required Map<String, bool> privacy,
    required Map<String, bool> external,
    required Map<String, ExternalKeyType> types,
    required Map<String, PomSetup> setups,
    required int? activeIndex,
    required List<String> remoteSigners,
  }) async {
    try {
      await _desktopStore.save(AccountStorageSnapshot(
        keys: keys,
        privateKeys: privacy,
        externalSigners: external,
        externalTypes: types.map((key, value) => MapEntry(key, value.name)),
        pomegranateSetups:
            setups.map((key, value) => MapEntry(key, value.toJson())),
        activeIndex: activeIndex,
        remoteSigners: remoteSigners,
      ));
      // Until the caller applies the saved change, a later mutation must not
      // use the old in-memory maps if an intervening operation throws.
      _accountRestartRequired = true;
    } catch (_) {
      if (_storageErrorHandler != null) {
        _storageErrorHandler!();
      } else {
        BotToastUtils.showError(t.accountStorageSaveFailed, force: true);
      }
      rethrow;
    }
  }

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

  /// index -> the central + operator set that account's key was sharded across.
  ///
  /// Keyed by index like [_externalKeysType]: recovery must use the operators
  /// and threshold the account was actually registered with, which vary per
  /// client and are user-configurable at signup.
  final Map<String, PomSetup> _pomegranateSetups = {};

  /// The active account's Pomegranate setup, or null when unknown — accounts
  /// created before this was persisted, and centrals that omit the fields.
  PomSetup? get pomegranateSetup {
    final index = _settingData?.privateKeyIndex;
    return index == null ? null : _pomegranateSetups[index.toString()];
  }

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

  bool isExternalGoogle(int index) {
    return _externalKeysType[index.toString()] == ExternalKeyType.Google;
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
    if (_desktopStorage) {
      final setting = StringUtil.isNotBlank(settingStr)
          ? SettingData.fromJson(json.decode(settingStr!))
          : SettingData();
      await _initDesktopAccounts(setting);
      if (!isClosed) {
        emit(state.copyWith(
          externalKeys: _keyIsExternalSignerMap,
          keyMap: _keyMap,
          externalKeysType: _externalKeysType,
          privateKeys: _keyIsPrivateMap,
          settingsData: _settingData,
          refreshSettingData: !state.refreshSettingData,
        ));
      }
      return;
    }
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
          localDatabaseRepository.getPomegranateSetups(),
        ]);

        final String? keyMapJson = data[0];

        final String? keyIsPrivateMapJson = data[1];

        final String? keyIsExternalSignerMapJson = data[2];

        final String? externalKeysTypeMapJson = data[3];

        final String? pomegranateSetupsJson = data[4];

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
            final pomegranateSetupsJsonMap = pomegranateSetupsJson != null
                ? jsonDecode(pomegranateSetupsJson)
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

                final setupJson = pomegranateSetupsJsonMap?[entry.key];

                if (setupJson != null) {
                  try {
                    _pomegranateSetups[entry.key] =
                        PomSetup.fromJson(Map<String, dynamic>.from(setupJson));
                  } catch (_) {
                    // A malformed setup only costs recovery its operator list,
                    // which falls back to the known set — not worth losing the
                    // whole key map over.
                  }
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
    packsSettingsCubit.initPacks();

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
    if (!_beginAccountMutation()) {
      return;
    }
    try {
      await _onLoginTap(index, onPop);
      _accountRestartRequired = false;
    } finally {
      _endAccountMutation();
    }
  }

  Future<void> _onLoginTap(int index, Function() onPop) async {
    if (privateKeyIndex != index) {
      if (_desktopStorage) {
        try {
          await _saveDesktopAccounts(
            keys: Map.of(_keyMap),
            privacy: Map.of(_keyIsPrivateMap),
            external: Map.of(_keyIsExternalSignerMap),
            types: Map.of(_externalKeysType),
            setups: Map.of(_pomegranateSetups),
            activeIndex: index,
            remoteSigners: List.of(_desktopRemoteSigners),
          );
        } catch (_) {
          return;
        }
      }
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
      packsSettingsCubit.initPacks();
    }
  }

  Future<void> onLogoutTap(
    int index, {
    bool routerBack = true,
    required Function() onPop,
  }) async {
    if (!_beginAccountMutation()) {
      return;
    }
    try {
      await _onLogoutTap(index, routerBack: routerBack, onPop: onPop);
      _accountRestartRequired = false;
    } finally {
      _endAccountMutation();
    }
  }

  Future<void> _onLogoutTap(
    int index, {
    required bool routerBack,
    required Function() onPop,
  }) async {
    final oldIndex = privateKeyIndex;
    if (_desktopStorage) {
      final indexStr = index.toString();
      final keys = Map<String, String>.of(_keyMap)..remove(indexStr);
      final privacy = Map<String, bool>.of(_keyIsPrivateMap)..remove(indexStr);
      final external = Map<String, bool>.of(_keyIsExternalSignerMap)
        ..remove(indexStr);
      final types = Map<String, ExternalKeyType>.of(_externalKeysType)
        ..remove(indexStr);
      final setups = Map<String, PomSetup>.of(_pomegranateSetups)
        ..remove(indexStr);
      final removedKey = _keyMap[indexStr];
      final removeSigner = removedKey != null &&
          (_keyIsExternalSignerMap[indexStr] ?? false) &&
          !keys.containsValue(removedKey);
      final remote = removeSigner
          ? _desktopRemoteSigners.where((signer) {
              final decoded = jsonDecode(signer) as Map<String, dynamic>;
              return decoded['publicKey'] != removedKey;
            }).toList()
          : List<String>.of(_desktopRemoteSigners);
      final active = oldIndex == index
          ? (keys.isEmpty ? null : int.tryParse(keys.keys.first))
          : oldIndex;
      try {
        await _saveDesktopAccounts(
            keys: keys,
            privacy: privacy,
            external: external,
            types: types,
            setups: setups,
            activeIndex: active,
            remoteSigners: remote);
      } catch (_) {
        return;
      }
      _desktopRemoteSigners = remote;
      if (removeSigner) {
        final signer = nostrRepository.remoteSigners.remove(removedKey);
        if (signer != null) {
          await signer.close();
        }
      }
    }
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
        packsSettingsCubit.initPacks();
      }
    }

    saveAndUpdate();

    if (routerBack) {
      onPop.call();
    }
  }

  Future<bool> onAllLogout() async {
    if (!_beginAccountMutation()) {
      return false;
    }
    try {
      final result = await _onAllLogout();
      _accountRestartRequired = false;
      return result;
    } finally {
      _endAccountMutation();
    }
  }

  Future<bool> _onAllLogout() async {
    if (_desktopStorage) {
      try {
        await _saveDesktopAccounts(
            keys: {},
            privacy: {},
            external: {},
            types: {},
            setups: {},
            activeIndex: null,
            remoteSigners: []);
      } catch (_) {
        return false;
      }
      _desktopRemoteSigners = [];
      for (final signer in nostrRepository.remoteSigners.values) {
        await signer.close();
      }
      nostrRepository.remoteSigners.clear();
    }
    BotToastUtils.showWarning(
      t.disconnecting.capitalizeFirst(),
    );
    final c = BotToastUtils.showLoading();

    if (!_desktopStorage) {
      localDatabaseRepository.setKeysMap(json.encode({}));
      localDatabaseRepository.setPomegranateSetups(json.encode({}));
    }
    privateKeyIndex = null;
    _keyIsExternalSignerMap.clear();
    _externalKeysType.clear();
    _pomegranateSetups.clear();
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
    packsSettingsCubit.initPacks();
    c.call();
    saveAndUpdate();
    return true;
  }

  Future<int> addAndChangeKey(
    String key,
    bool isPrivate,
    bool isExternalSigner, {
    bool fetchData = false,
    ExternalKeyType externalKeyType = ExternalKeyType.Bunker,
    RemoteEventSigner? remoteSigner,
    PomSetup? pomegranateSetup,
  }) async {
    if (!_beginAccountMutation()) {
      throw StateError('Account change already in progress');
    }
    try {
      final result = await _addAndChangeKey(
        key,
        isPrivate,
        isExternalSigner,
        fetchData: fetchData,
        externalKeyType: externalKeyType,
        remoteSigner: remoteSigner,
        pomegranateSetup: pomegranateSetup,
      );
      _accountRestartRequired = false;
      return result;
    } finally {
      _endAccountMutation();
    }
  }

  Future<int> _addAndChangeKey(
    String key,
    bool isPrivate,
    bool isExternalSigner, {
    required bool fetchData,
    required ExternalKeyType externalKeyType,
    RemoteEventSigner? remoteSigner,
    PomSetup? pomegranateSetup,
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
      if (_desktopStorage) {
        await _saveDesktopAccounts(
            keys: Map.of(_keyMap),
            privacy: Map.of(_keyIsPrivateMap),
            external: Map.of(_keyIsExternalSignerMap),
            types: Map.of(_externalKeysType),
            setups: Map.of(_pomegranateSetups),
            activeIndex: findIndex,
            remoteSigners: List.of(_desktopRemoteSigners));
      }
      privateKeyIndex = findIndex;
      return findIndex;
    }

    if (!_desktopStorage) {
      await nostrRepository.clearData();
    }

    for (var i = 0; i < 20; i++) {
      final index = i.toString();
      final pk = _keyMap[index];

      if (pk == null) {
        if (_desktopStorage) {
          final keys = Map<String, String>.of(_keyMap)..[index] = key;
          final privacy = Map<String, bool>.of(_keyIsPrivateMap)
            ..[index] = isPrivate;
          final external = Map<String, bool>.of(_keyIsExternalSignerMap)
            ..[index] = isExternalSigner;
          final types = Map<String, ExternalKeyType>.of(_externalKeysType);
          final setups = Map<String, PomSetup>.of(_pomegranateSetups);
          types.remove(index);
          setups.remove(index);
          if (isExternalSigner) {
            types[index] = externalKeyType;
          }
          if (externalKeyType == ExternalKeyType.Google &&
              pomegranateSetup != null) {
            setups[index] = pomegranateSetup;
          }
          final remote = <String>[
            ...nostrRepository.remoteSigners.values
                .where((signer) => signer.publicKey != remoteSigner?.publicKey)
                .map((signer) => signer.toJson()),
            if (remoteSigner != null) remoteSigner.toJson(),
          ];
          await _saveDesktopAccounts(
              keys: keys,
              privacy: privacy,
              external: external,
              types: types,
              setups: setups,
              activeIndex: i,
              remoteSigners: remote);
          _desktopRemoteSigners = remote;
          await nostrRepository.clearData();
        }
        _keyMap[index] = key;
        _keyIsPrivateMap[index] = isPrivate;
        _keyIsExternalSignerMap[index] = isExternalSigner;
        if (_desktopStorage) {
          _externalKeysType.remove(index);
          _pomegranateSetups.remove(index);
        }
        if (isExternalSigner) {
          _externalKeysType[index] = externalKeyType;
        }

        // Only Google keys have one, and only when the central reported its
        // operator set — never guess, a wrong set makes recovery impossible.
        if (externalKeyType == ExternalKeyType.Google &&
            pomegranateSetup != null) {
          _pomegranateSetups[index] = pomegranateSetup;
        }

        _settingData!.privateKeyIndex = i;

        if (!_desktopStorage) {
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

          await localDatabaseRepository.setPomegranateSetups(
            json.encode(
              _pomegranateSetups.map(
                (key, value) => MapEntry(key, value.toJson()),
              ),
            ),
          );
        }

        saveAndUpdate(updateUI: fetchData);

        final publicKey = isPrivate ? getPublicKey(key) : key;

        currentSigner = isExternalSignerKey
            ? (externalKeyType == ExternalKeyType.Bunker ||
                    externalKeyType == ExternalKeyType.Google)
                ? remoteSigner
                : AmberEventSigner(publicKey)
            : Bip340EventSigner(
                isPrivate ? key : null,
                publicKey,
              );

        if (currentSigner is RemoteEventSigner && !_desktopStorage) {
          nostrRepository.addRemoteSigner(currentSigner! as RemoteEventSigner);
        } else if (currentSigner is RemoteEventSigner) {
          final signer = currentSigner! as RemoteEventSigner;
          nostrRepository.remoteSigners[signer.publicKey] = signer;
        }

        nc.setSigner(currentSigner);
        nostrRepository.setCurrentSignerState(currentSigner);

        if (fetchData) {
          nostrRepository.loadCurrentUserRelatedData();
          walletManagerCubit.switchWallets();
          cashuWalletManagerCubit.init();
          if (currentSigner?.canSign() ?? false) {
            pointsManagementCubit.login(onSuccess: () {});
          }
        }

        appSettingsManagerCubit.loadAppSharedSettings();
        relayInfoCubit.initRelays();
        packsSettingsCubit.initPacks();

        return i;
      }
    }

    return -1;
  }

  void removeKey(int index) {
    final indexStr = index.toString();
    _keyMap.remove(indexStr);
    _pomegranateSetups.remove(indexStr);

    // Indexes are reused by `addAndChangeKey`, so a left-behind flag makes the
    // next key at this index inherit the old one's signer type — a plain nsec
    // account showing the Google recover/unlink rows, for instance.
    _keyIsExternalSignerMap.remove(indexStr);
    _externalKeysType.remove(indexStr);
    _keyIsPrivateMap.remove(indexStr);

    if (!_desktopStorage) {
      localDatabaseRepository.setKeysMap(json.encode(_keyMap));

      localDatabaseRepository
          .setKeysPrivacyStatus(json.encode(_keyIsPrivateMap));

      localDatabaseRepository.setKeysExternalStatus(
        json.encode(_keyIsExternalSignerMap),
      );

      localDatabaseRepository.setExternalKeysType(
        json.encode(_externalKeysType.map((k, v) => MapEntry(k, v.name))),
      );

      localDatabaseRepository.setPomegranateSetups(
        json.encode(
          _pomegranateSetups.map((key, value) => MapEntry(key, value.toJson())),
        ),
      );
    }

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

        NostrFunctionsRepository.queryEvents(
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

    await NostrFunctionsRepository.queryEvents(
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
