// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'discover_cubit.dart';

class DiscoverState extends Equatable {
  final List<BaseEventModel> content;
  final List<BaseEventModel> extraContent;
  final bool onLoading;
  final UpdatingState onAddingData;
  final Set<String> bookmarks;
  final List<String> mutes;
  final List<String> followings;
  final bool refresh;
  final AppContentSource selectedSource;
  final bool showFollowingListMessage;

  const DiscoverState({
    required this.content,
    required this.extraContent,
    required this.onLoading,
    required this.onAddingData,
    required this.bookmarks,
    required this.mutes,
    required this.followings,
    required this.refresh,
    required this.selectedSource,
    required this.showFollowingListMessage,
  });

  @override
  List<Object> get props => [
        content,
        extraContent,
        onAddingData,
        bookmarks,
        mutes,
        onLoading,
        followings,
        refresh,
        selectedSource,
        showFollowingListMessage
      ];

  DiscoverState copyWith({
    List<BaseEventModel>? content,
    List<BaseEventModel>? extraContent,
    bool? onLoading,
    UpdatingState? onAddingData,
    Set<String>? bookmarks,
    List<String>? mutes,
    List<String>? followings,
    bool? refresh,
    AppContentSource? selectedSource,
    bool? showFollowingListMessage,
  }) {
    return DiscoverState(
      content: content ?? this.content,
      extraContent: extraContent ?? this.extraContent,
      onLoading: onLoading ?? this.onLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      bookmarks: bookmarks ?? this.bookmarks,
      mutes: mutes ?? this.mutes,
      followings: followings ?? this.followings,
      refresh: refresh ?? this.refresh,
      selectedSource: selectedSource ?? this.selectedSource,
      showFollowingListMessage:
          showFollowingListMessage ?? this.showFollowingListMessage,
    );
  }
}
