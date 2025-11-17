// ignore_for_file: public_member_api_docs, sort_constructors_first, prefer_foreach
import 'package:nostr_core_enhanced/nostr/nostr.dart';

class MuteModel {
  final String pubkey;
  final Set<String> usersMutes;
  final Set<String> eventsMutes;

  MuteModel({
    required this.pubkey,
    required this.usersMutes,
    required this.eventsMutes,
  });

  factory MuteModel.fromEvent(Event event) {
    final pubkeys = <String>{};
    final events = <String>{};

    if (event.pTags.isNotEmpty) {
      for (final tag in event.pTags) {
        pubkeys.add(tag);
      }
    }

    if (event.eTags.isNotEmpty) {
      for (final tag in event.eTags) {
        events.add(tag);
      }
    }

    return MuteModel(
      pubkey: event.pubkey,
      usersMutes: pubkeys,
      eventsMutes: events,
    );
  }

  static MuteModel empty() {
    return MuteModel(
      pubkey: '',
      usersMutes: {},
      eventsMutes: {},
    );
  }

  MuteModel copyWith({
    String? pubkey,
    Set<String>? usersMutes,
    Set<String>? eventsMutes,
  }) {
    return MuteModel(
      pubkey: pubkey ?? this.pubkey,
      usersMutes: usersMutes ?? this.usersMutes,
      eventsMutes: eventsMutes ?? this.eventsMutes,
    );
  }
}
