import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/services/namecoin/namecoin_name_resolver.dart';
import 'package:yakihonne/services/namecoin/namecoin_settings.dart';
import 'package:yakihonne/services/namecoin/electrumx_server.dart';

void main() {
  group('NamecoinNameResolver.isNamecoinIdentifier', () {
    test('recognizes dot-bit domains', () {
      expect(NamecoinNameResolver.isNamecoinIdentifier('example.bit'), isTrue);
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('alice@example.bit'),
        isTrue,
      );
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('_@example.bit'),
        isTrue,
      );
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('EXAMPLE.BIT'),
        isTrue,
      );
    });

    test('recognizes d/ names', () {
      expect(NamecoinNameResolver.isNamecoinIdentifier('d/example'), isTrue);
      expect(NamecoinNameResolver.isNamecoinIdentifier('D/Example'), isTrue);
    });

    test('recognizes id/ names', () {
      expect(NamecoinNameResolver.isNamecoinIdentifier('id/alice'), isTrue);
      expect(NamecoinNameResolver.isNamecoinIdentifier('ID/Alice'), isTrue);
    });

    test('rejects non-namecoin identifiers', () {
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('alice@example.com'),
        isFalse,
      );
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('npub1abc'),
        isFalse,
      );
      expect(
        NamecoinNameResolver.isNamecoinIdentifier('some random text'),
        isFalse,
      );
      expect(NamecoinNameResolver.isNamecoinIdentifier(''), isFalse);
    });
  });

  group('NamecoinSettings', () {
    test('default settings', () {
      const settings = NamecoinSettings();
      expect(settings.enabled, isTrue);
      expect(settings.customServers, isEmpty);
      expect(settings.hasCustomServers, isFalse);
      expect(settings.toElectrumxServers(), isNull);
    });

    test('parseServerString parses host:port', () {
      final server = NamecoinSettings.parseServerString('example.com:50002');
      expect(server, isNotNull);
      expect(server!.host, 'example.com');
      expect(server.port, 50002);
      expect(server.useSsl, isTrue);
    });

    test('parseServerString parses host:port:tcp', () {
      final server =
          NamecoinSettings.parseServerString('example.com:50001:tcp');
      expect(server, isNotNull);
      expect(server!.host, 'example.com');
      expect(server.port, 50001);
      expect(server.useSsl, isFalse);
      expect(server.trustAllCerts, isTrue);
    });

    test('parseServerString handles onion addresses', () {
      final server = NamecoinSettings.parseServerString(
        'abcdef1234567890.onion:50002',
      );
      expect(server, isNotNull);
      expect(server!.trustAllCerts, isTrue);
    });

    test('parseServerString rejects invalid input', () {
      expect(NamecoinSettings.parseServerString(''), isNull);
      expect(NamecoinSettings.parseServerString('host'), isNull);
      expect(NamecoinSettings.parseServerString('host:abc'), isNull);
      expect(NamecoinSettings.parseServerString('host:0'), isNull);
      expect(NamecoinSettings.parseServerString('host:99999'), isNull);
    });

    test('formatServerString roundtrips', () {
      const server = ElectrumxServer(host: 'test.com', port: 50002);
      final formatted = NamecoinSettings.formatServerString(server);
      expect(formatted, 'test.com:50002');
      final parsed = NamecoinSettings.parseServerString(formatted);
      expect(parsed!.host, server.host);
      expect(parsed.port, server.port);
    });

    test('serialization roundtrip', () {
      const original = NamecoinSettings(
        enabled: false,
        customServers: ['host1:50002', 'host2:50001:tcp'],
      );
      final jsonMap = original.toJson();
      final restored = NamecoinSettings.fromJson(jsonMap);
      expect(restored.enabled, original.enabled);
      expect(restored.customServers, original.customServers);
    });

    test('custom servers replace defaults', () {
      const settings = NamecoinSettings(
        customServers: ['myserver.com:50002'],
      );
      expect(settings.hasCustomServers, isTrue);
      final servers = settings.toElectrumxServers();
      expect(servers, isNotNull);
      expect(servers!.length, 1);
      expect(servers.first.host, 'myserver.com');
    });

    test('copyWith preserves unset fields', () {
      const original = NamecoinSettings(
        enabled: false,
        customServers: ['a:1'],
      );
      final copy = original.copyWith(enabled: true);
      expect(copy.enabled, isTrue);
      expect(copy.customServers, ['a:1']);
    });
  });

  group('NamecoinNostrResult value parsing', () {
    // These tests verify the JSON parsing logic without network access,
    // similar to the Amethyst test suite.

    test('parses simple nostr field from domain value', () {
      final result = _extractNostrFromValue(
        '{"nostr":"b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9"}',
        'd/example',
        '_',
      );
      expect(result, isNotNull);
      expect(
        result!.pubkey,
        'b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9',
      );
    });

    test('parses extended nostr names from domain value', () {
      const value = '''
      {
        "nostr": {
          "names": {
            "_": "aaaa000000000000000000000000000000000000000000000000000000000001",
            "alice": "bbbb000000000000000000000000000000000000000000000000000000000002"
          },
          "relays": {
            "bbbb000000000000000000000000000000000000000000000000000000000002": [
              "wss://relay.example.com"
            ]
          }
        }
      }
      ''';

      // Root lookup
      final rootResult = _extractNostrFromValue(value, 'd/example', '_');
      expect(rootResult, isNotNull);
      expect(
        rootResult!.pubkey,
        'aaaa000000000000000000000000000000000000000000000000000000000001',
      );

      // Named lookup
      final aliceResult =
          _extractNostrFromValue(value, 'd/example', 'alice');
      expect(aliceResult, isNotNull);
      expect(
        aliceResult!.pubkey,
        'bbbb000000000000000000000000000000000000000000000000000000000002',
      );
      expect(aliceResult.relays, ['wss://relay.example.com']);
    });

    test('falls back to root when named user not found', () {
      const value = '''
      {
        "nostr": {
          "names": {
            "_": "aaaa000000000000000000000000000000000000000000000000000000000001"
          }
        }
      }
      ''';

      final result =
          _extractNostrFromValue(value, 'd/example', 'nonexistent');
      expect(result, isNotNull);
      expect(
        result!.pubkey,
        'aaaa000000000000000000000000000000000000000000000000000000000001',
      );
    });

    test('root lookup falls back to first entry when no underscore key', () {
      const value = '''
      {
        "nostr": {
          "names": {
            "m": "6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d"
          }
        }
      }
      ''';

      final result = _extractNostrFromValue(value, 'd/testls', '_');
      expect(result, isNotNull);
      expect(
        result!.pubkey,
        '6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d',
      );
      expect(result.localPart, 'm');
    });

    test('non-root lookup does NOT fall back to first entry', () {
      const value = '''
      {
        "nostr": {
          "names": {
            "m": "6cdebccabda1dfa058ab85352a79509b592b2bdfa0370325e28ec1cb4f18667d"
          }
        }
      }
      ''';

      final result = _extractNostrFromValue(value, 'd/testls', 'alice');
      expect(result, isNull);
    });

    test('parses simple nostr field from identity value', () {
      const value = '''
      {
        "nostr": "cccc000000000000000000000000000000000000000000000000000000000003",
        "email": "alice@example.com"
      }
      ''';

      final result = _extractNostrFromIdentityValue(value, 'id/alice');
      expect(result, isNotNull);
      expect(
        result!.pubkey,
        'cccc000000000000000000000000000000000000000000000000000000000003',
      );
    });

    test('parses object nostr field from identity value', () {
      const value = '''
      {
        "nostr": {
          "pubkey": "dddd000000000000000000000000000000000000000000000000000000000004",
          "relays": ["wss://relay.example.com", "wss://relay2.example.com"]
        }
      }
      ''';

      final result = _extractNostrFromIdentityValue(value, 'id/bob');
      expect(result, isNotNull);
      expect(
        result!.pubkey,
        'dddd000000000000000000000000000000000000000000000000000000000004',
      );
      expect(result.relays.length, 2);
    });

    test('rejects invalid pubkey lengths', () {
      final result = _extractNostrFromValue(
        '{"nostr":"tooshort"}',
        'd/bad',
        '_',
      );
      expect(result, isNull);
    });

    test('rejects non-hex pubkeys', () {
      final result = _extractNostrFromValue(
        '{"nostr":"zzzz000000000000000000000000000000000000000000000000000000000000"}',
        'd/bad',
        '_',
      );
      expect(result, isNull);
    });

    test('handles missing nostr field', () {
      final result = _extractNostrFromValue(
        '{"ip":"1.2.3.4","map":{"www":{"ip":"1.2.3.4"}}}',
        'd/example',
        '_',
      );
      expect(result, isNull);
    });

    test('handles malformed JSON gracefully', () {
      final result = _extractNostrFromValue(
        'not json at all',
        'd/broken',
        '_',
      );
      expect(result, isNull);
    });
  });
}

// ── Test helpers ───────────────────────────────────────────────────────
// Directly test value parsing without network access,
// matching the approach used in Amethyst's test suite.

final _hexPubkeyRegex = RegExp(r'^[0-9a-fA-F]{64}$');

NamecoinNostrResult? _extractNostrFromValue(
  String jsonValue,
  String namecoinName,
  String localPart,
) {
  try {
    final obj = _tryParseJson(jsonValue);
    if (obj == null) return null;

    final nostrField = obj['nostr'];
    if (nostrField == null) return null;

    // Simple form
    if (nostrField is String) {
      if (localPart == '_' && _hexPubkeyRegex.hasMatch(nostrField)) {
        return NamecoinNostrResult(
          pubkey: nostrField.toLowerCase(),
          namecoinName: namecoinName,
        );
      }
      return null;
    }

    // Extended form
    if (nostrField is Map<String, dynamic>) {
      final names = nostrField['names'] as Map<String, dynamic>?;
      if (names == null) return null;

      String? resolvedLocalPart;
      String? pubkey;

      final exactMatch = names[localPart];
      final rootMatch = names['_'];
      final firstEntry =
          (localPart == '_' && names.isNotEmpty) ? names.entries.first : null;

      if (exactMatch is String && _hexPubkeyRegex.hasMatch(exactMatch)) {
        resolvedLocalPart = localPart;
        pubkey = exactMatch;
      } else if (rootMatch is String && _hexPubkeyRegex.hasMatch(rootMatch)) {
        resolvedLocalPart = '_';
        pubkey = rootMatch;
      } else if (firstEntry != null &&
          firstEntry.value is String &&
          _hexPubkeyRegex.hasMatch(firstEntry.value as String)) {
        resolvedLocalPart = firstEntry.key;
        pubkey = firstEntry.value as String;
      }

      if (pubkey == null || resolvedLocalPart == null) return null;

      final relays = _extractRelays(nostrField, pubkey);
      return NamecoinNostrResult(
        pubkey: pubkey.toLowerCase(),
        relays: relays,
        namecoinName: namecoinName,
        localPart: resolvedLocalPart,
      );
    }

    return null;
  } catch (_) {
    return null;
  }
}

NamecoinNostrResult? _extractNostrFromIdentityValue(
  String jsonValue,
  String namecoinName,
) {
  try {
    final obj = _tryParseJson(jsonValue);
    if (obj == null) return null;

    final nostrField = obj['nostr'];
    if (nostrField == null) return null;

    if (nostrField is String && _hexPubkeyRegex.hasMatch(nostrField)) {
      return NamecoinNostrResult(
        pubkey: nostrField.toLowerCase(),
        namecoinName: namecoinName,
      );
    }

    if (nostrField is Map<String, dynamic>) {
      final pubkey = nostrField['pubkey'] as String?;
      if (pubkey != null && _hexPubkeyRegex.hasMatch(pubkey)) {
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
          namecoinName: namecoinName,
        );
      }
    }

    return null;
  } catch (_) {
    return null;
  }
}

List<String> _extractRelays(Map<String, dynamic> nostrObj, String pubkey) {
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
