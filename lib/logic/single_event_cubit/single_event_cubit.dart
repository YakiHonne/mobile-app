// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/poll_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/uncensored_notes_models.dart';
import '../../models/video_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/article_view/article_view.dart';
import '../../views/curation_view/curation_view.dart';
import '../../views/note_view/note_view.dart';
import '../../views/smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../views/widgets/media_components/horizontal_video_view.dart';
import '../../views/widgets/media_components/vertical_video_view.dart';

part 'single_event_state.dart';

class SingleEventCubit extends Cubit<SingleEventState> with LaterFunction {
  SingleEventCubit()
      : super(
          const SingleEventState(
            refresh: false,
            sealedNotes: {},
            pollStats: {},
            events: {},
          ),
        );

  final List<String> _needUpdateIds = [];
  final List<String> _needUpdateDTags = [];
  final List<Event> _pendingEvents = [];
  final List<String> _sealedIds = [];
  final _accessTimes = <String, int>{};

  Timer? searchOnStoppedTyping;

  void pruneCache({int maxEntries = 100}) {
    if (state.events.length <= maxEntries) {
      return;
    }

    // Sort by last access time (most recent first)
    final sortedIds = state.events.keys.toList()
      ..sort((a, b) {
        final timeA = _accessTimes[a] ?? 0;
        final timeB = _accessTimes[b] ?? 0;
        return timeB.compareTo(timeA); // Most recent first
      });

    // Keep only the most recently accessed entries
    final keysToKeep = sortedIds.take(maxEntries).toSet();

    final prunedCache = {for (final key in keysToKeep) key: state.events[key]!};

    // Clean up access times for removed entries
    _accessTimes.removeWhere((key, _) => !keysToKeep.contains(key));

    lg.i(
      '🧹 Pruned cache from ${state.events.length} to $maxEntries entries',
    );

    emit(state.copyWith(events: prunedCache));
  }

  Future<Event?> getEvenById({
    required String id,
    required bool isIdentifier,
    List<int>? kinds,
  }) async {
    _accessTimes[id] = Helpers.now;

    final ev = await nc.db.loadEventById(id, isIdentifier);

    if (ev != null) {
      return ev;
    }

    final newEv = await NostrFunctionsRepository.getEventById(
      eventId: id,
      isIdentifier: isIdentifier,
      kinds: kinds,
    );

    if (newEv != null) {
      _onEvent(newEv);
    }

    return newEv;
  }

  Event? getProviderEvent(String id, r) {
    if (state.events[id] != null) {
      return state.events[id]!;
    }

    getEvent(id, r);

    return null;
  }

  Future<void> loadEventFromCache(String id, bool r) async {
    final ev = await getCachedEvent(id, r);

    if (ev != null) {
      updateEventsList([ev]);
    }
  }

  Future<Event?> getEvent(String id, bool r) async {
    final ev = state.events[id];

    if (ev != null) {
      return ev;
    }

    final event = await nc.db.loadEventById(id, r);

    if (event != null) {
      updateEventsList([event]);
      return event;
    }

    if (!_needUpdateIds.contains(id) && !r && id.isNotEmpty) {
      _needUpdateIds.add(id);
    }

    if (!_needUpdateDTags.contains(id) && r && id.isNotEmpty) {
      _needUpdateDTags.add(id);
    }

    later(
      () {
        _laterCallback.call();
      },
      null,
    );

    return null;
  }

  Future<void> searchEvents(Map<String, bool> events) async {
    for (final ev in events.entries) {
      final id = ev.key;
      final r = ev.value;

      final event = await nc.db.loadEventById(id, r);

      if (event != null) {
        continue;
      }

      if (!_needUpdateIds.contains(id) && !r) {
        _needUpdateIds.add(id);
      }

      if (!_needUpdateDTags.contains(id) && r) {
        _needUpdateDTags.add(id);
      }
    }

    later(
      () {
        _laterCallback.call();
      },
      null,
    );
  }

  Future<Event?> getCachedEvent(String id, bool r) async {
    return nc.db.loadEventById(id, r);
  }

  SealedNote? getSealedEventOverHttp(String id) {
    final event = state.sealedNotes[id];

    if (event != null) {
      return event;
    }

    if (!_sealedIds.contains(id)) {
      _sealedIds.add(id);
    }

    later(_laterSealedCallback, null);

    return null;
  }

  void _laterSealedCallback() {
    if (_sealedIds.isNotEmpty) {
      _laterSealedSearch();
    }
  }

  void _laterCallback() {
    if (_needUpdateIds.isNotEmpty || _needUpdateDTags.isNotEmpty) {
      _laterSearch();
    }

    if (_pendingEvents.isNotEmpty) {
      _handlePendingEvents();
    }
  }

  Future<void> _handlePendingEvents() async {
    await nc.db.saveEvents(_pendingEvents);
    updateEventsList(_pendingEvents);

    _pendingEvents.clear();
  }

  void updateEventsList(List<Event> events) {
    final newEvents = Map<String, Event>.from(state.events);

    for (final e in events) {
      if (isReplaceable(e.kind)) {
        newEvents[e.dTag ?? e.id] = e;
      } else {
        newEvents[e.id] = e;
      }

      _accessTimes[e.id] = Helpers.now;
    }

    if (!isClosed) {
      emit(
        state.copyWith(refresh: !state.refresh, events: newEvents),
      );
    }

    if (newEvents.length >= 150) {
      pruneCache();
    }
  }

  Future<void> handlePushNotificationEventId(String id) async {
    final context = nostrRepository.currentContext();
    BotToastUtils.showInformation(context.t.fetchingNotificationEvent);

    await Future.delayed(const Duration(seconds: 1));

    if (id.isEmpty) {
      return;
    }

    final event = await NostrFunctionsRepository.getEventById(
      isIdentifier: false,
      eventId: id,
    );

    if (event == null) {
      BotToastUtils.showInformation(context.t.notificationEventNotFound);
      return;
    }

    if (event.kind == EventKind.TEXT_NOTE) {
      _handleNotificationEventView(event: event, context: context);
    } else {
      _handleNonNoteActions(event, context);
    }
  }

  Future<void> _handleNonNoteActions(Event event, BuildContext context) async {
    String? parent;
    bool isRepleaceable = false;

    final kind = event.kind;

    for (final tag in event.tags) {
      if (kind == EventKind.REACTION ||
          kind == EventKind.REPOST ||
          kind == EventKind.ZAP) {
        if ((tag.first == 'a' || tag.first == 'e') && tag.length > 1) {
          if (tag.first == 'e') {
            parent = tag[1];
            isRepleaceable = false;
          } else {
            if (tag[1].contains(':')) {
              parent = tag[1].split(':').last;
            }

            isRepleaceable = true;
          }
        }
      }
    }

    if (parent != null && parent.isNotEmpty) {
      final e = await NostrFunctionsRepository.getEventById(
        isIdentifier: isRepleaceable,
        eventId: parent,
      );

      if (e != null) {
        _handleNotificationEventView(event: e, context: context);
      } else {
        BotToastUtils.showInformation(context.t.notificationEventNotFound);
      }
    }
  }

  void _handleNotificationEventView(
      {required Event event, required BuildContext context}) {
    switch (event.kind) {
      case EventKind.TEXT_NOTE:
        YNavigator.pushPage(
          context,
          (_) => NoteView(
            note: DetailedNoteModel.fromEvent(event),
          ),
        );
      case EventKind.LONG_FORM:
        YNavigator.pushPage(
          context,
          (_) => ArticleView(
            article: Article.fromEvent(event),
          ),
        );
      case EventKind.CURATION_ARTICLES:
        YNavigator.pushPage(
          context,
          (_) => CurationView(
            curation: Curation.fromEvent(event, ''),
          ),
        );
      case EventKind.CURATION_VIDEOS:
        YNavigator.pushPage(
          context,
          (_) => CurationView(
            curation: Curation.fromEvent(event, ''),
          ),
        );
      case EventKind.VIDEO_VERTICAL:
        YNavigator.pushPage(
          context,
          (_) => VerticalVideoView(
            video: VideoModel.fromEvent(event),
          ),
        );
      case EventKind.VIDEO_HORIZONTAL:
        YNavigator.pushPage(
          context,
          (_) => HorizontalVideoView(
            video: VideoModel.fromEvent(event),
          ),
        );
      case EventKind.SMART_WIDGET_ENH:
        YNavigator.pushPage(
          context,
          (_) => SmartWidgetChecker(
            swm: SmartWidget.fromEvent(event),
          ),
        );
    }
  }

  Future<void> _laterSearch() async {
    if (_needUpdateIds.isEmpty && _needUpdateDTags.isEmpty) {
      return;
    }

    NostrFunctionsRepository.getEvents(
      ids: _needUpdateIds,
      dTags: _needUpdateDTags,
    ).listen(
      _onEvent,
      onDone: () {},
    );

    _needUpdateIds.clear();
    _needUpdateDTags.clear();
  }

  Future<void> _laterSealedSearch() async {
    if (_sealedIds.isEmpty) {
      return;
    }

    final currentSealedNotes = Map<String, SealedNote>.from(state.sealedNotes);
    final currentSealedIds = List<String>.from(_sealedIds);

    final fetchedSealedNotes =
        await HttpFunctionsRepository.getSealedNotesByIds(
      flashNewsIds: currentSealedIds,
    );

    if (fetchedSealedNotes.isNotEmpty) {
      currentSealedNotes.addAll(fetchedSealedNotes);
      if (!isClosed) {
        emit(
          state.copyWith(
            sealedNotes: currentSealedNotes,
          ),
        );
      }
    }

    _sealedIds.clear();
  }

  Future<void> zapPollSearch(String id, Function() onFinished) async {
    if (id.isEmpty) {
      return;
    }

    final cancel = BotToast.showLoading();

    final currentZapPolls = Map<String, List<PollStat>>.from(state.pollStats);
    final zaps = <String, Event>{};

    NostrFunctionsRepository.getEvents(
      eTags: [id],
      kinds: [EventKind.ZAP],
    ).listen(
      (event) {
        zaps[event.id] = event;
      },
      onDone: () async {
        await Future.delayed(const Duration(seconds: 1));
        final List<PollStat> pollStats = [];

        if (zaps.isNotEmpty) {
          for (final zap in zaps.values.toList()) {
            final stats = getZapByPollStats(zap);

            final createdAt =
                DateTime.fromMillisecondsSinceEpoch(zap.createdAt * 1000);

            pollStats.add(
              PollStat(
                pubkey: stats['pubkey'] ?? '',
                zapAmount: stats['amount'] ?? 0,
                createdAt: createdAt,
                index: stats['index'] ?? -1,
              ),
            );
          }

          currentZapPolls[id] = pollStats;
          if (!isClosed) {
            emit(
              state.copyWith(
                pollStats: currentZapPolls,
              ),
            );
          }
        } else {
          currentZapPolls[id] = [];
          if (!isClosed) {
            emit(
              state.copyWith(
                pollStats: currentZapPolls,
              ),
            );
          }
        }

        onFinished.call();
        cancel.call();
      },
    );
  }

  void _onEvent(Event event) {
    _pendingEvents.add(event);

    later(_laterCallback, null);
  }

  @override
  Future<void> close() {
    disposeLater();
    return super.close();
  }
}
