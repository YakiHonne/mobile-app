import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/smart_widgets_components.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'tools_state.dart';

class ToolsCubit extends Cubit<ToolsState> {
  ToolsCubit({this.loadBookmarked = false})
      : super(
          const ToolsState(
            isLoading: true,
            tools: [],
            savedTools: [],
            apps: {},
            bookmarks: {},
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

          emit(
            state.copyWith(
              savedTools: state.tools
                  .where(
                    (sw) => bms.contains(sw.identifier),
                  )
                  .toList(),
              bookmarks: bms,
            ),
          );
        } else {
          emit(
            state.copyWith(
              savedTools: [],
              bookmarks: {},
            ),
          );
        }
      },
    );
  }

  bool loadBookmarked;
  late StreamSubscription smartWidgetsBookmarks;

  Future<void> addBookmark(String identifier, String pubkey) async {
    await NostrFunctionsRepository.setSmartWidgetBookmark(
      identifier: identifier,
      pubkey: pubkey,
    );
  }

  Future<void> init() async {
    emit(state.copyWith(isLoading: true));

    final swBookmark = nostrRepository.bookmarksLists[smartWidgetSavedTools];
    Set<String> bookmarks = {};

    if (swBookmark != null) {
      bookmarks = swBookmark.bookmarkedReplaceableEvents
          .map(
            (e) => e.identifier,
          )
          .toSet();
    }

    if (loadBookmarked && bookmarks.isEmpty) {
      emit(
        state.copyWith(isLoading: false),
      );
    }

    final events = await NostrFunctionsRepository.getEventsAsync(
      lTags: [SWType.tool.name],
      kinds: [EventKind.SMART_WIDGET_ENH],
      dTags: loadBookmarked ? bookmarks.toList() : [],
    );

    nc.db.saveEvents(events);

    final sws = events
        .map(
          (e) => SmartWidget.fromEvent(e),
        )
        .toList();

    final apps = await getApps(
      {
        for (final sw in sws) ...{sw.identifier: sw.getAppUrl()},
      },
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          isLoading: false,
          tools: sws,
          apps: apps,
          bookmarks: bookmarks,
          savedTools: sws
              .where(
                (sw) => bookmarks.contains(sw.identifier),
              )
              .toList(),
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

  @override
  Future<void> close() async {
    smartWidgetsBookmarks.cancel();
    super.close();
  }
}
