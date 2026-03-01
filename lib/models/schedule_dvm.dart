import 'dart:convert';
import 'dart:typed_data';

import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';

class DvmMasterResponse {
  const DvmMasterResponse({
    required this.tag,
    required this.version,
    required this.kr,
    required this.mb,
    required this.relays,
  });

  factory DvmMasterResponse.fromJson(String json) {
    return DvmMasterResponse.fromMap(jsonDecode(json));
  }

  factory DvmMasterResponse.fromMap(Map<String, dynamic> map) {
    return DvmMasterResponse(
      tag: map['t'] ?? '',
      version: map['version'] ?? 0,
      kr: map['kr'] ?? '',
      mb: map['mb'] ?? '',
      relays: map['relays'] != null ? List<String>.from(map['relays']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      't': tag,
      'version': version,
      'kr': kr,
      'mb': mb,
      'relays': relays,
    };
  }

  final String tag;
  final int version;
  final String kr;
  final String mb;
  final List<String> relays;

  Uint8List get kSubmit {
    final krBytes = kr.length == 64
        ? hexToBytes(kr)
        : base64Url.decode(base64Url.normalize(kr));
    final salt = Uint8List(0);
    final info = utf8.encode('pidgeon:v3:key:submit');

    final prk = Nip44v2.hkdfExtract(salt, krBytes);
    return Nip44v2.hkdfExpand(prk, Uint8List.fromList(info), 32);
  }

  Uint8List get mailboxKey {
    final krBytes = base64Url.decode(base64Url.normalize(kr));
    final salt = Uint8List(0);
    final info = utf8.encode('pidgeon:v3:key:mailbox');

    final prk = Nip44v2.hkdfExtract(salt, krBytes);
    return Nip44v2.hkdfExpand(prk, Uint8List.fromList(info), 32);
  }

  Future<Event?> generateScheduleEvent({
    required List<String> relays,
    required Event event,
    required String dvmPubkey,
    required EventSigner signer,
  }) async {
    final content = jsonEncode({
      'tags': [
        ['i', event.toJsonString(), 'text']
      ],
      'cap': {'allowFree': true}
    });

    final encryptedRumorContent = await Nip44v2.encrypt(
      content,
      kSubmit,
    );

    final rumorTags = [
      ['p', dvmPubkey],
      ['k', '3'],
      ['relays', ...relays],
    ];

    final rumor = Event.withoutSignature(
      pubkey: currentSigner!.getPublicKey(),
      kind: EventKind.DVM_SCHEDULE_POST,
      content: encryptedRumorContent,
      tags: rumorTags,
      createdAt: currentUnixTimestampSeconds(),
    );

    return currentSigner!.encrypt44Event(rumor, dvmPubkey);
  }
}
