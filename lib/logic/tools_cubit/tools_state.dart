// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tools_cubit.dart';

class ToolsState extends Equatable {
  final List<SmartWidget> tools;
  final List<SmartWidget> savedTools;
  final Map<String, AppSmartWidget?> apps;
  final Set<String> bookmarks;
  final bool isLoading;

  const ToolsState({
    required this.tools,
    required this.savedTools,
    required this.apps,
    required this.bookmarks,
    required this.isLoading,
  });

  @override
  List<Object> get props => [tools, isLoading, apps, bookmarks, savedTools];

  ToolsState copyWith({
    List<SmartWidget>? tools,
    List<SmartWidget>? savedTools,
    Map<String, AppSmartWidget?>? apps,
    Set<String>? bookmarks,
    bool? isLoading,
  }) {
    return ToolsState(
      tools: tools ?? this.tools,
      savedTools: savedTools ?? this.savedTools,
      apps: apps ?? this.apps,
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
