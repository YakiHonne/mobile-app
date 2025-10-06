// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'uncensored_notes_cubit.dart';

class UncensoredNotesState extends Equatable {
  final List<UnFlashNews> unNewFlashNews;
  final bool loading;
  final int index;
  final bool refresh;
  final Set<String> bookmarks;
  final num balance;
  final UpdatingState addingFlashNewsStatus;
  final int page;

  const UncensoredNotesState({
    required this.unNewFlashNews,
    required this.loading,
    required this.index,
    required this.refresh,
    required this.bookmarks,
    required this.balance,
    required this.addingFlashNewsStatus,
    required this.page,
  });

  @override
  List<Object> get props => [
        unNewFlashNews,
        loading,
        index,
        refresh,
        bookmarks,
        balance,
        addingFlashNewsStatus,
        page,
      ];

  UncensoredNotesState copyWith({
    List<UnFlashNews>? unNewFlashNews,
    bool? loading,
    int? index,
    bool? refresh,
    Set<String>? bookmarks,
    num? balance,
    UpdatingState? addingFlashNewsStatus,
    int? page,
  }) {
    return UncensoredNotesState(
      unNewFlashNews: unNewFlashNews ?? this.unNewFlashNews,
      loading: loading ?? this.loading,
      index: index ?? this.index,
      refresh: refresh ?? this.refresh,
      bookmarks: bookmarks ?? this.bookmarks,
      balance: balance ?? this.balance,
      addingFlashNewsStatus:
          addingFlashNewsStatus ?? this.addingFlashNewsStatus,
      page: page ?? this.page,
    );
  }
}
