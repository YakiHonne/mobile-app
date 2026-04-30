import 'package:nostr_core_enhanced/nostr/event.dart';

class UnpaidNote {
  UnpaidNote({
    required this.event,
    this.relays,
  });

  factory UnpaidNote.fromJson(Map<String, dynamic> json) {
    return UnpaidNote(
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      relays: json['relays'] != null
          ? List<String>.from(json['relays'] as List<dynamic>)
          : null,
    );
  }

  final Event event;
  final List<String>? relays;

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'relays': relays,
    };
  }
}
