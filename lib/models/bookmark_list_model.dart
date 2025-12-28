// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../utils/utils.dart';
import 'flash_news_model.dart';

class BookmarkListModel implements BaseEventModel {
  @override
  final String id;
  final String title;
  final String description;
  final String image;
  final String identifier;
  final List<EventCoordinates> bookmarkedReplaceableEvents;
  final List<String> bookmarkedEvents;
  final List<BookmarkOtherType> bookmarkedUrls;
  final List<BookmarkOtherType> bookmarkedTags;
  @override
  final String pubkey;
  @override
  final DateTime createdAt;
  final String stringifiedEvent;

  BookmarkListModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.identifier,
    required this.bookmarkedReplaceableEvents,
    required this.bookmarkedEvents,
    required this.pubkey,
    required this.createdAt,
    required this.stringifiedEvent,
    required this.bookmarkedUrls,
    required this.bookmarkedTags,
  });

  bool isReplaceableEventAvailable({
    required String identifier,
    required bool isReplaceableEvent,
  }) {
    if (isReplaceableEvent) {
      for (final event in bookmarkedReplaceableEvents) {
        if (event.identifier == identifier) {
          return true;
        }
      }
    } else {
      for (final eventId in bookmarkedEvents) {
        if (eventId == identifier) {
          return true;
        }
      }
    }

    return false;
  }

  bool isTagAvailable({required String tag}) {
    return bookmarkedTags.where((element) => element.val == tag).isNotEmpty;
  }

  bool isUrlAvailable({required String url}) {
    return bookmarkedUrls.where((element) => element.val == url).isNotEmpty;
  }

  Future<Event?> bookmarkListModelToEvent() async {
    try {
      final replaceableEvents = bookmarkedReplaceableEvents
          .map((e) => Nip33.coordinatesToTag(e))
          .toList();

      final events = bookmarkedEvents
          .map(
            (event) => ['e', event],
          )
          .toList();

      return await Event.genEvent(
        kind: EventKind.CATEGORIZED_BOOKMARK,
        tags: [
          ['d', identifier],
          ['title', title],
          ['description', description],
          if (image.isNotEmpty) ['image', image],
          ...replaceableEvents,
          ...events,
          ...bookmarkedUrls.map((url) => ['r', url.val, url.description]),
          ...bookmarkedTags.map((tag) => ['t', tag.val]),
          // ['t', 'Yakihonne'],
          // ['r', 'https://yakihonne.com', 'A nostr client']
        ],
        content: '',
        signer: currentSigner,
      );
    } catch (_) {
      return null;
    }
  }

  factory BookmarkListModel.fromEvent(Event event) {
    String identifier = '';
    String title = '';
    String description = '';
    String image = '';
    final List<EventCoordinates> bookmarkedReplaceableEvents = [];
    final List<String> bookmarkedEvents = [];
    final List<BookmarkOtherType> bookmarkedUrls = [];
    final List<BookmarkOtherType> bookmarkedTags = [];

    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

    for (final tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1];
      } else if (tag.first == 'title' && tag.length > 1) {
        title = tag[1];
      } else if (tag.first == 'description' && tag.length > 1) {
        description = tag[1];
      } else if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'a') {
        final c = Nip33.getEventCoordinates(tag);
        if (c != null) {
          bookmarkedReplaceableEvents.add(c);
        }
      } else if (tag.first == 'e') {
        bookmarkedEvents.add(tag[1]);
      } else if (tag.first == 'r') {
        bookmarkedUrls.add(BookmarkOtherType(
          val: tag[1],
          isTag: false,
          description: tag.length > 2 ? tag[2] : '',
          createdAt: createdAt,
          pubkey: event.pubkey,
          id: event.id,
        ));
      } else if (tag.first == 't') {
        bookmarkedTags.add(BookmarkOtherType(
          val: tag[1],
          isTag: true,
          description: '',
          createdAt: createdAt,
          pubkey: event.pubkey,
          id: event.id,
        ));
      }
    }

    return BookmarkListModel(
      id: event.id,
      title: title,
      identifier: identifier,
      description: description,
      image: image,
      bookmarkedReplaceableEvents: bookmarkedReplaceableEvents,
      bookmarkedEvents: bookmarkedEvents,
      bookmarkedUrls: bookmarkedUrls,
      bookmarkedTags: bookmarkedTags,
      pubkey: event.pubkey,
      createdAt: createdAt,
      stringifiedEvent: event.toJsonString(),
    );
  }

  BookmarkListModel copyWith({
    String? id,
    String? title,
    String? description,
    String? image,
    String? placeholder,
    String? identifier,
    List<EventCoordinates>? bookmarkedReplaceableEvents,
    List<String>? bookmarkedEvents,
    List<BookmarkOtherType>? bookmarkedUrls,
    List<BookmarkOtherType>? bookmarkedTags,
    String? pubkey,
    DateTime? createdAt,
    String? stringifiedEvent,
  }) {
    return BookmarkListModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      identifier: identifier ?? this.identifier,
      bookmarkedReplaceableEvents:
          bookmarkedReplaceableEvents ?? this.bookmarkedReplaceableEvents,
      bookmarkedEvents: bookmarkedEvents ?? this.bookmarkedEvents,
      bookmarkedUrls: bookmarkedUrls ?? this.bookmarkedUrls,
      bookmarkedTags: bookmarkedTags ?? this.bookmarkedTags,
      pubkey: pubkey ?? this.pubkey,
      createdAt: createdAt ?? this.createdAt,
      stringifiedEvent: stringifiedEvent ?? this.stringifiedEvent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        image,
        identifier,
        bookmarkedReplaceableEvents,
        bookmarkedEvents,
        bookmarkedUrls,
        bookmarkedTags,
        pubkey,
        createdAt,
        stringifiedEvent,
      ];

  @override
  bool? get stringify => throw UnimplementedError();

  @override
  String getScheme() {
    return '';
  }

  @override
  Future<String> getSchemeWithRelays() async {
    return '';
  }
}

class BookmarkOtherType extends BaseEventModel {
  const BookmarkOtherType({
    required super.createdAt,
    required super.pubkey,
    required super.id,
    required this.val,
    required this.isTag,
    required this.description,
  });

  final String val;
  final bool isTag;
  final String description;

  @override
  String getScheme() {
    return '';
  }

  @override
  Future<String> getSchemeWithRelays() async {
    return '';
  }
}
