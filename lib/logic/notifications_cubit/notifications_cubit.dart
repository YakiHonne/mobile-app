// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:collection';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/notifications/local_notification_manager.dart';
import '../../common/notifications/notification_helper.dart';
import '../../common/notifications/push_core.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit()
      : super(
          NotificationsState(
            events: const <Event>[],
            index: localDatabaseRepository
                .getMainViewSubTab(
                  currentSigner?.getPublicKey() ?? '',
                  'notifications',
                )
                .clamp(0, 5),
            isRead: true,
            refresh: false,
            isLoading: true,
          ),
        );

  int? since;
  String? notificationsSubscriptionId;
  bool isNotificationView = false;
  bool canShowNotification = true;
  bool initialized = false;
  bool _notificationsLoaded = false;
  String? _handledAccountPubkey;

  Map<String, List<String>> registredNotifications = <String, List<String>>{};
  Map<String, List<String>> newNotifications = <String, List<String>>{};

  Timer? _uiUpdateTimer;
  Timer? _notificationPersistenceTimer;
  Timer? _catchUpRetryTimer;
  final Map<String, Event> _unemittedEvents = {};
  final LinkedHashMap<String, Event> _recentLiveEvents = LinkedHashMap();
  final LinkedHashSet<String> _recentHandledEventIds = LinkedHashSet<String>();
  Future<void> _notificationPersistence = Future<void>.value();
  Future<void> _notificationCursorPersistence = Future<void>.value();
  Future<void>? _syncInFlight;
  Future<void>? _historyLoadInFlight;
  String? _livePubkey;
  String? _historyLoadedPubkey;
  String? _historySnapshotPubkey;
  final Map<String, Future<void>> _historySnapshotRestores = {};
  Future<void> _historySnapshotPersistence = Future<void>.value();
  bool _liveInitialized = false;
  int _syncGeneration = 0;
  int _historyGeneration = 0;
  final Map<String, int> _notificationBaselines = <String, int>{};

  void loadNotifications() {
    if (!_notificationsLoaded) {
      final registered = _loadBoundedNotificationMap(
        localDatabaseRepository.getNotifications(true),
        maxIds: 2000,
      );
      final unread = _loadBoundedNotificationMap(
        localDatabaseRepository.getNotifications(false),
        maxIds: 500,
      );
      registredNotifications = registered.map;
      newNotifications = unread.map;
      _notificationsLoaded = true;
      if (registered.changed || unread.changed) {
        unawaited(_persistNotificationMapsNow());
      }
    }

    if (canSign()) {
      final pubkey = currentSigner!.getPublicKey();
      _ensureNotificationBaseline(pubkey);
      if (_handledAccountPubkey != pubkey) {
        _recentHandledEventIds.clear();
        _rememberHandledIds([
          ...registredNotifications[pubkey] ?? <String>[],
          ...newNotifications[pubkey] ?? <String>[],
        ]);
        _handledAccountPubkey = pubkey;
      }
      _emitReadState();
    } else if (!isClosed) {
      emit(state.copyWith(isRead: true));
    }
  }

  void setNotificationView(bool isNotification) {
    isNotificationView = isNotification;
  }

  void _ensureNotificationBaseline(String pubkey) {
    final persistedSince =
        localDatabaseRepository.getNotificationSyncSince(pubkey);
    if (persistedSince != null) {
      final cachedSince = _notificationBaselines[pubkey];
      if (cachedSince == null || cachedSince <= persistedSince) {
        _notificationBaselines[pubkey] = persistedSince;
      } else {
        unawaited(_saveNotificationSyncSince(pubkey, cachedSince));
      }
      return;
    }

    final existingBaseline = _notificationBaselines[pubkey];
    if (existingBaseline != null) {
      return;
    }

    final baseline = _notificationBaselines.putIfAbsent(
      pubkey,
      () => DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    unawaited(_saveNotificationSyncSince(pubkey, baseline));
  }

  int? _notificationSyncSince(String pubkey) {
    final persistedSince =
        localDatabaseRepository.getNotificationSyncSince(pubkey);
    final cachedSince = _notificationBaselines[pubkey];
    if (persistedSince == null) {
      return cachedSince;
    }
    if (cachedSince == null || persistedSince >= cachedSince) {
      return persistedSince;
    }
    return cachedSince;
  }

  Future<void> _saveNotificationSyncSince(String pubkey, int timestamp) {
    final cachedSince = _notificationBaselines[pubkey];
    final persistedSince =
        localDatabaseRepository.getNotificationSyncSince(pubkey);
    var nextSince = timestamp;
    if (cachedSince != null && cachedSince > nextSince) {
      nextSince = cachedSince;
    }
    if (persistedSince != null && persistedSince > nextSince) {
      nextSince = persistedSince;
    }
    _notificationBaselines[pubkey] = nextSince;

    _notificationCursorPersistence = _notificationCursorPersistence.then(
      (_) =>
          localDatabaseRepository.setNotificationSyncSince(pubkey, nextSince),
    );
    return _notificationCursorPersistence;
  }

  Future<void> clear() async {
    await closeNotifications();

    since = null;
    _uiUpdateTimer?.cancel();
    _notificationPersistenceTimer?.cancel();
    _catchUpRetryTimer?.cancel();
    _unemittedEvents.clear();
    _recentLiveEvents.clear();
    _recentHandledEventIds.clear();
    _livePubkey = null;
    _handledAccountPubkey = null;
    _historyLoadedPubkey = null;
    _historySnapshotPubkey = null;
    _historyGeneration++;
    isNotificationView = false;

    if (!isClosed) {
      emit(
        state.copyWith(
          events: <Event>[],
          premiumEvents: <Event>[],
          index: 0,
          isRead: true,
          isLoading: false,
          refresh: !state.refresh,
        ),
      );
    }
  }

  /// Content from creators the user is actively subscribed to, restricted to
  /// their premium-gated posts (nip63 + NIP-70 protected `-` tag). Fetched
  /// from each creator's NIP-65 write relays, mirroring how ProfileCubit
  /// fetches a single creator's premium tab (getOutboxRelays + client-side
  /// nip63 filtering), just broadened to every subscribed creator.
  Future<void> fetchPremiumContent({bool force = false}) async {
    if (state.isPremiumLoading || (!force && state.premiumEvents.isNotEmpty)) {
      return;
    }

    final pubkeys = creatorSubscriptionsCubit.state.subscriptions
        .where((s) => s.isActive)
        .map((s) => s.creatorPubkey)
        .toList();

    if (pubkeys.isEmpty) {
      if (!isClosed) {
        emit(state.copyWith(premiumEvents: <Event>[]));
      }
      return;
    }

    if (!isClosed) {
      emit(state.copyWith(isPremiumLoading: true));
    }

    try {
      final relaysPerCreator = await Future.wait(
        pubkeys.map((p) => getOutboxRelays(p, showMessage: false)),
      );
      final writeRelays = relaysPerCreator.expand((r) => r).toSet();

      final events = await NostrFunctionsRepository.getEventsAsync(
        pubkeys: pubkeys,
        kinds: [EventKind.TEXT_NOTE, EventKind.LONG_FORM],
        relays: writeRelays.toList(),
        source: EventsSource.all,
      );

      final premiumEvents = events.where(getPremiumStatus).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!isClosed) {
        emit(
          state.copyWith(
            premiumEvents: premiumEvents,
            isPremiumLoading: false,
          ),
        );
      }
    } catch (e) {
      lg.e('Error loading premium notifications: $e');

      if (!isClosed) {
        emit(state.copyWith(isPremiumLoading: false));
      }
    }
  }

  Future<void> closeNotifications() async {
    _syncGeneration++;
    _liveInitialized = false;
    initialized = false;
    _livePubkey = null;
    _catchUpRetryTimer?.cancel();

    final subscriptionId = notificationsSubscriptionId;
    notificationsSubscriptionId = null;
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      await nc.closeRequests(<String>[subscriptionId]);
    }
  }

  Future<void> initNotifications({bool isRefresh = false}) async {
    loadNotifications();
    if (isRefresh) {
      _historyLoadedPubkey = null;
    }

    if (!canSign()) {
      await closeNotifications();
      return;
    }

    await checkNotificationAllowed();

    if (nostrRepository.currentAppCustomization?.enablePushNotification ??
        false) {
      unawaited(LocalNotificationManager.instance.initNotifications());
      final helper = NotificationHelper.sharedInstance;
      final pubkey = currentSigner!.getPublicKey();
      if (helper.deviceId.isEmpty) {
        unawaited(PushCore.sharedInstance.setup());
      } else if (isRefresh || helper.configuredPubkey != pubkey) {
        setPushNotifications(helper.deviceId);
      } else {
        unawaited(helper.init());
      }
    }

    await _ensureLiveNotifications(force: isRefresh);
    if (isNotificationView) {
      await loadHistory(force: isRefresh);
    }
  }

  void cleanAndSubscribe() {
    unawaited(initNotifications(isRefresh: true));
  }

  Future<void> checkNotificationAllowed() async {
    canShowNotification = await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> queryAndSubscribe({bool isRefresh = false}) async {
    await loadHistory(force: true);
    await _ensureLiveNotifications(force: isRefresh);
  }

  Future<void> loadHistory({
    bool force = false,
    bool restoreSnapshot = false,
  }) async {
    if (!canSign()) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
      return;
    }

    final pubkey = currentSigner!.getPublicKey();
    if (restoreSnapshot) {
      await _restoreCachedHistory(pubkey);
      if (!_isCurrentAccount(pubkey)) {
        return;
      }
    }

    if (!force && _historyLoadedPubkey == pubkey) {
      return;
    }

    final runningLoad = _historyLoadInFlight;
    if (runningLoad != null) {
      await runningLoad;
      if (identical(_historyLoadInFlight, runningLoad)) {
        _historyLoadInFlight = null;
      }
      if (!force && _historyLoadedPubkey == pubkey) {
        return;
      }
      if (_historyLoadInFlight != null) {
        return;
      }
    }

    final generation = _historyGeneration;
    final task = _loadHistory(pubkey, generation);
    _historyLoadInFlight = task;
    try {
      await task;
    } finally {
      if (identical(_historyLoadInFlight, task)) {
        _historyLoadInFlight = null;
      }
    }
  }

  Future<void> _loadHistory(String pubkey, int generation) async {
    if (!isClosed) {
      emit(state.copyWith(isLoading: state.events.isEmpty));
    }

    try {
      final result = await NostrFunctionsRepository.queryNotifications(
        pubkey: pubkey,
        limit: 40,
        onHistoryEvent: (event) {
          if (_isCurrentAccount(pubkey) && generation == _historyGeneration) {
            _queueEventsForDisplay([event]);
          }
        },
      );

      if (!_isCurrentAccount(pubkey) || generation != _historyGeneration) {
        _resetLoadingIfLoggedOut();
        return;
      }

      final eventsById = <String, Event>{
        for (final event in state.events) event.id: event,
        for (final event in result.events) event.id: event,
        ..._recentLiveEvents,
        ..._unemittedEvents,
      };
      final events = eventsById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (events.length > 500) {
        events.removeRange(500, events.length);
      }
      since = events.isEmpty ? null : events.first.createdAt;

      if (!isClosed) {
        emit(state.copyWith(events: events, isLoading: false));
      }

      if (result.isComplete) {
        _historyLoadedPubkey = pubkey;
      }
      _historySnapshotPubkey = pubkey;
    } catch (e) {
      lg.e('Error loading notification history: $e');
      if (!isClosed && _isCurrentAccount(pubkey)) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> _restoreCachedHistory(String pubkey) async {
    if (_historySnapshotPubkey == pubkey) {
      return;
    }

    final task = _historySnapshotRestores.putIfAbsent(
      pubkey,
      () => _loadCachedHistory(pubkey),
    );
    try {
      await task;
    } finally {
      if (identical(_historySnapshotRestores[pubkey], task)) {
        _historySnapshotRestores.remove(pubkey);
      }
    }
  }

  Future<void> _loadCachedHistory(String pubkey) async {
    final savedIds = localDatabaseRepository.getMainViewFeedSnapshot(
      pubkey,
      'notifications',
    );
    if (savedIds.isEmpty) {
      if (_isCurrentAccount(pubkey)) {
        _historySnapshotPubkey = pubkey;
        if (!isClosed && state.events.isNotEmpty) {
          emit(state.copyWith(events: <Event>[], isLoading: true));
        }
      }
      return;
    }

    try {
      final cachedEvents = await NostrFunctionsRepository.getCachedEventsByIds(
        savedIds,
      );
      if (!_isCurrentAccount(pubkey) || isClosed) {
        return;
      }

      final eventsById = <String, Event>{};
      for (final event in cachedEvents) {
        if (NostrFunctionsRepository.canNotificationBeAdded(
          event,
          eventsById,
          pubkey,
          nostrRepository.currentAppCustomization,
        )) {
          eventsById[event.id] = event;
        }
      }
      final orderedEvents =
          savedIds.map((id) => eventsById[id]).whereType<Event>().toList();
      final events = await filteredWotEvents(orderedEvents);
      if (!_isCurrentAccount(pubkey) || isClosed) {
        return;
      }

      _historySnapshotPubkey = pubkey;
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!isClosed) {
        emit(
          state.copyWith(
            events: events,
            isLoading: false,
          ),
        );
      }
    } catch (error) {
      lg.i('Unable to restore cached notifications: $error');
      if (_isCurrentAccount(pubkey)) {
        _historySnapshotPubkey = pubkey;
      }
    }
  }

  @override
  void onChange(Change<NotificationsState> change) {
    super.onChange(change);
    final currentIds =
        change.currentState.events.map((event) => event.id).toList();
    final nextEvents = change.nextState.events;
    final nextIds = nextEvents.map((event) => event.id).toList();
    if (currentIds.length == nextIds.length &&
        currentIds.asMap().entries.every(
              (entry) => nextIds[entry.key] == entry.value,
            )) {
      return;
    }

    final owner = currentSigner?.getPublicKey() ?? '';
    _historySnapshotPersistence = _historySnapshotPersistence.then((_) async {
      await localDatabaseRepository.setMainViewFeedSnapshot(
        owner,
        'notifications',
        nextIds,
      );
    });
  }

  Future<void> _ensureLiveNotifications({bool force = false}) async {
    final runningSync = _syncInFlight;
    if (runningSync != null) {
      await runningSync;
      if (identical(_syncInFlight, runningSync)) {
        _syncInFlight = null;
      }
    }

    if (!canSign()) {
      return;
    }

    final pubkey = currentSigner!.getPublicKey();
    if (!force && _liveInitialized && _livePubkey == pubkey) {
      return;
    }

    if (_syncInFlight != null) {
      return;
    }

    final generation = ++_syncGeneration;
    final task = _syncLiveNotifications(pubkey, generation).catchError(
      (Object error, StackTrace stackTrace) {
        lg.e('Error starting notification updates: $error');
        _liveInitialized = false;
        _scheduleCatchUpRetry(pubkey, generation);
      },
    );
    _syncInFlight = task;
    try {
      await task;
    } finally {
      if (identical(_syncInFlight, task)) {
        _syncInFlight = null;
      }
    }
  }

  Future<void> _syncLiveNotifications(String pubkey, int generation) async {
    _catchUpRetryTimer?.cancel();
    final oldSubscriptionId = notificationsSubscriptionId;
    notificationsSubscriptionId = null;
    _uiUpdateTimer?.cancel();
    _unemittedEvents.clear();
    _recentLiveEvents.clear();
    if (oldSubscriptionId != null && oldSubscriptionId.isNotEmpty) {
      await nc.closeRequests(<String>[oldSubscriptionId]);
    }

    if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _ensureNotificationBaseline(pubkey);
    final storedSince = _notificationSyncSince(pubkey);

    final hasNotificationFilters =
        NostrFunctionsRepository.getNotificationsFilter(
      pubkey: pubkey,
      c: nostrRepository.currentAppCustomization,
    ).any((filter) => filter != null);

    if (!hasNotificationFilters) {
      await _saveNotificationSyncSince(pubkey, now);
      notificationsSubscriptionId = '';
      _livePubkey = pubkey;
      _liveInitialized = true;
      initialized = true;
      return;
    }

    var liveSince = now;

    if (storedSince == null) {
      // Establish a baseline without flagging old cached history as unread.
      await _saveNotificationSyncSince(pubkey, now);
    } else {
      final catchUpSince = storedSince > 0 ? storedSince - 1 : 0;
      final result = await NostrFunctionsRepository.queryNotifications(
        pubkey: pubkey,
        limit: 1,
        since: catchUpSince,
        until: now,
        startingTimeout: 3,
      );

      if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
        return;
      }

      await _handleIncomingEvents(result.events, pubkey);
      if (result.events.isNotEmpty) {
        await _persistNotificationMapsNow();
      }
      if (result.isComplete) {
        await _saveNotificationSyncSince(pubkey, now);
        _catchUpRetryTimer?.cancel();
      } else {
        _scheduleCatchUpRetry(pubkey, generation);
      }
      liveSince = now - 1;
    }

    if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
      return;
    }

    final subscriptionId =
        await NostrFunctionsRepository.subscribeToNotifications(
      pubkey: pubkey,
      onEvents: (event) {
        if (generation == _syncGeneration) {
          onEvent(event, pubkey);
        }
      },
      since: liveSince,
    );

    if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
      if (subscriptionId.isNotEmpty) {
        await nc.closeRequests(<String>[subscriptionId]);
      }
      return;
    }

    notificationsSubscriptionId = subscriptionId;
    _livePubkey = pubkey;
    _liveInitialized = subscriptionId.isNotEmpty;
    initialized = _liveInitialized;
    if (!_liveInitialized) {
      _scheduleCatchUpRetry(pubkey, generation);
    }
  }

  void _scheduleCatchUpRetry(String pubkey, int generation) {
    if (_catchUpRetryTimer?.isActive ?? false) {
      return;
    }

    _catchUpRetryTimer = Timer(const Duration(seconds: 30), () {
      _catchUpRetryTimer = null;
      if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
        return;
      }
      unawaited(_retryCatchUp(pubkey, generation));
    });
  }

  Future<void> _retryCatchUp(String pubkey, int generation) async {
    final storedSince = _notificationSyncSince(pubkey);
    if (storedSince == null || !_isCurrentAccount(pubkey)) {
      return;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final result = await NostrFunctionsRepository.queryNotifications(
        pubkey: pubkey,
        limit: 1,
        since: storedSince > 0 ? storedSince - 1 : 0,
        until: now,
        startingTimeout: 3,
      );

      if (!_isCurrentAccount(pubkey) || generation != _syncGeneration) {
        return;
      }

      await _handleIncomingEvents(result.events, pubkey);
      if (result.events.isNotEmpty) {
        await _persistNotificationMapsNow();
      }
      if (result.isComplete) {
        await _saveNotificationSyncSince(pubkey, now);
        if (!_liveInitialized) {
          await _ensureLiveNotifications(force: true);
          if (isNotificationView) {
            await loadHistory(force: true);
          }
        }
      } else {
        _scheduleCatchUpRetry(pubkey, generation);
      }
    } catch (e) {
      lg.e('Error catching up notification updates: $e');
      _scheduleCatchUpRetry(pubkey, generation);
    }
  }

  void _resetLoadingIfLoggedOut() {
    if (!isClosed && currentSigner == null) {
      emit(
        state.copyWith(
          isLoading: false,
        ),
      );
    }
  }

  void onEvent(Event event, String pubkey) {
    if (!_isCurrentAccount(pubkey)) {
      return;
    }

    unawaited(_handleIncomingEvents([event], pubkey));
  }

  bool _isCurrentAccount(String pubkey) {
    return currentSigner?.getPublicKey() == pubkey;
  }

  Future<void> _handleIncomingEvents(List<Event> events, String pubkey) async {
    if (events.isEmpty || !_isCurrentAccount(pubkey)) {
      return;
    }

    final filtered = await filteredWotEvents(events);
    if (!_isCurrentAccount(pubkey)) {
      _resetLoadingIfLoggedOut();
      return;
    }

    if (filtered.isEmpty) {
      if (!isClosed && state.isLoading && isNotificationView) {
        emit(state.copyWith(isLoading: false));
      }
      return;
    }

    if (_livePubkey != pubkey) {
      _recentLiveEvents.clear();
      _livePubkey = pubkey;
    }
    for (final event in filtered) {
      _recentLiveEvents
        ..remove(event.id)
        ..[event.id] = event;
    }
    while (_recentLiveEvents.length > 500) {
      _recentLiveEvents.remove(_recentLiveEvents.keys.first);
    }

    _queueEventsForDisplay(filtered);

    final registeredIds = registredNotifications[pubkey]?.toSet() ?? <String>{};
    final unreadIds = newNotifications[pubkey]?.toSet() ?? <String>{};
    final unhandledEvents = filtered.where(
      (event) =>
          !_recentHandledEventIds.contains(event.id) &&
          !registeredIds.contains(event.id) &&
          !unreadIds.contains(event.id),
    );
    final unhandledIds = unhandledEvents.map((event) => event.id).toList();
    _rememberHandledIds(filtered.map((event) => event.id));

    if (unhandledIds.isEmpty) {
      return;
    }

    if (isNotificationView) {
      registredNotifications[pubkey] = _boundedNotificationIds([
        ...registredNotifications[pubkey] ?? <String>[],
        ...unhandledIds,
      ], maxIds: 2000);
      _scheduleNotificationPersistence();
      return;
    }

    newNotifications[pubkey] = _boundedNotificationIds([
      ...newNotifications[pubkey] ?? <String>[],
      ...unhandledIds,
    ], maxIds: 500);
    if (!isClosed && state.isRead) {
      emit(state.copyWith(isRead: false));
    }
    _scheduleNotificationPersistence();
  }

  void _queueEventsForDisplay(List<Event> events) {
    for (final event in events) {
      _unemittedEvents[event.id] = event;
    }
    _scheduleUIUpdate();
  }

  void _scheduleUIUpdate() {
    if (_uiUpdateTimer?.isActive ?? false) {
      return;
    }

    _uiUpdateTimer = Timer(const Duration(milliseconds: 250), () {
      if (_unemittedEvents.isNotEmpty && !isClosed) {
        final map = {for (final e in state.events) e.id: e};
        map.addAll(_unemittedEvents);

        final newEvents = map.values.toList();
        newEvents.sort(
          (Event a, Event b) => b.createdAt.compareTo(a.createdAt),
        );
        if (newEvents.length > 500) {
          newEvents.removeRange(500, newEvents.length);
        }

        if (newEvents.isNotEmpty) {
          since = newEvents.first.createdAt;
        }

        emit(
          state.copyWith(
            events: newEvents,
            isLoading: _historyLoadInFlight != null && state.isLoading,
          ),
        );

        _unemittedEvents.clear();
      }
    });
  }

  void _rememberHandledIds(Iterable<String> eventIds) {
    for (final id in eventIds) {
      _recentHandledEventIds
        ..remove(id)
        ..add(id);
    }
    while (_recentHandledEventIds.length > 2000) {
      _recentHandledEventIds.remove(_recentHandledEventIds.first);
    }
  }

  List<String> _boundedNotificationIds(
    Iterable<String> eventIds, {
    required int maxIds,
  }) {
    final uniqueIds = LinkedHashSet<String>.from(eventIds).toList();
    if (uniqueIds.length <= maxIds) {
      return uniqueIds;
    }
    return uniqueIds.sublist(uniqueIds.length - maxIds);
  }

  ({Map<String, List<String>> map, bool changed}) _loadBoundedNotificationMap(
    Map<String, List<String>> source, {
    required int maxIds,
  }) {
    final bounded = <String, List<String>>{};
    var changed = false;
    for (final entry in source.entries) {
      final ids = _boundedNotificationIds(entry.value, maxIds: maxIds);
      if (ids.length != entry.value.length) {
        changed = true;
      }
      if (ids.isNotEmpty) {
        bounded[entry.key] = ids;
      }
    }
    return (map: bounded, changed: changed);
  }

  void _emitReadState() {
    if (!isClosed && canSign()) {
      emit(
        state.copyWith(
          isRead:
              newNotifications[currentSigner!.getPublicKey()]?.isEmpty ?? true,
        ),
      );
    }
  }

  void _scheduleNotificationPersistence() {
    _notificationPersistenceTimer?.cancel();
    _notificationPersistenceTimer = Timer(
      const Duration(milliseconds: 250),
      _persistNotificationMaps,
    );
  }

  void _persistNotificationMaps() {
    _notificationPersistenceTimer?.cancel();
    final unreadSnapshot = <String, List<String>>{
      for (final entry in newNotifications.entries)
        entry.key: List<String>.from(entry.value),
    };
    final registeredSnapshot = <String, List<String>>{
      for (final entry in registredNotifications.entries)
        entry.key: List<String>.from(entry.value),
    };

    _notificationPersistence = _notificationPersistence.then((_) async {
      await localDatabaseRepository.setNotifications(unreadSnapshot, false);
      await localDatabaseRepository.setNotifications(registeredSnapshot, true);
    }).catchError((Object error, StackTrace stackTrace) {
      lg.e('Error saving notification state: $error');
    });
  }

  Future<void> _persistNotificationMapsNow() {
    _notificationPersistenceTimer?.cancel();
    _persistNotificationMaps();
    return _notificationPersistence;
  }

  Future<List<Event>> filteredWotEvents(List<Event> events) async {
    if (canSign()) {
      final conf = nostrRepository.getWotConfiguration(
        currentSigner!.getPublicKey(),
      );

      if (conf.isEnabled && conf.notifications) {
        final pubkeys = events.map((e) => e.pubkey).toSet();

        Map<String, num?> wotScores;

        try {
          wotScores = await nc.calculatePeerPubkeyWotList(
            peerPubkeys: pubkeys.toList(),
            originPubkey: currentSigner!.getPublicKey(),
          );
        } catch (e) {
          lg.e('Error calculating WoT scores: $e');
          return events;
        }

        final filtered = <Event>[];

        for (final e in events) {
          if (e.kind == EventKind.ZAP || e.kind == EventKind.CASHU_NUTZAP) {
            filtered.add(e);
          } else {
            final score = wotScores[e.pubkey] ?? 0;

            if (score >= conf.threshold) {
              filtered.add(e);
            }
          }
        }

        return filtered;
      }
    }

    return events;
  }

  bool shouldBeNotified(List<Event> events, {String? pubkey}) {
    final key = pubkey ?? currentSigner?.getPublicKey() ?? '';
    final newIds = newNotifications[key]?.toSet() ?? <String>{};
    final registredIds = registredNotifications[key]?.toSet() ?? <String>{};

    return !isNotificationView &&
        events.isNotEmpty &&
        events.any(
          (event) =>
              !newIds.contains(event.id) && !registredIds.contains(event.id),
        );
  }

  int newEventsNumber({String? pubkey}) {
    final String usedPubkey = pubkey ?? currentSigner?.getPublicKey() ?? '';

    return newNotifications[usedPubkey]?.length ?? 0;
  }

  void addNotifications() {
    if (canSign()) {
      final String pubkey = currentSigner!.getPublicKey();
      final unreadIds = newNotifications[pubkey] ?? <String>[];
      if (unreadIds.isEmpty) {
        return;
      }

      registredNotifications[pubkey] = _boundedNotificationIds([
        ...registredNotifications[pubkey] ?? <String>[],
        ...unreadIds,
      ], maxIds: 2000);
      _rememberHandledIds(unreadIds);
      newNotifications.remove(pubkey);
      _persistNotificationMaps();
    }
  }

  void setIndex(int index) {
    unawaited(
      localDatabaseRepository.setMainViewSubTab(
        currentSigner?.getPublicKey() ?? '',
        'notifications',
        index,
      ),
    );
    emit(
      state.copyWith(
        index: index,
      ),
    );

    if (index == 5) {
      fetchPremiumContent();
    }
  }

  void markRead() {
    addNotifications();
    if (canSign()) {
      unawaited(
        _saveNotificationSyncSince(
          currentSigner!.getPublicKey(),
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
      );
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          isRead: true,
        ),
      );
    }

    if (canShowNotification) {
      AwesomeNotifications().setGlobalBadgeCounter(0);
    }
  }

  void setPushNotifications(String deviceId) {
    final c = nostrRepository.currentAppCustomization;
    if (!canSign() || !(c?.enablePushNotification ?? false)) {
      return;
    }

    final kinds = <int>{};
    if (c?.notifPrivateMessage ?? true) {
      kinds.addAll([
        EventKind.DIRECT_MESSAGE,
        EventKind.PRIVATE_DIRECT_MESSAGE,
      ]);
    }

    if (c?.notifMentionsReplies ?? false) {
      kinds.addAll(
        [
          EventKind.TEXT_NOTE,
          EventKind.COMMENT,
          EventKind.LONG_FORM,
          EventKind.SMART_WIDGET_ENH,
        ],
      );
    }

    if (c?.notifHighlights ?? true) {
      kinds.add(EventKind.HIGHLIGHT);
    }

    if (c?.notifReactions ?? false) {
      kinds.addAll(
        [
          EventKind.REACTION,
        ],
      );
    }

    if (c?.notifZaps ?? false) {
      kinds.addAll(
        [
          EventKind.ZAP,
          EventKind.CASHU_NUTZAP,
        ],
      );
    }

    if (c?.notifReposts ?? false) {
      kinds.addAll(
        [
          EventKind.REPOST,
        ],
      );
    }

    unawaited(
      NotificationHelper.sharedInstance.setNotification(
        deviceId,
        kinds.toList(),
      ),
    );
  }

  Future<void> refreshPushConfiguration() async {
    if (!canSign() ||
        !(nostrRepository.currentAppCustomization?.enablePushNotification ??
            false)) {
      return;
    }

    final deviceId = NotificationHelper.sharedInstance.deviceId;
    if (deviceId.isNotEmpty) {
      setPushNotifications(deviceId);
    } else {
      await PushCore.sharedInstance.setup();
    }
  }

  @override
  Future<void> close() async {
    _uiUpdateTimer?.cancel();
    await _persistNotificationMapsNow();
    _catchUpRetryTimer?.cancel();
    await closeNotifications();
    return super.close();
  }
}
