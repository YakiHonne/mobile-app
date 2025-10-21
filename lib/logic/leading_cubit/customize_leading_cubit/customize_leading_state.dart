// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'customize_leading_cubit.dart';

class CustomizeLeadingState extends Equatable {
  final Map<CommonFeedTypes, bool> feedTypes;
  final bool hideNonFollowedMedia;
  final bool showSuggestions;
  final bool showPeopleToFollow;
  final bool showRelatedContent;
  final bool showInterests;
  final bool refresh;
  final bool collapseNote;
  final bool useSingleColumnFeed;
  final Map<String, bool> actionsArrangement;

  const CustomizeLeadingState({
    required this.hideNonFollowedMedia,
    required this.feedTypes,
    required this.showSuggestions,
    required this.showPeopleToFollow,
    required this.showRelatedContent,
    required this.showInterests,
    required this.refresh,
    required this.collapseNote,
    required this.useSingleColumnFeed,
    required this.actionsArrangement,
  });

  @override
  List<Object> get props => [
        hideNonFollowedMedia,
        feedTypes,
        showSuggestions,
        showPeopleToFollow,
        showRelatedContent,
        showInterests,
        refresh,
        collapseNote,
        useSingleColumnFeed,
        actionsArrangement,
      ];

  CustomizeLeadingState copyWith({
    bool? hideNonFollowedMedia,
    Map<CommonFeedTypes, bool>? feedTypes,
    bool? showSuggestions,
    bool? showPeopleToFollow,
    bool? showRelatedContent,
    bool? showInterests,
    bool? refresh,
    bool? collapseNote,
    bool? useSingleColumnFeed,
    Map<String, bool>? actionsArrangement,
  }) {
    return CustomizeLeadingState(
      hideNonFollowedMedia: hideNonFollowedMedia ?? this.hideNonFollowedMedia,
      feedTypes: feedTypes ?? this.feedTypes,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showPeopleToFollow: showPeopleToFollow ?? this.showPeopleToFollow,
      showRelatedContent: showRelatedContent ?? this.showRelatedContent,
      showInterests: showInterests ?? this.showInterests,
      refresh: refresh ?? this.refresh,
      collapseNote: collapseNote ?? this.collapseNote,
      useSingleColumnFeed: useSingleColumnFeed ?? this.useSingleColumnFeed,
      actionsArrangement: actionsArrangement ?? this.actionsArrangement,
    );
  }
}
