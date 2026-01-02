import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/picture_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../models/video_model.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'dashboard_content_state.dart';

class DashboardContentCubit extends Cubit<DashboardContentState> {
  DashboardContentCubit()
      : super(
          const DashboardContentState(
            content: [],
            savedTools: [],
            isLoading: true,
            updatingState: UpdatingState.success,
            chosenRE: AppContentType.article,
          ),
        );

  Future<void> getSmartWidgetsSavedTools() async {
    emit(
      state.copyWith(
        isLoading: true,
        updatingState: UpdatingState.success,
      ),
    );

    final bookmark = nostrRepository.bookmarksLists[smartWidgetSavedTools];
    if (bookmark != null && bookmark.bookmarkedReplaceableEvents.isNotEmpty) {
      final sws = await NostrFunctionsRepository.getSmartWidgetBookmark(
        bookmarksModel: bookmark,
      );

      emit(
        state.copyWith(
          isLoading: false,
          savedTools: sws,
          updatingState: UpdatingState.idle,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isLoading: false,
          savedTools: [],
          updatingState: UpdatingState.idle,
        ),
      );
    }
  }

  Future<void> buildContent({
    required AppContentType re,
    required bool onAdd,
    required bool isPublished,
  }) async {
    if (!onAdd) {
      if (!isClosed) {
        emit(
          state.copyWith(
            chosenRE: re,
            content: [],
            isLoading: true,
            updatingState: UpdatingState.success,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            chosenRE: re,
            updatingState: UpdatingState.progress,
          ),
        );
      }
    }

    final evs = await NostrFunctionsRepository.getEventsAsync(
      kinds: [
        if (re == AppContentType.article) ...[
          if (isPublished) EventKind.LONG_FORM,
          if (!isPublished) EventKind.LONG_FORM_DRAFT,
        ],
        if (re == AppContentType.curation) ...[
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
        if (re == AppContentType.video) ...[
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
          EventKind.LEGACY_VIDEO_HORIZONTAL,
          EventKind.LEGACY_VIDEO_VERTICAL,
        ],
        if (re == AppContentType.smartWidget) ...[
          EventKind.SMART_WIDGET_ENH,
        ],
        if (re == AppContentType.note) ...[
          EventKind.TEXT_NOTE,
          EventKind.REPOST,
        ],
        if (re == AppContentType.picture) ...[
          EventKind.PICTURE,
        ],
      ],
      pubkeys: [currentSigner!.getPublicKey()],
      limit: 20,
      until:
          onAdd ? state.content.last.createdAt.toSecondsSinceEpoch() - 1 : null,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [
            ...state.content,
            ...evs.map(
              (e) {
                if (re == AppContentType.article) {
                  return Article.fromEvent(
                    e,
                    isDraft: e.kind == EventKind.LONG_FORM_DRAFT,
                  );
                } else if (re == AppContentType.curation) {
                  return Curation.fromEvent(e, '');
                } else if (re == AppContentType.video) {
                  return VideoModel.fromEvent(e);
                } else if (re == AppContentType.smartWidget) {
                  return SmartWidget.fromEvent(e);
                } else if (re == AppContentType.picture) {
                  return PictureModel.fromEvent(e);
                } else {
                  if (e.kind == EventKind.TEXT_NOTE) {
                    return DetailedNoteModel.fromEvent(e);
                  } else {
                    return RepostModel.fromEvent(e);
                  }
                }
              },
            ),
          ],
          isLoading: false,
          updatingState:
              evs.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<void> onDeleteContent(String id) async {
    final cancel = BotToastUtils.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: id);
    if (isSuccessful) {
      buildContent(
        re: state.chosenRE,
        onAdd: false,
        isPublished: true,
      );
    } else {
      BotToastUtils.showError(
        t.zapSplitsMessage.capitalizeFirst(),
      );
    }

    cancel.call();
  }
}
