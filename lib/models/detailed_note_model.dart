// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'flash_news_model.dart';

class DetailedNoteModel extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final String pubkey;
  final String content;
  @override
  final DateTime createdAt;
  final bool isRoot;
  final bool isQuote;
  final String replyTo;
  final String stringifiedEvent;
  final List<String> pTags;
  final bool isPaid;
  final String? originId;
  final bool? isOriginEtag;

  const DetailedNoteModel({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.createdAt,
    required this.isRoot,
    required this.isQuote,
    required this.replyTo,
    required this.stringifiedEvent,
    required this.pTags,
    required this.isPaid,
    this.originId,
    this.isOriginEtag,
  });

  String getNevent() {
    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      [],
      pubkey,
      EventKind.TEXT_NOTE,
    );
  }

  String getYakiHonneUrl() {
    return '${baseUrl}notes/${Nip19.encodeNote(id)}';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'content': content,
      'createdAt': createdAt.toSecondsSinceEpoch(),
      'id': id,
      'isRoot': isRoot,
      'isQuote': isQuote,
      'replyTo': replyTo,
      'originId': originId,
      'stringifiedEvent': stringifiedEvent,
      'pTags': pTags,
      'isPaid': isPaid,
      'isOriginEtag': isOriginEtag,
    };
  }

  factory DetailedNoteModel.fromMap(Map<String, dynamic> map) {
    return DetailedNoteModel(
      id: map['id'],
      pubkey: map['pubkey'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] * 1000),
      isRoot: map['isRoot'],
      isQuote: map['isQuote'],
      replyTo: map['replyTo'],
      stringifiedEvent: map['stringifiedEvent'],
      pTags: List<String>.from(map['pTags']),
      originId: map['originId'],
      isOriginEtag: map['isOriginEtag'],
      isPaid: map['isPaid'],
    );
  }

  factory DetailedNoteModel.fromEvent(Event event) {
    bool root = true;
    bool isQuote = false;
    String replyTo = '';
    String? originEventId;
    bool? isOriginEtag;
    bool isPaid = false;

    for (final tag in event.tags) {
      if (tag.isNotEmpty) {
        if (tag.first == 'e') {
          if (tag.length > 3 && (tag[3] == 'reply')) {
            root = false;
            replyTo = tag[1];
          } else if (tag.length > 3 && (tag[3] == 'root')) {
            root = false;
            isOriginEtag = true;
            originEventId = tag[1];
          }
        } else if (tag.first == 'a' && tag.length > 3 && tag[3] == 'root') {
          root = false;
          isOriginEtag = false;
          originEventId = tag[1];
        } else if (tag.first == 'q') {
          isQuote = true;
        } else if (tag.first == FN_ENCRYPTION && tag.length > 1) {
          isPaid = true;
        }
      }
    }

    if (replyTo.isNotEmpty &&
        (originEventId?.isNotEmpty ?? false) &&
        replyTo == originEventId) {
      root = false;
      replyTo = '';
    }

    return DetailedNoteModel(
      pubkey: event.pubkey,
      content: event.content,
      originId: originEventId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      id: event.id,
      isRoot: root,
      replyTo: replyTo,
      isQuote: isQuote,
      stringifiedEvent: event.toJsonString(),
      pTags: event.pTags
          .where(
            (p) => p.isNotEmpty,
          )
          .toList(),
      isPaid: isPaid,
      isOriginEtag: isOriginEtag,
    );
  }

  List<String> cleanPtags() {
    return pTags
        .where(
          (element) => element.isNotEmpty,
        )
        .toList();
  }

  List<List<String>> replyData() {
    final noteRoot = isRoot ? id : originId ?? id;

    final root = [
      if (isOriginEtag != null && !isOriginEtag!) 'a' else 'e',
      noteRoot,
      '',
      'root',
    ];

    return [
      root,
      if (!isRoot) ['e', id, '', 'reply'],
    ];
  }

  String toJson() => json.encode(toMap());

  factory DetailedNoteModel.fromJson(String note) =>
      DetailedNoteModel.fromMap(jsonDecode(note));

  @override
  List<Object?> get props => [
        id,
        pubkey,
        content,
        createdAt,
        isRoot,
        isQuote,
        replyTo,
        stringifiedEvent,
        pTags,
        isPaid,
        isOriginEtag,
      ];
}

class RepostModel extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final String pubkey;
  final String content;
  @override
  final DateTime createdAt;
  final Event event;

  const RepostModel({
    required this.id,
    required this.pubkey,
    required this.content,
    required this.createdAt,
    required this.event,
  });

  @override
  List<Object?> get props => [
        id,
        pubkey,
        content,
        createdAt,
        event,
      ];

  factory RepostModel.fromEvent(Event event) {
    return RepostModel(
      id: event.id,
      pubkey: event.pubkey,
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      event: event,
    );
  }

  Event? getRepostedEvent() {
    try {
      if (event.content.isNotEmpty) {
        return Event.fromJson(jsonDecode(event.content));
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
