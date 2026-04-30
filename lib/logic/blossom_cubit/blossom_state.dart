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

  BlossomState copyWith({
    List<BlossomAggregatedMedia>? allMedia,
    List<BlossomAggregatedMedia>? filteredMedia,
    List<String>? servers,
    int? selectedServerIndex,
    bool? isGridView,
    bool? isLoading,
  }) {
    return BlossomState(
      allMedia: allMedia ?? this.allMedia,
      filteredMedia: filteredMedia ?? this.filteredMedia,
      servers: servers ?? this.servers,
      selectedServerIndex: selectedServerIndex ?? this.selectedServerIndex,
      isGridView: isGridView ?? this.isGridView,
      isLoading: isLoading ?? this.isLoading,
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
      ];
}
