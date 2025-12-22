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

  Future<void> initNotifications() async {
    final c = nostrRepository.currentAppCustomization;
    if (c?.enablePushNotification ?? false) {
      PushCore.sharedInstance.setup();
    }

    await checkNotificationAllowed();
    await queryAndSubscribe();
  }

  void cleanAndSubscribe() {
    clear();
    queryAndSubscribe();
  }

  Future<void> checkNotificationAllowed() async {
    canShowNotification = await AwesomeNotifications().isNotificationAllowed();
  }

  Future<void> queryAndSubscribe() async {
    if (notificationsSubscriptionId != null) {
      nc.closeRequests(<String>[notificationsSubscriptionId!]);
    }

    if (canSign()) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isRead: newNotifications[currentSigner!.getPublicKey()]?.isEmpty ??
                true,
            events: [],
            isLoading: true,
          ),
        );
      }

      final events = await NostrFunctionsRepository.queryNotifications(
        pubkey: currentSigner!.getPublicKey(),
        limit: 40,
      );

      await eventLaterHandle(events);

      notificationsSubscriptionId =
          await NostrFunctionsRepository.subscribeToNotifications(
        pubkey: currentSigner!.getPublicKey(),
        onEvents: onEvent,
        since: since != null ? since! + 1 : null,
      );
    }
  }

  void onEvent(Event event) {
    eventLaterHandle([event]);
  }

  Future<void> eventLaterHandle(List<Event> events) async {
    if (events.isNotEmpty) {
      final filtered = await filteredWotEvents(events);

      if (filtered.isEmpty) {
        return;
      }

      final map = {for (final e in state.events) e.id: e};

      map.addAll({for (final e in filtered) e.id: e});

      final newEvents = map.values.toList();

      newEvents.sort(
        (Event a, Event b) => b.createdAt.compareTo(a.createdAt),
      );

      since = newEvents.first.createdAt;
      if (!isClosed) {
        emit(
          state.copyWith(
            events: newEvents,
            isLoading: false,
          ),
        );
      }

      setNotification(newEvents);
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
          if (e.kind == EventKind.ZAP) {
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
    final userNewNotifications =
        newNotifications[pubkey ?? currentSigner?.getPublicKey() ?? ''];
    final userRegistredNotifications =
        registredNotifications[pubkey ?? currentSigner?.getPublicKey() ?? ''];

    final doesNotContainNew = userNewNotifications == null ||
        userNewNotifications.isEmpty ||
        events.where((Event e) => userNewNotifications.contains(e.id)).length !=
            events.length;

    final doesNotContainRegistred = userRegistredNotifications == null ||
        userRegistredNotifications.isEmpty ||
        events
                .where((Event e) => userRegistredNotifications.contains(e.id))
                .length !=
            events.length;

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
    final c = nostrRepository.currentAppCustomization;

    if (!(c?.enablePushNotification ?? false)) {
      return;
    }

    final kinds = <int>{
      EventKind.DIRECT_MESSAGE,
      EventKind.PRIVATE_DIRECT_MESSAGE,
    };

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
}
