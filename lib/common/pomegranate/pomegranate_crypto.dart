// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/ecc/api.dart';

final _params = ECDomainParameters('secp256k1');

// secp256k1 curve order
final BigInt _N = _params.n;

Uint8List bigIntToBytes32(BigInt value) {
  final hex = value.toRadixString(16).padLeft(64, '0');
  final bytes = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

BigInt bytesToBigInt(Uint8List bytes) {
  return BigInt.parse(
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}

BigInt _mod(BigInt n) {
  final v = n % _N;
  return v >= BigInt.zero ? v : v + _N;
}

BigInt _invert(BigInt n) {
  BigInt a = _mod(n);
  BigInt b = _N;
  BigInt x = BigInt.one;
  BigInt y = BigInt.zero;
  while (b != BigInt.zero) {
    final q = a ~/ b;
    final ta = b;
    final tb = a % b;
    final tx = y;
    final ty = x - q * y;
    a = ta;
    b = tb;
    x = tx;
    y = ty;
  }
  if (a != BigInt.one) {
    throw Exception('No modular inverse');
  }
  return _mod(x);
}

Uint8List _compressPoint(ECPoint point) {
  final x = point.x!.toBigInteger()!;
  final y = point.y!.toBigInteger()!;
  final prefix = (y & BigInt.one) == BigInt.zero ? 0x02 : 0x03;
  final result = Uint8List(33);
  result[0] = prefix;
  result.setRange(1, 33, bigIntToBytes32(x));
  return result;
}

BigInt _randScalar() {
  final rng = Random.secure();
  while (true) {
    final bytes =
        Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    final n = bytesToBigInt(bytes);
    if (n > BigInt.zero && n < _N) {
      return n;
    }
  }
}

class PomShard {
  const PomShard({
    required this.id,
    required this.secret,
    required this.pubShardCompressed,
    required this.pubkeyCompressed,
  });
  final int id;
  final BigInt secret;
  final Uint8List pubShardCompressed;
  final Uint8List pubkeyCompressed;
}

List<PomShard> pomTrustedKeyDeal(BigInt secret, int threshold, int maxSigners) {
  ECPoint? pubPoint = _params.G * secret;
  if (pubPoint == null) {
    throw Exception('EC multiply failed');
  }

  // Normalize to even y (BIP-340 convention)
  if ((pubPoint.y!.toBigInteger()! & BigInt.one) == BigInt.one) {
    secret = _N - secret;
    pubPoint = _params.G * secret;
    if (pubPoint == null) {
      throw Exception('EC multiply failed');
    }
  }

  final pubkeyBytes = _compressPoint(pubPoint);

  // Build random polynomial with constant term = secret
  final poly = List<BigInt>.generate(
    threshold,
    (i) => i == 0 ? secret : _randScalar(),
  );

  BigInt evalPoly(BigInt x) {
    BigInt value = poly[poly.length - 1];
    for (int i = poly.length - 2; i >= 0; i--) {
      value = _mod(value * x + poly[i]);
    }
    return value;
  }

  final shards = <PomShard>[];
  for (int i = 1; i <= maxSigners; i++) {
    final yi = evalPoly(BigInt.from(i));
    final pubShardPoint = _params.G * yi;
    if (pubShardPoint == null) {
      throw Exception('EC multiply failed');
    }
    shards.add(PomShard(
      id: i,
      secret: yi,
      pubShardCompressed: _compressPoint(pubShardPoint),
      pubkeyCompressed: pubkeyBytes,
    ));
  }

  return shards;
}

// Layout: [id:2 LE][commitCount=0:4 LE][pubShard:33][secret:32][pubkey:33] = 104 bytes
String pomHexShard(PomShard shard) {
  final bytes = Uint8List(104);
  final dv = ByteData.sublistView(bytes);
  dv.setUint16(0, shard.id, Endian.little);
  dv.setUint32(2, 0, Endian.little);
  bytes.setRange(6, 39, shard.pubShardCompressed);
  bytes.setRange(39, 71, bigIntToBytes32(shard.secret));
  bytes.setRange(71, 104, shard.pubkeyCompressed);
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// Layout: [id:2 LE][commitCount=0:4 LE][pubShard:33] = 39 bytes
String pomHexPubShard(PomShard shard) {
  final bytes = Uint8List(39);
  final dv = ByteData.sublistView(bytes);
  dv.setUint16(0, shard.id, Endian.little);
  dv.setUint32(2, 0, Endian.little);
  bytes.setRange(6, 39, shard.pubShardCompressed);
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

PomShard pomKeyShardFromHex(String hex) {
  final bytes = Uint8List.fromList(
    List.generate(hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
  );
  final dv = ByteData.sublistView(bytes);
  final id = dv.getUint16(0, Endian.little);
  final commitCount = dv.getUint32(2, Endian.little);
  final pubShardBytes = bytes.sublist(6, 39);
  final secretOffset = 6 + 33 + commitCount * 33;
  final secretBytes = bytes.sublist(secretOffset, secretOffset + 32);
  final pubkeyBytes = bytes.sublist(secretOffset + 32, secretOffset + 65);
  return PomShard(
    id: id,
    secret: bytesToBigInt(secretBytes),
    pubShardCompressed: pubShardBytes,
    pubkeyCompressed: pubkeyBytes,
  );
}

// Lagrange interpolation over GF(N) to recover the master secret
BigInt pomAggregateShards(List<PomShard> shards) {
  if (shards.isEmpty) {
    throw Exception('No shards provided');
  }
  final participants = shards.map((s) => s.id).toList();

  BigInt computeLambda(int id) {
    BigInt num = BigInt.one;
    BigInt den = BigInt.one;
    for (final part in participants) {
      if (part == id) {
        continue;
      }
      num = _mod(num * BigInt.from(part));
      den = _mod(den * _mod(BigInt.from(part) - BigInt.from(id)));
    }
    return _mod(num * _invert(den));
  }

  BigInt res = BigInt.zero;
  for (final shard in shards) {
    res = _mod(res + _mod(computeLambda(shard.id) * shard.secret));
  }

  if (res == BigInt.zero) {
    throw Exception('Recovered key is zero');
  }
  return res;
}

int pomThreshold(int operatorCount) => ((operatorCount * 7) / 12).ceil();
