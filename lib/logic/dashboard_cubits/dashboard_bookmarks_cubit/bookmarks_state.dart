// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'bookmarks_cubit.dart';

class DashboardBookmarksState extends Equatable {
  final bool refresh;
  final List<BookmarkListModel> bookmarksLists;

  const DashboardBookmarksState({
    required this.refresh,
    required this.bookmarksLists,
  });

  @override
  List<Object> get props => [
        refresh,
        bookmarksLists,
      ];

  DashboardBookmarksState copyWith({
    bool? refresh,
    List<BookmarkListModel>? bookmarksLists,
  }) {
    return DashboardBookmarksState(
      refresh: refresh ?? this.refresh,
      bookmarksLists: bookmarksLists ?? this.bookmarksLists,
    );
  }
}
