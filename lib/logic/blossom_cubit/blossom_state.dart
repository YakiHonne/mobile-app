import 'package:equatable/equatable.dart';

import '../../models/blossom_media.dart';

class BlossomState extends Equatable {
  const BlossomState({
    required this.allMedia,
    required this.filteredMedia,
    required this.servers,
    required this.selectedServerIndex,
    required this.isGridView,
    required this.isLoading,
    this.searchQuery = '',
  });

  factory BlossomState.initial() {
    return const BlossomState(
      allMedia: [],
      filteredMedia: [],
      servers: [],
      selectedServerIndex: -1,
      isGridView: true,
      isLoading: false,
    );
  }
  final List<BlossomAggregatedMedia> allMedia;
  final List<BlossomAggregatedMedia> filteredMedia;
  final List<String> servers;
  final int selectedServerIndex; // -1 for "All servers"
  final bool isGridView;
  final bool isLoading;
  final String searchQuery;

  BlossomState copyWith({
    List<BlossomAggregatedMedia>? allMedia,
    List<BlossomAggregatedMedia>? filteredMedia,
    List<String>? servers,
    int? selectedServerIndex,
    bool? isGridView,
    bool? isLoading,
    String? searchQuery,
  }) {
    return BlossomState(
      allMedia: allMedia ?? this.allMedia,
      filteredMedia: filteredMedia ?? this.filteredMedia,
      servers: servers ?? this.servers,
      selectedServerIndex: selectedServerIndex ?? this.selectedServerIndex,
      isGridView: isGridView ?? this.isGridView,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props => [
        allMedia,
        filteredMedia,
        servers,
        selectedServerIndex,
        isGridView,
        isLoading,
        searchQuery,
      ];
}
