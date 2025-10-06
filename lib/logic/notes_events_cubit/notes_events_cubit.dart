// ignore_for_file: prefer_foreach

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/event_stats.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/detailed_note_model.dart';
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
            mutes: nostrRepository.mutes.toList(),
          ),
        ) {
    _init();
  }

  late final StreamSubscription muteListSubscription;
  late final StreamSubscription bookmarksSubscription;

  final maxCacheSize = 100;
  final alreadySearchedContentIds = <String>{};
  final _notesIds = <String>[];
  final _aTags = <String>[];
  final _pendingNotesEvents = <String, Event>{};
  final _accessTimes = <String, int>{};

  Timer? _pendingEventsTimer;
  Map<String, Event>? _pendingEventsBuffer;

  void pruneCache({int maxEntries = 100}) {
    if (state.eventsStats.length <= maxEntries) {
      return;
    }

    // Sort by last access time (most recent first)
    final sortedIds = state.eventsStats.keys.toList()
      ..sort((a, b) {
        final timeA = _accessTimes[a] ?? 0;
        final timeB = _accessTimes[b] ?? 0;
        return timeB.compareTo(timeA); // Most recent first
      });

    // Keep only the most recently accessed entries
    final keysToKeep = sortedIds.take(maxEntries).toSet();
    final keysToRemove = sortedIds.skip(maxEntries).toSet();

    alreadySearchedContentIds.removeAll(keysToRemove);

    final prunedCache = {
      for (final key in keysToKeep) key: state.eventsStats[key]!
    };

    // Clean up access times for removed entries
    _accessTimes.removeWhere((key, _) => !keysToKeep.contains(key));

    lg.i(
      '🧹 Pruned cache from ${state.eventsStats.length} to $maxEntries entries',
    );

    emit(state.copyWith(eventsStats: prunedCache));
  }

  void _init() {
    muteListSubscription = nostrRepository.mutesStream.listen(_onMutesUpdate);
    bookmarksSubscription =
        nostrRepository.bookmarksStream.listen(_onBookmarksUpdate);
  }

  void _onMutesUpdate(Set<String> mutes) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(mutes: mutes.toList()));
  }

  void _onBookmarksUpdate(Map<String, BookmarkListModel> bookmarks) {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(bookmarks: getBookmarkIds(bookmarks).toSet()));
  }

  Future<void> getSpecificContentStats(String id, {bool r = false}) async {
    EventStats? eventStats = state.eventsStats[id];
    eventStats ??= await nc.db.loadEventStats(id);

    if (eventStats != null && !isClosed) {
      _accessTimes[id] = Helpers.now;

      final stats = Map<String, EventStats>.from(state.eventsStats)
        ..addAll(
          {
            eventStats.eventId: eventStats,
          },
        );

      updateEventStats(stats);
    }

    final searchedEvents = <Event>[];

    NostrFunctionsRepository.getContentStats(
      noteIds: [id],
      aTags: _aTags,
      since: eventStats != null ? eventStats.newestCreatedAt + 1 : null,
    ).listen(
      (event) {
        searchedEvents.add(event);
        later(
          () => _handleContentStats(searchedEvents),
          null,
        );
      },
    );
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
    final rawReplies = noteStats.filteredReplies(mutes);
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

    final Map<String, String> eventsData = await _getEventDataByType(
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
        final replies = stats.filteredReplies(state.mutes);
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

  void getContentStats(String id, {bool r = false}) {
    _accessTimes[id] = Helpers.now;

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
    later(() => _laterContentSearch(), null);
  }

  void updateEventStats(Map<String, EventStats> stats) {
    if (isClosed) {
      return;
    }

    emit(state.copyWith(eventsStats: stats));

    if (stats.length >= 150) {
      pruneCache(maxEntries: maxCacheSize);
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
    _accessTimes[eventStat.eventId] = Helpers.now;

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

    final Map<String, List<Event>> eventsByParent = {};
    for (final ev in events) {
      final id = ev.getEventParent();

      if (id != null) {
        (eventsByParent[id] ??= []).add(ev);
      }
    }

    if (eventsByParent.isEmpty) {
      return;
    }

    final currentEventStats = Map<String, EventStats>.from(state.eventsStats);

    eventsByParent.forEach((id, events) {
      processEvents(id, events, currentEventStats);
      _accessTimes[id] = Helpers.now;
    });

    updateEventStats(currentEventStats);
  }

  void _onContentEvent(Event event) {
    if (_pendingEventsBuffer != null) {
      _pendingEventsBuffer![event.id] = event;
    } else {
      _pendingEventsBuffer = {event.id: event};
      _pendingEventsTimer?.cancel();
      _pendingEventsTimer =
          Timer(const Duration(milliseconds: 300), _processBufferedEvents);
    }
  }

  Future<void> processEvents(
    String id,
    List<Event> events,
    Map<String, EventStats> currentEventStats,
  ) async {
    alreadySearchedContentIds.add(id);

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

    currentEventStats[id] = updatedNStats;
    await nc.db.saveEvents(events);
    await nc.db.saveEventStats(updatedNStats);
  }

  Future<List<DetailedNoteModel>> getNotePrevious(
    DetailedNoteModel note,
    Function(bool) setLoading,
  ) async {
    if (note.isRoot) {
      return [];
    }

    try {
      setLoading(true);

      // Check if we already have the previous notes cached
      final List<DetailedNoteModel>? cachedNotes = state.previousNotes[note.id];

      if (cachedNotes != null) {
        setLoading(false);
        return cachedNotes;
      }

      final availablePreviousNotes = await searchPreviousNotes(note);

      // Get content stats for all found notes
      for (final e in availablePreviousNotes) {
        getContentStats(e.id);
      }

      // Update state with new notes
      if (!isClosed) {
        final map =
            Map<String, List<DetailedNoteModel>>.from(state.previousNotes);
        map[note.id] = availablePreviousNotes;

        emit(
          state.copyWith(
            previousNotes: map,
          ),
        );
      }

      setLoading(false);
      return availablePreviousNotes;
    } catch (e, stack) {
      lg.i(stack);
      setLoading(false);
      return [];
    }
  }

  Future<List<DetailedNoteModel>> searchPreviousNotes(
    DetailedNoteModel note,
  ) async {
    List<DetailedNoteModel> notes = await getCachedPreviousNotes(note);

    if (notes.isNotEmpty && notes.first.isRoot) {
      return notes;
    }

    final previousEventId = note.originId ?? '';

    if (previousEventId.isEmpty) {
      return notes;
    }

    final events = <String, Event>{};

    await nc.doQuery(
      <Filter>[
        Filter(
          e: <String>[previousEventId],
          kinds: <int>[EventKind.TEXT_NOTE],
        ),
        Filter(
          ids: <String>[previousEventId],
          kinds: <int>[EventKind.TEXT_NOTE],
        ),
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

    if (events.isNotEmpty) {
      nc.db.saveEvents(events.values.toList());
      notes = await getCachedPreviousNotes(note);
    }

    return notes;
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

    if (e == null || e.kind != EventKind.TEXT_NOTE) {
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

  Future<void> _laterContentSearch() async {
    if (_notesIds.isEmpty && _aTags.isEmpty) {
      return;
    }

    NostrFunctionsRepository.getContentStats(
      noteIds: List.from(_notesIds),
      aTags: List.from(_aTags),
    ).listen(_onContentEvent);

    _notesIds.clear();
    _aTags.clear();
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

    _accessTimes[note.id] = Helpers.now;
    updateEventStats(stats);
  }

  Future<void> _createRepost(
    DetailedNoteModel note,
    EventStats eventStats,
    Map<String, EventStats> stats,
  ) async {
    final cancel = BotToast.showLoading();

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
      nc.db.saveEvent(event);
      final ns = eventStats.addEvent(event);
      stats[note.id] = ns;
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

    _accessTimes[id] = Helpers.now;
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
    final ns = eventStats.addEvent(event);
    stats[ns.eventId] = ns;
    nc.db.saveEventStats(ns);

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

  void getContentStatsOptimized(String id, {bool r = false}) {
    // Check if already processed recently

    if (alreadySearchedContentIds.contains(id)) {
      return;
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

    later(
      () => _laterContentSearch(),
      null,
    );
  }
}
