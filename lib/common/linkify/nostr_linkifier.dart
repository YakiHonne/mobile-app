import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../common_regex.dart';
import 'linkify.dart';

class NostrSchemeLinkifier extends Linkifier {
  const NostrSchemeLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement && element.text.isNotEmpty) {
        _parseNostrSchemes(element.text, result);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  void _parseNostrSchemes(
    String text,
    List<LinkifyElement> result,
  ) {
    final matches = nostrSchemeRegex.allMatches(text);

    int currentIndex = 0;

    for (final match in matches) {
      // Add the text before the match
      if (match.start > currentIndex) {
        result.add(TextElement(text.substring(currentIndex, match.start)));
      }

      // Process the matched element asynchronously
      final element = _createNostrElement(match);
      result.add(element);

      currentIndex = match.end;
    }

    // Add any remaining text after the last match
    if (currentIndex < text.length) {
      result.add(TextElement(text.substring(currentIndex)));
    }
  }

  LinkifyElement _createNostrElement(Match match) {
    final prefix = match.group(2);
    final suffix = match.group(3);

    if (prefix == null || suffix == null || prefix.isEmpty || suffix.isEmpty) {
      return TextElement(match.group(0) ?? '');
    }

    final fullKey = prefix + suffix;

    try {
      switch (prefix) {
        case 'npub1':
          return _createUserElement(fullKey);
        case 'nprofile1':
          return _createProfileElement(fullKey);
        case 'note1':
          return _createNoteElement(fullKey);
        case 'naddr1':
          return _createAddressElement(fullKey);
        case 'nevent1':
          return _createEventElement(fullKey);
        default:
          return TextElement(fullKey);
      }
    } catch (e) {
      debugPrint('Error parsing Nostr scheme: $e');
      return TextElement(fullKey);
    }
  }

  UserSchemeElement _createUserElement(String fullKey) {
    if (fullKey.length != 63) {
      return UserSchemeElement('', fullKey);
    }

    final pubkey = Nip19.decodePubkey(fullKey);

    return UserSchemeElement(
      pubkey,
    );
  }

  LinkifyElement _createProfileElement(String fullKey) {
    final entity = Nip19.decodeShareableEntity(fullKey);

    if (entity.isEmpty) {
      return TextElement(fullKey);
    }

    final pubkey = entity['special'] as String?;

    return UserSchemeElement(
      pubkey ?? '',
    );
  }

  LinkifyElement _createNoteElement(String fullKey) {
    final noteId = Nip19.decodeNote(fullKey);

    return NoteElement(
      noteId,
    );
  }

  LinkifyElement _createAddressElement(String fullKey) {
    final entity = Nip19.decodeShareableEntity(fullKey);
    final eventKind = entity['kind'];

    if (!_isValidEventKind(eventKind)) {
      return TextElement(fullKey);
    }

    final hexCode = hex.decode(entity['special']);
    final eventIdentifier = String.fromCharCodes(hexCode);

    return _createElementFromEventKind(eventKind, eventIdentifier, fullKey);
  }

  LinkifyElement _createEventElement(String fullKey) {
    final entity = Nip19.decodeShareableEntity(fullKey);
    final eventId = entity['special'] as String?;

    return Neventlement(eventId ?? '', fullKey);
  }

  bool _isValidEventKind(dynamic eventKind) {
    return eventKind == EventKind.LONG_FORM ||
        eventKind == EventKind.VIDEO_HORIZONTAL ||
        eventKind == EventKind.VIDEO_VERTICAL ||
        eventKind == EventKind.SMART_WIDGET_ENH ||
        eventKind == EventKind.CURATION_ARTICLES ||
        eventKind == EventKind.CURATION_VIDEOS;
  }

  LinkifyElement _createElementFromEventKind(
    int eventKind,
    String identifier,
    String fullKey,
  ) {
    switch (eventKind) {
      case EventKind.LONG_FORM:
        return ArtCurSchemeElement(
          identifier,
          'article',
          fullKey,
        );

      case EventKind.VIDEO_HORIZONTAL:
        return ArtCurSchemeElement(
          identifier,
          'video',
          fullKey,
        );
      case EventKind.VIDEO_VERTICAL:
        return ArtCurSchemeElement(
          identifier,
          'video',
          fullKey,
        );

      case EventKind.SMART_WIDGET_ENH:
        return ArtCurSchemeElement(
          identifier,
          'smart-widget',
          fullKey,
        );

      default:
        return ArtCurSchemeElement(
          identifier,
          'curation',
          fullKey,
        );
    }
  }
}

/// Custom element classes with improved immutability
@immutable
class UserSchemeElement extends LinkableElement {
  const UserSchemeElement(String url, [String? text]) : super(text, url);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSchemeElement && other.text == text && other.url == url);

  @override
  String toString() => "user: '$url'";
}

@immutable
class ArtCurSchemeElement extends LinkableElement {
  const ArtCurSchemeElement(String url, this.kind, [String? text])
      : super(text, url);

  final String kind;

  @override
  int get hashCode => Object.hash(text, url, kind);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtCurSchemeElement &&
          other.text == text &&
          other.url == url &&
          other.kind == kind);

  @override
  String toString() => "$kind: '$url' ($text)";
}

@immutable
class NoteElement extends LinkableElement {
  const NoteElement(String url, [String? text]) : super(text, url);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteElement && other.text == text && other.url == url);

  @override
  String toString() => "note: '$url' ($text)";
}

@immutable
class Neventlement extends LinkableElement {
  const Neventlement(String url, [String? text]) : super(text, url);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Neventlement && other.text == text && other.url == url);

  @override
  String toString() => "note: '$url' ($text)";
}

@immutable
class ZapPollElement extends LinkableElement {
  const ZapPollElement(String url, [String? text]) : super(text, url);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZapPollElement && other.text == text && other.url == url);

  @override
  String toString() => "zapPoll: '$url' ($text)";
}
