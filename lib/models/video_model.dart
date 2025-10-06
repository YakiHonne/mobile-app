// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'article_model.dart';
import 'flash_news_model.dart';

class VideoModel extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final String pubkey;
  final int kind;
  final String title;
  final String summary;
  final String alt;
  final String thumbnail;
  final String placeHolder;
  @override
  final DateTime createdAt;
  final DateTime publishedAt;
  final String url;
  final num duration;
  final String mimeType;
  final List<String> tags;
  final List<String> participants;
  final bool isHorizontal;
  final List<ZapSplit> zapsSplits;
  final bool contentWarning;
  final Set<String> relays;
  final String stringifiedEvent;

  const VideoModel({
    required this.id,
    required this.pubkey,
    required this.kind,
    required this.title,
    required this.summary,
    required this.alt,
    required this.thumbnail,
    required this.placeHolder,
    required this.createdAt,
    required this.publishedAt,
    required this.url,
    required this.duration,
    required this.mimeType,
    required this.tags,
    required this.participants,
    required this.isHorizontal,
    required this.zapsSplits,
    required this.contentWarning,
    required this.relays,
    required this.stringifiedEvent,
  });

  String getNevent() {
    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      [],
      pubkey,
      kind,
    );
  }

  bool isHorizontalVideo() => kind == EventKind.VIDEO_HORIZONTAL;

  factory VideoModel.fromEvent(Event e, {String? relay}) {
    final videoId = e.id;
    final pubkey = e.pubkey;
    final kind = e.kind;
    final summary = e.content;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(e.createdAt * 1000);
    DateTime publishedAt = createdAt;

    String title = '';
    String alt = '';
    String thumbnail = '';
    String url = '';
    num duration = 0;
    String mimeType = '';
    final bool isHorizontal = e.kind == EventKind.VIDEO_HORIZONTAL;
    final List<String> tags = [];
    bool contentWarning = false;
    final List<String> participants = [];
    final List<ZapSplit> zaps = [];

    for (final tag in e.tags) {
      if (tag.first == 'url' && tag.length > 1) {
        url = tag[1];
      } else if (tag.first == 'published_at' && tag.length > 1) {
        publishedAt = DateTime.fromMillisecondsSinceEpoch(
            num.parse(tag[1]).toInt() * 1000);
      } else if (tag.first == 'thumb' && tag.length > 1) {
        thumbnail = tag[1];
      } else if (tag.first == 'alt' && tag.length > 1) {
        alt = tag[1];
      } else if (tag.first == 'm' && tag.length > 1) {
        mimeType = tag[1];
      } else if (tag.first == 'duration' && tag.length > 1) {
        duration = num.tryParse(tag[1]) ?? 0;
      } else if (tag.first == 't' && tag.length > 1) {
        tags.add(tag[1]);
      } else if (tag.first == 'p' && tag.length > 1) {
        participants.add(tag[1]);
      } else if (tag.first == 'zap' && tag.length > 1) {
        zaps.add(
          ZapSplit(pubkey: tag[1], percentage: int.tryParse(tag[3]) ?? 0),
        );
      } else if (tag.first == 'content-warning' && tag.length > 1) {
        contentWarning = true;
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'imeta' && tag.length > 1) {
        for (final t in tag) {
          if (t.startsWith('url')) {
            url = t.split(' ').last;
          }

          if (t.startsWith('m')) {
            mimeType = t.split(' ').last;
          }

          if (t.startsWith('image')) {
            thumbnail = t.split(' ').last;
          }
        }
      }
    }

    const placeHolder = RandomCovers.videoThumbnail;

    return VideoModel(
      id: videoId,
      pubkey: pubkey,
      kind: kind,
      title: title,
      summary: summary,
      alt: alt,
      thumbnail: thumbnail,
      placeHolder: placeHolder,
      createdAt: createdAt,
      publishedAt: publishedAt,
      url: url,
      duration: duration,
      mimeType: mimeType,
      tags: tags,
      participants: participants,
      isHorizontal: isHorizontal,
      zapsSplits: zaps,
      contentWarning: contentWarning,
      relays: relay != null ? {relay} : {},
      stringifiedEvent: e.toJsonString(),
    );
  }

  VideoModel copyWith({
    String? id,
    String? identifier,
    String? pubKey,
    int? kind,
    String? title,
    String? summary,
    String? alt,
    String? thumbnail,
    String? placeHolder,
    DateTime? createdAt,
    DateTime? publishedAt,
    String? url,
    num? duration,
    String? mimeType,
    List<String>? tags,
    List<String>? participants,
    bool? isHorizontal,
    List<ZapSplit>? zapsSplits,
    bool? contentWarning,
    Set<String>? relays,
    String? stringifiedEvent,
  }) {
    return VideoModel(
      id: id ?? this.id,
      pubkey: pubKey ?? pubkey,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      alt: alt ?? this.alt,
      thumbnail: thumbnail ?? this.thumbnail,
      placeHolder: placeHolder ?? this.placeHolder,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      mimeType: mimeType ?? this.mimeType,
      tags: tags ?? this.tags,
      participants: participants ?? this.participants,
      isHorizontal: isHorizontal ?? this.isHorizontal,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      contentWarning: contentWarning ?? this.contentWarning,
      relays: relays ?? this.relays,
      stringifiedEvent: stringifiedEvent ?? this.stringifiedEvent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pubkey,
        kind,
        title,
        summary,
        alt,
        thumbnail,
        placeHolder,
        createdAt,
        publishedAt,
        url,
        duration,
        mimeType,
        tags,
        participants,
        isHorizontal,
        zapsSplits,
        contentWarning,
        relays,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'videoId': id,
      'pubkey': pubkey,
      'kind': kind,
      'title': title,
      'summary': summary,
      'alt': alt,
      'thumbnail': thumbnail,
      'placeHolder': placeHolder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'publishedAt': publishedAt.millisecondsSinceEpoch,
      'url': url,
      'duration': duration,
      'mimeType': mimeType,
      'tags': tags,
      'participants': participants,
      'isHorizontal': isHorizontal,
      'zapsSplits': zapsSplits.map((x) => x.toMap()).toList(),
      'contentWarning': contentWarning,
      'relays': relays.toList(),
      'stringifiedEvent': stringifiedEvent,
    };
  }

  String toJson() => json.encode(toMap());

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['videoId'] as String,
      pubkey: map['pubkey'] as String,
      kind: map['kind'] as int,
      title: map['title'] as String,
      summary: map['summary'] as String,
      alt: map['alt'] as String,
      thumbnail: map['thumbnail'] as String,
      placeHolder: map['placeHolder'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      publishedAt:
          DateTime.fromMillisecondsSinceEpoch(map['publishedAt'] as int),
      url: map['url'] as String,
      duration: map['duration'] as num,
      mimeType: map['mimeType'] as String,
      tags: List<String>.from(map['tags']),
      participants: List<String>.from(map['participants']),
      isHorizontal: map['isHorizontal'] as bool,
      zapsSplits: List<ZapSplit>.from(
        map['zapsSplits'].map<ZapSplit>(
          (x) => ZapSplit.fromMap(x as Map<String, dynamic>),
        ),
      ),
      contentWarning: map['contentWarning'] as bool? ?? false,
      relays: Set<String>.from(
        map['relays'],
      ),
      stringifiedEvent: map['stringifiedEvent'] as String? ?? '',
    );
  }

  factory VideoModel.fromJson(String source) =>
      VideoModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
