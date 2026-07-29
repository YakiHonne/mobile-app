import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:yakihonne/common/pomegranate/pomegranate_crypto.dart';

void main() {
  final params = ECDomainParameters('secp256k1');

  // Derive the canonical (even-y) secret for a given raw secret BigInt.
  BigInt canonical0(BigInt secret) {
    final N = params.n;
    final pub = params.G * secret;
    if (pub == null) {
      throw StateError('EC multiply failed');
    }
    if ((pub.y!.toBigInteger()! & BigInt.one) == BigInt.one) {
      return N - secret;
    }
    return secret;
  }

  BigInt randSecret() {
    final rng = Random.secure();
    final N = params.n;
    while (true) {
      final bytes =
          Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
      final n = bytesToBigInt(bytes);
      if (n > BigInt.zero && n < N) {
        return n;
      }
    }
  }

  // Verify that x-coordinate of secret*G matches the original key's x.
  void checkXCoord(BigInt original, BigInt recovered) {
    final origPub = params.G * original;
    final recPub = params.G * recovered;
    expect(recPub, isNotNull);
    expect(
      recPub!.x!.toBigInteger(),
      equals(origPub!.x!.toBigInteger()),
      reason: 'recovered key x-coordinate must match original',
    );
  }

  group('pomegranate_crypto round-trip', () {
    const threshold = 3;
    const maxSigners = 5;

    // All 3-of-5 subsets to test exhaustively
    final subsets = <List<int>>[
      [0, 1, 2],
      [0, 1, 3],
      [0, 1, 4],
      [0, 2, 3],
      [0, 2, 4],
      [0, 3, 4],
      [1, 2, 3],
      [1, 2, 4],
      [1, 3, 4],
      [2, 3, 4],
    ];

    test('round-trips with random key, all 3-of-5 subsets', () {
      final rawSecret = randSecret();
      final canonical = canonical0(rawSecret);

      final shards = pomTrustedKeyDeal(rawSecret, threshold, maxSigners);
      expect(shards.length, equals(maxSigners));

      for (final subset in subsets) {
        final encoded = subset.map((i) => pomHexShard(shards[i])).toList();
        final decoded = encoded.map(pomKeyShardFromHex).toList();
        final recovered = pomAggregateShards(decoded);

        expect(recovered, equals(canonical),
            reason:
                'subset $subset: recovered key must equal canonical secret');
        checkXCoord(rawSecret, recovered);
      }
    });

    test('round-trips with multiple random keys', () {
      for (int trial = 0; trial < 5; trial++) {
        final rawSecret = randSecret();
        final canonical = canonical0(rawSecret);

        final shards = pomTrustedKeyDeal(rawSecret, threshold, maxSigners);

        // Pick a different 3-of-5 subset each trial
        final subset = subsets[trial];
        final encoded = subset.map((i) => pomHexShard(shards[i])).toList();
        final decoded = encoded.map(pomKeyShardFromHex).toList();
        final recovered = pomAggregateShards(decoded);

        expect(recovered, equals(canonical),
            reason: 'trial $trial: recovered key must equal canonical secret');
        checkXCoord(rawSecret, recovered);
      }
    });

    test('hex encoding/decoding preserves all shard fields', () {
      final secret = randSecret();
      final shards = pomTrustedKeyDeal(secret, threshold, maxSigners);
      for (final shard in shards) {
        final encoded = pomHexShard(shard);
        expect(encoded.length, equals(208),
            reason: '104 bytes = 208 hex chars');
        final decoded = pomKeyShardFromHex(encoded);
        expect(decoded.id, equals(shard.id));
        expect(decoded.secret, equals(shard.secret));
        expect(decoded.pubShardCompressed, equals(shard.pubShardCompressed));
        expect(decoded.pubkeyCompressed, equals(shard.pubkeyCompressed));
      }
    });

    test('pubShard hex is 39 bytes', () {
      final secret = randSecret();
      final shards = pomTrustedKeyDeal(secret, threshold, maxSigners);
      for (final shard in shards) {
        final encoded = pomHexPubShard(shard);
        expect(encoded.length, equals(78), reason: '39 bytes = 78 hex chars');
      }
    });

    test('pomThreshold(5) == 3', () {
      expect(pomThreshold(5), equals(3));
    });

    test('even-y normalization: G*canonical has even y', () {
      final rawSecret = randSecret();
      final shards = pomTrustedKeyDeal(rawSecret, threshold, maxSigners);
      final recovered = pomAggregateShards(
        [0, 1, 2]
            .map((i) => pomKeyShardFromHex(pomHexShard(shards[i])))
            .toList(),
      );
      final pub = params.G * recovered;
      expect(pub, isNotNull);
      final y = pub!.y!.toBigInteger()!;
      expect(y & BigInt.one, equals(BigInt.zero),
          reason: 'canonical key must have even y');
    });
  });
}
