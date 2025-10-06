// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'unsent_events_cubit.dart';

class UnsentEventsState extends Equatable {
  final Map<String, Event> events;
  final Map<String, String> pubkeys;

  const UnsentEventsState({
    this.events = const {},
    this.pubkeys = const {},
  });

  @override
  List<Object> get props => [events, pubkeys];

  UnsentEventsState copyWith({
    Map<String, Event>? events,
    Map<String, String>? pubkeys,
  }) {
    return UnsentEventsState(
      events: events ?? this.events,
      pubkeys: pubkeys ?? this.pubkeys,
    );
  }
}
