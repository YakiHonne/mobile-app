// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'notes_events_cubit.dart';

// class NotesEventsState extends Equatable {
//   final Map<String, List<DetailedNoteModel>> previousNotes;
//   final List<String> mutes;
//   final Set<String> bookmarks;

//   const NotesEventsState({
//     required this.previousNotes,
//     required this.mutes,
//     required this.bookmarks,
//   });

//   @override
//   List<Object> get props => [
//         previousNotes,
//         mutes,
//         bookmarks,
//       ];

//   NotesEventsState copyWith({
//     Map<String, List<DetailedNoteModel>>? previousNotes,
//     List<String>? mutes,
//     Set<String>? bookmarks,
//   }) {
//     return NotesEventsState(
//       previousNotes: previousNotes ?? this.previousNotes,
//       mutes: mutes ?? this.mutes,
//       bookmarks: bookmarks ?? this.bookmarks,
//     );
//   }
// }

class NotesEventsState extends Equatable {
  final Map<String, EventStats> eventsStats;
  final Map<String, List<DetailedNoteModel>> previousNotes;
  final List<String> mutes;
  final Set<String> bookmarks;

  const NotesEventsState({
    required this.eventsStats,
    required this.previousNotes,
    required this.mutes,
    required this.bookmarks,
  });

  @override
  List<Object> get props => [
        previousNotes,
        mutes,
        bookmarks,
        eventsStats,
      ];

  NotesEventsState copyWith({
    Map<String, EventStats>? eventsStats,
    Map<String, List<DetailedNoteModel>>? previousNotes,
    List<String>? mutes,
    Set<String>? bookmarks,
  }) {
    return NotesEventsState(
      eventsStats: eventsStats ?? this.eventsStats,
      previousNotes: previousNotes ?? this.previousNotes,
      mutes: mutes ?? this.mutes,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
