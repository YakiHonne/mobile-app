// ignore_for_file: non_constant_identifier_names, pattern_never_matches_value_type

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/theme_cubit/theme_cubit.dart';
import '../models/filter_status.dart';
import '../models/media_manager_data.dart';
import '../models/relays_list.dart';
import '../models/topic.dart';
import '../models/wot_configuration.dart';
import '../utils/topics.dart';
import '../utils/utils.dart';

late SharedPreferences prefs;

// ==================================================
// LOCAL DATABASE REPOSITORY
// ==================================================

class LocalDatabaseRepository {
  LocalDatabaseRepository() {
    _initializeSecureStorage();
  }

  late FlutterSecureStorage secureStorage;

  // ==================================================
  // STORAGE KEYS - Organized by Category
  // ==================================================

  // Authentication & Security
  static const String _keysMap = 'private_keys_map';
  static const String _isPrivateMap = 'keys_is_private_map';
  static const String _isExternalSignerMap = 'keys_is_external_map';
  static const String _externalKeysType = 'external_keys_map';
  static const String _remoteSigners = 'remote_signers_map';
  static const String _appWallets = 'global_app_wallets';
  static const String _selectedWalletId = 'selected_wallet_id';
  static const String _defaultWallet = 'default_wallet';
  static const String _useDefaultWallet = 'use_default_wallet';
  static const String _allowAutomaticSigning = 'allow_automatic_signing';
  static const String _activeCurrency = 'active_currency';

  // App Settings & Configuration
  static const String _settings = 'settings';
  static const String _appCustomization = 'keys_is_external_map';
  static const String _appLanguage = 'app_language';
  static const String _appTheme = 'app_theme';
  static const String _appMainColor = 'app_main_color';
  static const String _textScaleFactor = 'text_scale_factor';
  static const String _crashlyticsData = 'collect_data';

  // User Interface & Experience
  static const String _onboarding = 'onBoarding';
  static const String _showDisclosure = 'show_disclosure';
  static const String _notificationPrompter = 'notification_prompter';
  static const String _showNewSettingPopup = 'show_new_setting_popup';
  static const String _showCachePopup = 'show_cache_popup';
  static const String _versionNews = 'version_news';
  static const String _pointsSystem = 'points_system';

  // Content & Communication
  static const String _topics = 'topics';
  static const String _topicsStatus = 'topics_status';
  static const String _localMute = 'local_mute';
  static const String _relays = 'relays';
  static const String _messagingNip = 'messaging_nip';
  static const String _dmsDrafts = 'dms_drafts';
  static const String _loadLocalRemoteSignerDm = 'load_local_remote_signer_dm';
  static const String _giftWrapNewestDateTime = 'gift_wrap_newest_date_time';
  static const String _dmHistoryOldestUntil = 'dm_history_older_until';
  static const String _unsentEvents = 'unsent_events';
  static const String _unsentEventsPubkeys = 'unsent_events_pubkeys';

  // Features & Services
  static const String _translationServices = 'translation_services';
  static const String _mediaManager = 'media_manager';
  static const String _wotConfigurations = 'wot_configurations';
  static const String _filterStatus = 'filter_status';
  static const String _defaultZapAmounts = 'default_zap_amounts';
  static const String _defaultReaction = 'default_reaction';
  static const String _enableOneTapZap = 'enable_one_tap_zap';
  static const String _enableOneTapReaction = 'enable_one_tap_reaction';
  static const String _automaticCachePurge = 'automatic_cache_purge';

  // Notifications & Flash News
  static const String _pendingFlashNews = 'pending_flash_news';
  static const String _newNotifications = 'new_notifications';
  static const String _registeredNotifications = 'registred_notifications';

  // ==================================================
  // INITIALIZATION
  // ==================================================

  void _initializeSecureStorage() {
    secureStorage = FlutterSecureStorage(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }

  IOSOptions _getIOSOptions() => const IOSOptions(
        accountName: 'yakihonne',
        accessibility: KeychainAccessibility.first_unlock,
      );

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

  // ==================================================
  // HELPER METHODS
  // ==================================================

  Future<T?> _getSecureData<T>(String key) async {
    try {
      return await secureStorage.read(key: key) as T?;
    } catch (e) {
      lg.i('Error reading secure data for key $key: $e');
      return null;
    }
  }

  Future<void> _setSecureData(String key, String value) async {
    try {
      await secureStorage.write(key: key, value: value);
    } catch (e) {
      lg.i('Error writing secure data for key $key: $e');
    }
  }

  T? _getPrefsData<T>(String key, {T? defaultValue}) {
    try {
      switch (T) {
        case const (String):
          return prefs.getString(key) as T? ?? defaultValue;
        case const (bool):
          return prefs.getBool(key) as T? ?? defaultValue;
        case const (int):
          return prefs.getInt(key) as T? ?? defaultValue;
        case const (double):
          return prefs.getDouble(key) as T? ?? defaultValue;
        case const (List<String>):
          return prefs.getStringList(key) as T? ?? defaultValue;
        default:
          return prefs.get(key) as T? ?? defaultValue;
      }
    } catch (e) {
      lg.i('Error reading prefs data for key $key: $e');
      return defaultValue;
    }
  }

  Future<bool> _setPrefsData<T>(String key, T value) async {
    try {
      switch (value.runtimeType) {
        case const (String):
          return await prefs.setString(key, value as String);
        case const (bool):
          return await prefs.setBool(key, value as bool);
        case const (int):
          return await prefs.setInt(key, value as int);
        case const (double):
          return await prefs.setDouble(key, value as double);
        case const (List<String>):
          return await prefs.setStringList(key, value as List<String>);
        default:
          lg.i('Unsupported type for key $key');
          return false;
      }
    } catch (e) {
      lg.i('Error writing prefs data for key $key: $e');
      return false;
    }
  }

  // ==================================================
  // AUTHENTICATION & SECURITY METHODS
  // ==================================================

  /// Keys Management
  Future<String?> getKeysMap() async {
    return _getSecureData<String>(_keysMap);
  }

  Future<void> setKeysMap(String keyMap) async {
    await _setSecureData(_keysMap, keyMap);
  }

  Future<String?> getKeysPrivacyStatus() async {
    return _getSecureData<String>(_isPrivateMap);
  }

  Future<void> setKeysPrivacyStatus(String keysPrivacyMap) async {
    await _setSecureData(_isPrivateMap, keysPrivacyMap);
  }

  Future<String?> getKeysExternalStatus() async {
    return _getSecureData<String>(_isExternalSignerMap);
  }

  Future<void> setKeysExternalStatus(String keysExternalMap) async {
    await _setSecureData(_isExternalSignerMap, keysExternalMap);
  }

  Future<String?> getExternalKeysType() async {
    return _getSecureData<String>(_externalKeysType);
  }

  Future<void> setExternalKeysType(String keysExternalMap) async {
    await _setSecureData(_externalKeysType, keysExternalMap);
  }

  Future<String?> getRemoteSigners() async {
    return _getSecureData<String>(_remoteSigners);
  }

  Future<void> setRemoteSigners(String keysExternalMap) async {
    await _setSecureData(_remoteSigners, keysExternalMap);
  }

  /// Wallet Management
  Future<void> setUserWallets(String wallets) async {
    await _setSecureData(_appWallets, wallets);
  }

  Future<String> getWallets() async {
    return await _getSecureData<String>(_appWallets) ?? '';
  }

  Future<void> setSelectedWalletId(String walletId) async {
    await _setPrefsData(_selectedWalletId, walletId);
  }

  String getSelectedWalletId() {
    return _getPrefsData<String>(_selectedWalletId, defaultValue: '') ?? '';
  }

  Future<void> setUseDefaultWallet(bool useDefaultWallet) async {
    await _setPrefsData(_useDefaultWallet, useDefaultWallet);
  }

  Future<bool> getUseDefaultWallet() async {
    final useWallet = _getPrefsData<bool>(_useDefaultWallet);
    if (useWallet == null) {
      await setUseDefaultWallet(false);
      return false;
    }
    return useWallet;
  }

  Future<void> setDefaultWallet(String wallet) async {
    await _setPrefsData(_defaultWallet, wallet);
  }

  Future<String> getDefaultWallet() async {
    final wallet = _getPrefsData<String>(_defaultWallet);
    if (wallet == null || wallet.isEmpty) {
      await setDefaultWallet(defaultExternalWallet);
      return defaultExternalWallet;
    }
    return wallet;
  }

  Future<void> setActiveCurrency(String currency) async {
    await _setPrefsData(_activeCurrency, currency);
  }

  String getActiveCurrency() {
    return _getPrefsData<String>(_activeCurrency, defaultValue: 'usd') ?? 'usd';
  }

  /// Signing Configuration
  Future<void> setAutomaticSigning(bool enable) async {
    await _setPrefsData(_allowAutomaticSigning, enable);
  }

  bool getAutomaticSigning() {
    return _getPrefsData<bool>(_allowAutomaticSigning, defaultValue: true) ??
        false;
  }

  // ==================================================
  // APP SETTINGS & CONFIGURATION
  // ==================================================

  /// General Settings
  String? getSettings() {
    return _getPrefsData<String>(_settings);
  }

  Future<void> setSettings(String settings) async {
    await _setPrefsData(_settings, settings);
  }

  /// App Customization
  Map<String, String> getAppCustomization() {
    final data = _getPrefsData<String>(_appCustomization);
    if (data == null) {
      setAppCustomization({});
      return <String, String>{};
    }
    try {
      return Map<String, String>.from(jsonDecode(data));
    } catch (e) {
      lg.i('Error parsing app customization: $e');
      return <String, String>{};
    }
  }

  Future<void> setAppCustomization(Map<String, String> appCustomization) async {
    await _setPrefsData(_appCustomization, jsonEncode(appCustomization));
  }

  /// Language Configuration
  Future<void> setLanguage({required String language}) async {
    await _setPrefsData(_appLanguage, language);
  }

  Future<void> deleteLanguage() async {
    await prefs.remove(_appLanguage);
  }

  Future<String?> getLanguage() async {
    return _getPrefsData<String>(_appLanguage);
  }

  /// Text Scale Factor
  AppThemeMode getAppThemeMode() {
    final theme = _getPrefsData<String>(_appTheme);

    return AppThemeMode.values.firstWhere(
      (e) => e.name == theme,
      orElse: () => AppThemeMode.graphite,
    );
  }

  void setAppThemeMode(AppThemeMode mode) {
    _setPrefsData(_appTheme, mode.name);
  }

  /// Text Scale Factor
  Color? getAppMainColor() {
    final theme = _getPrefsData<String>(_appMainColor);

    return theme != null ? Color(int.parse(theme, radix: 16)) : null;
  }

  void setAppMainColor(Color color) {
    _setPrefsData(_appMainColor, color.toARGB32().toRadixString(16));
  }

  /// Text Scale Factor
  double getTextScaleFactor() {
    final textScaleFactor = _getPrefsData<double>(_textScaleFactor);
    if (textScaleFactor != null) {
      return textScaleFactor;
    }
    setTextScaleFactor(1.0);
    return 1.0;
  }

  void setTextScaleFactor(double textScaleFactor) {
    _setPrefsData(_textScaleFactor, textScaleFactor);
  }

  /// Analytics and Cache Configuration
  Future<void> setAutomaticCachePurge(bool enable) async {
    await _setPrefsData(_automaticCachePurge, enable);
  }

  bool getAutomaticCachePurge() {
    return _getPrefsData<bool>(_automaticCachePurge, defaultValue: false) ??
        false;
  }

  bool getCrashlyticsDataCollection() {
    final isAvailable = _getPrefsData<bool>(_crashlyticsData);
    if (isAvailable != null) {
      return isAvailable;
    }
    setAnalyticsDataCollection(true);
    return true;
  }

  void setAnalyticsDataCollection(bool analytics) {
    _setPrefsData(_crashlyticsData, analytics);
  }

  // ==================================================
  // USER INTERFACE & EXPERIENCE
  // ==================================================

  /// Onboarding Status
  Future<bool> getOnboardingStatus() async {
    final isAvailable = _getPrefsData(_onboarding);
    if (isAvailable != null) {
      return false;
    }
    await _setPrefsData(_onboarding, true);
    return true;
  }

  /// Points System Status
  bool getPointsSystemStatus() {
    final isAvailable = _getPrefsData(_pointsSystem);
    if (isAvailable != null) {
      return false;
    }
    _setPrefsData(_pointsSystem, true);
    return true;
  }

  /// Disclosure Status
  Future<bool> getDisclosureStatus() async {
    final isAvailable = _getPrefsData(_showDisclosure);
    if (isAvailable != null) {
      return false;
    }
    await _setPrefsData(_showDisclosure, true);
    return true;
  }

  /// Notification Prompter
  bool? getNotificationPrompter() {
    final isAvailable = _getPrefsData<bool>(_notificationPrompter);
    if (isAvailable != null) {
      return isAvailable;
    }
    _setPrefsData(_notificationPrompter, true);
    return null;
  }

  Future<void> removeNotificationPrompter() async {
    await prefs.remove(_notificationPrompter);
  }

  /// Popup Controls
  bool getNewSettingPopup() {
    final data = _getPrefsData<bool>(_showNewSettingPopup);
    if (data == null) {
      setNewSettingPopup(false);
      return true;
    }
    return data;
  }

  Future<void> setNewSettingPopup(bool enable) async {
    await _setPrefsData(_showNewSettingPopup, enable);
  }

  bool getCachePopup() {
    return _getPrefsData<bool>(_showCachePopup, defaultValue: true) ?? true;
  }

  Future<void> setCachePopup(bool enable) async {
    await _setPrefsData(_showCachePopup, enable);
  }

  /// Version News
  bool canDisplayVersionNews(String version) {
    final currentVersion = _getPrefsData<String>(_versionNews);
    _setPrefsData(_versionNews, version);
    return version != currentVersion;
  }

  // ==================================================
  // CONTENT & COMMUNICATION
  // ==================================================

  /// Topics Management
  Future<String> getTopics() async {
    final topics = _getPrefsData<String>(_topics);
    if (topics != null) {
      return topics;
    }

    final topicsList = topicsToJson(topicsFromMaps(topicsDefaultList));
    await _setPrefsData(_topics, topicsList);
    return topicsList;
  }

  Future<void> setTopics(List<Topic> topics) async {
    await _setPrefsData(_topics, topicsToJson(topics));
  }

  Future<bool> getTopicsStatus() async {
    final isAvailable = _getPrefsData(_topicsStatus);
    if (isAvailable != null) {
      return false;
    }
    await _setPrefsData(_topicsStatus, true);
    return true;
  }

  Future<void> removeTopicsStatus() async {
    await prefs.remove(_topicsStatus);
  }

  /// Local Mutes
  void setLocalMutes(List<String> localMutes) {
    _setPrefsData(_localMute, localMutes);
  }

  List<String> getLocalMutes() {
    return _getPrefsData<List<String>>(_localMute, defaultValue: <String>[]) ??
        <String>[];
  }

  /// Relays Management
  void registerRelays(Relays relays) {
    _setPrefsData('$_relays-${relays.pubKey}', relays.relays);
  }

  Future<List<String>?> getRelays(String pubkey) async {
    return _getPrefsData<List<String>>('$_relays-$pubkey');
  }

  /// Unsent events
  Future<void> setUnsentEvents(List<String> unsentEvents) async {
    await _setPrefsData(_unsentEvents, unsentEvents);
  }

  Future<void> removeUnsentEvents() async {
    await prefs.remove(_unsentEvents);
  }

  Future<List<String>> getUnsentEvents() async {
    return _getPrefsData<List<String>>(_unsentEvents) ?? <String>[];
  }

  /// Unsent events pubkeys
  Future<void> setUnsentEventsPubkeys(
    Map<String, String> unsentEventsPubkeys,
  ) async {
    await _setPrefsData(_unsentEventsPubkeys, jsonEncode(unsentEventsPubkeys));
  }

  Future<void> removeUnsentEventsPubkeys() async {
    await prefs.remove(_unsentEventsPubkeys);
  }

  Future<Map<String, String>> getUnsentEventsPubkeys() async {
    try {
      final data = _getPrefsData<String>(_unsentEventsPubkeys) ?? '';

      if (data.isNotEmpty) {
        return Map<String, String>.from(jsonDecode(data));
      }
      return <String, String>{};
    } catch (e) {
      return {};
    }
  }

  /// DM Drafts
  Future<void> setDmsDrafts({
    required Map<String, Map<String, String>> drafts,
  }) async {
    final encode = jsonEncode(drafts);
    await _setPrefsData(_dmsDrafts, encode);
  }

  Future<void> deleteDmsDrafts() async {
    await prefs.remove(_dmsDrafts);
  }

  Future<Map<String, Map<String, String>>> getDmsDrafts() async {
    try {
      final drafts = _getPrefsData<String>(_dmsDrafts);
      if (drafts == null) {
        return {};
      }

      final decoded = jsonDecode(drafts) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          Map<String, String>.from(value as Map),
        ),
      );
    } catch (e) {
      lg.i('Error parsing DM drafts: $e');
      return {};
    }
  }

  /// Gift Wrap Management
  int? getDmsHistoryOlderUntil(String pubkey) {
    return _getPrefsData<int>('$pubkey-$_dmHistoryOldestUntil');
  }

  Future<void> setDmsHistoryOlderUntil(String pubkey, int dateTime) async {
    await _setPrefsData('$pubkey-$_dmHistoryOldestUntil', dateTime);
  }

  Future<void> deleteDmsHistoryOlderUntil(String pubkey) async {
    await prefs.remove('$pubkey-$_dmHistoryOldestUntil');
  }

  /// Load local remote signer DMs
  bool? getLoadLocalRemoteSignerDmStatus(String pubkey) {
    return _getPrefsData<bool>('$pubkey-$_loadLocalRemoteSignerDm');
  }

  Future<void> setLoadLocaleRemoteSignerDmStatus(
      String pubkey, bool status) async {
    await _setPrefsData('$pubkey-$_loadLocalRemoteSignerDm', status);
  }

  Future<void> deleteLoadLocaleRemoteSignerDmStatus(String pubkey) async {
    await prefs.remove('$pubkey-$_loadLocalRemoteSignerDm');
  }

  /// Gift Wrap Management
  int? getNewestGiftWrap(String pubkey) {
    return _getPrefsData<int>('$pubkey-$_giftWrapNewestDateTime');
  }

  Future<void> setNewestGiftWrap(String pubkey, int dateTime) async {
    await _setPrefsData('$pubkey-$_giftWrapNewestDateTime', dateTime);
  }

  Future<void> deleteNewestGiftWrap(String pubkey) async {
    await prefs.remove('$pubkey-$_giftWrapNewestDateTime');
  }

  /// Images Links
  Future<List<String>> getImagesLinks(String pubkey) async {
    return _getPrefsData<List<String>>(pubkey, defaultValue: <String>[]) ??
        <String>[];
  }

  Future<void> setImagesLinks(String pubKey, List<String> imagesLinks) async {
    await _setPrefsData(pubKey, imagesLinks);
  }

  // ==================================================
  // FEATURES & SERVICES
  // ==================================================

  /// Translation Services
  Future<void> setTranslateServices({required String ts}) async {
    await _setPrefsData(_translationServices, ts);
  }

  Future<String?> getTranslateServices() async {
    return _getPrefsData<String>(_translationServices);
  }

  /// Filter Status
  Future<void> setFilterStatus({required FilterStatus fs}) async {
    await _setPrefsData(_filterStatus, fs.toJson());
  }

  FilterStatus? getFilterStatus() {
    final val = _getPrefsData<String>(_filterStatus);
    return val != null ? FilterStatus.fromJson(val) : null;
  }

  /// Reaction Configuration
  Future<void> setDefaultReactions({required Map<String, String> rs}) async {
    await _setPrefsData(_defaultReaction, jsonEncode(rs));
  }

  Future<Map<String, String>> getDefaultReactions() async {
    final data = _getPrefsData<String>(_defaultReaction);
    if (data == null) {
      return {};
    }
    try {
      return Map<String, String>.from(jsonDecode(data));
    } catch (e) {
      lg.i('Error parsing default zap amounts: $e');
      return {};
    }
  }

  Future<void> setOneTapReaction(bool enable) async {
    await _setPrefsData(_enableOneTapReaction, enable);
  }

  Future<bool> getOneTapReaction() async {
    return _getPrefsData<bool>(_enableOneTapReaction, defaultValue: false) ??
        false;
  }

  /// Zap Configuration
  Future<void> setDefaultZapAmount({required Map<String, int> ts}) async {
    await _setPrefsData(_defaultZapAmounts, jsonEncode(ts));
  }

  Future<Map<String, int>> getDefaultZapAmount() async {
    final data = _getPrefsData<String>(_defaultZapAmounts);
    if (data == null) {
      return {};
    }
    try {
      return Map<String, int>.from(jsonDecode(data));
    } catch (e) {
      lg.i('Error parsing default zap amounts: $e');
      return {};
    }
  }

  Future<void> setOneTapZap(bool enable) async {
    await _setPrefsData(_enableOneTapZap, enable);
  }

  Future<bool> getOneTapZap() async {
    return _getPrefsData<bool>(_enableOneTapZap, defaultValue: false) ?? false;
  }

  /// Messaging Configuration
  bool isUsingNip44() {
    final isAvailable = _getPrefsData<bool>(_messagingNip);
    if (isAvailable != null) {
      return isAvailable;
    }
    _setPrefsData(_messagingNip, true);
    return true;
  }

  Future<void> setUsedNip(bool isUsingNip44) async {
    await _setPrefsData(_messagingNip, isUsingNip44);
  }

  /// Media Manager
  List<MediaManagerItem> getMediaManager() {
    final mediaManager = _getPrefsData<String>(_mediaManager);
    if (mediaManager != null) {
      try {
        return mediaManagerFromJson(mediaManager);
      } catch (e) {
        lg.i('Error parsing media manager: $e');
      }
    }
    _setPrefsData(_mediaManager, json.encode([]));
    return [];
  }

  Future<void> setMediaManager(List<MediaManagerItem> status) async {
    await _setPrefsData(_mediaManager, mediaManagerToJson(status));
  }

  /// WoT Configurations
  List<WotConfiguration> getWotConfigurations() {
    final wotConfigs = _getPrefsData<String>(_wotConfigurations);

    if (wotConfigs != null) {
      try {
        return wotConfigurationsFromJson(wotConfigs);
      } catch (e) {
        lg.i('Error parsing WoT configurations: $e');
      }
    }

    _setPrefsData(_wotConfigurations, json.encode([]));
    return [];
  }

  Future<void> setWotConfigurations(List<WotConfiguration> status) async {
    await _setPrefsData(_wotConfigurations, wotConfigurationsToJson(status));
  }

  // ==================================================
  // NOTIFICATIONS & FLASH NEWS
  // ==================================================

  /// Notifications Management
  Map<String, List<String>> getNotifications(bool isRegistered) {
    final notificationsData = _getPrefsData<String>(
      isRegistered ? _registeredNotifications : _newNotifications,
    );

    if (notificationsData != null) {
      try {
        final map =
            Map<String, List<dynamic>>.from(jsonDecode(notificationsData));
        final Map<String, List<String>> newMap = {};

        map.forEach((key, value) {
          newMap[key] = value.cast<String>();
        });

        return newMap;
      } catch (e) {
        lg.i('Error parsing notifications: $e');
      }
    }

    _setPrefsData(
      isRegistered ? _registeredNotifications : _newNotifications,
      json.encode({}),
    );
    return {};
  }

  Future<void> setNotifications(
    Map<String, List<String>> notifications,
    bool isRegistered,
  ) async {
    await _setPrefsData<String>(
      isRegistered ? _registeredNotifications : _newNotifications,
      jsonEncode(notifications),
    );
  }

  Future<void> clearNotifications() async {
    await prefs.remove(_registeredNotifications);
  }

  /// Flash News Management
  List<String> getPendingFlashNews() {
    return _getPrefsData<List<String>>(_pendingFlashNews,
            defaultValue: <String>[]) ??
        <String>[];
  }

  Future<void> setPendingFlashNews(List<String> pendingFlashNews) async {
    await _setPrefsData(_pendingFlashNews, pendingFlashNews);
  }

  Future<void> clearPendingFlashNews() async {
    await prefs.remove(_pendingFlashNews);
  }

  // ==================================================
  // UTILITY METHODS
  // ==================================================

  /// Clear all data (for testing or reset purposes)
  Future<void> clearAllData() async {
    try {
      await prefs.clear();
      await secureStorage.deleteAll();
    } catch (e) {
      lg.i('Error clearing all data: $e');
    }
  }

  /// Get storage info (for debugging)
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefsKeys = prefs.getKeys();
      final secureKeys = await secureStorage.readAll();

      return {
        'prefsKeys': prefsKeys.length,
        'secureKeys': secureKeys.keys.length,
        'totalKeys': prefsKeys.length + secureKeys.keys.length,
      };
    } catch (e) {
      lg.i('Error getting storage info: $e');
      return {};
    }
  }
}
