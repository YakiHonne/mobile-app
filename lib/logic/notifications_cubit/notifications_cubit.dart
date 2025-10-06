// ignore_for_file: use_setters_to_change_properties

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../common/notifications/notification_helper.dart';
import '../../common/notifications/push_core.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState>
    with PendingEventsLaterFunction {
  NotificationsCubit()
      : super(
          const NotificationsState(
            events: <Event>[],
            index: 0,
            isRead: true,
            refresh: false,
            isLoading: true,
          ),
        ) {
    userStreamSubscription = nostrRepository.currentSignerStream.listen(
      (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );

    customizationSubscription = nostrRepository.appCustomizationStream.listen(
      (_) {
        clear();
        queryAndSubscribe();
      },
    );

    mutesSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (initialized) {
          clear();
          queryAndSubscribe();
        }

        initialized = true;
      },
    );
  }

  int? since;
  String? notificationsSubscriptionId;
  Timer? sendNotificationTimer;
  bool isNotificationView = false;
  bool canShowNotification = true;
  bool initialized = false;
  late Map<String, List<String>> registredNotifications =
      <String, List<String>>{};
  late Map<String, List<String>> newNotifications = <String, List<String>>{};
  late StreamSubscription userStreamSubscription;
  late StreamSubscription mutesSubscription;
  late StreamSubscription customizationSubscription;

  void loadNotifications() {
    registredNotifications = localDatabaseRepository.getNotifications(true);
    newNotifications = localDatabaseRepository.getNotifications(false);
  }

  void setNotificationView(bool isNotification) {
    isNotificationView = isNotification;
  }

  void clear() {
    if (notificationsSubscriptionId != null) {
      nc.closeRequests(<String>[notificationsSubscriptionId!]);
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

      eventLaterHandle(events);

      notificationsSubscriptionId =
          await NostrFunctionsRepository.subscribeToNotifications(
        pubkey: currentSigner!.getPublicKey(),
        onEvents: onEvent,
        since: since != null ? since! + 1 : null,
      );
    }
  }

  void onEvent(Event event) {
    later(event, eventLaterHandle, null);
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

  // Future<void> sendNotification(Event ev, int count) async {
  //   final an = AwesomeNotifications();

  //   String title = '';
  //   String? body;
  //   final ExtendedEvent event = ExtendedEvent.fromEv(ev);

  //   Metadata? user = metadataCubit.getCachedMetadata(event.pubkey);

  //   String name = user?.getName() ??
  //       Metadata.empty()
  //           .copyWith(
  //             pubkey: event.pubkey,
  //           )
  //           .getName();

  //   if (event.kind == EventKind.REACTION) {
  //     title = t
  //         .reactedWith(
  //           name: name,
  //           reaction: event.content.replaceAll('+', '👍').replaceAll('-', '👎'),
  //         )
  //         .capitalizeFirst();
  //   } else if (event.kind == EventKind.ZAP) {
  //     final double zapNum = getZapValue(event);
  //     final List<String> list = getZapPubkey(event.tags);

  //     if (list.first.isNotEmpty) {
  //       user = metadataCubit.getCachedMetadata(list.first);
  //       name = user?.getName() ??
  //           Metadata.empty()
  //               .copyWith(
  //                 pubkey: event.pubkey,
  //               )
  //               .getName();
  //     }

  //     if (list[1].isNotEmpty) {
  //       body = list[1];
  //     }

  //     title = t
  //         .userZappedYou(name: name, number: zapNum.toInt().toString())
  //         .capitalizeFirst();
  //   } else if (event.kind == EventKind.APP_CUSTOM) {
  //     title = t.yakihonneNotification.capitalizeFirst();

  //     final bool isAuthor = event.tags
  //         .where((List<String> element) =>
  //             element.first == 'author' &&
  //             element[1] == currentSigner!.getPublicKey())
  //         .toList()
  //         .isNotEmpty;

  //     body = isAuthor
  //         ? t.verifiedNoteSealed.capitalizeFirst()
  //         : t.verifiedNoteRateSealed.capitalizeFirst();
  //   } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
  //       event.kind == EventKind.VIDEO_HORIZONTAL) {
  //     final VideoModel video = VideoModel.fromEvent(event);
  //     title = t.userNewVideo(name: name).capitalizeFirst();

  //     body = video.title.isNotEmpty
  //         ? t.userNewVideo(name: video.title).capitalizeFirst()
  //         : t.checkoutVideo.capitalizeFirst();
  //   } else {
  //     if (event.isUserTagged()) {
  //       if (event.isUncensoredNote()) {
  //         title = t.unknownVerifiedNote.capitalizeFirst();
  //       } else {
  //         title = t.userReply(name: name).capitalizeFirst();
  //       }

  //       body = event.content;
  //     } else {
  //       final FlashNews flash = FlashNews.fromEvent(event);
  //       if (event.kind == EventKind.TEXT_NOTE && event.isFlashNews()) {
  //         title = t.userPaidNote(name: name).capitalizeFirst();
  //         body = flash.content.isNotEmpty
  //             ? t.contentData(description: flash.content).capitalizeFirst()
  //             : t.checkoutPaidNote.capitalizeFirst();
  //       } else if (event.kind == EventKind.CURATION_ARTICLES) {
  //         final curation = Curation.fromEvent(event, '');
  //         title = t.userNewCuration(name: name).capitalizeFirst();
  //         body = curation.title.isNotEmpty
  //             ? t.titleData(description: curation.title).capitalizeFirst()
  //             : t.checkoutCuration.capitalizeFirst();
  //       } else if (event.kind == EventKind.LONG_FORM) {
  //         final article = Article.fromEvent(event);
  //         title = t.userNewArticle(name: name).capitalizeFirst();
  //         body = article.title.isNotEmpty
  //             ? t.titleData(description: article.title).capitalizeFirst()
  //             : t.checkoutArticle.capitalizeFirst();
  //       } else if (event.kind == EventKind.SMART_WIDGET_ENH) {
  //         final sw = SmartWidget.fromEvent(event);
  //         title = t.userNewSmartWidget(name: name).capitalizeFirst();
  //         body = sw.title.isNotEmpty
  //             ? t.titleData(description: sw.title).capitalizeFirst()
  //             : t.checkoutSmartWidget.capitalizeFirst();
  //       }
  //     }
  //   }

  //   final count = await an.getGlobalBadgeCounter();

  //   try {
  //     if (await an.isNotificationAllowed()) {
  //       an.createNotification(
  //         content: NotificationContent(
  //           id: event.id.hashCode,
  //           channelKey: 'yaki_channel',
  //           largeIcon: user?.picture,
  //           title: title,
  //           body: body,
  //           payload: <String, String?>{'name': 'new notification'},
  //           badge: count + 1,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     lg.i(e);
  //   }
  // }

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

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {}

  @override
  Future<void> close() {
    userStreamSubscription.cancel();
    mutesSubscription.cancel();
    customizationSubscription.cancel();
    return super.close();
  }
}
