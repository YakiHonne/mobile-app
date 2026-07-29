// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:bip340/bip340.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../repositories/http_functions_repository.dart';
import 'pomegranate_crypto.dart';

const kPomCentralUrl = 'https://auth.njump.me';
const kPomOperatorUrls = [
  'https://po.jumble.social',
  'https://po.coracle.social',
  'https://po.njump.me',
  'https://po.f7z.io',
  'https://po.nostrver.se',
];

class PomToken {
  const PomToken(
      {required this.raw, required this.email, required this.createdAt});
  final String raw;
  final String email;
  final int createdAt;
}

PomToken? parsePomToken(String raw) {
  try {
    final decoded = utf8.decode(base64.decode(base64.normalize(raw)));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final createdAt = (json['created_at'] as num?)?.toInt() ?? 0;
    String email = '';
    final tags = json['tags'] as List?;
    if (tags != null) {
      for (final tag in tags) {
        if (tag is List && tag.length >= 2 && tag[0] == 'email') {
          email = tag[1] as String;
          break;
        }
      }
    }
    return PomToken(raw: raw, email: email, createdAt: createdAt);
  } catch (_) {
    return null;
  }
}

bool isPomTokenValid(PomToken token) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return (now - token.createdAt) < 24 * 60 * 60;
}

Future<Map<String, dynamic>?> pomGetAccount(
    String central, PomToken token) async {
  try {
    final dio = await HttpFunctionsRepository.getDio();
    final res = await dio.get(
      '$central/account',
      options: Options(
        headers: {'Authorization': 'Token ${token.raw}'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (res.statusCode == 404 || res.statusCode == 401) {
      return null;
    }
    if (res.statusCode == 200) {
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['pubkey'] != null) {
        return data;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<List<dynamic>> pomListProfiles(String central, PomToken token) async {
  final dio = await HttpFunctionsRepository.getDio();
  final res = await dio.get(
    '$central/profiles',
    options: Options(headers: {'Authorization': 'Token ${token.raw}'}),
  );
  if (res.statusCode != 200) {
    throw Exception('Failed to list profiles');
  }
  return res.data as List<dynamic>;
}

Future<Map<String, dynamic>> pomCreateProfile(
    String central, PomToken token, String name) async {
  final dio = await HttpFunctionsRepository.getDio();
  final res = await dio.post(
    '$central/profiles',
    data: jsonEncode({'name': name}),
    options: Options(headers: {
      'Authorization': 'Token ${token.raw}',
      'Content-Type': 'application/json',
    }),
  );
  if ((res.statusCode ?? 0) >= 400) {
    throw Exception('Profile creation failed');
  }
  return res.data as Map<String, dynamic>;
}

String pomGetBunkerUrl(String central, Map<String, dynamic> profile) {
  final relay = central
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');
  final handlerPubkey = profile['handler_pubkey'] as String;
  return 'bunker://$handlerPubkey?relay=${Uri.encodeComponent(relay)}';
}

Future<void> pomRegister({
  required String central,
  required List<String> operators,
  required int threshold,
  required PomToken token,
  required String email,
  required String secretKeyHex,
  required String session,
}) async {
  final pubKeyHex = getPublicKey(secretKeyHex);
  final signer = Bip340EventSigner(secretKeyHex, pubKeyHex);

  final secretBigInt = bytesToBigInt(
    Uint8List.fromList(
      List.generate(
        secretKeyHex.length ~/ 2,
        (i) => int.parse(secretKeyHex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    ),
  );
  final shards = pomTrustedKeyDeal(secretBigInt, threshold, operators.length);

  // Build and send kind 20445 event to central
  final regEvent = await Event.genEvent(
    kind: EventKind.POMEGRANATE_REGISTRATION,
    tags: [
      ['threshold', threshold.toString()],
      for (int i = 0; i < operators.length; i++)
        ['operator', operators[i], pomHexPubShard(shards[i])],
    ],
    content: '',
    signer: signer,
  );

  if (regEvent == null) {
    throw Exception('Failed to build registration event');
  }

  final dio = await HttpFunctionsRepository.getDio();
  final regRes = await dio.post(
    '$central/register',
    data: jsonEncode(regEvent.toJson()),
    options: Options(headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Token ${token.raw}',
      'X-Pomegranate-Session': session,
    }),
  );
  if ((regRes.statusCode ?? 0) >= 400) {
    throw Exception(
        'Central server registration failed (${regRes.statusCode})');
  }

  // Send kind 20444 to each operator
  const utf8enc = Utf8Encoder();
  int successCount = 0;

  await Future.wait(
    List.generate(operators.length, (i) async {
      final operator = operators[i];
      final opEvent = await Event.genEvent(
        kind: EventKind.POMEGRANATE_SHARD,
        tags: [
          ['central', central],
          ['email', email],
        ],
        content: pomHexShard(shards[i]),
        signer: signer,
      );
      if (opEvent == null) {
        return;
      }

      final sessionOpHash =
          sha256.convert(utf8enc.convert('$session:$operator'));
      final opToken = sessionOpHash.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      try {
        final opDio = await HttpFunctionsRepository.getDio();
        final res = await opDio.post(
          '$operator/po/register',
          data: jsonEncode(opEvent.toJson()),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'X-Pomegranate-Operator-Token': opToken,
            },
            validateStatus: (s) => true,
          ),
        );
        if ((res.statusCode ?? 0) < 300) {
          successCount++;
        }
      } catch (_) {}
    }),
  );

  if (successCount < threshold) {
    throw Exception(
        'Could not register with enough operators ($successCount/$threshold)');
  }
}
