// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

class VoteModel extends Equatable {
  final String eventId;
  final String pubkey;
  final bool vote;

  const VoteModel({
    required this.eventId,
    required this.pubkey,
    required this.vote,
  });

  factory VoteModel.fromEvent(Event event) {
    return VoteModel(
      eventId: event.id,
      pubkey: event.pubkey,
      vote: event.content == '+',
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        pubkey,
        vote,
      ];

  VoteModel copyWith({
    String? eventId,
    String? pubkey,
    bool? vote,
  }) {
    return VoteModel(
      eventId: eventId ?? this.eventId,
      pubkey: pubkey ?? this.pubkey,
      vote: vote ?? this.vote,
    );
  }
}
