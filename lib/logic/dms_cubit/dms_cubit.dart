import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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
import '../../models/dm_history_cursor.dart';
import '../../models/dm_models.dart';
import '../../models/mute_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'dms_state.dart';

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
            pendingEventIds: const {},
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
  Timer? _historyBackfillTimer;
  bool canShowNotification = true;
  Map<String, DMSessionInfo> infoMap = {};

  // Only ids are needed for dedupe — keeping the full gift-wrap events here
  // held every encrypted DM payload in memory for the whole session.
  Set<String> giftWrapIds = {};
  final Set<String> _giftWrapsInFlight = {};
  DmHistoryCursor? _historyCursor;
  int _dmLoadGeneration = 0;
  int? _historyRunGeneration;
  int _historyRetryCount = 0;
  String? _activeDmPubkey;
  int? _liveSubscriptionSince;
  int _initSince = 0;
  String? dmsSubscriptionId;
  int? giftWrapNewestDateTime;
  DMSessionDetail? selectedDmSessionDetail;
  bool isDmsView = false;
  bool showDmsRelayMessage = false;
  bool _isStreamingMode = false;
  Set<String> _processedEventIds = {};
  final Queue<Future<void> Function()> _sendQueue = Queue();
  bool _isSending = false;

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
      final tempId = 'temp-${Helpers.now}-${text.hashCode}';
      final shellEvent = Event.partial(
        kind: state.isUsingNip44
            ? EventKind.PRIVATE_DIRECT_MESSAGE
            : EventKind.DIRECT_MESSAGE,
        tags: [
          if (replayId != null) ['e', replayId],
          ['p', pubkey],
        ],
        content: text,
        pubkey: currentSigner!.getPublicKey(),
        createdAt: Helpers.now,
      )..id = tempId;

      // Optimistically add to UI immediately
      _addEventAndEmitImmediate(pubkey, shellEvent);
      _updatePendingStatus(tempId, true);
      onSuccessful.call();

      _sendQueue.add(() async {
        try {
          late Event realEvent;

          final relays = await getDmInboxRelays(
            pubkey,
            forceRefresh: !searchDmRelaysPubkeys.contains(pubkey),
          );

          searchDmRelaysPubkeys.add(pubkey);

          if (state.isUsingNip44) {
            final pmEvent = Event.withoutSignature(
              kind: EventKind.PRIVATE_DIRECT_MESSAGE,
              tags: [
                if (replayId != null) ['e', replayId],
                ['p', pubkey],
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

            await currentSigner!.sign(pmEvent);
            realEvent = pmEvent;

            // Swap shell with real event immediately
            _removeEventsAndEmitImmediate(pubkey, [tempId]);
            _updatePendingStatus(tempId, false);
            _addEventAndEmitImmediate(pubkey, realEvent);
            _updatePendingStatus(realEvent.id, true);

            if (senderEvent == null || receiverEvent == null) {
              _onMessageSentFailed(pubkey, tempId);
              return;
            }

            final successList = await Future.wait([
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
            ]);

            if (successList.first && successList.last) {
              _onMessageSentSuccess(pubkey);
            } else {
              _onMessageSentFailed(pubkey, realEvent.id);
            }
            _updatePendingStatus(realEvent.id, false);
          } else {
            final encryptedEvent = await currentSigner!.encrypt04Event(
              text,
              pubkey,
              replyId: replayId,
            );

            if (encryptedEvent == null) {
              _onMessageSentFailed(pubkey, tempId);
              return;
            }

            realEvent = encryptedEvent;

            // Swap shell with real event immediately
            _removeEventsAndEmitImmediate(pubkey, [tempId]);
            _updatePendingStatus(tempId, false);
            _addEventAndEmitImmediate(pubkey, realEvent);
            _updatePendingStatus(realEvent.id, true);

            final isSuccessful = await NostrFunctionsRepository.sendEvent(
              event: realEvent,
              relays: relays,
              setProgress: false,
            );

            if (isSuccessful) {
              _onMessageSentSuccess(pubkey);
            } else {
              _onMessageSentFailed(pubkey, realEvent.id);
            }
            _updatePendingStatus(realEvent.id, false);
          }
        } catch (_) {
          _onMessageSentFailed(pubkey, tempId);
          _updatePendingStatus(tempId, false);
        }
      });

      _processSendQueue();
    } catch (_) {
      BotToastUtils.showError(
        t.errorSendingMessage.capitalizeFirst(),
      );
    }
  }

  Future<void> sendGift({
    required String receiverPubkey,
    required String cover,
    required int amount,
    required String message,
    required String refundAddress,
    required ZapPaymentMethod paymentMethod,
    String? replyId,
    required Function() onSuccess,
  }) async {
    final cancelLoading = BotToastUtils.showLoading();

    try {
      final senderPubkey = currentSigner!.getPublicKey();
      final createdAt = Helpers.now;

      // 1. Initial Token Construction
      final initialPayload = {
        's': senderPubkey,
        's_addr': refundAddress,
        'r': receiverPubkey,
        'a': amount,
        'c_at': createdAt,
      };

      final encodedToken = encodeGiftToken(initialPayload);
      lg.i('Encoded Gift Token: $encodedToken');

      // 2. Invoice Generation
      final bridgeMetadata = Metadata.empty().copyWith(
        lud16: 'giftbridge@wallet.yakihonne.com',
      );

      final result = await ZapAction.genInvoiceCode(
        amount,
        bridgeMetadata,
        currentSigner!,
        currentUserRelayList.relays.keys.toList(),
        comment: encodedToken,
      );

      if (result == null || result.key.isEmpty) {
        return;
      }

      final invoice = result.key;

      // 3. Payment
      await walletManagerCubit.payInvoiceAndGetPreimage(
        invoice: invoice,
        onSuccess: (preimage) async {
          // 4. Final Token Construction
          final finalPayload = {
            ...initialPayload,
            'pi': preimage,
            'm': message.substring(0, message.length.clamp(0, 32)),
            'img': cover,
          };

          final finalEncodedToken = encodeGiftToken(finalPayload);

          // 5. Send DM
          await sendEvent(
            receiverPubkey,
            finalEncodedToken,
            replyId,
            onSuccess,
          );

          BotToastUtils.showSuccess(t.giftSentSuccessfully);
        },
        onFailure: (err) {
          BotToastUtils.showError(err);
        },
        useDefaultWallet: paymentMethod == ZapPaymentMethod.external,
      );
    } catch (e) {
      BotToastUtils.showError('Error: $e');
    } finally {
      cancelLoading();
    }
  }

  Future<void> claimGift({
    required String preimage,
    required String receiverAddress,
    required Function() onSuccess,
  }) async {
    final cancelLoading = BotToastUtils.showLoading();

    try {
      final userPubkey = currentSigner!.getPublicKey();
      const targetPubkey =
          'db48fbfb9f89b2870bcfd96cb1d283af6da999dde248b9bed6660f3c1e591380';

      // 1. Simulate fake invoice for validation
      final mockMetadata = Metadata.empty().copyWith(lud16: receiverAddress);
      final mockInvoiceResult = await ZapAction.genInvoiceCode(
        1,
        mockMetadata,
        currentSigner!,
        currentUserRelayList.relays.keys.toList(),
      );

      if (mockInvoiceResult == null || mockInvoiceResult.key.isEmpty) {
        BotToastUtils.showError(t.invalidLightningAddress.capitalizeFirst());
        return;
      }

      // 2. Encrypt payload with NIP-44
      final payload = {
        'pubkey': userPubkey,
        'preimage': preimage,
        'addr': receiverAddress,
      };

      final encryptedToken = await currentSigner!.encrypt44(
        jsonEncode(payload),
        targetPubkey,
      );

      if (encryptedToken == null) {
        BotToastUtils.showError(t.encryptionFailed.capitalizeFirst());
        return;
      }

      // 3. Claim red packet via API
      final result = await HttpFunctionsRepository.claimRedPacket(
        pubkey: userPubkey,
        token: encryptedToken,
      );

      lg.i(result);

      if (result != null && result['isRedeemed'] == true) {
        onSuccess();
        BotToastUtils.showSuccess(t.giftClaimedSuccessfully);
      } else if (result != null && result['isExpired'] == true) {
        BotToastUtils.showError(t.expired.capitalizeFirst());
      } else {
        BotToastUtils.showError(result?['message'] ?? t.errorClaimingGift);
      }
    } catch (e) {
      lg.e('Error claiming gift: $e');
      BotToastUtils.showError('Error: $e');
    } finally {
      cancelLoading();
    }
  }

  Future<void> _processSendQueue() async {
    if (_isSending || _sendQueue.isEmpty) {
      return;
    }

    _isSending = true;

    final task = _sendQueue.removeFirst();
    await task();

    _isSending = false;
    _processSendQueue();
  }

  void _updatePendingStatus(String eventId, bool isPending) {
    final pendingEventIds = Set<String>.from(state.pendingEventIds);
    if (isPending) {
      pendingEventIds.add(eventId);
    } else {
      pendingEventIds.remove(eventId);
    }
    _emit(state.copyWith(pendingEventIds: pendingEventIds));
  }

  void _onMessageSentSuccess(String pubkey) {
    if (pubkey == yakihonneHex) {
      HttpFunctionsRepository.sendAction(PointsActions.DMSYAKI);
    } else {
      HttpFunctionsRepository.sendAction(PointsActions.DMS);
    }
  }

  void _onMessageSentFailed(String pubkey, String eventId) {
    BotToastUtils.showError(
      t.errorSendingEvent.capitalizeFirst(),
    );
    _removeEventsAndEmitImmediate(pubkey, [eventId]);
  }

  void _addEventAndEmitImmediate(String pubkey, Event event) {
    if (event.id.startsWith('temp-')) {
      _processedEventIds.remove(event.id); // Don't block real event later
    } else {
      _processedEventIds.add(event.id);
    }

    final dms = Map<String, DMSessionDetail>.from(state.dmSessionDetails);
    DMSessionDetail? dmSessionDetail = dms[pubkey];

    if (dmSessionDetail == null) {
      dmSessionDetail = DMSessionDetail(
        dmSession: DMSession(pubkey: pubkey),
        info: DMSessionInfo(
          id: '${currentSigner!.getPublicKey()}+$pubkey',
          peerPubkey: pubkey,
          ownPubkey: currentSigner!.getPublicKey(),
          readTime: 0,
        ),
        dmsType: DmsType.unknown,
      );
    } else {
      dmSessionDetail = dmSessionDetail.copyWith(
          dmSession: dmSessionDetail.dmSession.clone());
    }

    if (dmSessionDetail.dmSession.addEvent(event)) {
      if (contactListCubit.contacts.contains(pubkey)) {
        dms[pubkey] = dmSessionDetail.copyWith(dmsType: DmsType.followings);
      } else if (dmSessionDetail.dmSession
          .doesEventExist(currentSigner!.getPublicKey())) {
        dms[pubkey] = dmSessionDetail.copyWith(dmsType: DmsType.known);
      } else {
        dms[pubkey] = dmSessionDetail;
      }

      _emit(
        state.copyWith(
          dmSessionDetails: dms,
          rebuild: !state.rebuild,
        ),
      );
    }

    updateReadedTime(pubkey);
  }

  Future<void> deleteMessage(String pubkey, String eventId) async {
    await deleteMessages(pubkey, [eventId]);
  }

  Future<void> deleteMessages(String pubkey, List<String> eventIds) async {
    final myPubkey = currentSigner?.getPublicKey();
    if (myPubkey == null) {
      return;
    }

    final sessionDetail = state.dmSessionDetails[pubkey];
    if (sessionDetail == null) {
      return;
    }

    final deletableIds = eventIds.where((id) {
      final event = sessionDetail.dmSession.getById(id);
      return event != null && event.pubkey == myPubkey;
    }).toList();

    if (deletableIds.isEmpty) {
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.deleteEvents(
      eventIds: deletableIds,
    );

    if (isSuccessful) {
      _removeEventsAndEmitImmediate(pubkey, deletableIds);
      BotToastUtils.showSuccess(
        t.messageDeleted.capitalizeFirst(),
      );
    } else {
      BotToastUtils.showError(
        t.errorDeletingMessage.capitalizeFirst(),
      );
    }
  }

  void removeEvent(String pubkey, String eventId) {
    _removeEventsAndEmitImmediate(pubkey, [eventId]);
  }

  void _removeEventsAndEmitImmediate(String pubkey, List<String> eventIds) {
    eventIds.forEach(_processedEventIds.remove);

    final dms = Map<String, DMSessionDetail>.from(state.dmSessionDetails);
    final sessionDetail = dms[pubkey];
    if (sessionDetail != null) {
      final session = sessionDetail.dmSession.clone();
      eventIds.forEach(session.removeEvent);
      dms[pubkey] = sessionDetail.copyWith(dmSession: session);
      _emit(
        state.copyWith(
          dmSessionDetails: dms,
          rebuild: !state.rebuild,
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

    final currentPubkey = currentSigner!.getPublicKey();
    final generation = ++_dmLoadGeneration;
    _historyBackfillTimer?.cancel();
    _historyBackfillTimer = null;
    _historyRunGeneration = null;
    _historyRetryCount = 0;
    _historyCursor = null;
    _activeDmPubkey = currentPubkey;

    if (dmsSubscriptionId != null) {
      nc.closeRequests([dmsSubscriptionId!]);
      dmsSubscriptionId = null;
    }

    clearEventQueue();
    _isStreamingMode = false;
    _pendingSessionUpdates.clear();
    _processedEventIds = {};
    giftWrapIds = {};
    _giftWrapsInFlight.clear();

    _initSince = 0;
    checkNotificationAllowed();

    giftWrapNewestDateTime = localDatabaseRepository.getNewestGiftWrap(
      currentPubkey,
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
        pendingEventIds: const {},
      ),
    );

    // The cache seeds the live and history cursors and dedupe IDs. Keep it
    // ahead of both network paths.
    await _loadCachedEventsNormally(currentPubkey, generation: generation);
    if (!_isCurrentDmLoad(generation, currentPubkey)) {
      return;
    }

    // Start live reception after the cache baseline is known, before older
    // history work can take an unbounded amount of time.
    _isStreamingMode = true;
    final savedCursor =
        localDatabaseRepository.getDmsHistoryProgress(currentPubkey);
    final hasCachedHistory = _initSince != 0 || giftWrapNewestDateTime != null;
    final needsHistoryBackfill =
        (_initSince == 0 && giftWrapNewestDateTime == null) ||
            (savedCursor != null && !savedCursor.isComplete);

    if (needsHistoryBackfill) {
      final now = Helpers.now;
      _historyCursor = savedCursor != null && !savedCursor.isComplete
          ? savedCursor
          : DmHistoryCursor(
              until: now,
              intervalIndex: 0,
              liveSince: now,
            );
    }

    _liveSubscriptionSince = _initSince != 0
        ? _initSince
        : (savedCursor?.liveSince ??
            _historyCursor?.liveSince ??
            (giftWrapNewestDateTime == null ? Helpers.now : null));
    query();

    if (needsHistoryBackfill) {
      if (!hasCachedHistory) {
        _emit(state.copyWith(isLoadingHistory: true));
      }
      _scheduleHistoryBackfill(
        pubkey: currentPubkey,
        generation: generation,
        delay: Duration.zero,
      );
    } else if (savedCursor?.isComplete ?? false) {
      await localDatabaseRepository.deleteDmsHistoryOlderUntil(currentPubkey);
      if (!_isCurrentDmLoad(generation, currentPubkey)) {
        return;
      }
      _emit(state.copyWith(isLoadingHistory: false));
    }
  }

  bool _isCurrentDmLoad(int generation, String pubkey) {
    return !isClosed &&
        generation == _dmLoadGeneration &&
        _activeDmPubkey == pubkey &&
        currentSigner?.getPublicKey() == pubkey;
  }

  void _scheduleHistoryBackfill({
    required String pubkey,
    required int generation,
    required Duration delay,
  }) {
    if (!_isCurrentDmLoad(generation, pubkey)) {
      return;
    }

    _historyBackfillTimer?.cancel();
    _historyBackfillTimer = Timer(delay, () {
      _historyBackfillTimer = null;
      unawaited(_runHistoryBackfill(pubkey, generation));
    });
  }

  Future<void> _runHistoryBackfill(String pubkey, int generation) async {
    if (!_isCurrentDmLoad(generation, pubkey) ||
        !canSign() ||
        _historyRunGeneration == generation) {
      return;
    }

    _historyRunGeneration = generation;
    try {
      for (var page = 0; page < 5; page++) {
        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }

        final cursor = _historyCursor;
        if (cursor == null || cursor.isComplete) {
          await localDatabaseRepository.deleteDmsHistoryOlderUntil(pubkey);
          if (!_isCurrentDmLoad(generation, pubkey)) {
            return;
          }
          _historyCursor = null;
          _emit(state.copyWith(isLoadingHistory: false));
          return;
        }

        final events = await NostrFunctionsRepository.getUserDmsAsync(
          since: cursor.since,
          until: cursor.until,
        );
        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }

        final decryptedGiftWraps = await handleGiftWrapsAsync(
          events.giftWraps,
          generation: generation,
          pubkey: pubkey,
        );
        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }

        try {
          await _processBackfilledEvents(
            [...events.directMessages, ...decryptedGiftWraps.messages],
            pubkey: pubkey,
            generation: generation,
          );
        } catch (_) {
          if (_isCurrentDmLoad(generation, pubkey)) {
            _releaseHistoryGiftWraps(
              decryptedGiftWraps.wrapIds,
              generation: generation,
              pubkey: pubkey,
            );
          }
          rethrow;
        }

        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }

        for (final event in decryptedGiftWraps.messages) {
          await setGiftWrapOldestDateTime(event, pubkey: pubkey);
        }
        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }

        if (!events.isComplete) {
          _historyRetryCount++;
          _scheduleHistoryBackfill(
            pubkey: pubkey,
            generation: generation,
            delay: _historyRetryDelay,
          );
          return;
        }

        _historyRetryCount = 0;
        final nextCursor = cursor.advance(
          pageHasEvents:
              events.directMessages.isNotEmpty || events.giftWraps.isNotEmpty,
        );

        if (nextCursor.isComplete) {
          await localDatabaseRepository.deleteDmsHistoryOlderUntil(pubkey);
          if (!_isCurrentDmLoad(generation, pubkey)) {
            return;
          }
          _historyCursor = null;
          _emit(state.copyWith(isLoadingHistory: false));
          return;
        }

        final saved = await localDatabaseRepository.setDmsHistoryProgress(
          pubkey,
          nextCursor,
        );
        if (!_isCurrentDmLoad(generation, pubkey)) {
          return;
        }
        if (!saved) {
          throw StateError('Could not persist DM history cursor.');
        }

        _historyCursor = nextCursor;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      _scheduleHistoryBackfill(
        pubkey: pubkey,
        generation: generation,
        delay: const Duration(seconds: 2),
      );
    } catch (e) {
      if (_isCurrentDmLoad(generation, pubkey)) {
        lg.e('DM history backfill failed: $e');
        _historyRetryCount++;
        _scheduleHistoryBackfill(
          pubkey: pubkey,
          generation: generation,
          delay: _historyRetryDelay,
        );
      }
    } finally {
      if (_historyRunGeneration == generation) {
        _historyRunGeneration = null;
      }
    }
  }

  Duration get _historyRetryDelay {
    final exponent = (_historyRetryCount - 1).clamp(0, 4);
    final seconds = (1 << exponent).clamp(1, 15);
    return Duration(seconds: seconds);
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

  Future<({List<Event> messages, Set<String> wrapIds})> handleGiftWrapsAsync(
    List<Event> events, {
    required int generation,
    required String pubkey,
  }) async {
    final toBeProcessedEvents = <Event>[];
    final wrapIds = <String>{};

    for (final giftWrap in events) {
      if (_processedEventIds.contains(giftWrap.id) ||
          _giftWrapsInFlight.contains(giftWrap.id) ||
          !giftWrapIds.add(giftWrap.id)) {
        continue;
      }

      _processedEventIds.add(giftWrap.id);
      _giftWrapsInFlight.add(giftWrap.id);
      wrapIds.add(giftWrap.id);
      toBeProcessedEvents.add(giftWrap);
    }

    if (toBeProcessedEvents.isEmpty) {
      return (messages: <Event>[], wrapIds: wrapIds);
    }

    try {
      if (!_isCurrentDmLoad(generation, pubkey)) {
        return (messages: <Event>[], wrapIds: <String>{});
      }

      final signer = currentSigner!;
      final List<Event> messages;
      if (signer is AmberEventSigner) {
        // Amber decrypts through a platform channel, which cannot run inside
        // compute()'s background isolate.
        messages = <Event>[];
        for (final giftWrap in toBeProcessedEvents) {
          final message = await signer.decrypt44Event(giftWrap);
          if (message?.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
            messages.add(message!);
          }
        }
      } else if (signer is Bip340EventSigner) {
        messages = await compute(_handleGiftWrapsInIsolate, {
          'giftWraps':
              toBeProcessedEvents.map((event) => event.toJson()).toList(),
          'signerData': _getCurrentSignerData(),
        });
      } else {
        throw StateError('Unsupported signer for DM history decryption.');
      }

      if (!_isCurrentDmLoad(generation, pubkey)) {
        return (messages: <Event>[], wrapIds: <String>{});
      }

      _giftWrapsInFlight.removeAll(wrapIds);
      return (messages: messages, wrapIds: wrapIds);
    } catch (_) {
      if (_isCurrentDmLoad(generation, pubkey)) {
        _releaseHistoryGiftWraps(
          wrapIds,
          generation: generation,
          pubkey: pubkey,
        );
      }
      rethrow;
    }
  }

  void _releaseHistoryGiftWraps(
    Iterable<String> wrapIds, {
    required int generation,
    required String pubkey,
  }) {
    if (!_isCurrentDmLoad(generation, pubkey)) {
      return;
    }

    for (final wrapId in wrapIds) {
      _giftWrapsInFlight.remove(wrapId);
      giftWrapIds.remove(wrapId);
      _processedEventIds.remove(wrapId);
    }
  }

  Future<void> _processBackfilledEvents(
    List<Event> events, {
    required String pubkey,
    required int generation,
  }) async {
    final newEvents = <Event>[];
    for (final event in events) {
      if (_processedEventIds.add(event.id)) {
        event.currentUser = pubkey;
        newEvents.add(event);
      }
    }

    if (newEvents.isEmpty) {
      return;
    }

    try {
      await nc.db.saveEvents(newEvents);
      if (!_isCurrentDmLoad(generation, pubkey)) {
        return;
      }

      _handleEvents(newEvents, persistEvents: false);
    } catch (_) {
      if (_isCurrentDmLoad(generation, pubkey)) {
        for (final event in newEvents) {
          _processedEventIds.remove(event.id);
        }
      }
      rethrow;
    }
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

  Future<void> handleGiftWraps(
    Event gwe, {
    int? generation,
    String? pubkey,
  }) async {
    final currentPubkey = pubkey ?? currentSigner?.getPublicKey();
    final currentGeneration = generation ?? _dmLoadGeneration;
    if (currentPubkey == null ||
        !_isCurrentDmLoad(currentGeneration, currentPubkey) ||
        _processedEventIds.contains(gwe.id) ||
        _giftWrapsInFlight.contains(gwe.id) ||
        !giftWrapIds.add(gwe.id)) {
      return;
    }

    _giftWrapsInFlight.add(gwe.id);
    Event? event;
    try {
      event = await currentSigner!.decrypt44Event(gwe);
    } catch (e) {
      if (_isCurrentDmLoad(currentGeneration, currentPubkey)) {
        _giftWrapsInFlight.remove(gwe.id);
        giftWrapIds.remove(gwe.id);
      }
      lg.i('Could not decrypt incoming DM gift wrap: $e');
      return;
    }

    if (!_isCurrentDmLoad(currentGeneration, currentPubkey)) {
      return;
    }
    _giftWrapsInFlight.remove(gwe.id);

    _processedEventIds.add(gwe.id);
    if (_isStreamingMode) {
      queueEvent(gwe);
    } else {
      eventLaterHandle([gwe]);
    }

    if (event != null && event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
      if (_processedEventIds.add(event.id)) {
        if (_isStreamingMode) {
          queueEvent(event);
        } else {
          eventLaterHandle([event]);
        }

        await setGiftWrapOldestDateTime(event, pubkey: currentPubkey);
      }
    }
  }

  void query() {
    final pubkey = _activeDmPubkey;
    final generation = _dmLoadGeneration;
    if (!canSign() ||
        pubkey == null ||
        dmsSubscriptionId != null ||
        !_isCurrentDmLoad(generation, pubkey)) {
      return;
    }

    final subscriptionId = NostrFunctionsRepository.getUserDms(
      since: _initSince != 0 ? _initSince : _liveSubscriptionSince,
      since1059: giftWrapNewestDateTime ?? _liveSubscriptionSince,
      kind1059Events: (giftEvent) {
        if (_isCurrentDmLoad(generation, pubkey)) {
          unawaited(
            handleGiftWraps(
              giftEvent,
              generation: generation,
              pubkey: pubkey,
            ),
          );
        }
      },
      kind4Events: (dmEvent) {
        if (_isCurrentDmLoad(generation, pubkey)) {
          onEvent(dmEvent);
        }
      },
    );

    if (_isCurrentDmLoad(generation, pubkey)) {
      dmsSubscriptionId = subscriptionId;
    } else {
      nc.closeRequests([subscriptionId]);
    }
  }

  // Load cached events using original logic (fast, no queue)
  Future<void> _loadCachedEventsNormally(
    String currentPubkey, {
    required int generation,
  }) async {
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

    if (!_isCurrentDmLoad(generation, currentPubkey)) {
      return;
    }

    if (localGiftWraps.isNotEmpty) {
      giftWrapIds = {for (final v in localGiftWraps) v.id};
    }

    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (events.isNotEmpty) {
      _initSince = events.first.createdAt;
    }

    // Track which events we've already processed from cache
    _processedEventIds = events.map((e) => e.id).toSet();
    _processedEventIds.addAll(localGiftWraps.map((e) => e.id));

    // Process cached events using ORIGINAL logic (no queue overhead)
    await _processCachedEvents(
      events,
      currentPubkey,
      generation: generation,
    );
  }

  // Process cached events with original logic - fast and efficient
  Future<void> _processCachedEvents(
    List<Event> events,
    String currentPubkey, {
    required int generation,
  }) async {
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
    if (!_isCurrentDmLoad(generation, currentPubkey)) {
      return;
    }

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

  Future<void> setGiftWrapOldestDateTime(
    Event event, {
    String? pubkey,
  }) async {
    final currentPubkey = pubkey ?? currentSigner?.getPublicKey();
    if (currentPubkey == null ||
        currentSigner?.getPublicKey() != currentPubkey ||
        (_activeDmPubkey != null && _activeDmPubkey != currentPubkey)) {
      return;
    }

    if (giftWrapNewestDateTime == null ||
        event.createdAt > giftWrapNewestDateTime!) {
      giftWrapNewestDateTime = event.createdAt;
      await localDatabaseRepository.setNewestGiftWrap(
        currentPubkey,
        event.createdAt,
      );
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
    _handleEvents(events, persistEvents: true);
  }

  void _handleEvents(
    List<Event> events, {
    required bool persistEvents,
  }) {
    bool updated = false;
    final List<Event> toSave = [];

    for (final event in events) {
      final addResult = _addEventWithoutEmit(event); // Don't emit state here
      if (addResult) {
        if (!event.id.startsWith('temp-')) {
          toSave.add(event);
        }
        updated = true;
      }
    }

    if (updated) {
      if (persistEvents && toSave.isNotEmpty) {
        unawaited(nc.db.saveEvents(toSave));
      }

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
    _dmLoadGeneration++;
    _activeDmPubkey = null;
    _historyBackfillTimer?.cancel();
    _historyBackfillTimer = null;
    _historyCursor = null;
    _historyRetryCount = 0;
    _historyRunGeneration = null;
    _liveSubscriptionSince = null;
    _isStreamingMode = false;

    if (dmsSubscriptionId != null) {
      nc.closeRequests([dmsSubscriptionId!]);
      dmsSubscriptionId = null;
    }

    // Clear the event queue
    clearEventQueue();
    disposeLater();

    infoMap = {};
    giftWrapIds = {};
    _giftWrapsInFlight.clear();
    _processedEventIds = {};
    _initSince = 0;
    giftWrapNewestDateTime = null;
    selectedDmSessionDetail = null;
    _pendingSessionUpdates.clear();
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = null;

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
        pendingEventIds: const {},
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
        nostrRepository.nip04Dms.capSize(1000);
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
  Future<void> close() async {
    _dmLoadGeneration++;
    _activeDmPubkey = null;
    _historyBackfillTimer?.cancel();
    _uiUpdateTimer?.cancel();
    sendNotificationTimer?.cancel();
    disposeLater();
    clearEventQueue();
    if (dmsSubscriptionId != null) {
      nc.closeRequests([dmsSubscriptionId!]);
      dmsSubscriptionId = null;
    }
    await followingsSubscription.cancel();
    await muteListSubscription.cancel();
    await super.close();
  }
}
