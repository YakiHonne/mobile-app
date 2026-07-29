// ignore_for_file: use_setters_to_change_properties

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/notifications/notification_helper.dart';
import '../../common/notifications/push_core.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit()
      : super(
          const NotificationsState(
            events: <Event>[],
            index: 0,
            isRead: true,
            refresh: false,
            isLoading: true,
          ),
        );

  int? since;
  String? notificationsSubscriptionId;
  Timer? sendNotificationTimer;
  bool isNotificationView = false;
  bool canShowNotification = true;
  bool initialized = false;

  late Map<String, List<String>> registredNotifications =
      <String, List<String>>{};
  late Map<String, List<String>> newNotifications = <String, List<String>>{};

  Timer? _uiUpdateTimer;
  bool _hasPendingUpdates = false;
  final Map<String, Event> _unemittedEvents = {};

  void loadNotifications() {
    registredNotifications = localDatabaseRepository.getNotifications(true);
    newNotifications = localDatabaseRepository.getNotifications(false);
  }

  void setNotificationView(bool isNotification) {
    isNotificationView = isNotification;
  }

  Future<void> clear() async {
    if (notificationsSubscriptionId != null) {
      await nc.closeRequests(<String>[notificationsSubscriptionId!]);
      notificationsSubscriptionId = null;
    }

    since = null;
    _uiUpdateTimer?.cancel();
    _unemittedEvents.clear();
    _hasPendingUpdates = false;

    if (!isClosed) {
      emit(
        state.copyWith(
          events: <Event>[],
          index: 0,
          isRead: true,
          refresh: !state.refresh,
        ),
      );
    }
  }

  void closeNotifications() {
    if (notificationsSubscriptionId != null) {
      nc.closeRequests(<String>[notificationsSubscriptionId!]);
      notificationsSubscriptionId = null;
    }
  }

  Future<void> initNotifications({bool isRefresh = false}) async {
    final c = nostrRepository.currentAppCustomization;
    if (!isRefresh && (c?.enablePushNotification ?? false)) {
      PushCore.sharedInstance.setup();
    }

    await checkNotificationAllowed();
    await queryAndSubscribe(isRefresh: isRefresh);
  }

  void cleanAndSubscribe() {
    clear();
    queryAndSubscribe();
  }

  Future<void> checkNotificationAllowed() async {
    canShowNotification = await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> queryAndSubscribe({bool isRefresh = false}) async {
    if (notificationsSubscriptionId != null) {
      nc.closeRequests(<String>[notificationsSubscriptionId!]);
      notificationsSubscriptionId = null;
    }

    if (canSign()) {
      final pubkey = currentSigner!.getPublicKey();

      _uiUpdateTimer?.cancel();
      if (!isRefresh) {
        _unemittedEvents.clear();
      }
      _hasPendingUpdates = false;

      if (!isClosed) {
        emit(
          state.copyWith(
            isRead: newNotifications[pubkey]?.isEmpty ?? true,
            events: isRefresh ? state.events : [],
            isLoading: true,
          ),
        );
      }

      final events = await NostrFunctionsRepository.queryNotifications(
        pubkey: pubkey,
        limit: 40,
      );

      // ponytail: the query above can resolve after the account has already
      // switched (no cancellation support upstream); drop stale results
      // instead of leaking the old account's notifications into the new one.
      if (currentSigner?.getPublicKey() != pubkey) {
        return;
      }

      await eventLaterHandle(events, pubkey: pubkey);

      final subscriptionId =
          await NostrFunctionsRepository.subscribeToNotifications(
        pubkey: pubkey,
        onEvents: (event) => onEvent(event, pubkey),
        since: since != null ? since! + 1 : null,
      );

      if (currentSigner?.getPublicKey() != pubkey) {
        nc.closeRequests(<String>[subscriptionId]);
      } else {
        notificationsSubscriptionId = subscriptionId;
      }
    }
  }

  void onEvent(Event event, String pubkey) {
    if (currentSigner?.getPublicKey() != pubkey) {
      return;
    }

    eventLaterHandle([event], pubkey: pubkey);
  }

  Future<void> eventLaterHandle(List<Event> events, {String? pubkey}) async {
    if (events.isNotEmpty) {
      final filtered = await filteredWotEvents(events);

      if (pubkey != null && currentSigner?.getPublicKey() != pubkey) {
        return;
      }

      if (filtered.isEmpty) {
        return;
      }

      for (final e in filtered) {
        _unemittedEvents[e.id] = e;
      }

      _hasPendingUpdates = true;
      _scheduleUIUpdate();
      setNotification(filtered);
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
          ),
        );
      }
    }
  }

  void _scheduleUIUpdate() {
    if (_uiUpdateTimer?.isActive ?? false) {
      return;
    }

    _uiUpdateTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_hasPendingUpdates && !isClosed) {
        final map = {for (final e in state.events) e.id: e};
        map.addAll(_unemittedEvents);

        final newEvents = map.values.toList();
        newEvents.sort(
          (Event a, Event b) => b.createdAt.compareTo(a.createdAt),
        );

        if (newEvents.isNotEmpty) {
          since = newEvents.first.createdAt;
        }

        emit(
          state.copyWith(
            events: newEvents,
            isLoading: false,
          ),
        );

        _unemittedEvents.clear();
        _hasPendingUpdates = false;
      }
    });
  }

  Future<List<Event>> filteredWotEvents(List<Event> events) async {
    if (canSign()) {
      final conf = nostrRepository.getWotConfiguration(
        currentSigner!.getPublicKey(),
      );

      if (conf.isEnabled && conf.notifications) {
        final pubkeys = events.map((e) => e.pubkey).toSet();

        final wotScores = await nc.calculatePeerPubkeyWotList(
          peerPubkeys: pubkeys.toList(),
          originPubkey: currentSigner!.getPublicKey(),
        );

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

  void setNotification(List<Event> newEvents) {
    if (sendNotificationTimer != null) {
      sendNotificationTimer!.cancel();
    }

    sendNotificationTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (canSign()) {
          if (isNotificationView) {
            addNotifications();
          } else if (shouldBeNotified(newEvents)) {
            final pubkey = currentSigner!.getPublicKey();

            newNotifications[pubkey] = <String>{
              ...newNotifications[pubkey] ?? <String>[],
              ...newEvents.map((Event e) => e.id),
            }.toList();

            localDatabaseRepository.setNotifications(
              newNotifications,
              false,
            );

            if (!isClosed) {
              emit(
                state.copyWith(
                  isRead: false,
                ),
              );
            }

            sendNotificationTimer?.cancel();
          }
        }
      },
    );
  }

  bool shouldBeNotified(List<Event> events, {String? pubkey}) {
    final key = pubkey ?? currentSigner?.getPublicKey() ?? '';
    final userNewNotifications = newNotifications[key];
    final userRegistredNotifications = registredNotifications[key];

    final newIds =
        userNewNotifications != null && userNewNotifications.isNotEmpty
            ? userNewNotifications.toSet()
            : null;
    final registredIds = userRegistredNotifications != null &&
            userRegistredNotifications.isNotEmpty
        ? userRegistredNotifications.toSet()
        : null;

    final doesNotContainNew =
        newIds == null || events.any((e) => !newIds.contains(e.id));
    final doesNotContainRegistred =
        registredIds == null || events.any((e) => !registredIds.contains(e.id));

    return !isNotificationView &&
        events.isNotEmpty &&
        doesNotContainNew &&
        doesNotContainRegistred;
  }

  int newEventsNumber({String? pubkey}) {
    final String usedPubkey = pubkey ?? currentSigner!.getPublicKey();

    return newNotifications[usedPubkey]?.length ?? 0;
  }

  void addNotifications() {
    if (canSign()) {
      final String pubkey = currentSigner!.getPublicKey();

      final List<String>? registredNotificationsIds =
          registredNotifications[pubkey];

      if (registredNotificationsIds == null ||
          registredNotificationsIds.isEmpty) {
        registredNotifications[pubkey] = newNotifications[pubkey] ?? <String>[];
      } else {
        registredNotifications[pubkey] = <String>{
          ...registredNotifications[pubkey]!,
          ...newNotifications[pubkey] ?? <String>[],
        }.toList();
      }

      localDatabaseRepository.setNotifications(
        registredNotifications,
        true,
      );

      newNotifications.remove(pubkey);

      localDatabaseRepository.setNotifications(
        newNotifications,
        false,
      );
    }
  }

  void setIndex(int index) {
    emit(
      state.copyWith(
        index: index,
      ),
    );
  }

  void markRead() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isRead: true,
        ),
      );
    }

    addNotifications();
    if (canShowNotification) {
      AwesomeNotifications().setGlobalBadgeCounter(0);
    }
  }

  void setPushNotifications(String deviceId) {
    final kinds = <int>{
      EventKind.DIRECT_MESSAGE,
      EventKind.PRIVATE_DIRECT_MESSAGE,
    };
    final c = nostrRepository.currentAppCustomization;

    if (c?.notifMentionsReplies ?? false) {
      kinds.addAll(
        [
          EventKind.TEXT_NOTE,
          EventKind.LONG_FORM,
          EventKind.SMART_WIDGET_ENH,
        ],
      );
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

    NotificationHelper.sharedInstance.setNotification(
      deviceId,
      kinds.toList(),
    );

    NotificationHelper.sharedInstance.init();
  }

  @override
  Future<void> close() {
    _uiUpdateTimer?.cancel();
    sendNotificationTimer?.cancel();
    return super.close();
  }
}
