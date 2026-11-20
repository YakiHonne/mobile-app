/// Resolves Namecoin names to Nostr public keys.
///
/// This is the primary entry point for Namecoin→Nostr resolution.
/// If an identifier ends with `.bit`, it should be routed here
/// instead of to the HTTP-based NIP-05 path.
///
/// Ported from Amethyst's NamecoinNameResolver.kt (MIT License, Vitor Pamplona).

import 'dart:async';
import 'dart:convert';

import 'electrumx_client.dart';
import 'electrumx_server.dart';

/// Detailed outcome of a Namecoin resolution attempt.
abstract class NamecoinResolveOutcome {}

class NamecoinResolveSuccess extends NamecoinResolveOutcome {
  final NamecoinNostrResult result;
  NamecoinResolveSuccess(this.result);
}

class NamecoinNameNotFound extends NamecoinResolveOutcome {
  final String name;
  NamecoinNameNotFound(this.name);
}

class NamecoinNoNostrField extends NamecoinResolveOutcome {
  final String name;
  NamecoinNoNostrField(this.name);
}

class NamecoinServersUnreachable extends NamecoinResolveOutcome {
  final String message;
  NamecoinServersUnreachable(this.message);
}

class NamecoinInvalidIdentifier extends NamecoinResolveOutcome {
  final String identifier;
  NamecoinInvalidIdentifier(this.identifier);
}

class NamecoinTimeout extends NamecoinResolveOutcome {}

/// Result of resolving a Namecoin name to Nostr identity data.
class NamecoinNostrResult {
  /// Hex-encoded 32-byte Schnorr public key
  final String pubkey;

  /// Optional relay URLs where this user can be found
  final List<String> relays;

  /// The Namecoin name that was resolved (e.g. "d/example")
  final String namecoinName;

  /// The local-part that was matched (e.g. "alice" or "_")
  final String localPart;

  const NamecoinNostrResult({
    required this.pubkey,
    this.relays = const [],
    required this.namecoinName,
    this.localPart = '_',
  });
}

class NamecoinNameResolver {
  final ElectrumXClient _electrumxClient;
  final Duration _lookupTimeout;
  final List<ElectrumxServer> Function() _serverListProvider;

  static final _hexPubkeyRegex = RegExp(r'^[0-9a-fA-F]{64}$');

  NamecoinNameResolver({
    required ElectrumXClient electrumxClient,
    Duration lookupTimeout = const Duration(seconds: 20),
    List<ElectrumxServer> Function()? serverListProvider,
  })  : _electrumxClient = electrumxClient,
        _lookupTimeout = lookupTimeout,
        _serverListProvider =
            (serverListProvider ?? () => defaultElectrumxServers);

  /// Check whether an identifier should be routed to Namecoin
  /// resolution rather than standard NIP-05.
  static bool isNamecoinIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return normalized.endsWith('.bit') ||
        normalized.startsWith('d/') ||
        normalized.startsWith('id/');
  }

  /// Resolve a user-supplied identifier to a Nostr pubkey via Namecoin.
  ///
  /// [identifier] User input, e.g. "alice@example.bit", "id/alice", "example.bit"
  /// Returns [NamecoinNostrResult] on success, null if resolution failed
  Future<NamecoinNostrResult?> resolve(String identifier) async {
    final parsed = _parseIdentifier(identifier);
    if (parsed == null) return null;
    try {
      return await _performLookup(parsed).timeout(_lookupTimeout);
    } catch (_) {
      return null;
    }
  }

  /// Resolve with detailed outcome for error reporting in UI flows.
  Future<NamecoinResolveOutcome> resolveDetailed(String identifier) async {
    final parsed = _parseIdentifier(identifier);
    if (parsed == null) return NamecoinInvalidIdentifier(identifier);

    try {
      final result =
          await _performLookupDetailed(parsed).timeout(_lookupTimeout);
      return result;
    } on TimeoutException {
      return NamecoinTimeout();
    } catch (_) {
      return NamecoinTimeout();
    }
  }

  // ── Identifier Parsing ─────────────────────────────────────────────

  _ParsedIdentifier? _parseIdentifier(String raw) {
    final input = raw.trim();

    // Direct namespace references
    if (input.toLowerCase().startsWith('d/')) {
      return _ParsedIdentifier(
        namecoinName: input.toLowerCase(),
        localPart: '_',
        namespace: _Namespace.domain,
      );
    }
    if (input.toLowerCase().startsWith('id/')) {
      return _ParsedIdentifier(
        namecoinName: input.toLowerCase(),
        localPart: '_',
        namespace: _Namespace.identity,
      );
    }

    // NIP-05 style: user@domain.bit
    if (input.contains('@') && input.toLowerCase().endsWith('.bit')) {
      final parts = input.split('@');
      if (parts.length != 2) return null;
      var localPart = parts[0].toLowerCase();
      if (localPart.isEmpty) localPart = '_';
      final domain = parts[1]
          .toLowerCase()
          .replaceAll(RegExp(r'\.bit$', caseSensitive: false), '');
      if (domain.isEmpty) return null;
      return _ParsedIdentifier(
        namecoinName: 'd/$domain',
        localPart: localPart,
        namespace: _Namespace.domain,
      );
    }

    // Bare domain: example.bit
    if (input.toLowerCase().endsWith('.bit')) {
      final domain = input
          .toLowerCase()
          .replaceAll(RegExp(r'\.bit$', caseSensitive: false), '');
      if (domain.isEmpty) return null;
      return _ParsedIdentifier(
        namecoinName: 'd/$domain',
        localPart: '_',
        namespace: _Namespace.domain,
      );
    }

    return null;
  }

  // ── Lookup & Value Parsing ─────────────────────────────────────────

  Future<NamecoinNostrResult?> _performLookup(
    _ParsedIdentifier parsed,
  ) async {
    final nameResult = await _electrumxClient.nameShowWithFallback(
      parsed.namecoinName,
      _serverListProvider(),
    );
    if (nameResult == null) return null;
    final valueJson = _tryParseJson(nameResult.value);
    if (valueJson == null) return null;

    return switch (parsed.namespace) {
      _Namespace.domain => _extractFromDomainValue(valueJson, parsed),
      _Namespace.identity => _extractFromIdentityValue(valueJson, parsed),
    };
  }

  Future<NamecoinResolveOutcome> _performLookupDetailed(
    _ParsedIdentifier parsed,
  ) async {
    NameShowResult nameResult;
    try {
      final nr = await _electrumxClient.nameShowWithFallback(
        parsed.namecoinName,
        _serverListProvider(),
      );
      if (nr == null) return NamecoinNameNotFound(parsed.namecoinName);
      nameResult = nr;
    } on NamecoinNameNotFoundException {
      return NamecoinNameNotFound(parsed.namecoinName);
    } on NamecoinNameExpiredException {
      return NamecoinNameNotFound(parsed.namecoinName);
    } on NamecoinServersUnreachableException catch (e) {
      return NamecoinServersUnreachable(
        e.message,
      );
    }

    final valueJson = _tryParseJson(nameResult.value);
    if (valueJson == null) {
      return NamecoinNoNostrField(parsed.namecoinName);
    }

    final nostrResult = switch (parsed.namespace) {
      _Namespace.domain => _extractFromDomainValue(valueJson, parsed),
      _Namespace.identity => _extractFromIdentityValue(valueJson, parsed),
    };

    if (nostrResult != null) {
      return NamecoinResolveSuccess(nostrResult);
    } else {
      return NamecoinNoNostrField(parsed.namecoinName);
    }
  }

  /// Extract Nostr data from a `d/` domain value.
  ///
  /// Supports:
  ///   { "nostr": "hex-pubkey" }                           → simple form
  ///   { "nostr": { "names": { "alice": "hex" }, ... } }   → extended NIP-05-like form
  NamecoinNostrResult? _extractFromDomainValue(
    Map<String, dynamic> value,
    _ParsedIdentifier parsed,
  ) {
    final nostrField = value['nostr'];
    if (nostrField == null) return null;

    // Simple form: "nostr": "hex-pubkey"
    if (nostrField is String) {
      if (parsed.localPart == '_' && _isValidPubkey(nostrField)) {
        return NamecoinNostrResult(
          pubkey: nostrField.toLowerCase(),
          namecoinName: parsed.namecoinName,
          localPart: '_',
        );
      }
      if (parsed.localPart != '_') return null;
    }

    // Extended form: "nostr": { "names": {...}, "relays": {...} }
    if (nostrField is Map<String, dynamic>) {
      final names = nostrField['names'] as Map<String, dynamic>?;
      if (names == null) return null;

      String? resolvedLocalPart;
      String? pubkey;

      // Resolve: exact match → "_" root → first entry (root lookups only)
      final exactMatch = names[parsed.localPart];
      final rootMatch = names['_'];
      final firstEntry = (parsed.localPart == '_' && names.isNotEmpty)
          ? names.entries.first
          : null;

      if (exactMatch is String && _isValidPubkey(exactMatch)) {
        resolvedLocalPart = parsed.localPart;
        pubkey = exactMatch;
      } else if (rootMatch is String && _isValidPubkey(rootMatch)) {
        resolvedLocalPart = '_';
        pubkey = rootMatch;
      } else if (firstEntry != null &&
          firstEntry.value is String &&
          _isValidPubkey(firstEntry.value as String)) {
        resolvedLocalPart = firstEntry.key;
        pubkey = firstEntry.value as String;
      }

      if (pubkey == null || resolvedLocalPart == null) return null;

      final relays = _extractRelays(nostrField, pubkey);
      return NamecoinNostrResult(
        pubkey: pubkey.toLowerCase(),
        relays: relays,
        namecoinName: parsed.namecoinName,
        localPart: resolvedLocalPart,
      );
    }

    return null;
  }

  /// Extract Nostr data from an `id/` identity value.
  NamecoinNostrResult? _extractFromIdentityValue(
    Map<String, dynamic> value,
    _ParsedIdentifier parsed,
  ) {
    final nostrField = value['nostr'];
    if (nostrField == null) return null;

    // Simple: "nostr": "hex-pubkey"
    if (nostrField is String) {
      if (_isValidPubkey(nostrField)) {
        return NamecoinNostrResult(
          pubkey: nostrField.toLowerCase(),
          namecoinName: parsed.namecoinName,
        );
      }
    }

    // Object form: "nostr": { "pubkey": "hex", "relays": [...] }
    if (nostrField is Map<String, dynamic>) {
      final pubkey = nostrField['pubkey'] as String?;
      if (pubkey != null && _isValidPubkey(pubkey)) {
        List<String> relays;
        try {
          final relayList = nostrField['relays'] as List<dynamic>?;
          relays = relayList?.whereType<String>().toList() ?? [];
        } catch (_) {
          relays = [];
        }

        return NamecoinNostrResult(
          pubkey: pubkey.toLowerCase(),
          relays: relays,
          namecoinName: parsed.namecoinName,
        );
      }

      // Also try NIP-05-like "names" structure for id/ names
      final names = nostrField['names'] as Map<String, dynamic>?;
      if (names != null) {
        final rootPubkey = names['_'] as String?;
        if (rootPubkey != null && _isValidPubkey(rootPubkey)) {
          final relays = _extractRelays(nostrField, rootPubkey);
          return NamecoinNostrResult(
            pubkey: rootPubkey.toLowerCase(),
            relays: relays,
            namecoinName: parsed.namecoinName,
          );
        }
      }
    }

    return null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  List<String> _extractRelays(
    Map<String, dynamic> nostrObj,
    String pubkey,
  ) {
    try {
      final relaysMap = nostrObj['relays'] as Map<String, dynamic>?;
      if (relaysMap == null) return [];
      final relayArray =
          (relaysMap[pubkey.toLowerCase()] ?? relaysMap[pubkey]) as List?;
      if (relayArray == null) return [];
      return relayArray.whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic>? _tryParseJson(String raw) {
    try {
      final result = json.decode(raw);
      if (result is Map<String, dynamic>) return result;
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isValidPubkey(String s) => _hexPubkeyRegex.hasMatch(s);
}

// ── Internal types ────────────────────────────────────────────────────

enum _Namespace { domain, identity }

class _ParsedIdentifier {
  final String namecoinName;
  final String localPart;
  final _Namespace namespace;

  const _ParsedIdentifier({
    required this.namecoinName,
    required this.localPart,
    required this.namespace,
  });
}
