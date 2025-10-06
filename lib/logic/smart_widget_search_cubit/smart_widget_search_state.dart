// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'smart_widget_search_cubit.dart';

class SmartWidgetSearchState extends Equatable {
  final List<SmartWidget> widgets;
  final List<SmartWidget> dvmWidgets;
  final String dvmSearch;
  final Map<String, AppSmartWidget?> apps;
  final Set<String> bookmarks;
  final UpdatingState dvmState;
  final UpdatingState isAddingLoading;
  final bool isSmartWidgetLoading;
  final bool isAiLoading;
  final List<AiChatMessage> messages;
  final String aiErrorMessage;

  const SmartWidgetSearchState({
    required this.widgets,
    required this.apps,
    required this.dvmSearch,
    required this.dvmWidgets,
    required this.bookmarks,
    required this.dvmState,
    required this.isAddingLoading,
    required this.isSmartWidgetLoading,
    required this.isAiLoading,
    required this.messages,
    required this.aiErrorMessage,
  });

  @override
  List<Object> get props => [
        widgets,
        apps,
        dvmState,
        dvmSearch,
        bookmarks,
        isAddingLoading,
        isSmartWidgetLoading,
        isAiLoading,
        dvmWidgets,
        messages,
        aiErrorMessage,
      ];

  SmartWidgetSearchState copyWith({
    List<SmartWidget>? widgets,
    List<SmartWidget>? dvmWidgets,
    String? dvmSearch,
    Map<String, AppSmartWidget?>? apps,
    Set<String>? bookmarks,
    UpdatingState? dvmState,
    UpdatingState? isAddingLoading,
    bool? isSmartWidgetLoading,
    bool? isAiLoading,
    List<AiChatMessage>? messages,
    String? aiErrorMessage,
  }) {
    return SmartWidgetSearchState(
      widgets: widgets ?? this.widgets,
      dvmWidgets: dvmWidgets ?? this.dvmWidgets,
      dvmSearch: dvmSearch ?? this.dvmSearch,
      apps: apps ?? this.apps,
      bookmarks: bookmarks ?? this.bookmarks,
      dvmState: dvmState ?? this.dvmState,
      isAddingLoading: isAddingLoading ?? this.isAddingLoading,
      isSmartWidgetLoading: isSmartWidgetLoading ?? this.isSmartWidgetLoading,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      messages: messages ?? this.messages,
      aiErrorMessage: aiErrorMessage ?? this.aiErrorMessage,
    );
  }
}
