import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';

class RelayReview extends Equatable {
  const RelayReview({
    required this.id,
    required this.identifier,
    required this.pubkey,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory RelayReview.fromEvent(Event event) {
    String identifier = '';
    num rating = -1;

    for (final tag in event.tags) {
      if (tag.first == 'd' && tag.length > 1) {
        identifier = tag[1];
      }
      if (tag.first == 'rating' && tag.length > 1) {
        rating = num.parse(tag[1]) * 5;
      }
    }

    return RelayReview(
      id: event.id,
      identifier: identifier,
      pubkey: event.pubkey,
      comment: event.content,
      rating: rating,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  final String id;
  final String identifier;
  final num rating;
  final String pubkey;
  final String comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        identifier,
        pubkey,
        comment,
        createdAt,
      ];
}
