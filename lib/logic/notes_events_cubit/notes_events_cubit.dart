// ignore_for_file: prefer_foreach

import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/event_stats.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/mute_model.dart';
import '../../models/wot_configuration.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'notes_events_state.dart';

class NotesEventsCubit extends Cubit<NotesEventsState> with LaterFunction {
  NotesEventsCubit()
      : super(
          NotesEventsState(
            eventsStats: const {},
            previousNotes: const <String, List<DetailedNoteModel>>{},
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            mutesEvents: nostrRepository.muteModel.eventsMutes.toList(),
            deletedNotes: const {},
          ),
        ) {
    _init();
  }

  late final StreamSubscription muteListSubscription;
  late final StreamSubscription bookmarksSubscription;

  final statesMaxCacheSize = 50;
  final previousMaxCacheSize = 20;
  final alreadySearchedContentIds = <String>{};
  final _requestedStatIds = <String>{};
  final _notesIds = <String>[];
  final _aTags = <String>[];
  final _pendingNotesEvents = <String, Event>{};
  final _statsAccessTimes = <String, int>{};
  final _previousNotesAccessTime = <String, int>{};

  Timer? _pendingEventsTimer;
  Map<String, Event>? _pendingEventsBuffer;
  bool _includeCommentsInLaterSearch = false;

  void pruneCache({bool isStats = true}) {
    if (isStats) {
      _pruneCacheInternal(
        cache: state.eventsStats,
        accessTimes: _statsAccessTimes,
        maxSize: statesMaxCacheSize,
        name: 'eventsStats',
        updateState: (pruned) => state.copyWith(eventsStats: pruned),
      );
    } else {
      final removedKeys = state.previousNotes.keys.toSet();
      _pruneCacheInternal(
        cache: state.previousNotes,
        accessTimes: _previousNotesAccessTime,
        maxSize: previousMaxCacheSize,
        name: 'previousNotes',
        updateState: (pruned) => state.copyWith(previousNotes: pruned),
      );
      removedKeys.removeAll(state.previousNotes.keys);

      for (final key in removedKeys) {
        localDatabaseRepository.removePreviousNoteChain(key);
      }
    }
  }

  void _pruneCacheInternal<K, V>({
    required Map<K, V> cache,
    required Map<K, int> accessTimes,
    required int maxSize,
    required String name,
    required Function(Map<K, V>) updateState,
  }) {
    if (cache.length <= maxSize) {
      return;
    }

    // Sort keys by access time (most recent first)
    final sortedIds = cache.keys.toList()
      ..sort((a, b) => (accessTimes[b] ?? 0).compareTo(accessTimes[a] ?? 0));

    // Split into keep/remove sets
    final keysToKeep = sortedIds.take(maxSize).toSet();
    final keysToRemove = sortedIds.skip(maxSize);

    // Bulk remove from alreadySearchedContentIds
    alreadySearchedContentIds.removeAll(keysToRemove);
    _requestedStatIds.removeAll(keysToRemove);

    // Rebuild cache with kept entries only
    final prunedCache = Map<K, V>.fromEntries(
        keysToKeep.map((key) => MapEntry(key, cache[key] as V)));

    // Clean up access times
    accessTimes.removeWhere((key, _) => !keysToKeep.contains(key));

    lg.w('🧹 Pruned $name cache from ${cache.length} to $maxSize entries');

    emit(updateState(prunedCache));
  }

  void _init() {
    muteListSubscription = nostrRepository.mutesStream.listen(_onMutesUpdate);
    bookmarksSubscription =
        nostrRepository.bookmarksStream.listen(_onBookmarksUpdate);
  }

  void _onMutesUpdate(MuteModel mm) {
    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        mutes: mm.usersMutes.toList(),
        mutesEvents: mm.eventsMutes.toList(),
      ),
    );
  }

  void _onBookmarksUpdate(Map<String, BookmarkListModel> bookmarks) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(bookmarks: getBookmarkIds(bookmarks).toSet()));
  }

  Future<void> getSpecificContentStats(
    String id, {
    bool r = false,
    bool includeComments = false,
    String? authorPubkey,
  }) async {
    _requestedStatIds.add(id);
    EventStats? eventStats = state.eventsStats[id];
    eventStats ??= await nc.db.loadEventStats(id);

    if (eventStats != null && !isClosed) {
      _statsAccessTimes[id] = Helpers.now;

      final stats = Map<String, EventStats>.from(state.eventsStats)
        ..addAll(
          {
            eventStats.eventId: eventStats,
          },
        );

      updateEventStats(stats);
    }

    NostrFunctionsRepository.getContentStats(
      noteIds: r ? [] : [id],
      aTags: r ? [id] : [],
      since: eventStats != null ? eventStats.newestCreatedAt + 1 : null,
      includeComments: includeComments,
      authorPubkey: authorPubkey,
    ).listen((event) => _handleContentStats([event]));

    // .listen(
    //   (event) {
    //     received = true;
    //     if (!isClosed) {
    //       _applyEventsBatch([event]);
    //     }
    //   },
    //   onDone: () {
    //     if (isClosed) {
    //       return;
    //     }

    //     if (!received && state.eventsStats[id] == null) {
    //       final stats = Map<String, EventStats>.from(state.eventsStats)
    //         ..[id] = EventStats.empty(id);
    //       updateEventStats(stats);
    //     }
    //   },
    // );
  }

  Map<String, dynamic> getDirectStats(String id) {
    final pubkey = currentSigner?.getPublicKey() ?? '';
    final noteStats = state.eventsStats[id];

    if (noteStats == null) {
      return getEmptyStats();
    }

    // final filteredStats = await getFilteredStats(
    //   noteStats: noteStats,
    // );

    final zapsData = noteStats.getZapsData(state.mutes);
    final zappers = noteStats.getZappersList(state.mutes);

    return {
      'replies': noteStats.replies,
      'reposts': noteStats.reposts,
      'quotes': noteStats.quotes,
      'reactions': noteStats.reactions,
      'zapsData': zapsData,
      'zappers': zappers,
      'selfReply': noteStats.isSelfReply(pubkey),
      'selfQuote': noteStats.isSelfQuote(pubkey),
      'selfRepost': noteStats.isSelfRepost(pubkey),
      'selfReaction': noteStats.isSelfReaction(pubkey),
      'selfZaps': noteStats.isSelfZap(pubkey),
    };
  }

  Map<String, dynamic> getEmptyStats() {
    return {
      'replies': <String, String>{},
      'reposts': <String, String>{},
      'quotes': <String, String>{},
      'reactions': <String, String>{},
      'zapsData': EventStats.emptyZapData(),
      'zappers': <String, MapEntry<String, int>>{},
      'selfReply': false,
      'selfQuote': false,
      'selfRepost': false,
      'selfReaction': null,
      'selfZaps': false,
    };
  }

  Future<Map<String, Map<String, String>>> getFilteredStats({
    required EventStats noteStats,
  }) async {
    final mutes = state.mutes;
    final rawReplies = noteStats.filteredReplies(mutes, state.mutesEvents);
    final rawReposts = noteStats.filteredReposts(mutes);
    final rawQuotes = noteStats.filteredQuotes(mutes);
    final rawReactions = noteStats.filteredReactions(mutes);

    WotConfiguration? conf;

    if (canSign()) {
      conf = nostrRepository.getWotConfiguration(
        currentSigner!.getPublicKey(),
      );
    }

    if (!canSign() || conf == null || !conf.isEnabled || !conf.postActions) {
      return {
        'replies': rawReplies,
        'reposts': rawReposts,
        'quotes': rawQuotes,
        'reactions': rawReactions,
      };
    }

    // Collect ALL unique pubkeys from all interaction types
    final allPubkeys = <String>{
      ...rawReplies.values,
      ...rawReposts.values,
      ...rawQuotes.values,
      ...rawReactions.values,
    }.toList();

    if (allPubkeys.isEmpty) {
      return {
        'replies': rawReplies,
        'reposts': rawReposts,
        'quotes': rawQuotes,
        'reactions': rawReactions,
      };
    }

    // Single WoT call - let the core handle its own database caching
    final wotScores = await nc.calculatePeerPubkeyWotList(
      peerPubkeys: allPubkeys,
      originPubkey: currentSigner!.getPublicKey(),
    );

    // Apply filtering with single-pass approach
    return {
      'replies': _filterByWotScores(rawReplies, wotScores, conf.threshold),
      'reposts': _filterByWotScores(rawReposts, wotScores, conf.threshold),
      'quotes': _filterByWotScores(rawQuotes, wotScores, conf.threshold),
      'reactions': _filterByWotScores(rawReactions, wotScores, conf.threshold),
    };
  }

  Map<String, String> _filterByWotScores(
    Map<String, String> data,
    Map<String, num?> wotScores,
    double defaultWotScore,
  ) {
    if (data.isEmpty) {
      return data;
    }

    final filtered = <String, String>{};

    for (final entry in data.entries) {
      final score = wotScores[entry.value] ?? 0;
      if (score >= defaultWotScore ||
          entry.value == currentSigner!.getPublicKey()) {
        filtered[entry.key] = entry.value;
      }
    }

    return filtered;
  }

  Future<List<Event>> loadNoteRelatedEvents({
    required String id,
    required NoteRelatedEventsType type,
    bool fetchAllMetadata = true,
  }) async {
    final eventStats = state.eventsStats[id];

    if (eventStats == null) {
      return [];
    }

    final eventsData = await _getEventDataByType(
      eventStats,
      type,
    );

    if (eventsData.isEmpty) {
      return [];
    }

    if (fetchAllMetadata) {
      metadataCubit.fetchMetadata(eventsData.values.toList());
    }

    final evs = await nc.db.loadEvents(
      f: Filter(
        ids: eventsData.keys.toList(),
      ),
    );

    return evs;
  }

  Future<Map<String, String>> _getEventDataByType(
    EventStats stats,
    NoteRelatedEventsType type,
  ) async {
    switch (type) {
      case NoteRelatedEventsType.replies:
        final replies = stats.filteredReplies(state.mutes, state.mutesEvents);
        return getSpecificFilteredWot(replies);
      case NoteRelatedEventsType.reposts:
        final reposts = stats.filteredReposts(state.mutes);
        return getSpecificFilteredWot(reposts);
      case NoteRelatedEventsType.quotes:
        final quotes = stats.filteredQuotes(state.mutes);
        return getSpecificFilteredWot(quotes);
      case NoteRelatedEventsType.reactions:
        final reactions = stats.filteredReactions(state.mutes);
        return getSpecificFilteredWot(reactions);
      case NoteRelatedEventsType.zaps:
        return const {};
    }
  }

  Future<Map<String, String>> getSpecificFilteredWot(
    Map<String, String> map,
  ) async {
    if (!canSign()) {
      return map;
    }

    final conf = nostrRepository.getWotConfiguration(
      currentSigner!.getPublicKey(),
    );

    if (conf.isEnabled && conf.postActions) {
      final wotScores = await nc.calculatePeerPubkeyWotList(
        peerPubkeys: map.values.toList(),
        originPubkey: currentSigner!.getPublicKey(),
      );

      return _filterByWotScores(map, wotScores, conf.threshold);
    }

    return map;
  }

  void getContentStats(
    String id, {
    bool r = false,
    bool includeComments = false,
  }) {
    _statsAccessTimes[id] = Helpers.now;

    if (includeComments) {
      _includeCommentsInLaterSearch = true;
    }

    if (alreadySearchedContentIds.contains(id)) {
      return;
    }

    if (!r && !_notesIds.contains(id)) {
      _notesIds.add(id);
    }

    if (r && !_aTags.contains(id)) {
      _aTags.add(id);
    }

    loadCachedContentStats(id);
    // Tearoff, not a fresh closure: later() dedupes on the callback, and
    // tearoffs of the same method compare equal while closures never do.
    later(_laterContentSearch, null);
  }

  void updateEventStats(Map<String, EventStats> stats) {
    if (isClosed) {
      return;
    }

    emit(state.copyWith(eventsStats: stats));

    if (stats.length >= statesMaxCacheSize * 2) {
      pruneCache();
    }
  }

  void updatePreviousNotes(Map<String, List<DetailedNoteModel>> previousNotes) {
    if (isClosed) {
      return;
    }

    emit(state.copyWith(previousNotes: previousNotes));

    if (previousNotes.length >= previousMaxCacheSize * 2) {
      pruneCache(isStats: false);
    }
  }

  Future<void> loadCachedContentStats(String id) async {
    final eventStat = await nc.db.loadEventStats(id);

    if (eventStat == null || isClosed) {
      return;
    }

    alreadySearchedContentIds.add(id);

    final currentEventStatsList = Map<String, EventStats>.from(
      state.eventsStats,
    );

    currentEventStatsList[eventStat.eventId] = eventStat;
    _statsAccessTimes[eventStat.eventId] = Helpers.now;

    updateEventStats(currentEventStatsList);
  }

  void _handleContentStats(Iterable<Event> list) {
    if (_pendingEventsBuffer == null) {
      _pendingEventsBuffer = {};
      _pendingEventsTimer?.cancel();
      _pendingEventsTimer = Timer(
        const Duration(milliseconds: 300),
        _processBufferedEvents,
      );
    }

    for (final ev in list) {
      _pendingEventsBuffer![ev.id] = ev;
    }

    _pendingNotesEvents.clear();
  }

  void _processBufferedEvents() {
    if (_pendingEventsBuffer == null || _pendingEventsBuffer!.isEmpty) {
      _pendingEventsBuffer = null;
      return;
    }

    final events = _pendingEventsBuffer!.values.toList();
    _pendingEventsBuffer = null;

    _applyEventsBatch(events);
  }

  void _applyEventsBatch(List<Event> events) {
    if (events.isEmpty) {
      return;
    }

    final Map<String, List<Event>> eventsByParent = {};
    for (final ev in events) {
      String? id;

      if (ev.kind == EventKind.COMMENT) {
        String? rootId;
        for (final tag in ev.tags) {
          if (tag.length > 1) {
            if (tag.first == 'e' || tag.first == 'a') {
              id = tag[1];
              break;
            } else if ((tag.first == 'E' || tag.first == 'A') &&
                rootId == null) {
              rootId = tag[1];
            }
          }
        }
        id ??= rootId;
      }

      id ??= ev.getEventParent();

      // Fallback for Kind 1111 or articles/videos where getEventParent might fail
      if (id == null || id.isEmpty) {
        for (final tag in ev.tags) {
          if ((tag.first == 'A' ||
                  tag.first == 'E' ||
                  tag.first == 'a' ||
                  tag.first == 'e') &&
              tag.length > 1) {
            id = tag[1];
            break;
          }
        }
      }

      if (id != null) {
        (eventsByParent[id] ??= []).add(ev);
      }
    }

    if (eventsByParent.isEmpty) {
      return;
    }

    final currentEventStats = Map<String, EventStats>.from(state.eventsStats);
    final statsBatch = <EventStats>[];

    eventsByParent.forEach((id, eventsForParent) {
      final stats = processEvents(id, eventsForParent, currentEventStats);
      statsBatch.add(stats);
      _statsAccessTimes[id] = Helpers.now;
    });

    updateEventStats(currentEventStats);

    // Defer DB writes until after the current frame — keeps the main thread free
    // during the burst of stat updates that happens on startup and feed load.
    Future.microtask(() {
      nc.db.saveEvents(events);
      nc.db.saveEventStatsList(statsBatch);
    });
  }

  // Returns the computed EventStats so the caller can batch-write all stats at once.
  EventStats processEvents(
    String id,
    List<Event> events,
    Map<String, EventStats> currentEventStats,
  ) {
    if (_requestedStatIds.contains(id)) {
      alreadySearchedContentIds.add(id);
    }

    final nStats = currentEventStats[id] ??
        EventStats(
          eventId: id,
          reactions: const {},
          replies: const {},
          quotes: const {},
          reposts: const {},
          zaps: const {},
          newestCreatedAt: 0,
        );

    final updatedNStats = nStats.addEvents(events);

    // Manually ensure Kind 1111 events are in the replies map if not already added
    final newReplies = Map<String, String>.from(updatedNStats.replies);
    bool changed = false;

    for (final e in events) {
      if (e.kind == EventKind.COMMENT && !newReplies.containsKey(e.id)) {
        newReplies[e.id] = e.pubkey;
        changed = true;
      }
    }

    final finalStats = changed
        ? EventStats(
            eventId: updatedNStats.eventId,
            reactions: updatedNStats.reactions,
            replies: newReplies,
            quotes: updatedNStats.quotes,
            reposts: updatedNStats.reposts,
            zaps: updatedNStats.zaps,
            newestCreatedAt: updatedNStats.newestCreatedAt,
          )
        : updatedNStats;

    currentEventStats[id] = finalStats;
    return finalStats;
  }

  Future<List<DetailedNoteModel>> getNotePrevious(
    DetailedNoteModel note,
    Function(bool) setLoading, {
    bool Function()? isActive,
  }) async {
    if (note.isRoot) {
      return [];
    }

    try {
      setLoading(true);

      // Check if we already have the previous notes cached
      final List<DetailedNoteModel>? cachedNotes = state.previousNotes[note.id];

      if (cachedNotes != null &&
          (cachedNotes.isEmpty ||
              _isCompletePreviousChain(note, cachedNotes))) {
        setLoading(false);
        _previousNotesAccessTime[note.id] = Helpers.now;
        return cachedNotes;
      }

      // Reconstruct from the persisted chain (root-first event ids) so repeat
      // opens skip the network walk entirely.
      final persistedNotes = await _reconstructPreviousNotes(note.id);
      if (persistedNotes != null) {
        setLoading(false);
        _previousNotesAccessTime[note.id] = Helpers.now;
        if (!isClosed) {
          final map =
              Map<String, List<DetailedNoteModel>>.from(state.previousNotes);
          map[note.id] = persistedNotes;
          updatePreviousNotes(map);
        }
        return persistedNotes;
      }

      if (isActive?.call() == false) {
        setLoading(false);
        return [];
      }

      final searchedPreviousNotes = await searchPreviousNotes(
        note,
        isActive: isActive,
      );

      // A reply can name a valid root while its immediate parent has been
      // deleted or is unavailable on the queried relays. Keep that root as
      // useful context instead of discarding the whole thread.
      final availablePreviousNotes = await _addRootFallback(
        note,
        searchedPreviousNotes,
      );

      if (isActive?.call() == false) {
        setLoading(false);
        return [];
      }

      // Persist the resolved chain so later opens of this thread are instant.
      if (_isCompletePreviousChain(note, availablePreviousNotes)) {
        await localDatabaseRepository.setPreviousNoteChain(
          note.id,
          availablePreviousNotes.map((e) => e.id).toList(),
        );
      }

      // Get content stats for all found notes
      for (final e in availablePreviousNotes) {
        getContentStats(e.id);
      }

      // Update state with new notes
      if (!isClosed) {
        final map =
            Map<String, List<DetailedNoteModel>>.from(state.previousNotes);
        map[note.id] = availablePreviousNotes;

        _previousNotesAccessTime[note.id] = Helpers.now;
        updatePreviousNotes(map);
      }

      setLoading(false);
      return availablePreviousNotes;
    } catch (e, stack) {
      lg.i(stack);
      setLoading(false);
      return [];
    }
  }

  Future<List<DetailedNoteModel>> _addRootFallback(
    DetailedNoteModel note,
    List<DetailedNoteModel> notes,
  ) async {
    if ((notes.isNotEmpty && notes.first.isRoot) ||
        note.isOriginEtag != true ||
        note.originId == null ||
        note.originId!.isEmpty) {
      return notes;
    }

    final event = await nc.db.loadEventById(note.originId!, false);
    if (event == null ||
        (event.kind != EventKind.TEXT_NOTE &&
            event.kind != EventKind.COMMENT)) {
      return notes;
    }

    final root = DetailedNoteModel.fromEvent(event);
    if (!root.isRoot || notes.any((n) => n.id == root.id)) {
      return notes;
    }

    return [root, ...notes];
  }

  bool _isCompletePreviousChain(
    DetailedNoteModel note,
    List<DetailedNoteModel> notes,
  ) {
    if (notes.isEmpty || !notes.first.isRoot) {
      return false;
    }

    for (var index = 1; index < notes.length; index++) {
      if (!_isDirectChildOf(notes[index], notes[index - 1])) {
        return false;
      }
    }

    return _isDirectChildOf(note, notes.last);
  }

  bool _isDirectChildOf(DetailedNoteModel child, DetailedNoteModel parent) {
    return child.replyTo == parent.id ||
        (child.replyTo.isEmpty && child.originId == parent.id);
  }

  Future<List<DetailedNoteModel>?> _reconstructPreviousNotes(
    String noteId,
  ) async {
    final chain = localDatabaseRepository.getPreviousNoteChain(noteId);
    if (chain == null || chain.isEmpty) {
      return null;
    }

    final notes = <DetailedNoteModel>[];
    for (final id in chain) {
      final e = await nc.db.loadEventById(id, false);
      if (e == null ||
          (e.kind != EventKind.TEXT_NOTE && e.kind != EventKind.COMMENT)) {
        return null;
      }
      notes.add(DetailedNoteModel.fromEvent(e));
    }

    if (notes.isEmpty || !notes.first.isRoot) {
      return null;
    }

    return notes;
  }

  Future<List<DetailedNoteModel>> searchPreviousNotes(
    DetailedNoteModel note, {
    bool Function()? isActive,
  }) async {
    List<DetailedNoteModel> notes = await getCachedPreviousNotes(note);

    if (notes.isNotEmpty && notes.first.isRoot) {
      return notes;
    }

    final previousEventId = note.originId ?? '';

    if (previousEventId.isEmpty) {
      return notes;
    }

    final kinds = <int>[EventKind.TEXT_NOTE, EventKind.COMMENT];
    final collected = <String, Event>{};
    final hintRelays = <String>{};
    final originEvent = _originEvent(note);

    if (originEvent != null) {
      hintRelays.addAll(eventRelayHints(originEvent));
    }

    lg.i(
      '[thread-walk] start note=${note.id} replyTo=${note.replyTo} origin=${note.originId} rootKind=${note.rootKind}',
    );

    // Fast path: recover the whole ancestor chain from the note's own e-tags
    // in a single batched query (general + hint relays concurrently), instead
    // of walking one missing event at a time.
    if (originEvent != null) {
      final uniqueETagIds =
          _eTagIds(originEvent).where((id) => id != note.id).toSet().toList();

      final dbEvents = await Future.wait(
        uniqueETagIds.map((id) => nc.db.loadEventById(id, false)),
      );

      final wantedIds = <String>[];
      for (var i = 0; i < uniqueETagIds.length; i++) {
        final existing = dbEvents[i];
        if (existing == null ||
            (existing.kind != EventKind.TEXT_NOTE &&
                existing.kind != EventKind.COMMENT)) {
          wantedIds.add(uniqueETagIds[i]);
        }
      }

      final batchIds = wantedIds.take(_maxThreadBatchSize).toList();
      if (batchIds.isNotEmpty) {
        final batchResults = await Future.wait([
          NostrFunctionsRepository.getEventsAsync(
            ids: batchIds,
            kinds: kinds,
          ),
          if (hintRelays.isNotEmpty)
            NostrFunctionsRepository.getEventsAsync(
              ids: batchIds,
              kinds: kinds,
              relays: hintRelays.toList(),
              source: EventsSource.all,
              timeout: 3,
            ),
        ]);

        for (final list in batchResults) {
          for (final ev in list) {
            if (ev.kind == EventKind.TEXT_NOTE ||
                ev.kind == EventKind.COMMENT) {
              collected[ev.id] = ev;
            }
          }
        }

        if (collected.isNotEmpty) {
          await nc.db.saveEvents(collected.values.toList());
          notes = await getCachedPreviousNotes(note);
        }

        lg.i(
          '[thread-walk] batch ids=${batchIds.length} got=${collected.length} rooted=${notes.isNotEmpty && notes.first.isRoot}',
        );
      }
    }

    if (notes.isEmpty || !notes.first.isRoot) {
      if (isActive?.call() == false) {
        return notes;
      }

      var frontier = <String>[previousEventId];
      const maxRounds = 10;
      const maxFrontierSize = 100;

      for (var round = 0; round < maxRounds && frontier.isNotEmpty; round++) {
        if (isActive?.call() == false) {
          return notes;
        }

        final events = <String, Event>{};

        await NostrFunctionsRepository.queryEvents(
          <Filter>[
            Filter(ids: frontier, kinds: kinds),
            Filter(e: frontier, kinds: kinds),
            Filter(capitalE: frontier, kinds: kinds),
          ],
          <String>[],
          source: EventsSource.all,
          eventCallBack: (Event ev, String r) {
            final e = events[ev.id];

            if (e == null || e.createdAt < ev.createdAt) {
              events[ev.id] = ev;
            }
          },
          timeOut: 1,
        );

        final fresh =
            events.values.where((ev) => !collected.containsKey(ev.id)).toList();

        lg.i(
          '[thread-walk] round=$round frontier=${frontier.length} got=${events.length} fresh=${fresh.length}',
        );

        if (fresh.isEmpty) {
          break;
        }

        for (final ev in fresh) {
          collected[ev.id] = ev;
        }

        frontier = fresh
            .where((ev) =>
                ev.kind == EventKind.TEXT_NOTE || ev.kind == EventKind.COMMENT)
            .take(maxFrontierSize)
            .map((ev) => ev.id)
            .toList();
      }

      if (collected.isNotEmpty) {
        await nc.db.saveEvents(collected.values.toList());
        notes = await getCachedPreviousNotes(note);
      }
    }

    if (isActive?.call() == false) {
      return notes;
    }

    if (notes.isEmpty || !notes.first.isRoot) {
      final chain = <DetailedNoteModel>[];
      String? nextId = note.replyTo.isNotEmpty ? note.replyTo : note.originId;
      var depth = 0;
      // Kept open across hops and closed once below: reconnecting to the
      // same growing hint-relay set on every hop was the main cost of this
      // walk (TLS/WS handshake + NIP-42 auth per hop, up to 100 hops).
      final walkedRelays = <String>{};

      lg.i('[thread-walk] fallback start nextId=$nextId hints=$hintRelays');

      try {
        while (nextId != null &&
            nextId.isNotEmpty &&
            depth < _maxFallbackWalkDepth) {
          if (isActive?.call() == false) {
            break;
          }

          depth++;

          var ev = await nc.db.loadEventById(nextId, false);

          if (ev == null ||
              (ev.kind != EventKind.TEXT_NOTE &&
                  ev.kind != EventKind.COMMENT)) {
            ev = null;

            if (hintRelays.isNotEmpty) {
              walkedRelays.addAll(hintRelays);
            }

            final fetchedLists = await Future.wait([
              NostrFunctionsRepository.getEventsAsync(
                ids: [nextId],
                kinds: kinds,
              ),
              if (hintRelays.isNotEmpty)
                NostrFunctionsRepository.getEventsAsync(
                  ids: [nextId],
                  kinds: kinds,
                  relays: hintRelays.toList(),
                  source: EventsSource.all,
                  timeout: 3,
                  closeRelaysOnFinish: false,
                ),
            ]);

            for (final list in fetchedLists) {
              for (final e in list) {
                if ((e.kind == EventKind.TEXT_NOTE ||
                        e.kind == EventKind.COMMENT) &&
                    ev == null) {
                  ev = e;
                }
              }
            }

            if (ev != null) {
              lg.i('[thread-walk] fetched missing $nextId');
              await nc.db.saveEvents([ev]);
            }
          }

          if (ev == null) {
            break;
          }

          hintRelays.addAll(_relayHints(ev));

          final n = DetailedNoteModel.fromEvent(ev);

          chain.insert(0, n);

          if (n.isRoot) {
            break;
          }

          nextId = n.replyTo.isNotEmpty ? n.replyTo : n.originId;
        }
      } finally {
        if (walkedRelays.isNotEmpty) {
          unawaited(nc.closeConnect(walkedRelays.toList()));
        }
      }

      if (chain.length > notes.length) {
        notes = chain;
      }
    }

    return notes;
  }

  Event? _originEvent(DetailedNoteModel note) {
    if (note.stringifiedEvent.isEmpty) {
      return null;
    }

    try {
      return Event.fromJson(
        jsonDecode(note.stringifiedEvent) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _eTagIds(Event event) {
    return event.tags
        .where((t) =>
            t.isNotEmpty && t.first == 'e' && t.length > 1 && t[1].isNotEmpty)
        .map((t) => t[1])
        .toList();
  }

  static const int _maxThreadBatchSize = 100;
  static const int _maxFallbackWalkDepth = 8;

  Set<String> _relayHints(Event event) {
    return eventRelayHints(event);
  }

  Future<List<DetailedNoteModel>> getCachedPreviousNotes(
    DetailedNoteModel note,
  ) async {
    if (note.isRoot) {
      return [];
    }

    List<DetailedNoteModel> thread = [];

    final previousEventId =
        note.replyTo.isNotEmpty ? note.replyTo : note.originId ?? '';

    if (previousEventId.isEmpty) {
      return thread;
    }

    final e = await nc.db.loadEventById(previousEventId, false);

    if (e == null ||
        (e.kind != EventKind.TEXT_NOTE && e.kind != EventKind.COMMENT)) {
      return thread;
    }

    final n = DetailedNoteModel.fromEvent(e);
    thread.add(n);

    if (!n.isRoot) {
      final cached = await getCachedPreviousNotes(n);
      thread = [...cached, ...thread];
    }

    return thread;
  }

  void _laterContentSearch() {
    if (_notesIds.isEmpty && _aTags.isEmpty) {
      return;
    }

    _requestedStatIds.addAll(_notesIds);
    _requestedStatIds.addAll(_aTags);

    NostrFunctionsRepository.getContentStats(
      noteIds: List.from(_notesIds),
      aTags: List.from(_aTags),
      includeComments: _includeCommentsInLaterSearch,
    ).listen((event) => _handleContentStats([event]));

    _notesIds.clear();
    _aTags.clear();
    _includeCommentsInLaterSearch = false;
  }

  Future<void> repostNote(DetailedNoteModel note) async {
    final stats = Map<String, EventStats>.from(state.eventsStats);

    final eventStats = stats[note.id] ??= EventStats.empty(note.id);

    final repostId = eventStats.reposts.entries
        .firstWhere(
          (entry) => entry.value == currentSigner!.getPublicKey(),
          orElse: () => const MapEntry('', ''),
        )
        .key;

    if (repostId.isEmpty) {
      await _createRepost(note, eventStats, stats);
    } else {
      await _deleteRepost(repostId, eventStats, stats);
    }

    _statsAccessTimes[note.id] = Helpers.now;
    updateEventStats(stats);
  }

  Future<void> _createRepost(
    DetailedNoteModel note,
    EventStats eventStats,
    Map<String, EventStats> stats,
  ) async {
    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.REPOST,
      tags: <List<String>>[
        <String>['e', note.id],
        <String>['p', note.pubkey],
      ],
      content: note.stringifiedEvent,
      signer: currentSigner,
    );

    cancel.call();

    if (event == null) {
      BotToastUtils.showError(t.errorGeneratingEvent.capitalizeFirst());
      return;
    }

    final relays = await broadcastRelays(note.pubkey);
    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: relays,
      setProgress: true,
      destinationPubkey: note.pubkey,
    );

    if (isSuccessful) {
      final ns = eventStats.addEvent(event);
      stats[note.id] = ns;
      nc.db.saveEvent(event);
      nc.db.saveEventStats(ns);
    }
  }

  Future<void> _deleteRepost(
    String repostId,
    EventStats eventStats,
    Map<String, EventStats> stats,
  ) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: repostId,
    );

    if (isSuccessful) {
      final ns = eventStats.removeRepost(repostId);
      stats[ns.eventId] = ns;
      nc.db.saveEventStats(ns);
    }
  }

  Future<bool> deleteNote(String id) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: id,
    );

    if (isSuccessful) {
      final eventsStats = Map<String, EventStats>.from(state.eventsStats);

      // Remove the note stats itself
      eventsStats.remove(id);

      // Remove the note from other stats where it might be a comment (reply)
      final idsToUpdate = <String>[];

      for (final entry in eventsStats.entries) {
        if (entry.value.replies.containsKey(id)) {
          idsToUpdate.add(entry.key);
        }
      }

      for (final parentId in idsToUpdate) {
        final stats = eventsStats[parentId];
        if (stats != null) {
          final updatedStats = stats.removeReply(id);

          eventsStats[parentId] = updatedStats;
          nc.db.saveEventStats(updatedStats);
        }
      }

      final previousNotes =
          Map<String, List<DetailedNoteModel>>.from(state.previousNotes);
      previousNotes.remove(id);

      emit(
        state.copyWith(
          eventsStats: eventsStats,
          previousNotes: previousNotes,
          deletedNotes: Set.from(state.deletedNotes)..add(id),
        ),
      );

      nostrRepository.notifyNoteDeletion(id);
      return true;
    }

    return false;
  }

  Future<void> onReact({
    required String id,
    required String pubkey,
    required bool r,
    String? customReaction,
  }) async {
    final stats = Map<String, EventStats>.from(state.eventsStats);

    // Get or create stats for this note
    final eventStats = stats[id] ??= EventStats.empty(id);

    // Check if already voted
    final voteId = eventStats.reactions.entries
        .firstWhere(
          (entry) => entry.value == currentSigner!.getPublicKey(),
          orElse: () => const MapEntry('', ''),
        )
        .key;

    if (voteId.isEmpty) {
      await _createReaction(id, pubkey, r, eventStats, stats, customReaction);
    } else {
      final ev = await nc.db.loadEventById(voteId, false);
      final reaction = customReaction ?? '+';
      final shouldReplace = ev != null && ev.content != reaction;

      if (shouldReplace) {
        await _deleteReaction(voteId, eventStats, stats);

        updateEventStats(stats);

        final es = stats[id] ??= EventStats.empty(id);
        await _createReaction(id, pubkey, r, es, stats, customReaction);
      } else {
        await _deleteReaction(voteId, eventStats, stats);
      }
    }

    _statsAccessTimes[id] = Helpers.now;
    updateEventStats(stats);
  }

  Future<void> _createReaction(
    String id,
    String pubkey,
    bool r,
    EventStats eventStats,
    Map<String, EventStats> stats,
    String? customReaction,
  ) async {
    final event = await Event.genEvent(
      kind: EventKind.REACTION,
      tags: <List<String>>[
        <String>[if (r) 'a' else 'e', id],
        <String>['p', pubkey],
      ],
      content: customReaction ?? '+',
      signer: currentSigner,
    );

    if (event == null) {
      return;
    }

    final relays = await broadcastRelays(pubkey);
    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: relays,
      setProgress: true,
      destinationPubkey: pubkey,
    );

    if (isSuccessful) {
      nc.db.saveEvent(event);
      final ns = eventStats.addEvent(event);
      stats[id] = ns;
      nc.db.saveEventStats(ns);
    }
  }

  Future<void> _deleteReaction(
    String voteId,
    EventStats eventStats,
    Map<String, EventStats> stats,
  ) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: voteId,
    );

    if (isSuccessful) {
      final ns = eventStats.removeReaction(voteId);
      stats[ns.eventId] = ns;
      nc.db.saveEventStats(ns);
    }
  }

  void handleSubmittedZap({
    required String eventId,
    required int amount,
    required bool isIdentifier,
    required String recipientPubkey,
    required String senderPubkey, // Current user's pubkey
  }) {
    final stats = Map<String, EventStats>.from(state.eventsStats);
    final eventStats = stats[eventId] ??= EventStats.empty(eventId);

    final tempZapId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_$senderPubkey';

    // Add optimistic zap directly to stats
    final updatedStats = eventStats.addOptimisticZap(
      zapId: tempZapId,
      zapperPubkey: senderPubkey,
      amount: amount,
    );

    stats[eventId] = updatedStats;

    updateEventStats(stats);

    fetchZapReceiptInBackground(
      eventId: eventId,
      senderPubkey: senderPubkey,
      receiverPubkey: recipientPubkey,
      tempZapId: tempZapId,
      isIdentifier: isIdentifier,
    );
  }

  Future<void> fetchZapReceiptInBackground({
    required String eventId,
    required String senderPubkey,
    required String receiverPubkey,
    required bool isIdentifier,
    String? tempZapId,
  }) async {
    const maxAttempts = 4;
    const delays = [2000, 5000, 10000, 15000];

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(Duration(milliseconds: delays[attempt]));

      final event = await NostrFunctionsRepository.getZapEvent(
        eventId: eventId,
        pTag: receiverPubkey,
        isIdentifier: isIdentifier,
      );

      if (event != null) {
        if (tempZapId != null) {
          // Replace optimistic zap with real one
          replaceOptimisticZapWithReal(
            eventId: eventId,
            tempZapId: tempZapId,
            realEvent: event,
          );
        } else {
          // Fallback to normal flow
          addEventRelatedData(event: event, replyNoteId: eventId);
        }
        return;
      }
    }
  }

  void replaceOptimisticZapWithReal({
    required String eventId,
    required String tempZapId,
    required Event realEvent,
  }) {
    final stats = Map<String, EventStats>.from(state.eventsStats);
    final eventStats = stats[eventId];

    if (eventStats != null) {
      nc.db.saveEvent(realEvent);
      final updatedStats = eventStats.replaceOptimisticZap(
        tempZapId: tempZapId,
        realZapEvent: realEvent,
      );
      stats[eventId] = updatedStats;
      nc.db.saveEventStats(updatedStats);

      updateEventStats(stats);
    }
  }

  void addEventRelatedData({
    required Event event,
    required String replyNoteId,
  }) {
    final stats = Map<String, EventStats>.from(state.eventsStats);

    final eventStats = stats[replyNoteId] ??= EventStats.empty(replyNoteId);

    nc.db.saveEvent(event);
    final updatedNStats = eventStats.addEvent(event);

    // Manually ensure Kind 1111 event is in the replies map
    if (event.kind == EventKind.COMMENT &&
        !updatedNStats.replies.containsKey(event.id)) {
      final newReplies = Map<String, String>.from(updatedNStats.replies);
      newReplies[event.id] = event.pubkey;

      final finalStats = EventStats(
        eventId: updatedNStats.eventId,
        reactions: updatedNStats.reactions,
        replies: newReplies,
        quotes: updatedNStats.quotes,
        reposts: updatedNStats.reposts,
        zaps: updatedNStats.zaps,
        newestCreatedAt: updatedNStats.newestCreatedAt,
      );

      stats[finalStats.eventId] = finalStats;
      nc.db.saveEventStats(finalStats);
    } else {
      stats[updatedNStats.eventId] = updatedNStats;
      nc.db.saveEventStats(updatedNStats);
    }

    updateEventStats(stats);
  }

  @override
  Future<void> close() {
    disposeLater();
    muteListSubscription.cancel();
    bookmarksSubscription.cancel();
    return super.close();
  }
}

extension OptimizedBatching on NotesEventsCubit {
  static final Set<String> _batchQueue = {};
  static Timer? _batchTimer;

  void getContentStatsOptimized(String id,
      {bool r = false, bool includeComments = false}) {
    // Check if already processed recently

    if (alreadySearchedContentIds.contains(id)) {
      return;
    }

    if (includeComments) {
      _includeCommentsInLaterSearch = true;
    }

    // Add to batch queue instead of immediate processing
    _batchQueue.add(id);

    // Cancel existing timer and start new batch window
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 200), () {
      _processBatch(r);
    });
  }

  void _processBatch(bool r) {
    if (_batchQueue.isEmpty) {
      return;
    }

    final batch = _batchQueue.toList();
    _batchQueue.clear();

    // Load cached stats first
    for (final id in batch) {
      loadCachedContentStats(id);
    }

    // Then batch network requests
    if (!r) {
      _notesIds.addAll(batch);
    } else {
      _aTags.addAll(batch);
    }

    later(_laterContentSearch, null);
  }
}
