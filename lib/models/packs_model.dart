import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../utils/constants.dart';

class PacksModel {
  PacksModel({
    required this.id,
    required this.identifier,
    required this.title,
    required this.description,
    required this.image,
    required this.pubkey,
    required this.createdAt,
    required this.pubkeys,
    required this.kind,
  });
  factory PacksModel.fromMap(Map<String, dynamic> map) {
    return PacksModel(
      id: map['id'] as String,
      identifier: map['identifier'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      image: map['image'] as String,
      pubkey: map['pubkey'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      pubkeys: Set<String>.from(map['pubkeys'] as List),
      kind: map['kind'] as int,
    );
  }

  factory PacksModel.fromEvent(Event event) {
    String identifier = '';
    String title = '';
    String description = '';
    String image = '';

    for (final tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1) {
        identifier = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      }
    }

    return PacksModel(
      id: event.id,
      identifier: identifier,
      title: title,
      description: description,
      image: image,
      pubkey: event.pubkey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      pubkeys: event.pTags.toSet(),
      kind: event.kind,
    );
  }

  final String id;
  final String identifier;
  final String title;
  final String description;
  final String image;
  final String pubkey;
  final DateTime createdAt;
  final Set<String> pubkeys;
  final int kind;

  bool isStarterPack() => kind == EventKind.STARTER_PACKS;
  bool isMediaPack() => kind == EventKind.MEDIA_PACKS;

  String aTag() {
    return '$kind:$pubkey:$identifier';
  }

  String get url {
    final uri = Uri(
      scheme: 'https',
      host: baseUrl2,
      path: '/pack/${isStarterPack() ? 's' : 'm'}',
      queryParameters: {
        'd': identifier,
      },
    );
    return uri.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identifier': identifier,
      'title': title,
      'description': description,
      'image': image,
      'pubkey': pubkey,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'pubkeys': pubkeys.toList(),
      'kind': kind,
    };
  }
}
