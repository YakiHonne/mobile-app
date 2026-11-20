/// Application-level singleton for Namecoin name resolution.
///
/// Thread-safe, designed for integration into YakiHonne's existing
/// service infrastructure.
///
/// Ported from Amethyst's NamecoinNameService.kt (MIT License, Vitor Pamplona).

import 'dart:async';

import 'electrumx_client.dart';
import 'electrumx_server.dart';
import 'namecoin_lookup_cache.dart';
import 'namecoin_name_resolver.dart';
import 'namecoin_settings.dart';

/// Observable state for a Namecoin resolution in progress.
abstract class NamecoinResolveState {}

class NamecoinResolveLoading extends NamecoinResolveState {}

class NamecoinResolveResolved extends NamecoinResolveState {
  final NamecoinNostrResult result;
  NamecoinResolveResolved(this.result);
}

class NamecoinResolveNotFound extends NamecoinResolveState {}

class NamecoinResolveError extends NamecoinResolveState {
  final String message;
  NamecoinResolveError(this.message);
}

class NamecoinNameService {
  final ElectrumXClient _electrumxClient;
  late final NamecoinNameResolver _resolver;
  final NamecoinLookupCache _cache = NamecoinLookupCache();

  /// Current settings — set by the preferences layer.
  NamecoinSettings _settings = NamecoinSettings.defaultSettings;

  NamecoinSettings get settings => _settings;

  NamecoinNameService({ElectrumXClient? electrumxClient})
      : _electrumxClient = electrumxClient ?? ElectrumXClient() {
    _resolver = NamecoinNameResolver(
      electrumxClient: _electrumxClient,
      serverListProvider: _getServers,
    );
  }

  List<ElectrumxServer> _getServers() {
    return _settings.toElectrumxServers() ?? defaultElectrumxServers;
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Resolve a Namecoin identifier to a Nostr pubkey.
  ///
  /// Returns cached results when available. This is the primary method
  /// that the search bar and NIP-05 verifier should call.
  ///
  /// [identifier] e.g. "alice@example.bit", "id/bob", "example.bit"
  Future<NamecoinNostrResult?> resolve(String identifier) async {
    if (!_settings.enabled) return null;

    // Check cache first
    if (_cache.contains(identifier)) {
      return _cache.get(identifier);
    }

    // Perform lookup
    final result = await _resolver.resolve(identifier);
    _cache.put(identifier, result);
    return result;
  }

  /// Resolve and return just the hex pubkey, or null.
  /// Convenience for follow-import integration.
  Future<String?> resolvePubkey(String identifier) async {
    final result = await resolve(identifier);
    return result?.pubkey;
  }

  /// Resolve with detailed outcome for error reporting.
  Future<NamecoinResolveOutcome> resolveDetailed(String identifier) async {
    if (!_settings.enabled) {
      return NamecoinServersUnreachable('Namecoin resolution is disabled');
    }
    return _resolver.resolveDetailed(identifier);
  }

  /// Verify that a Namecoin name maps to the expected pubkey.
  ///
  /// This is the Namecoin equivalent of NIP-05 verification:
  /// given a pubkey from a kind-0 event and a `nip05` value
  /// ending in `.bit`, check that the Namecoin blockchain
  /// confirms the mapping.
  Future<bool> verifyNip05(
    String nip05Address,
    String expectedPubkeyHex,
  ) async {
    if (!_settings.enabled) return false;
    if (!NamecoinNameResolver.isNamecoinIdentifier(nip05Address)) return false;
    final result = await resolve(nip05Address);
    if (result == null) return false;
    return result.pubkey.toLowerCase() == expectedPubkeyHex.toLowerCase();
  }

  /// Perform a lookup and emit results via a Stream.
  ///
  /// Useful for widget UIs that observe resolution state.
  Stream<NamecoinResolveState> resolveLive(String identifier) async* {
    yield NamecoinResolveLoading();
    try {
      final result = await resolve(identifier);
      if (result != null) {
        yield NamecoinResolveResolved(result);
      } else {
        yield NamecoinResolveNotFound();
      }
    } catch (e) {
      yield NamecoinResolveError(e.toString());
    }
  }

  /// Update settings. Called by the preferences layer.
  void updateSettings(NamecoinSettings newSettings) {
    _settings = newSettings;
  }

  /// Clear the resolution cache.
  void clearCache() => _cache.clear();

  /// Check if identifier is a Namecoin identifier.
  static bool isNamecoinIdentifier(String identifier) {
    return NamecoinNameResolver.isNamecoinIdentifier(identifier);
  }
}
