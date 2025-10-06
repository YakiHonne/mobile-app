// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'customize_leading_cubit.dart';

class CustomizeLeadingState extends Equatable {
  final Map<CommonFeedTypes, bool> feedTypes;
  final bool showSuggestions;
  final bool showPeopleToFollow;
  final bool showRelatedContent;
  final bool showInterests;
  final bool refresh;
  final bool collapseNote;
  final bool useSingleColumnFeed;

  const CustomizeLeadingState({
    required this.feedTypes,
    required this.showSuggestions,
    required this.showPeopleToFollow,
    required this.showRelatedContent,
    required this.showInterests,
    required this.refresh,
    required this.useSingleColumnFeed,
    required this.collapseNote,
  });

  @override
  List<Object> get props => [
        feedTypes,
        showSuggestions,
        showPeopleToFollow,
        showRelatedContent,
        showInterests,
        refresh,
        collapseNote,
        useSingleColumnFeed,
      ];

  CustomizeLeadingState copyWith({
    Map<CommonFeedTypes, bool>? feedTypes,
    bool? showSuggestions,
    bool? showPeopleToFollow,
    bool? showRelatedContent,
    bool? showInterests,
    bool? refresh,
    bool? collapseNote,
    bool? useSingleColumnFeed,
  }) {
    return CustomizeLeadingState(
      feedTypes: feedTypes ?? this.feedTypes,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      showPeopleToFollow: showPeopleToFollow ?? this.showPeopleToFollow,
      showRelatedContent: showRelatedContent ?? this.showRelatedContent,
      showInterests: showInterests ?? this.showInterests,
      refresh: refresh ?? this.refresh,
      collapseNote: collapseNote ?? this.collapseNote,
      useSingleColumnFeed: useSingleColumnFeed ?? this.useSingleColumnFeed,
    );
  }
}
