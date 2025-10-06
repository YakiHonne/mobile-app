import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/ai_chat_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'smart_widget_search_state.dart';

class SmartWidgetSearchCubit extends Cubit<SmartWidgetSearchState> {
  SmartWidgetSearchCubit()
      : super(
          const SmartWidgetSearchState(
            isAddingLoading: UpdatingState.progress,
            isSmartWidgetLoading: true,
            isAiLoading: false,
            widgets: [],
            dvmWidgets: [],
            dvmSearch: '',
            apps: {},
            bookmarks: {},
            messages: [],
            dvmState: UpdatingState.idle,
            aiErrorMessage: '',
          ),
        ) {
    init();

    smartWidgetsBookmarks = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        final swBookmark = bookmarks[smartWidgetSavedTools];
        if (swBookmark != null) {
          final bms = swBookmark.bookmarkedReplaceableEvents
              .map(
                (e) => e.identifier,
              )
              .toSet();
          if (!isClosed) {
            emit(
              state.copyWith(
                bookmarks: bms,
              ),
            );
          }
        } else {
          if (!isClosed) {
            emit(
              state.copyWith(
                bookmarks: {},
              ),
            );
          }
        }
      },
    );
  }

  late StreamSubscription smartWidgetsBookmarks;

  Future<void> init() async {
    loadBookmarks();
    await loadSmartWidgets();
  }

  void loadBookmarks() {
    final swBookmark = nostrRepository.bookmarksLists[smartWidgetSavedTools];
    Set<String> bookmarks = {};

    if (swBookmark != null) {
      bookmarks = swBookmark.bookmarkedReplaceableEvents
          .map(
            (e) => e.identifier,
          )
          .toSet();
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          bookmarks: bookmarks,
        ),
      );
    }
  }

  Future<void> loadSmartWidgets({
    bool isAdding = false,
    bool isTools = true,
  }) async {
    emit(
      state.copyWith(
        isAddingLoading: isAdding ? UpdatingState.progress : null,
        isSmartWidgetLoading: isAdding ? null : true,
        widgets: isAdding ? state.widgets : [],
      ),
    );

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.SMART_WIDGET_ENH],
      lTags: isTools
          ? [SWType.tool.name, SWType.action.name]
          : [SWType.basic.name],
      limit: 50,
      compareById: false,
      until: isAdding
          ? state.widgets.last.createdAt.toSecondsSinceEpoch() - 1
          : null,
    );

    nc.db.saveEvents(events);

    final sws = events
        .map(
          (e) => SmartWidget.fromEvent(e),
        )
        .toList();

    final apps = await getApps(
      {
        for (final sw in sws)
          if (sw.getAppUrl() != null) ...{sw.identifier: sw.getAppUrl()},
      },
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          isAddingLoading:
              sws.isNotEmpty ? UpdatingState.success : UpdatingState.idle,
          isSmartWidgetLoading: false,
          widgets: [...state.widgets, ...sws],
          apps: {...state.apps, ...apps},
        ),
      );
    }
  }

  Future<Map<String, AppSmartWidget?>> getApps(
    Map<String, String?> urls,
  ) async {
    final finedApps = <String, AppSmartWidget?>{};

    final apps = await Future.wait(
      [
        for (final url in urls.values)
          if (url != null) HttpFunctionsRepository.getAppSmartWidget(url),
      ],
    );

    for (final app in apps) {
      if (app != null) {
        final id = urls.entries
            .firstWhere(
              (e) => e.value == app.url,
              orElse: () => const MapEntry('', ''),
            )
            .key;

        if (id.isNotEmpty) {
          finedApps[id] = app;
        }
      }
    }

    return finedApps;
  }

  Future<void> addBookmark(String identifier, String pubkey) async {
    await NostrFunctionsRepository.setSmartWidgetBookmark(
      identifier: identifier,
      pubkey: pubkey,
    );
  }

  void clearSearch() {
    if (!isClosed) {
      emit(
        state.copyWith(
          dvmSearch: '',
        ),
      );
    }
  }

  Future<void> getSmartWidgetThroughDvm(String search) async {
    if (!isClosed) {
      emit(
        state.copyWith(
          dvmSearch: search,
          isSmartWidgetLoading: true,
        ),
      );
    }

    final sws = await HttpFunctionsRepository.getDvmSmartWidgets(search);

    if (!isClosed) {
      emit(
        state.copyWith(
          dvmWidgets: sws,
          isSmartWidgetLoading: false,
        ),
      );
    }
  }

  Future<void> sendSmartWidgetChatMessage({
    required String search,
    required Function() onDone,
  }) async {
    _emit(
      isAiLoading: true,
      messages: [
        ...state.messages,
        AiChatMessage(
          content: search,
          isCurrentUser: true,
          createdAt: DateTime.now(),
          id: uuid.v4(),
        ),
      ],
    );

    final response = await HttpFunctionsRepository.getAiChatResponse(search);

    _emit(
      isAiLoading: false,
      messages: response.key
          ? [
              ...state.messages,
              AiChatMessage(
                content: response.value,
                isCurrentUser: false,
                createdAt: DateTime.now(),
                id: uuid.v4(),
              ),
            ]
          : null,
      aiErrorMessage: response.key ? '' : getAiErrorMessage(response.value),
    );
  }

  String getAiErrorMessage(String messageKey) {
    String message = '';

    switch (messageKey) {
      case 'QuotaLimit':
        message = t.quotaLimit.capitalizeFirst();
      default:
        message = t.quotaLimit.capitalizeFirst();
    }

    return message;
  }

  void removeAiErrorMessage() {
    _emit(
      aiErrorMessage: '',
    );
  }

  void _emit({
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
    if (!isClosed) {
      emit(
        state.copyWith(
          widgets: widgets,
          dvmWidgets: dvmWidgets,
          dvmSearch: dvmSearch,
          apps: apps,
          bookmarks: bookmarks,
          dvmState: dvmState,
          isAddingLoading: isAddingLoading,
          isSmartWidgetLoading: isSmartWidgetLoading,
          isAiLoading: isAiLoading,
          messages: messages,
          aiErrorMessage: aiErrorMessage,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    smartWidgetsBookmarks.cancel();
    return super.close();
  }
}
