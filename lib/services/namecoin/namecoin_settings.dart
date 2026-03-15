/// Immutable data class representing the current Namecoin resolution config.
///
/// When custom servers are configured, they are used EXCLUSIVELY and the
/// hardcoded defaults are ignored. This gives privacy-conscious users full
/// control over which ElectrumX servers observe their name lookups.
///
/// Ported from Amethyst's NamecoinSettings.kt (MIT License, Vitor Pamplona).

import 'electrumx_server.dart';

class NamecoinSettings {
  /// Whether Namecoin resolution is enabled at all.
  final bool enabled;

  /// Custom ElectrumX servers. When non-empty, these replace the defaults.
  /// Each entry is `host:port` (TLS) or `host:port:tcp` (plaintext).
  final List<String> customServers;

  const NamecoinSettings({
    this.enabled = true,
    this.customServers = const [],
  });

  static const defaultSettings = NamecoinSettings();

  /// True when the user has configured at least one custom server.
  bool get hasCustomServers => customServers.isNotEmpty;

  /// Convert to [ElectrumxServer] instances used by the resolver.
  /// Returns null when no valid custom servers are configured (use defaults).
  List<ElectrumxServer>? toElectrumxServers() {
    if (customServers.isEmpty) return null;
    final servers = customServers
        .map((s) => parseServerString(s))
        .whereType<ElectrumxServer>()
        .toList();
    return servers.isEmpty ? null : servers;
  }

  NamecoinSettings copyWith({
    bool? enabled,
    List<String>? customServers,
  }) {
    return NamecoinSettings(
      enabled: enabled ?? this.enabled,
      customServers: customServers ?? this.customServers,
    );
  }

  /// Parse `host:port` or `host:port:tcp` into an [ElectrumxServer].
  ///
  /// TLS is the default protocol. Append `:tcp` for plaintext
  /// (useful for `.onion` addresses and local servers).
  ///
  /// `.onion` addresses automatically get `trustAllCerts = true`
  /// since certificate verification is meaningless over Tor.
  static ElectrumxServer? parseServerString(String s) {
    final parts = s.trim().split(':');
    if (parts.length < 2) return null;
    final host = parts[0].trim();
    final port = int.tryParse(parts[1].trim());
    if (host.isEmpty || port == null || port <= 0 || port > 65535) return null;
    final useSsl =
        parts.length > 2 ? parts[2].trim().toLowerCase() != 'tcp' : true;
    final isOnion = host.endsWith('.onion');
    return ElectrumxServer(
      host: host,
      port: port,
      useSsl: useSsl,
      trustAllCerts: isOnion || !useSsl,
    );
  }

  /// Format an [ElectrumxServer] back to the `host:port[:tcp]` string form.
  static String formatServerString(ElectrumxServer server) {
    final base = '${server.host}:${server.port}';
    return server.useSsl ? base : '$base:tcp';
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'customServers': customServers,
      };

  factory NamecoinSettings.fromJson(Map<String, dynamic> json) {
    return NamecoinSettings(
      enabled: json['enabled'] as bool? ?? true,
      customServers: (json['customServers'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamecoinSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          _listEquals(customServers, other.customServers);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(customServers));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
