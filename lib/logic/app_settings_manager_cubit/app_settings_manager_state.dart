// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'app_settings_manager_cubit.dart';

class AppSettingsManagerState extends Equatable {
  final Map<String, DiscoverFilter> discoverFilters;
  final String selectedDiscoverFilter;
  final List<BaseFeed> discoverSources;
  final Map<String, CommunityFeedOption> discoverCommunity;
  final Map<String, DvmModel> discoverDvms;
  final MapEntry<String, String> selectedDiscoverSource;

  final Map<String, NotesFilter> notesFilters;
  final String selectedNotesFilter;
  final List<BaseFeed> notesSources;
  final Map<String, CommunityFeedOption> notesCommunity;
  final Map<String, DvmModel> notesDvms;
  final MapEntry<String, String> selectedNotesSource;

  final List<String> favoriteRelays;

  const AppSettingsManagerState({
    required this.discoverFilters,
    required this.selectedDiscoverFilter,
    required this.discoverSources,
    required this.discoverCommunity,
    required this.discoverDvms,
    required this.selectedDiscoverSource,
    required this.notesFilters,
    required this.selectedNotesFilter,
    required this.notesSources,
    required this.notesCommunity,
    required this.notesDvms,
    required this.selectedNotesSource,
    required this.favoriteRelays,
  });

  @override
  List<Object> get props => [
        discoverFilters,
        selectedDiscoverFilter,
        discoverSources,
        discoverCommunity,
        discoverDvms,
        selectedDiscoverSource,
        notesFilters,
        selectedNotesFilter,
        notesSources,
        notesCommunity,
        notesDvms,
        selectedNotesSource,
        favoriteRelays,
      ];

  AppSettingsManagerState copyWith({
    Map<String, DiscoverFilter>? discoverFilters,
    String? selectedDiscoverFilter,
    List<BaseFeed>? discoverSources,
    Map<String, CommunityFeedOption>? discoverCommunity,
    Map<String, DvmModel>? discoverDvms,
    MapEntry<String, String>? selectedDiscoverSource,
    Map<String, NotesFilter>? notesFilters,
    String? selectedNotesFilter,
    List<BaseFeed>? notesSources,
    Map<String, CommunityFeedOption>? notesCommunity,
    Map<String, DvmModel>? notesDvms,
    MapEntry<String, String>? selectedNotesSource,
    List<String>? favoriteRelays,
  }) {
    return AppSettingsManagerState(
      discoverFilters: discoverFilters ?? this.discoverFilters,
      selectedDiscoverFilter:
          selectedDiscoverFilter ?? this.selectedDiscoverFilter,
      discoverSources: discoverSources ?? this.discoverSources,
      discoverCommunity: discoverCommunity ?? this.discoverCommunity,
      discoverDvms: discoverDvms ?? this.discoverDvms,
      selectedDiscoverSource:
          selectedDiscoverSource ?? this.selectedDiscoverSource,
      notesFilters: notesFilters ?? this.notesFilters,
      selectedNotesFilter: selectedNotesFilter ?? this.selectedNotesFilter,
      notesSources: notesSources ?? this.notesSources,
      notesCommunity: notesCommunity ?? this.notesCommunity,
      notesDvms: notesDvms ?? this.notesDvms,
      selectedNotesSource: selectedNotesSource ?? this.selectedNotesSource,
      favoriteRelays: favoriteRelays ?? this.favoriteRelays,
    );
  }
}
