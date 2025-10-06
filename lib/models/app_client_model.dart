// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../utils/enums.dart';

class AppClientModel extends Equatable {
  final String identifier;
  final DateTime publishedAt;
  final DateTime createdAt;
  final String name;
  final List<int> supportedKinds;
  final String pubkey;
  final List<String> tags;
  final List<AppClientExtension> appClientExtensions;

  const AppClientModel({
    required this.identifier,
    required this.publishedAt,
    required this.createdAt,
    required this.name,
    required this.supportedKinds,
    required this.pubkey,
    required this.tags,
    required this.appClientExtensions,
  });

  factory AppClientModel.fromEvent(Event event) {
    final List<String> tags = [];
    String identifier = '';
    String name = '';
    String pubkey = event.pubkey;
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    DateTime publishedAt = createdAt;
    final List<AppClientExtension> appClientExtensions = [];
    final List<int> supportedKinds = [];

    for (final tag in event.tags) {
      final tagLength = tag.length;

      if (tag.first == 'd' && tagLength > 1 && identifier.isEmpty) {
        identifier = tag[1];
      } else if (tag.first == 't' && tagLength > 2) {
        tags.add(tag[1]);
      } else if (tag.first == 'p' && tagLength > 2) {
        pubkey = tag[1];
      } else if (tag.first == 'alt' && tagLength > 1) {
        name = tag[1].contains('Nostr App:')
            ? tag[1].split('Nostr App:').last.trim()
            : tag[1];
      } else if (tag.first == 'k' && tagLength > 2) {
        final kind = int.tryParse(tag[1]);
        if (kind != null) {
          supportedKinds.add(kind);
        }
      } else if (tag.first == 'published_at') {
        final time = tag[1];

        publishedAt = DateTime.fromMillisecondsSinceEpoch(
          time.length <= 10
              ? num.parse(time).toInt() * 1000
              : num.parse(time).toInt(),
        );
      } else if ((tag.first == 'web' ||
              tag.first == 'ios' ||
              tag.first == 'android' ||
              tag.first == 'linux') &&
          tagLength > 3) {
        final type = tag.first == 'web'
            ? AppClientExtensionType.web
            : tag.first == 'ios'
                ? AppClientExtensionType.ios
                : tag.first == 'android'
                    ? AppClientExtensionType.android
                    : AppClientExtensionType.linux;

        appClientExtensions.add(
          AppClientExtension(
            type: type,
            link: tag[1],
            scheme: tag[2],
          ),
        );
      }
    }

    return AppClientModel(
      identifier: identifier,
      publishedAt: publishedAt,
      createdAt: createdAt,
      name: name,
      supportedKinds: supportedKinds,
      pubkey: pubkey,
      tags: tags,
      appClientExtensions: appClientExtensions,
    );
  }

  @override
  List<Object?> get props => [
        identifier,
        publishedAt,
        createdAt,
        name,
        supportedKinds,
        pubkey,
        tags,
        appClientExtensions,
      ];
}

class AppClientExtension extends Equatable {
  final AppClientExtensionType type;
  final String link;
  final String scheme;

  const AppClientExtension({
    required this.type,
    required this.link,
    required this.scheme,
  });

  @override
  List<Object?> get props => [
        type,
        link,
        scheme,
      ];
}
