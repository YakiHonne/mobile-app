// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../utils/utils.dart';
import 'flash_news_model.dart';

/// Represents image metadata from imeta tags
class ImageMeta extends Equatable {
  final String url;
  final String mimeType;
  final String blurhash;
  final String dimensions;
  final String alt;
  final String hash;
  final List<String> fallbackUrls;
  final List<UserAnnotation> annotations;

  const ImageMeta({
    required this.url,
    required this.mimeType,
    required this.blurhash,
    required this.dimensions,
    required this.alt,
    required this.hash,
    required this.fallbackUrls,
    required this.annotations,
  });

  @override
  List<Object?> get props => [
        url,
        mimeType,
        blurhash,
        dimensions,
        alt,
        hash,
        fallbackUrls,
        annotations,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'mimeType': mimeType,
      'blurhash': blurhash,
      'dimensions': dimensions,
      'alt': alt,
      'hash': hash,
      'fallbackUrls': fallbackUrls,
      'annotations': annotations.map((x) => x.toMap()).toList(),
    };
  }

  factory ImageMeta.fromMap(Map<String, dynamic> map) {
    return ImageMeta(
      url: map['url'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      blurhash: map['blurhash'] as String? ?? '',
      dimensions: map['dimensions'] as String? ?? '',
      alt: map['alt'] as String? ?? '',
      hash: map['hash'] as String? ?? '',
      fallbackUrls: List<String>.from(map['fallbackUrls'] ?? []),
      annotations: List<UserAnnotation>.from(
        (map['annotations'] ?? []).map<UserAnnotation>(
          (x) => UserAnnotation.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageMeta.fromJson(String source) =>
      ImageMeta.fromMap(json.decode(source) as Map<String, dynamic>);

  ImageMeta copyWith({
    String? url,
    String? mimeType,
    String? blurhash,
    String? dimensions,
    String? alt,
    String? hash,
    List<String>? fallbackUrls,
    List<UserAnnotation>? annotations,
  }) {
    return ImageMeta(
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      blurhash: blurhash ?? this.blurhash,
      dimensions: dimensions ?? this.dimensions,
      alt: alt ?? this.alt,
      hash: hash ?? this.hash,
      fallbackUrls: fallbackUrls ?? this.fallbackUrls,
      annotations: annotations ?? this.annotations,
    );
  }
}

/// Represents user annotations in images (tagged users with positions)
class UserAnnotation extends Equatable {
  final String pubkey;
  final double posX;
  final double posY;

  const UserAnnotation({
    required this.pubkey,
    required this.posX,
    required this.posY,
  });

  @override
  List<Object?> get props => [pubkey, posX, posY];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'posX': posX,
      'posY': posY,
    };
  }

  factory UserAnnotation.fromMap(Map<String, dynamic> map) {
    return UserAnnotation(
      pubkey: map['pubkey'] as String? ?? '',
      posX: map['posX'] as double? ?? 0.0,
      posY: map['posY'] as double? ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserAnnotation.fromJson(String source) =>
      UserAnnotation.fromMap(json.decode(source) as Map<String, dynamic>);

  factory UserAnnotation.fromString(String annotation) {
    final parts = annotation.split(':');
    if (parts.length >= 3) {
      return UserAnnotation(
        pubkey: parts[0],
        posX: double.tryParse(parts[1]) ?? 0.0,
        posY: double.tryParse(parts[2]) ?? 0.0,
      );
    }
    return const UserAnnotation(pubkey: '', posX: 0, posY: 0);
  }
}

class PictureModel extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final String pubkey;
  final int kind;
  final String content;
  @override
  final DateTime createdAt;
  final String title;
  final List<ImageMeta> images;
  final String contentWarningReason;
  final List<String> taggedUsers;
  final List<String> mediaTypes;
  final List<String> hashes;
  final List<String> hashtags;
  final String location;
  final String geohash;
  final String languageCode;
  final Set<String> relays;
  final String stringifiedEvent;

  const PictureModel({
    required this.id,
    required this.pubkey,
    required this.kind,
    required this.content,
    required this.createdAt,
    required this.title,
    required this.images,
    required this.contentWarningReason,
    required this.taggedUsers,
    required this.mediaTypes,
    required this.hashes,
    required this.hashtags,
    required this.location,
    required this.geohash,
    required this.languageCode,
    required this.relays,
    required this.stringifiedEvent,
  });

  bool get hasContentWarning => contentWarningReason.isNotEmpty;

  String getUrl() {
    return images.isNotEmpty ? images.first.url : '';
  }

  Future<String> getNeventWithRelays() async {
    final relays = await getEventSeenOnRelays(id: id, isReplaceable: false);

    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      relays,
      pubkey,
      kind,
    );
  }

  factory PictureModel.fromEvent(Event e, {String? relay}) {
    final pictureId = e.id;
    final pubkey = e.pubkey;
    final kind = e.kind;
    final content = e.content;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(e.createdAt * 1000);

    String title = '';
    String contentWarningReason = '';
    final List<ImageMeta> images = [];
    final List<String> taggedUsers = [];
    final List<String> mediaTypes = [];
    final List<String> hashes = [];
    final List<String> hashtags = [];
    String location = '';
    String geohash = '';
    String languageCode = '';

    for (final tag in e.tags) {
      if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'imeta') {
        // Parse imeta tag for image metadata
        String url = '';
        String mimeType = '';
        String blurhash = '';
        String dimensions = '';
        String alt = '';
        String hash = '';
        final List<String> fallbackUrls = [];
        final List<UserAnnotation> annotations = [];

        for (int i = 1; i < tag.length; i++) {
          final item = tag[i];
          if (item.startsWith('url ')) {
            url = item.substring(4);
          } else if (item.startsWith('m ')) {
            mimeType = item.substring(2);
          } else if (item.startsWith('blurhash ')) {
            blurhash = item.substring(9);
          } else if (item.startsWith('dim ')) {
            dimensions = item.substring(4);
          } else if (item.startsWith('alt ')) {
            alt = item.substring(4);
          } else if (item.startsWith('x ')) {
            hash = item.substring(2);
          } else if (item.startsWith('fallback ')) {
            fallbackUrls.add(item.substring(9));
          } else if (item.startsWith('annotate-user ')) {
            final annotationStr = item.substring(14);
            annotations.add(UserAnnotation.fromString(annotationStr));
          }
        }

        if (url.isNotEmpty) {
          images.add(ImageMeta(
            url: url,
            mimeType: mimeType,
            blurhash: blurhash,
            dimensions: dimensions,
            alt: alt,
            hash: hash,
            fallbackUrls: fallbackUrls,
            annotations: annotations,
          ));
        }
      } else if (tag.first == 'content-warning' && tag.length > 1) {
        contentWarningReason = tag[1].isNotEmpty ? tag[1] : 'Reason unknown';
      } else if (tag.first == 'p' && tag.length > 1) {
        taggedUsers.add(tag[1]);
      } else if (tag.first == 'm' && tag.length > 1) {
        mediaTypes.add(tag[1]);
      } else if (tag.first == 'x' && tag.length > 1) {
        hashes.add(tag[1]);
      } else if (tag.first == 't' && tag.length > 1) {
        hashtags.add(tag[1]);
      } else if (tag.first == 'location' && tag.length > 1) {
        location = tag[1];
      } else if (tag.first == 'g' && tag.length > 1) {
        geohash = tag[1];
      } else if (tag.first == 'l' && tag.length > 1) {
        languageCode = tag[1];
      }
    }

    return PictureModel(
      id: pictureId,
      pubkey: pubkey,
      kind: kind,
      content: content,
      createdAt: createdAt,
      title: title,
      images: images,
      contentWarningReason: contentWarningReason,
      taggedUsers: taggedUsers,
      mediaTypes: mediaTypes,
      hashes: hashes,
      hashtags: hashtags,
      location: location,
      geohash: geohash,
      languageCode: languageCode,
      relays: relay != null ? {relay} : {},
      stringifiedEvent: e.toJsonString(),
    );
  }

  PictureModel copyWith({
    String? id,
    String? pubkey,
    int? kind,
    String? content,
    DateTime? createdAt,
    String? title,
    List<ImageMeta>? images,
    String? contentWarningReason,
    List<String>? taggedUsers,
    List<String>? mediaTypes,
    List<String>? hashes,
    List<String>? hashtags,
    String? location,
    String? geohash,
    String? languageCode,
    Set<String>? relays,
    String? stringifiedEvent,
  }) {
    return PictureModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      images: images ?? this.images,
      contentWarningReason: contentWarningReason ?? this.contentWarningReason,
      taggedUsers: taggedUsers ?? this.taggedUsers,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      hashes: hashes ?? this.hashes,
      hashtags: hashtags ?? this.hashtags,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      languageCode: languageCode ?? this.languageCode,
      relays: relays ?? this.relays,
      stringifiedEvent: stringifiedEvent ?? this.stringifiedEvent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pubkey,
        kind,
        content,
        createdAt,
        title,
        images,
        contentWarningReason,
        taggedUsers,
        mediaTypes,
        hashes,
        hashtags,
        location,
        geohash,
        languageCode,
        relays,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pubkey': pubkey,
      'kind': kind,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'title': title,
      'images': images.map((x) => x.toMap()).toList(),
      'contentWarningReason': contentWarningReason,
      'taggedUsers': taggedUsers,
      'mediaTypes': mediaTypes,
      'hashes': hashes,
      'hashtags': hashtags,
      'location': location,
      'geohash': geohash,
      'languageCode': languageCode,
      'relays': relays.toList(),
      'stringifiedEvent': stringifiedEvent,
    };
  }

  String toJson() => json.encode(toMap());

  factory PictureModel.fromMap(Map<String, dynamic> map) {
    return PictureModel(
      id: map['id'] as String,
      pubkey: map['pubkey'] as String,
      kind: map['kind'] as int,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      title: map['title'] as String? ?? '',
      images: List<ImageMeta>.from(
        (map['images'] ?? []).map<ImageMeta>(
          (x) => ImageMeta.fromMap(x as Map<String, dynamic>),
        ),
      ),
      contentWarningReason: map['contentWarningReason'] as String? ?? '',
      taggedUsers: List<String>.from(map['taggedUsers'] ?? []),
      mediaTypes: List<String>.from(map['mediaTypes'] ?? []),
      hashes: List<String>.from(map['hashes'] ?? []),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      location: map['location'] as String? ?? '',
      geohash: map['geohash'] as String? ?? '',
      languageCode: map['languageCode'] as String? ?? '',
      relays: Set<String>.from(map['relays'] ?? []),
      stringifiedEvent: map['stringifiedEvent'] as String? ?? '',
    );
  }

  factory PictureModel.fromJson(String source) =>
      PictureModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String getScheme() {
    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      [],
      pubkey,
      kind,
    );
  }

  @override
  Future<String> getSchemeWithRelays() async {
    final relays = await getEventSeenOnRelays(id: id, isReplaceable: false);

    return Nip19.encodeShareableEntity(
      'nevent',
      id,
      relays,
      pubkey,
      kind,
    );
  }
}
