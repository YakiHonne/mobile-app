// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart'
    show EventKind;

import '../utils/utils.dart';

class RelayFeeds extends Equatable {
  final List<String> favoriteRelays;
  final List<EventCoordinates> events;

  const RelayFeeds({
    required this.favoriteRelays,
    required this.events,
  });

  factory RelayFeeds.fromEvent(Event event) {
    final favoriteRelays = <String>[];
    final events = <EventCoordinates>[];

    for (final t in event.tags) {
      if (t.first == 'relay' && t.length > 1) {
        favoriteRelays.add(t[1]);
      } else if (t.first == 'a' && t.length > 1) {
        final c = t[1];
        final elements = c.split(':');

        events.add(
          EventCoordinates(
            int.tryParse(elements[0]) ?? 0,
            elements[1],
            elements[2],
            null,
          ),
        );
      }
    }

    return RelayFeeds(
      favoriteRelays: favoriteRelays,
      events: events,
    );
  }

  Future<Event?> toEvent() async {
    return Event.genEvent(
      kind: EventKind.FAVORITE_RELAYS,
      tags: [
        for (final relay in favoriteRelays) ['relay', relay],
        for (final event in events)
          ['a', '${event.kind}:${event.pubkey}:${event.identifier}'],
      ],
      content: '',
      signer: currentSigner,
    );
  }

  @override
  List<Object?> get props => [favoriteRelays, events];

  RelayFeeds copyWith({
    List<String>? favoriteRelays,
    List<EventCoordinates>? events,
  }) {
    return RelayFeeds(
      favoriteRelays: favoriteRelays ?? this.favoriteRelays,
      events: events ?? this.events,
    );
  }
}

class UserRelaySet {
  final String id;
  final String identifier;
  final String pubkey;
  final DateTime createdAt;
  final String title;
  final String description;
  final String image;
  final List<String> relays;

  UserRelaySet({
    required this.id,
    required this.identifier,
    required this.pubkey,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.image,
    required this.relays,
  });

  UserRelaySet copyWith({
    String? id,
    String? identifier,
    String? pubkey,
    DateTime? createdAt,
    String? title,
    String? description,
    String? image,
    List<String>? relays,
  }) {
    return UserRelaySet(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      description: description ?? this.description,
      pubkey: pubkey ?? this.pubkey,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      image: image ?? this.image,
      relays: relays ?? this.relays,
    );
  }

  factory UserRelaySet.fromEvent(Event event) {
    String title = '';
    String image = '';
    String description = '';
    final relays = <String>[];

    for (final t in event.tags) {
      if (t.first == 'relay' && t.length > 1) {
        relays.add(t[1]);
      } else if (t.first == 'title' && t.length > 1) {
        title = t[1];
      } else if (t.first == 'image' && t.length > 1) {
        image = t[1];
      } else if (t.first == 'description' && t.length > 1) {
        description = t[1];
      }
    }

    return UserRelaySet(
      id: event.id,
      identifier: event.dTag ?? '',
      pubkey: event.pubkey,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      title: title,
      description: description,
      image: image,
      relays: relays,
    );
  }

  String getTitle() {
    return title.isNotEmpty
        ? title
        : '${relays.first.nineCharacters()}...${relays.last.nineCharacters()}';
  }

  String getDescription() {
    return description.isNotEmpty ? description : getTitle();
  }

  EventCoordinates toEventCoordinates() {
    return EventCoordinates(
      EventKind.RELAY_SET,
      pubkey,
      identifier,
      null,
    );
  }
}
