// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'bookmark_details_cubit.dart';

class BookmarkDetailsState extends Equatable {
  final List<dynamic> content;
  final BookmarkListModel bookmarkListModel;
  final Map<String, Metadata> metadatas;
  final List<String> followings;
  final bool isLoading;
  final bool refresh;
  final List<String> mutes;

  const BookmarkDetailsState({
    required this.content,
    required this.bookmarkListModel,
    required this.metadatas,
    required this.followings,
    required this.isLoading,
    required this.refresh,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        content,
        metadatas,
        followings,
        mutes,
        isLoading,
        bookmarkListModel,
        refresh,
      ];

  BookmarkDetailsState copyWith({
    List<dynamic>? content,
    BookmarkListModel? bookmarkListModel,
    Map<String, Metadata>? metadatas,
    List<String>? followings,
    bool? isLoading,
    bool? refresh,
    List<String>? mutes,
  }) {
    return BookmarkDetailsState(
      content: content ?? this.content,
      bookmarkListModel: bookmarkListModel ?? this.bookmarkListModel,
      metadatas: metadatas ?? this.metadatas,
      followings: followings ?? this.followings,
      isLoading: isLoading ?? this.isLoading,
      refresh: refresh ?? this.refresh,
      mutes: mutes ?? this.mutes,
    );
  }
}
