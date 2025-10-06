// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'article_model.dart';
import 'flash_news_model.dart';

class Curation extends Equatable implements BaseEventModel {
  @override
  final String id;
  final String identifier;
  @override
  final String pubkey;
  final String title;
  final String description;
  final String image;
  @override
  final DateTime createdAt;
  final DateTime publishedAt;
  final List<EventCoordinates> eventsIds;
  final Set<String> relays;
  final bool isSensitive;
  final String placeHolder;
  final int kind;
  final String client;
  final List<ZapSplit> zapsSplits;
  final List<String> tags;
  final String stringifiedEvent;

  const Curation({
    required this.id,
    required this.identifier,
    required this.pubkey,
    required this.title,
    required this.description,
    required this.image,
    required this.isSensitive,
    required this.createdAt,
    required this.publishedAt,
    required this.eventsIds,
    required this.relays,
    required this.tags,
    this.placeHolder = '',
    required this.kind,
    required this.client,
    required this.zapsSplits,
    required this.stringifiedEvent,
  });

  bool isArticleCuration() => kind == EventKind.CURATION_ARTICLES;

  String getNaddr() {
    final List<int> charCodes = identifier.runes.toList();
    final special = charCodes.map((code) => code.toRadixString(16)).join();

    return Nip19.encodeShareableEntity(
      'naddr',
      special,
      [],
      pubkey,
      kind,
    );
  }

  factory Curation.fromEvent(Event event, String relay) {
    String identifier = '';
    String title = '';
    String description = '';
    String image = '';
    String client = '';
    bool isSensitive = false;
    final List<EventCoordinates> eventsIds = [];
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    DateTime publishedAt = createdAt;
    final List<ZapSplit> zaps = [];
    final List<String> tags = [];

    for (final tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'client' && tag.length > 1) {
        client = tag[1];
      } else if (tag.first == 't' && tag.length > 1) {
        tags.add(tag[1]);
      } else if (tag.first == 'a') {
        final c = Nip33.getEventCoordinates(tag);
        if (c != null) {
          eventsIds.add(c);
        }
      } else if (tag.first == 'zap' && tag.length > 1) {
        zaps.add(
          ZapSplit(pubkey: tag[1], percentage: int.tryParse(tag[3]) ?? 0),
        );
      } else if (tag.first.toLowerCase() == 'l' &&
          tag.length > 1 &&
          tag[1] == 'content-warning') {
        isSensitive = true;
      } else if (tag.first == 'published_at') {
        final time = tag[1];

        if (time.isNotEmpty) {
          publishedAt = DateTime.fromMillisecondsSinceEpoch(
            time.length <= 10
                ? num.parse(time).toInt() * 1000
                : num.parse(time).toInt(),
          );
        }
      }
    }

    final placeHolder = getRandomPlaceholder(
      input: identifier,
      isPfp: false,
    );

    return Curation(
      id: event.id,
      kind: event.kind,
      identifier: identifier,
      isSensitive: isSensitive,
      pubkey: event.pubkey,
      title: title,
      description: description,
      image: image,
      eventsIds: eventsIds,
      createdAt: createdAt,
      tags: tags,
      publishedAt: publishedAt,
      placeHolder: placeHolder,
      zapsSplits: zaps,
      client: client,
      relays: {relay},
      stringifiedEvent: event.toJsonString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        identifier,
        pubkey,
        title,
        description,
        image,
        tags,
        isSensitive,
        createdAt,
        publishedAt,
        eventsIds,
        relays,
        placeHolder,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'eventId': id,
      'kind': kind,
      'identifier': identifier,
      'pubkey': pubkey,
      'title': title,
      'description': description,
      'image': image,
      'createdAt': createdAt.toSecondsSinceEpoch(),
      'publishedAt': publishedAt.toSecondsSinceEpoch(),
      'eventsIds': eventsIds.map((x) => x.toMap()).toList(),
      'relays': relays.toList(),
      'tags': tags,
      'client': client,
      'isSensitive': isSensitive,
      'placeHolder': placeHolder,
      'stringifiedEvent': stringifiedEvent,
    };
  }

  factory Curation.fromMap(Map<String, dynamic> map) {
    return Curation(
      id: map['eventId'] as String,
      kind: map['kind'] as int,
      client: map['client'] as String,
      identifier: map['identifier'] as String,
      pubkey: map['pubkey'] as String,
      title: map['title'] as String,
      tags: List<String>.from(map['tags'] as List? ?? []),
      zapsSplits: List<ZapSplit>.from(map['zapSplits'] as List? ?? []),
      description: map['description'] as String,
      image: map['image'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as int) * 1000),
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['publishedAt'] as int) * 1000,
      ),
      isSensitive: map['isSensitive'] as bool? ?? false,
      eventsIds: List<EventCoordinates>.from(
        (map['eventsIds'] as List).map<EventCoordinates>(
          (x) => EventCoordinates.fromMap(x),
        ),
      ),
      relays: Set<String>.from(map['relays']),
      placeHolder: map['placeHolder'] as String,
      stringifiedEvent: map['stringifiedEvent'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Curation.curation(String source) =>
      Curation.fromMap(json.decode(source) as Map<String, dynamic>);

  Curation copyWith({
    String? id,
    String? identifier,
    String? pubkey,
    String? title,
    String? description,
    String? image,
    DateTime? createdAt,
    DateTime? publishedAt,
    String? client,
    List<EventCoordinates>? eventsIds,
    Set<String>? relays,
    bool? isSensitive,
    String? placeHolder,
    List<String>? tags,
    int? kind,
    List<ZapSplit>? zapsSplits,
    String? stringifiedEvent,
  }) {
    return Curation(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      pubkey: pubkey ?? this.pubkey,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      isSensitive: isSensitive ?? this.isSensitive,
      description: description ?? this.description,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      eventsIds: eventsIds ?? this.eventsIds,
      relays: relays ?? this.relays,
      placeHolder: placeHolder ?? this.placeHolder,
      kind: kind ?? this.kind,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      client: client ?? this.client,
      stringifiedEvent: stringifiedEvent ?? this.stringifiedEvent,
    );
  }
}
