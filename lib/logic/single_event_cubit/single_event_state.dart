// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'single_event_cubit.dart';

class SingleEventState extends Equatable {
  final bool refresh;
  final Map<String, SealedNote> sealedNotes;
  final Map<String, List<PollStat>> pollStats;
  final Map<String, Event> events;

  const SingleEventState({
    required this.refresh,
    required this.sealedNotes,
    required this.pollStats,
    required this.events,
  });

  @override
  List<Object> get props => [
        refresh,
        sealedNotes,
        pollStats,
        events,
      ];

  SingleEventState copyWith({
    bool? refresh,
    Map<String, SealedNote>? sealedNotes,
    Map<String, List<PollStat>>? pollStats,
    Map<String, Event>? events,
  }) {
    return SingleEventState(
      refresh: refresh ?? this.refresh,
      sealedNotes: sealedNotes ?? this.sealedNotes,
      pollStats: pollStats ?? this.pollStats,
      events: events ?? this.events,
    );
  }
}
