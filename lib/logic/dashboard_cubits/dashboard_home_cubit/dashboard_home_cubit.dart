import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/article_model.dart';
import '../../../models/curation_model.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'dashboard_home_state.dart';

class DashboardHomeCubit extends Cubit<DashboardHomeState> {
  DashboardHomeCubit()
      : super(
          const DashboardHomeState(
            drafts: [],
            popular: [],
            stats: {},
            latest: [],
          ),
        ) {
    init();
  }

  void init() {
    getRemoteCacheStats();
    getSentZaps();
    getPopularaNotes();
    getArticlesDrafts();
    getLatestContent();
  }

  Future<void> getRemoteCacheStats() async {
    final stats = await NostrFunctionsRepository.getRcUserStats(
      currentSigner!.getPublicKey(),
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          stats: Map.from(state.stats)..addAll(stats),
        ),
      );
    }
  }

  Future<void> getSentZaps() async {
    final stats = await HttpFunctionsRepository.getUserReceivedZaps(
      currentSigner!.getPublicKey(),
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          stats: Map.from(state.stats)..addAll(stats),
        ),
      );
    }
  }

  Future<void> getPopularaNotes() async {
    final notes = await NostrFunctionsRepository.getRcPopularNotes(
      currentSigner!.getPublicKey(),
    );
    if (!isClosed) {
      emit(state.copyWith(popular: notes));
    }
  }

  Future<void> getArticlesDrafts() async {
    final evs = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.LONG_FORM_DRAFT],
      pubkeys: [currentSigner!.getPublicKey()],
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          drafts: evs
              .map(
                (e) => Article.fromEvent(e),
              )
              .toList(),
        ),
      );
    }
  }

  Future<void> getLatestContent() async {
    try {
      final evs = await NostrFunctionsRepository.getEventsAsync(
        kinds: [
          EventKind.LONG_FORM,
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
        ],
        pubkeys: [currentSigner!.getPublicKey()],
        limit: 10,
      );

      List<Event> ev1 = evs
          .where(
            (element) => element.kind == EventKind.LONG_FORM,
          )
          .toList();

      ev1 = ev1.isNotEmpty
          ? ev1.length > 1
              ? ev1.sublist(0, 2)
              : [ev1.first]
          : [];

      List<Event> ev2 = evs
          .where(
            (element) =>
                element.kind == EventKind.VIDEO_HORIZONTAL ||
                element.kind == EventKind.VIDEO_VERTICAL,
          )
          .toList();

      ev2 = ev2.isNotEmpty
          ? ev2.length > 1
              ? ev2.sublist(0, 2)
              : [ev2.first]
          : [];

      List<Event> ev3 = evs
          .where(
            (element) =>
                element.kind == EventKind.CURATION_ARTICLES ||
                element.kind == EventKind.CURATION_VIDEOS,
          )
          .toList();

      ev3 = ev3.isNotEmpty
          ? ev3.length > 1
              ? ev3.sublist(0, 2)
              : [ev3.first]
          : [];
      if (!isClosed) {
        emit(
          state.copyWith(latest: [
            ...ev1.map(
              (e) => Article.fromEvent(e),
            ),
            ...ev2.map(
              (e) => VideoModel.fromEvent(e),
            ),
            ...ev3.map(
              (e) => Curation.fromEvent(e, ''),
            ),
          ]),
        );
      }
    } catch (e, stack) {
      lg.i(stack);
    }
  }

  Future<void> getRecent() async {
    final evs = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.LONG_FORM_DRAFT],
      pubkeys: [currentSigner!.getPublicKey()],
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          drafts: evs
              .map(
                (e) => Article.fromEvent(e),
              )
              .toList(),
        ),
      );
    }
  }

  Future<void> onDeleteContent(String id) async {
    final cancel = BotToast.showLoading();

    final isSuccessful =
        await NostrFunctionsRepository.deleteEvent(eventId: id);
    if (isSuccessful) {
      getLatestContent();
      getRecent();
    } else {
      BotToastUtils.showError(
        t.errorDeletingContent.capitalizeFirst(),
      );
    }

    cancel.call();
  }
}
