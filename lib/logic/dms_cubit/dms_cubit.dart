import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/remote_event_signer.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/dm_models.dart';
import '../../models/mute_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'dms_state.dart';

const List<Duration> _batchIntervals = [
  Duration(days: 7),
  Duration(days: 14),
  Duration(days: 30),
  Duration(days: 90),
  Duration(days: 180),
];

class DmsCubit extends Cubit<DmsState>
    with PendingEventsLaterFunction, SimpleEventQueue {
  DmsCubit()
      : super(
          DmsState(
            dmSessionDetails: const {},
            index: 0,
            isUsingNip44: localDatabaseRepository.isUsingNip44(),
            rebuild: true,
            isSendingMessage: false,
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            selectedTime: 0,
            isLoadingHistory: false,
            dmDataState: DmDataState.enabled,
          ),
        ) {
    nostrRepository.isUsingNip44 = localDatabaseRepository.isUsingNip44();
    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        updateSessionsByFollowings(followings);
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        _onMutesUpdate(mm);
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription muteListSubscription;
  final Map<String, DMSessionDetail> _pendingSessionUpdates = {};
  Set<String> searchDmRelaysPubkeys = {};
  bool _hasPendingUpdates = false;
  Timer? _uiUpdateTimer;
  Timer? sendNotificationTimer;
  bool canShowNotification = true;
  Map<String, DMSessionInfo> infoMap = {};
  Map<String, Event> giftWraps = {};
  int _currentBatchIndex = 0;
  int _currentBatchUntil = Helpers.now;
  int _initSince = 0;
  String? dmsSubscriptionId;
  int? giftWrapNewestDateTime;
  DMSessionDetail? selectedDmSessionDetail;
  bool isDmsView = false;
  bool showDmsRelayMessage = false;
  bool _isStreamingMode = false;
  Set<String> _processedEventIds = {};

  // Get WoT score for DM sender (uses core caching)
  Future<double> _getDmWotScore(String senderPubkey) async {
    final wotScore = await nc.calculatePeerPubkeyWot(
      peerPubkey: senderPubkey,
      originPubkey: currentSigner!.getPublicKey(),
    );

    return wotScore?.score ?? 0.0;
  }

  // Check if DM session passes WoT filter
  Future<bool> _passesDmWotFilter(String senderPubkey, DmsType dmsType) async {
    // Always show followings and known conversations
    if (dmsType == DmsType.followings) {
      return true;
    }

    // If WoT filtering is disabled or threshold not set, show all
    final conf = nostrRepository.getWotConfiguration(
      currentSigner!.getPublicKey(),
    );

    if (!conf.isEnabled || !conf.privateMessages) {
      return true;
    }

    final wotScore = await _getDmWotScore(senderPubkey);

    return wotScore >= conf.threshold;
  }

  Future<void> uploadMediaAndSend({
    required File file,
    required String pubkey,
    required String? replyId,
    required Function() onSuccess,
    required Function() onFailed,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final imageLink = (await mediaServersCubit.uploadMedia(file: file))['url'];

    if (imageLink != null) {
      cancel.call();
      sendEvent(pubkey, imageLink, replyId, onSuccess);
    } else {
      cancel.call();
      onFailed.call();
      BotToastUtils.showError(t.errorUploadingMedia.capitalize());
    }
  }

  Future<void> setUsedMessagingNip(bool isUsingNip44) async {
    _emit(
      state.copyWith(isUsingNip44: isUsingNip44),
    );

    nostrRepository.isUsingNip44 = isUsingNip44;
    localDatabaseRepository.setUsedNip(isUsingNip44);
  }

  Future<void> markAllAsRead() async {
    final dmSessions =
        Map<String, DMSessionDetail>.from(state.dmSessionDetails);
    final now = DateTime.now().millisecondsSinceEpoch / 1000;

    for (final detail in dmSessions.values) {
      final newInfo = detail.info.copyWith(
        readTime: now.toInt(),
      );

      infoMap[detail.info.id] = newInfo;
      dmSessions[detail.dmSession.pubkey] = detail.copyWith(info: newInfo);
    }

    await nc.db.saveDmSessionsInfos(infoMap.values.toList());

    _emit(
      state.copyWith(
        dmSessionDetails: dmSessions,
        rebuild: true,
      ),
    );

    if (canShowNotification) {
      final globalCounter =
          await AwesomeNotifications().getGlobalBadgeCounter();

      if (globalCounter > 0 && globalCounter >= dmSessions.length) {
        AwesomeNotifications().setGlobalBadgeCounter(
          globalCounter - dmSessions.length,
        );
      } else {
        AwesomeNotifications().setGlobalBadgeCounter(0);
      }
    }
  }

  void setIndex(int index) {
    _emit(
      state.copyWith(
        index: index,
        rebuild: !state.rebuild,
      ),
    );
  }

  Future<void> checkNotificationAllowed() async {
    canShowNotification = await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> updateReadedTime(String pubkey) async {
    final detail = state.dmSessionDetails[pubkey];

    if (detail != null && detail.dmSession.newestEvent != null) {
      final dmSessionDetail = state.dmSessionDetails[detail.dmSession.pubkey];

      if (dmSessionDetail != null) {
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final newInfo = detail.info.copyWith(
          readTime: now.toInt(),
        );

        final map = Map<String, DMSessionDetail>.from(
          state.dmSessionDetails,
        );

        infoMap[detail.info.id] = newInfo;
        map[detail.dmSession.pubkey] = detail.copyWith(info: newInfo);

        _emit(
          state.copyWith(
            dmSessionDetails: map,
          ),
        );

        await nc.db.saveDmSessionsInfo(newInfo);

        if (canShowNotification) {
          final globalCounter =
              await AwesomeNotifications().getGlobalBadgeCounter();

          if (globalCounter > 0) {
            AwesomeNotifications().setGlobalBadgeCounter(globalCounter - 1);
          }
        }
      }
    }
  }

  Future<void> sendEvent(
    String pubkey,
    String text,
    String? replayId,
    Function() onSuccessful,
  ) async {
    try {
      _emit(
        state.copyWith(
          isSendingMessage: true,
        ),
      );

      late Event event;
      bool isSuccessful = true;

      if (state.isUsingNip44) {
        final pmEvent = Event.withoutSignature(
          kind: EventKind.PRIVATE_DIRECT_MESSAGE,
          tags: [
            if (replayId != null) ['e', replayId],
            [
              'p',
              pubkey,
            ],
          ],
          content: text,
          pubkey: currentSigner!.getPublicKey(),
        );

        final receiverEvent = await currentSigner!.encrypt44Event(
          pmEvent,
          pubkey,
        );

        final senderEvent = await currentSigner!.encrypt44Event(
          pmEvent,
          currentSigner!.getPublicKey(),
        );

        if (senderEvent == null || receiverEvent == null) {
          _emit(
            state.copyWith(
              isSendingMessage: false,
            ),
          );

          BotToastUtils.showError(
            t.zapSplitsMessage.capitalizeFirst(),
          );
          return;
        }

        final relays = await getDmInboxRelays(
          pubkey,
          forceRefresh: !searchDmRelaysPubkeys.contains(pubkey),
        );

        searchDmRelaysPubkeys.add(pubkey);

        final successList = await Future.wait(
          [
            NostrFunctionsRepository.sendEvent(
              event: receiverEvent,
              relays: relays,
              setProgress: false,
            ),
            NostrFunctionsRepository.sendEvent(
              event: senderEvent,
              relays: relays,
              setProgress: false,
            ),
          ],
        );

        isSuccessful = successList.first && successList.last;
        event = senderEvent;
      } else {
        final relays = await getDmInboxRelays(
          pubkey,
          forceRefresh: !searchDmRelaysPubkeys.contains(pubkey),
        );

        searchDmRelaysPubkeys.add(pubkey);

        final receivedEvent = await currentSigner!.encrypt04Event(
          text,
          pubkey,
          replyId: replayId,
        );

        if (receivedEvent == null) {
          _emit(
            state.copyWith(
              isSendingMessage: false,
            ),
          );

          BotToastUtils.showError(
            t.errorSigningEvent.capitalizeFirst(),
          );

          return;
        }

        event = receivedEvent;
        isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: event,
          relays: relays,
          setProgress: false,
        );
      }

      if (isSuccessful) {
        if (pubkey == yakihonneHex) {
          HttpFunctionsRepository.sendAction(PointsActions.DMSYAKI);
        } else {
          HttpFunctionsRepository.sendAction(PointsActions.DMS);
        }

        addEventAndUpdateReadedTime(pubkey, event);
        onSuccessful.call();
      } else {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );
      }

      _emit(
        state.copyWith(
          isSendingMessage: false,
        ),
      );
    } catch (_) {
      BotToastUtils.showError(
        t.errorSendingMessage.capitalizeFirst(),
      );

      _emit(
        state.copyWith(
          isSendingMessage: false,
        ),
      );
    }
  }

  void addEventAndUpdateReadedTime(String pubkey, Event event) {
    if (event.kind == EventKind.GIFT_WRAP) {
      handleGiftWraps(event);
    } else {
      onEvent(event);
    }

    updateReadedTime(pubkey);
  }

  void updateSessionsByFollowings(List<String> followings) {
    final dms = Map<String, DMSessionDetail>.from(state.dmSessionDetails);

    for (final dm in dms.entries) {
      if (followings.contains(dm.key)) {
        if (dm.value.dmsType != DmsType.followings) {
          dms[dm.key] = dm.value.copyWith(
            dmsType: DmsType.followings,
          );
        }
      } else {
        if (dm.value.dmsType == DmsType.followings) {
          if (dm.value.dmSession
              .doesEventExist(currentSigner!.getPublicKey())) {
            dms[dm.key] = dm.value.copyWith(
              dmsType: DmsType.known,
            );
          } else {
            dms[dm.key] = dm.value.copyWith(
              dmsType: DmsType.unknown,
            );
          }
        }
      }
    }

    _emit(
      state.copyWith(
        dmSessionDetails: dms,
      ),
    );
  }

  Future<void> loadLocalRemoteSignerDms() async {
    await localDatabaseRepository.setLoadLocaleRemoteSignerDmStatus(
      currentSigner!.getPublicKey(),
      true,
    );

    initDmSessions();
  }

  Future<void> initDmSessions() async {
    if (currentSigner is RemoteEventSigner) {
      _emit(
        state.copyWith(
          dmDataState: DmDataState.disabled,
        ),
      );

      return;
    }

    if (currentSigner is AmberEventSigner) {
      final shouldLoad =
          localDatabaseRepository.getLoadLocalRemoteSignerDmStatus(
                  currentSigner!.getPublicKey()) ??
              false;

      if (shouldLoad) {
        _emit(
          state.copyWith(
            dmDataState: DmDataState.enabled,
          ),
        );
      } else {
        _emit(
          state.copyWith(
            dmDataState: DmDataState.canBeLoaded,
          ),
        );

        return;
      }
    }

    _initSince = 0;
    checkNotificationAllowed();

    giftWrapNewestDateTime = localDatabaseRepository.getNewestGiftWrap(
      currentSigner!.getPublicKey(),
    );

    _emit(
      DmsState(
        dmSessionDetails: const {},
        isUsingNip44: nostrRepository.isUsingNip44,
        index: 0,
        rebuild: true,
        mutes: nostrRepository.muteModel.usersMutes.toList(),
        isSendingMessage: false,
        selectedTime: 0,
        isLoadingHistory: false,
        dmDataState: DmDataState.enabled,
      ),
    );

    final currentPubkey = currentSigner!.getPublicKey();

    // LOAD CACHED EVENTS NORMALLY (no queue)
    await _loadCachedEventsNormally(currentPubkey);

    // NOW switch to streaming mode for new events
    _isStreamingMode = true;

    final oldestUntil = localDatabaseRepository.getDmsHistoryOlderUntil(
      currentSigner!.getPublicKey(),
    );

    if ((_initSince == 0 && giftWrapNewestDateTime == null) ||
        oldestUntil != null) {
      _currentBatchUntil = oldestUntil ?? _currentBatchUntil;

      final since = _currentBatchUntil -
          _batchIntervals[_currentBatchIndex < _batchIntervals.length
                  ? _currentBatchIndex
                  : _batchIntervals.length - 1]
              .inSeconds;

      _emit(
        state.copyWith(
          isLoadingHistory: true,
        ),
      );

      if (oldestUntil == null) {
        localDatabaseRepository.setDmsHistoryOlderUntil(
          currentSigner!.getPublicKey(),
          _currentBatchUntil,
        );
      }

      queryAsync(
        since: since,
        until: _currentBatchUntil,
      );
    } else {
      query();
    }
  }

  Future<void> queryAsync({
    required int since,
    required int until,
  }) async {
    final events = await NostrFunctionsRepository.getUserDmsAsync(
      since: since,
      until: until,
    );

    final directMessages = events['directMessages']!;
    final giftWraps = events['giftWraps']!;

    // Process events if we have any
    if (directMessages.isNotEmpty || giftWraps.isNotEmpty) {
      final processedGiftWraps = <Event>[];

      if (giftWraps.isNotEmpty) {
        final decryptedChunk = await handleGiftWrapsAsync(giftWraps);
        processedGiftWraps.addAll(decryptedChunk);
      }

      final allEvents = [...directMessages, ...processedGiftWraps];
      eventLaterHandle(allEvents);
    }

    // Wait before next query
    await Future.delayed(const Duration(seconds: 1));

    // Determine next batch index
    if (directMessages.isEmpty && giftWraps.isEmpty) {
      _currentBatchIndex++;
    }

    // Check if we've reached the end of all batches
    if (_currentBatchIndex >= _batchIntervals.length) {
      _emit(
        state.copyWith(
          isLoadingHistory: false,
        ),
      );
      localDatabaseRepository.deleteDmsHistoryOlderUntil(
        currentSigner!.getPublicKey(),
      );
      query();
      return;
    }

    // Calculate next time range
    _currentBatchUntil = since - 1;
    final newSince = _currentBatchUntil -
        _batchIntervals[_currentBatchIndex < _batchIntervals.length
                ? _currentBatchIndex
                : _batchIntervals.length - 1]
            .inSeconds;

    // Update database with current progress
    localDatabaseRepository.setDmsHistoryOlderUntil(
      currentSigner!.getPublicKey(),
      _currentBatchUntil,
    );

    // Recursively query next batch
    queryAsync(
      since: newSince,
      until: _currentBatchUntil,
    );
  }

  static Future<List<Event>> _handleGiftWrapsInIsolate(
    Map<String, dynamic> params,
  ) async {
    final giftWrapsJson = params['giftWraps'] as List<dynamic>;
    final signerData = params['signerData'] as Map<String, dynamic>;

    // Reconstruct events
    final giftWraps =
        giftWrapsJson.map((json) => Event.fromJson(json)).toList();

    // Reconstruct signer (you'll need to adapt this based on your signer types)
    final signer = _reconstructSigner(signerData);

    if (signer == null) {
      return [];
    }
    // Now run your existing handleGiftWrapsAsync logic
    return _handleGiftWrapsLogic(giftWraps, signer);
  }

  static EventSigner? _reconstructSigner(Map<String, dynamic> signerData) {
    // Based on signerType, reconstruct the appropriate signer
    switch (signerData['signerType']) {
      case 'Bip340EventSigner':
        return Bip340EventSigner(
          signerData['privateKey'],
          signerData['publicKey'],
        );
      case 'AmberEventSigner':
        return AmberEventSigner(signerData['publicKey']);
      // Add other signer types as needed
      default:
        return null;
    }
  }

  static Future<List<Event>> _handleGiftWrapsLogic(
    List<Event> giftWraps,
    EventSigner signer,
  ) async {
    final processedGiftWraps = <Event>[];

    for (final giftWrap in giftWraps) {
      final event = await signer.decrypt44Event(giftWrap);

      if (event != null && event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
        processedGiftWraps.add(event);
      }
    }

    return processedGiftWraps;
  }

  Map<String, dynamic> _getCurrentSignerData() {
    // Extract whatever data your current signer needs
    return {
      'signerType': currentSigner.runtimeType.toString(),
      'publicKey': currentSigner!.getPublicKey(),
      'privateKey': currentSigner! is AmberEventSigner
          ? ''
          : (currentSigner! as Bip340EventSigner).privateKey,
    };
  }

  void onEvent(Event event) {
    // Skip events we already processed from cache
    if (_processedEventIds.contains(event.id)) {
      return;
    }

    // Add to processed set
    _processedEventIds.add(event.id);

    if (_isStreamingMode) {
      // Use queue for new streaming events only
      queueEvent(event);
    } else {
      // During initial load, use original method
      later(event, eventLaterHandle, null);
    }
  }

  // MODIFIED: Handle gift wraps - skip cached ones
  Future<List<Event>> handleGiftWrapsAsync(List<Event> events) async {
    final toBeProcessedEvents = <Event>[];
    final processedEvents = <Event>[];

    Event? newest;

    for (final gwe in events) {
      if (_processedEventIds.contains(gwe.id) || giftWraps[gwe.id] != null) {
        continue;
      }

      if (giftWraps[gwe.id] == null) {
        giftWraps[gwe.id] = gwe;
        _processedEventIds.add(gwe.id);
        toBeProcessedEvents.add(gwe);
      }
    }

    if (toBeProcessedEvents.isNotEmpty) {
      final data = await compute(_handleGiftWrapsInIsolate, {
        'giftWraps': toBeProcessedEvents.map((e) => e.toJson()).toList(),
        'signerData': _getCurrentSignerData(),
      });

      if (data.isNotEmpty) {
        for (final e in data) {
          if (newest == null || newest.createdAt < e.createdAt) {
            newest = e;
          }
        }

        setGiftWrapOldestDateTime(newest!);
      }
    }

    return processedEvents;
  }

  Future<void> handleGiftWraps(Event gwe) async {
    if (_processedEventIds.contains(gwe.id) || giftWraps[gwe.id] != null) {
      return;
    }

    if (giftWraps[gwe.id] == null) {
      giftWraps[gwe.id] = gwe;
      _processedEventIds.add(gwe.id);

      if (_isStreamingMode) {
        queueEvent(gwe);
      } else {
        onEvent(gwe);
      }

      final event = await currentSigner!.decrypt44Event(gwe);

      if (event != null && event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
        if (!_processedEventIds.contains(event.id)) {
          _processedEventIds.add(event.id);

          if (_isStreamingMode) {
            queueEvent(event);
          } else {
            onEvent(event);
          }

          setGiftWrapOldestDateTime(event);
        }
      }
    }
  }

  // MODIFIED: Query only processes truly new events
  Future<void> query() async {
    await Future.delayed(const Duration(seconds: 2));

    if (dmsSubscriptionId != null) {
      nc.closeRequests([dmsSubscriptionId!]);
    }

    dmsSubscriptionId = NostrFunctionsRepository.getUserDms(
      since: _initSince != 0 ? _initSince : null,
      since1059: giftWrapNewestDateTime,
      kind1059Events: (giftEvent) {
        handleGiftWraps(giftEvent);
      },
      kind4Events: (dmEvent) {
        onEvent(dmEvent);
      },
    );
  }

  // Load cached events using original logic (fast, no queue)
  Future<void> _loadCachedEventsNormally(
    String currentPubkey,
  ) async {
    // Load all cached events
    final events = await nc.db.loadEvents(
      f: Filter(
        kinds: [
          EventKind.DIRECT_MESSAGE,
          EventKind.PRIVATE_DIRECT_MESSAGE,
        ],
        authors: [currentPubkey],
      ),
      currentUser: currentPubkey,
    );

    final events2 = await nc.db.loadEvents(
      f: Filter(
        kinds: [
          EventKind.DIRECT_MESSAGE,
          EventKind.PRIVATE_DIRECT_MESSAGE,
        ],
        p: [currentPubkey],
      ),
      currentUser: currentPubkey,
    );

    events.addAll(events2);

    final localGiftWraps = await nc.db.loadEvents(
      f: Filter(
        kinds: [EventKind.GIFT_WRAP],
        p: [currentPubkey],
      ),
      currentUser: currentPubkey,
    );

    if (localGiftWraps.isNotEmpty) {
      giftWraps = {for (final v in localGiftWraps) v.id: v};
    }

    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (events.isNotEmpty) {
      _initSince = events.first.createdAt;
    }

    // Track which events we've already processed from cache
    _processedEventIds = events.map((e) => e.id).toSet();
    _processedEventIds.addAll(localGiftWraps.map((e) => e.id));

    // Process cached events using ORIGINAL logic (no queue overhead)
    await _processCachedEvents(events, currentPubkey);
  }

  // Process cached events with original logic - fast and efficient
  Future<void> _processCachedEvents(
    List<Event> events,
    String currentPubkey,
  ) async {
    final Map<String, List<Event>> eventListMap = {};

    // Group events by pubkey
    for (final event in events) {
      final pubkey = getPeerPubkeyFromEvent(event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }
        list.add(event);
      }
    }

    // Load session info
    final dmSessions = await nc.db.loadDmSessionsInfo(currentPubkey);

    infoMap = {};

    if (dmSessions.isNotEmpty) {
      for (final item in dmSessions) {
        infoMap[item.peerPubkey] = item;
      }
    }

    final Map<String, DMSessionDetail> dmSessions0 = {};

    // Create sessions from cached events
    for (final entry in eventListMap.entries) {
      final pubkey = entry.key;
      final list = entry.value;

      final session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      final info = infoMap[pubkey];
      final currentUser = currentSigner!.getPublicKey();

      final detail = DMSessionDetail(
        dmSession: session,
        dmsType: DmsType.unknown,
        info: info ??
            DMSessionInfo(
              id: '$currentUser+$pubkey',
              peerPubkey: pubkey,
              ownPubkey: currentUser,
              readTime: 0,
            ),
      );

      if (contactListCubit.contacts.contains(pubkey)) {
        dmSessions0[detail.dmSession.pubkey] = detail.copyWith(
          dmsType: DmsType.followings,
        );
      } else if (detail.dmSession
          .doesEventExist(currentSigner!.getPublicKey())) {
        dmSessions0[detail.dmSession.pubkey] = detail.copyWith(
          dmsType: DmsType.known,
        );
      } else {
        dmSessions0[detail.dmSession.pubkey] = detail;
      }
    }

    // Emit the cached data all at once
    _emit(state.copyWith(dmSessionDetails: dmSessions0));
  }

  Future<void> setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(muteKey: pubkey);
    cancel();

    if (result) {
      final hasBeenMuted = isUserMuted(pubkey);

      BotToastUtils.showSuccess(
        hasBeenMuted
            ? t.userHasBeenMuted.capitalizeFirst()
            : t.userHasBeenUnmuted.capitalizeFirst(),
      );

      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  void setGiftWrapOldestDateTime(Event event) {
    if (giftWrapNewestDateTime == null ||
        event.createdAt > giftWrapNewestDateTime!) {
      giftWrapNewestDateTime = event.createdAt;
      if (canSign()) {
        localDatabaseRepository.setNewestGiftWrap(
          currentSigner!.getPublicKey(),
          event.createdAt,
        );
      }
    }
  }

  String? getPeerPubkeyFromEvent(Event event) {
    if (event.pubkey != currentSigner!.getPublicKey()) {
      for (final tag in event.tags) {
        if (tag[0] == 'p' && tag[1] == currentSigner!.getPublicKey()) {
          return event.pubkey;
        }
      }

      return null;
    } else {
      for (final tag in event.tags) {
        if (tag[0] == 'p') {
          return tag[1];
        }
      }
    }

    return null;
  }

  @override
  void eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    bool updated = false;
    final List<Event> toSave = [];

    for (final event in events) {
      final addResult = _addEventWithoutEmit(event); // Don't emit state here
      if (addResult) {
        toSave.add(event);
        updated = true;
      }
    }

    if (updated) {
      nc.db.saveEvents(toSave);

      // Mark that we have pending updates but don't emit yet
      _hasPendingUpdates = true;
      _scheduleUIUpdate();
    }
  }

  void _scheduleUIUpdate() {
    // Only update UI every 2 seconds, not on every batch
    if (_uiUpdateTimer?.isActive != true) {
      _uiUpdateTimer = Timer(const Duration(seconds: 2), () {
        if (_hasPendingUpdates && !isClosed) {
          // Merge all pending updates and emit once
          final updatedSessions =
              Map<String, DMSessionDetail>.from(state.dmSessionDetails);
          updatedSessions.addAll(_pendingSessionUpdates);

          _emit(
            state.copyWith(
              dmSessionDetails: updatedSessions,
              rebuild: !state.rebuild,
            ),
          );

          _pendingSessionUpdates.clear();
          _hasPendingUpdates = false;
        }
      });
    }
  }

  // Modified _addEvent that stores updates but doesn't emit
  bool _addEventWithoutEmit(Event event) {
    event.currentUser = currentSigner!.getPublicKey();

    if (event.kind == EventKind.GIFT_WRAP) {
      return true;
    }

    final pubkey = getPubkeyRegularEvent(event);

    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    // Use pending updates instead of current state
    DMSessionDetail? dmSessionDetail =
        _pendingSessionUpdates[pubkey] ?? state.dmSessionDetails[pubkey];

    bool addResult = false;

    if (dmSessionDetail == null) {
      dmSessionDetail = DMSessionDetail(
        dmSession: DMSession(pubkey: pubkey!),
        info: DMSessionInfo(
          id: '${currentSigner!.getPublicKey()}+$pubkey',
          peerPubkey: pubkey,
          ownPubkey: currentSigner!.getPublicKey(),
          readTime: 0,
        ),
        dmsType: DmsType.unknown,
      );
      addResult = dmSessionDetail.dmSession.addEvent(event);
    } else {
      addResult = dmSessionDetail.dmSession.addEvent(event);
    }

    if (addResult) {
      // Store in pending updates instead of emitting immediately
      if (contactListCubit.contacts.contains(pubkey)) {
        _pendingSessionUpdates[pubkey!] =
            dmSessionDetail.copyWith(dmsType: DmsType.followings);
      } else if (dmSessionDetail.dmSession
          .doesEventExist(currentSigner!.getPublicKey())) {
        _pendingSessionUpdates[pubkey!] =
            dmSessionDetail.copyWith(dmsType: DmsType.known);
      } else {
        _pendingSessionUpdates[pubkey!] = dmSessionDetail;
      }
    }

    return addResult;
  }

  void updateCurrentMessagesReadTime(String pubkey) {
    if (nostrRepository.usersMessageNotifications.contains(pubkey)) {
      updateReadedTime(pubkey);
    }
  }

  // MODIFIED: Apply WoT filter to message count
  Future<int> howManyNewDMSessionsWithNewMessages(DmsType dmsType) async {
    int count = 0;
    final list = state.dmSessionDetails.values
        .where((element) => element.dmsType == dmsType)
        .toList();

    for (final element in list) {
      if (element.hasNewMessage()) {
        if (await _passesDmWotFilter(
            element.dmSession.pubkey, element.dmsType)) {
          count++;
        }
      }
    }

    return count;
  }

  // MODIFIED: Apply WoT filter to gotMessages check
  Future<bool> gotMessages() async {
    final following =
        await howManyNewDMSessionsWithNewMessages(DmsType.followings);

    if (following != 0) {
      return true;
    } else {
      final known = await howManyNewDMSessionsWithNewMessages(DmsType.known);

      if (known != 0) {
        return true;
      } else {
        final unknown =
            await howManyNewDMSessionsWithNewMessages(DmsType.unknown);
        return unknown != 0;
      }
    }
  }

  void setSelectedTime(int selectedTime) {
    _emit(
      state.copyWith(
        selectedTime: selectedTime,
        rebuild: !state.rebuild,
      ),
    );
  }

  // MODIFIED: Apply WoT filtering to session details
  Future<List<DMSessionDetail>> getSessionDetailsByType(DmsType dmsType) async {
    List<DMSessionDetail> detailList;

    if (dmsType == DmsType.all) {
      detailList = state.dmSessionDetails.values.toList();
    } else {
      detailList = state.dmSessionDetails.values
          .where((dmSessionDetails) => dmSessionDetails.dmsType == dmsType)
          .toList();
    }

    // Apply time filter
    detailList = detailList.where((dmSessionDetails) {
      bool meetsRequirement = false;
      final lastEventDate = dmSessionDetails.dmSession.newestEvent?.createdAt;

      if (lastEventDate != null) {
        if (state.selectedTime == 1) {
          meetsRequirement = lastEventDate.isNewerThan1Month();
        } else if (state.selectedTime == 3) {
          meetsRequirement = lastEventDate.isNewerThan3Months();
        } else if (state.selectedTime == 6) {
          meetsRequirement = lastEventDate.isNewerThan6Months();
        } else if (state.selectedTime == 12) {
          meetsRequirement = lastEventDate.isNewerThan1Year();
        } else {
          meetsRequirement = true;
        }
      } else {
        meetsRequirement = true;
      }

      return meetsRequirement;
    }).toList();

    // Apply WoT filter

    final newList = <DMSessionDetail>[];
    for (final item in detailList) {
      if (await _passesDmWotFilter(
        item.dmSession.pubkey,
        item.dmsType,
      )) {
        newList.add(item);
      }
    }

    newList.sort(
      (detail0, detail1) {
        return detail1.dmSession.newestEvent!.createdAt -
            detail0.dmSession.newestEvent!.createdAt;
      },
    );

    return newList;
  }

  // Get all DMs ignoring WoT filter (for settings/moderation)
  List<DMSessionDetail> getAllDmsIgnoringWot(DmsType dmsType) {
    if (dmsType == DmsType.all) {
      return state.dmSessionDetails.values.toList();
    }

    return state.dmSessionDetails.values
        .where((detail) => detail.dmsType == dmsType)
        .toList();
  }

  Future<void> setNotification(Event event) async {
    if (canShowNotification) {
      if (sendNotificationTimer != null) {
        sendNotificationTimer!.cancel();
      }

      sendNotificationTimer = Timer(
        const Duration(seconds: 1),
        () {
          sendNotification(event);
          sendNotificationTimer?.cancel();
        },
      );
    }
  }

  Future<void> sendNotification(Event event) async {
    if (event.pubkey != currentSigner!.getPublicKey() &&
        event.kind != EventKind.GIFT_WRAP &&
        !isDmsView &&
        !nostrRepository.usersMessageNotifications.contains(event.pubkey)) {
      String title = '';
      String? body;

      final metadata = await metadataCubit.getCachedMetadata(event.pubkey);

      final String name = metadata?.getName() ??
          Metadata.empty()
              .copyWith(
                pubkey: event.pubkey,
              )
              .getName();

      title = name;

      final data = await getMessage(event);
      body = data.first.trim().isNotEmpty
          ? data.first.trim()
          : t.messageCouldNotBeDecrypted.capitalizeFirst();

      final globalCounter =
          await AwesomeNotifications().getGlobalBadgeCounter();

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: event.id.hashCode,
          channelKey: 'yaki_channel',
          largeIcon: metadata?.picture,
          title: title,
          body: body,
          payload: {'name': 'new notification'},
          badge: globalCounter + 1,
        ),
      );
    }
  }

  // Update mutes without clearing cache (core handles caching)
  void _onMutesUpdate(MuteModel mm) {
    _emit(state.copyWith(mutes: mm.usersMutes.toList()));
  }

  void clear() {
    if (dmsSubscriptionId != null) {
      nc.closeRequests([dmsSubscriptionId!]);
      dmsSubscriptionId = null;
    }

    // Clear the event queue
    clearEventQueue();

    infoMap = {};
    giftWraps = {};
    _initSince = 0;
    giftWrapNewestDateTime = null;
    selectedDmSessionDetail = null;
    _currentBatchIndex = 0;
    _currentBatchUntil = Helpers.now;

    sendNotificationTimer?.cancel();
    _emit(
      DmsState(
        dmSessionDetails: const {},
        isUsingNip44: nostrRepository.isUsingNip44,
        index: 0,
        rebuild: true,
        isSendingMessage: false,
        mutes: nostrRepository.muteModel.usersMutes.toList(),
        selectedTime: 0,
        isLoadingHistory: false,
        dmDataState: DmDataState.enabled,
      ),
    );
  }

  Future<List<String>> getMessage(Event event) async {
    try {
      if (event.kind == EventKind.DIRECT_MESSAGE) {
        final peerPubkey = getPubkeyRegularEvent(event);
        String replyId = '';

        for (final tag in event.tags) {
          if (tag[0] == 'e' && tag.length > 1) {
            replyId = tag[1];
          }
        }

        String decryptedMessage = '';

        if (nostrRepository.nip04Dms[event.id] != null) {
          decryptedMessage = nostrRepository.nip04Dms[event.id]!;
        } else if (canSign()) {
          decryptedMessage = await currentSigner!.decrypt04(
                event.content,
                peerPubkey ?? '',
              ) ??
              "'Could not be decrypted'";
        } else {
          decryptedMessage = "'Could not be decrypted'";
        }

        nostrRepository.nip04Dms[event.id] = decryptedMessage;
        return [decryptedMessage, replyId];
      } else if (event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
        String replyId = '';
        for (final tag in event.tags) {
          if (tag[0] == 'e' && tag.length > 1) {
            replyId = tag[1];
          }
        }

        return [event.content.trim(), replyId];
      }

      return ['', ''];
    } catch (e) {
      lg.i(e);
      return ['', ''];
    }
  }

  String? getPubkeyRegularEvent(Event event) {
    if (event.pubkey != currentSigner!.getPublicKey()) {
      return event.pubkey;
    }

    for (final tag in event.tags) {
      if (tag[0] == 'p') {
        return tag[1];
      }
    }

    return null;
  }

  void _emit(DmsState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  @override
  Future<void> close() {
    clearEventQueue();
    followingsSubscription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
