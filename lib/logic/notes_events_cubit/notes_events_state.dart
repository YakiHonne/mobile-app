// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notes_events_cubit.dart';

class NotesEventsState extends Equatable {
  final Map<String, EventStats> eventsStats;
  final Map<String, List<DetailedNoteModel>> previousNotes;
  final List<String> mutes;
  final List<String> mutesEvents;
  final Set<String> bookmarks;
  final Set<String> deletedNotes;

  const NotesEventsState({
    required this.eventsStats,
    required this.previousNotes,
    required this.mutes,
    required this.mutesEvents,
    required this.bookmarks,
    required this.deletedNotes,
  });

  @override
  List<Object> get props => [
        previousNotes,
        mutes,
        mutesEvents,
        bookmarks,
        eventsStats,
        deletedNotes,
      ];

  NotesEventsState copyWith({
    Map<String, EventStats>? eventsStats,
    Map<String, List<DetailedNoteModel>>? previousNotes,
    List<String>? mutes,
    List<String>? mutesEvents,
    Set<String>? bookmarks,
    Set<String>? deletedNotes,
  }) {
    return NotesEventsState(
      eventsStats: eventsStats ?? this.eventsStats,
      previousNotes: previousNotes ?? this.previousNotes,
      mutes: mutes ?? this.mutes,
      mutesEvents: mutesEvents ?? this.mutesEvents,
      bookmarks: bookmarks ?? this.bookmarks,
      deletedNotes: deletedNotes ?? this.deletedNotes,
    );
  }
}
