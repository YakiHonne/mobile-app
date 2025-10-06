// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'app_models/diverse_functions.dart';
import 'uncensored_notes_models.dart';

const FN_SOURCE = 'source';
const FN_IMPORTANT = 'important';
const FN_ENCRYPTION = 'yaki_flash_news';
const FN_SEARCH_KEY = 'l';
const FN_SEARCH_VALUE = 'FLASH NEWS';

class PendingFlashNews {
  final FlashNews flashNews;
  final Map<String, dynamic> event;
  final String eventId;
  final String pubkey;
  final String lnbc;

  PendingFlashNews({
    required this.flashNews,
    required this.event,
    required this.eventId,
    required this.pubkey,
    required this.lnbc,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'flashNews': flashNews.toMap(),
      'eventId': eventId,
      'lnbc': lnbc,
      'pubkey': pubkey,
      'event': event,
    };
  }

  factory PendingFlashNews.fromMap(Map<String, dynamic> map) {
    final flash = FlashNews.fromMap2(map['flashNews'] as Map<String, dynamic>);

    return PendingFlashNews(
      flashNews: flash,
      eventId: map['eventId'] as String,
      pubkey: map['pubkey'] as String,
      lnbc: map['lnbc'] as String,
      event: map['event'] as Map<String, dynamic>,
    );
  }

  bool isExpired() {
    return DateTime.now().differenceInHours(flashNews.createdAt);
  }

  String toJson() => json.encode(toMap());

  factory PendingFlashNews.fromJson(String source) =>
      PendingFlashNews.fromMap(json.decode(source) as Map<String, dynamic>);

  PendingFlashNews copyWith({
    FlashNews? flashNews,
    Map<String, dynamic>? event,
    String? eventId,
    String? pubkey,
    String? lnbc,
  }) {
    return PendingFlashNews(
      flashNews: flashNews ?? this.flashNews,
      event: event ?? this.event,
      eventId: eventId ?? this.eventId,
      pubkey: pubkey ?? this.pubkey,
      lnbc: lnbc ?? this.lnbc,
    );
  }
}

List<MainFlashNews> mainFlashNewsFromJson(List main) =>
    main.map((e) => MainFlashNews.fromMap(e as Map<String, dynamic>)).toList();

class MainFlashNews extends Equatable {
  final FlashNews flashNews;
  final SealedNote? sealedNote;
  final bool isNoteNew;
  final List<String> unPubkeys;

  const MainFlashNews({
    required this.flashNews,
    this.isNoteNew = false,
    this.unPubkeys = const <String>[],
    this.sealedNote,
  });

  factory MainFlashNews.fromMap(Map<String, dynamic> map) {
    final sealed = map['sealed_note'] != null
        ? SealedNote.fromMap(map['sealed_note'])
        : null;
    final isNoteNewEl = map['is_note_new'] as bool? ?? false;
    final unPubkeys =
        List<String>.from(map['pubkeys_in_new_un'] as List? ?? <String>[]);
    final fn = FlashNews.fromMap(map['flashnews']);

    return MainFlashNews(
      flashNews: fn,
      sealedNote: sealed,
      isNoteNew: isNoteNewEl,
      unPubkeys: unPubkeys,
    );
  }

  AddUncensoredNote canAddUncensoredNote() {
    if (!isNoteNew) {
      return AddUncensoredNote.disabled;
    }

    final canAuthorVote =
        canSign() && currentSigner!.getPublicKey() != flashNews.pubkey;

    if (!canAuthorVote) {
      return AddUncensoredNote.disabled;
    }

    if (unPubkeys.contains(currentSigner!.getPublicKey())) {
      return AddUncensoredNote.added;
    } else {
      return AddUncensoredNote.enabled;
    }
  }

  MainFlashNews copyWith({
    FlashNews? flashNews,
    SealedNote? sealedNote,
    bool? isNoteNew,
    List<String>? unPubkeys,
  }) {
    return MainFlashNews(
      flashNews: flashNews ?? this.flashNews,
      sealedNote: sealedNote ?? this.sealedNote,
      isNoteNew: isNoteNew ?? this.isNoteNew,
      unPubkeys: unPubkeys ?? this.unPubkeys,
    );
  }

  @override
  List<Object?> get props => [
        flashNews,
        isNoteNew,
        unPubkeys,
      ];
}

class FlashNews extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final String pubkey;
  final String content;
  final bool isImportant;
  final String encryption;
  final String source;
  @override
  final DateTime createdAt;
  final String formattedDate;
  final bool isAuthentic;
  final List<String> tags;

  const FlashNews({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.isImportant,
    required this.encryption,
    required this.source,
    required this.createdAt,
    required this.formattedDate,
    required this.isAuthentic,
    required this.tags,
  });

  factory FlashNews.fromEvent(Event event) {
    bool isImportant = false;
    String source = '';
    final List<String> tags = [];
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    String encryption = '';

    for (final tag in event.tags) {
      if (tag.first == FN_SOURCE && tag.length > 1) {
        source = tag[1];
      } else if (tag.first == FN_IMPORTANT) {
        isImportant = true;
      } else if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      } else if (tag.first == 't' && tag.length > 1) {
        tags.add(tag[1]);
      }
    }

    return FlashNews(
      id: event.id,
      pubkey: event.pubkey,
      content: event.content,
      isImportant: isImportant,
      encryption: encryption,
      source: source,
      createdAt: createdAt,
      formattedDate: dateFormat2.format(createdAt),
      isAuthentic: checkAuthenticity(encryption, createdAt),
      tags: tags,
    );
  }

  FlashNews copyWith({
    String? id,
    String? pubKey,
    String? content,
    bool? isImportant,
    String? encryption,
    String? source,
    DateTime? createdAt,
    String? formattedDate,
    bool? isAuthentic,
    List<String>? tags,
  }) {
    return FlashNews(
      id: id ?? this.id,
      pubkey: pubKey ?? pubkey,
      content: content ?? this.content,
      isImportant: isImportant ?? this.isImportant,
      encryption: encryption ?? this.encryption,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      formattedDate: formattedDate ?? this.formattedDate,
      isAuthentic: isAuthentic ?? this.isAuthentic,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pubkey': pubkey,
      'content': content,
      'isImportant': isImportant,
      'encryption': encryption,
      'source': source,
      'createdAt': createdAt.toSecondsSinceEpoch(),
      'formattedDate': formattedDate,
      'isAuthentic': isAuthentic,
      'tags': tags,
    };
  }

  factory FlashNews.fromMap2(Map<String, dynamic> map) {
    return FlashNews(
      id: map['id'] as String? ?? '',
      pubkey: map['pubkey'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isImportant: map['isImportant'],
      encryption: map['encryption'],
      source: map['source'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] * 1000),
      formattedDate: map['formattedDate'],
      isAuthentic: map['isAuthentic'],
      tags: List.from(map['tags']),
    );
  }

  factory FlashNews.fromMap(Map<String, dynamic> map) {
    bool isImportant = false;
    String source = '';
    final List<String> tags = [];

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (map['created_at'] as int? ?? 0) * 1000,
    );
    String encryption = '';

    for (final tag in map['tags']) {
      if (tag.first == FN_SOURCE && tag.length > 1) {
        source = tag[1];
      } else if (tag.first == FN_IMPORTANT) {
        isImportant = true;
      } else if (tag.first == FN_ENCRYPTION && tag.length > 1) {
        encryption = tag[1];
      } else if (tag.first == 't' && tag.length > 1) {
        tags.add(tag[1]);
      }
    }

    return FlashNews(
      id: map['id'] as String? ?? '',
      pubkey: map['pubkey'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isImportant: isImportant,
      encryption: encryption,
      source: source,
      createdAt: createdAt,
      formattedDate: dateFormat2.format(createdAt),
      isAuthentic: checkAuthenticity(encryption, createdAt),
      tags: tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pubkey,
        content,
        isImportant,
        encryption,
        source,
        createdAt,
        formattedDate,
        isAuthentic,
        tags,
      ];
}

abstract class BaseEventModel extends Equatable {
  final DateTime createdAt;
  final String pubkey;
  final String id;

  const BaseEventModel({
    required this.createdAt,
    required this.pubkey,
    required this.id,
  });

  @override
  List<Object?> get props => [createdAt, pubkey, id];
}

class LightMetadata implements BaseEventModel {
  @override
  final DateTime createdAt;
  @override
  final String pubkey;
  @override
  final String id;

  const LightMetadata({
    required this.createdAt,
    required this.pubkey,
    required this.id,
  });

  @override
  factory LightMetadata.fromMetadata(Metadata metadata) {
    return LightMetadata(
      createdAt: DateTime.fromMillisecondsSinceEpoch(metadata.createdAt * 1000),
      pubkey: metadata.pubkey,
      id: metadata.pubkey,
    );
  }

  String getNProfile() {
    return Nip19.encodeShareableEntity(
      'nprofile',
      '',
      [],
      pubkey,
      EventKind.METADATA,
    );
  }

  @override
  bool? get stringify => throw UnimplementedError();

  @override
  List<Object?> get props => [
        createdAt,
        pubkey,
        id,
      ];
}
