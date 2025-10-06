// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'leading_cubit.dart';

class LeadingState extends Equatable {
  final List<Event> content;
  final List<Event> extraContent;
  final List<BaseEventModel> media;
  final bool onContentLoading;
  final bool onMediaLoading;
  final UpdatingState onAddingData;
  final List<CommonFeedTypes> commonFeedTypes;
  final bool showSuggestions;
  final bool refresh;
  final AppContentSource selectedSource;
  final bool showFollowingListMessage;

  const LeadingState({
    required this.content,
    required this.extraContent,
    required this.media,
    required this.onContentLoading,
    required this.onMediaLoading,
    required this.onAddingData,
    required this.commonFeedTypes,
    required this.showSuggestions,
    required this.refresh,
    required this.selectedSource,
    required this.showFollowingListMessage,
  });

  @override
  List<Object> get props => [
        content,
        extraContent,
        onContentLoading,
        onAddingData,
        media,
        onMediaLoading,
        commonFeedTypes,
        showSuggestions,
        refresh,
        selectedSource,
        showFollowingListMessage,
      ];

  LeadingState copyWith({
    List<Event>? content,
    List<Event>? extraContent,
    List<BaseEventModel>? media,
    bool? onContentLoading,
    bool? onMediaLoading,
    UpdatingState? onAddingData,
    List<CommonFeedTypes>? commonFeedTypes,
    bool? showSuggestions,
    bool? refresh,
    AppContentSource? selectedSource,
    bool? showFollowingListMessage,
  }) {
    return LeadingState(
      content: content ?? this.content,
      extraContent: extraContent ?? this.extraContent,
      media: media ?? this.media,
      onContentLoading: onContentLoading ?? this.onContentLoading,
      onMediaLoading: onMediaLoading ?? this.onMediaLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      commonFeedTypes: commonFeedTypes ?? this.commonFeedTypes,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      refresh: refresh ?? this.refresh,
      selectedSource: selectedSource ?? this.selectedSource,
      showFollowingListMessage:
          showFollowingListMessage ?? this.showFollowingListMessage,
    );
  }
}
