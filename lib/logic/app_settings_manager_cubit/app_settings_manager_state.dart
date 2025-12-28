// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'app_settings_manager_cubit.dart';

class AppSettingsManagerState extends Equatable {
  final Map<String, DiscoverFilter> discoverFilters;
  final String selectedDiscoverFilter;
  final List<BaseFeed> discoverSources;
  final Map<String, CommunityFeedOption> discoverCommunity;
  final MapEntry<String, dynamic> selectedDiscoverSource;

  final Map<String, NotesFilter> notesFilters;
  final String selectedNotesFilter;
  final List<BaseFeed> notesSources;
  final Map<String, CommunityFeedOption> notesCommunity;
  final MapEntry<String, dynamic> selectedNotesSource;

  final Map<String, MediaFilter> mediaFilters;
  final String selectedMediaFilter;
  final List<BaseFeed> mediaSources;
  final Map<String, CommunityFeedOption> mediaCommunity;
  final MapEntry<String, dynamic> selectedMediaSource;

  const AppSettingsManagerState({
    required this.discoverFilters,
    required this.selectedDiscoverFilter,
    required this.discoverSources,
    required this.discoverCommunity,
    required this.selectedDiscoverSource,
    required this.notesFilters,
    required this.selectedNotesFilter,
    required this.notesSources,
    required this.notesCommunity,
    required this.selectedNotesSource,
    required this.mediaFilters,
    required this.selectedMediaFilter,
    required this.mediaSources,
    required this.mediaCommunity,
    required this.selectedMediaSource,
  });

  @override
  List<Object> get props => [
        discoverFilters,
        selectedDiscoverFilter,
        discoverSources,
        discoverCommunity,
        selectedDiscoverSource,
        notesFilters,
        selectedNotesFilter,
        notesSources,
        notesCommunity,
        selectedNotesSource,
        mediaFilters,
        selectedMediaFilter,
        mediaSources,
        mediaCommunity,
        selectedMediaSource,
      ];

  AppSettingsManagerState copyWith({
    Map<String, DiscoverFilter>? discoverFilters,
    String? selectedDiscoverFilter,
    List<BaseFeed>? discoverSources,
    Map<String, CommunityFeedOption>? discoverCommunity,
    MapEntry<String, dynamic>? selectedDiscoverSource,
    Map<String, NotesFilter>? notesFilters,
    String? selectedNotesFilter,
    List<BaseFeed>? notesSources,
    Map<String, CommunityFeedOption>? notesCommunity,
    MapEntry<String, dynamic>? selectedNotesSource,
    Map<String, MediaFilter>? mediaFilters,
    String? selectedMediaFilter,
    List<BaseFeed>? mediaSources,
    Map<String, CommunityFeedOption>? mediaCommunity,
    MapEntry<String, dynamic>? selectedMediaSource,
  }) {
    return AppSettingsManagerState(
      discoverFilters: discoverFilters ?? this.discoverFilters,
      selectedDiscoverFilter:
          selectedDiscoverFilter ?? this.selectedDiscoverFilter,
      discoverSources: discoverSources ?? this.discoverSources,
      discoverCommunity: discoverCommunity ?? this.discoverCommunity,
      selectedDiscoverSource:
          selectedDiscoverSource ?? this.selectedDiscoverSource,
      notesFilters: notesFilters ?? this.notesFilters,
      selectedNotesFilter: selectedNotesFilter ?? this.selectedNotesFilter,
      notesSources: notesSources ?? this.notesSources,
      notesCommunity: notesCommunity ?? this.notesCommunity,
      selectedNotesSource: selectedNotesSource ?? this.selectedNotesSource,
      mediaFilters: mediaFilters ?? this.mediaFilters,
      selectedMediaFilter: selectedMediaFilter ?? this.selectedMediaFilter,
      mediaSources: mediaSources ?? this.mediaSources,
      mediaCommunity: mediaCommunity ?? this.mediaCommunity,
      selectedMediaSource: selectedMediaSource ?? this.selectedMediaSource,
    );
  }
}
