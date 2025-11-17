// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'add_bookmark_cubit.dart';

class AddBookmarkState extends Equatable {
  final List<BookmarkListModel> bookmarks;
  final List<String> loadingBookmarksList;
  final bool isBookmarksLists;
  final String eventId;
  final String eventPubkey;
  final int kind;

  const AddBookmarkState({
    required this.bookmarks,
    required this.loadingBookmarksList,
    required this.isBookmarksLists,
    required this.eventId,
    required this.eventPubkey,
    required this.kind,
  });

  @override
  List<Object> get props => [
        bookmarks,
        kind,
        isBookmarksLists,
        loadingBookmarksList,
        eventId,
        eventPubkey,
      ];

  AddBookmarkState copyWith({
    List<BookmarkListModel>? bookmarks,
    List<String>? loadingBookmarksList,
    bool? isBookmarksLists,
    String? eventId,
    String? eventPubkey,
    int? kind,
  }) {
    return AddBookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      loadingBookmarksList: loadingBookmarksList ?? this.loadingBookmarksList,
      isBookmarksLists: isBookmarksLists ?? this.isBookmarksLists,
      eventId: eventId ?? this.eventId,
      eventPubkey: eventPubkey ?? this.eventPubkey,
      kind: kind ?? this.kind,
    );
  }
}
