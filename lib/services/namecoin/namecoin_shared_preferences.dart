/// Persistent storage for [NamecoinSettings], following YakiHonne's
/// SharedPreferences pattern.
///
/// Settings are global (not per-account).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'namecoin_settings.dart';

class NamecoinSharedPreferences {
  static const String _keyEnabled = 'namecoin_enabled';
  static const String _keyCustomServers = 'namecoin_custom_servers';

  final SharedPreferences _prefs;

  NamecoinSharedPreferences(this._prefs);

  /// Load the current settings from disk.
  NamecoinSettings load() {
    final enabled = _prefs.getBool(_keyEnabled) ?? true;
    final serversJson = _prefs.getString(_keyCustomServers);
    List<String> servers = [];
    if (serversJson != null) {
      try {
        servers = (json.decode(serversJson) as List<dynamic>)
            .whereType<String>()
            .toList();
      } catch (_) {}
    }
    return NamecoinSettings(enabled: enabled, customServers: servers);
  }

  /// Save settings to disk.
  Future<void> save(NamecoinSettings settings) async {
    await _prefs.setBool(_keyEnabled, settings.enabled);
    await _prefs.setString(
      _keyCustomServers,
      json.encode(settings.customServers),
    );
  }

  /// Toggle the enabled state.
  Future<NamecoinSettings> setEnabled(bool enabled) async {
    final current = load();
    final updated = current.copyWith(enabled: enabled);
    await save(updated);
    return updated;
  }

  /// Add a custom server string.
  Future<NamecoinSettings> addServer(String server) async {
    final current = load();
    if (server.trim().isEmpty || current.customServers.contains(server)) {
      return current;
    }
    final updated = current.copyWith(
      customServers: [...current.customServers, server],
    );
    await save(updated);
    return updated;
  }

  /// Remove a custom server string.
  Future<NamecoinSettings> removeServer(String server) async {
    final current = load();
    final updated = current.copyWith(
      customServers:
          current.customServers.where((s) => s != server).toList(),
    );
    await save(updated);
    return updated;
  }

  /// Reset to defaults.
  Future<NamecoinSettings> reset() async {
    const defaults = NamecoinSettings.defaultSettings;
    await save(defaults);
    return defaults;
  }
}
