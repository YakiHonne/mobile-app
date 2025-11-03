import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/utils.dart';

NotificationChannel? notificationChannel;

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class LocalNotificationManager {
  LocalNotificationManager._internal();

  static final LocalNotificationManager _instance =
      LocalNotificationManager._internal();
  static LocalNotificationManager get instance => _instance;

  /// Initialize Awesome Notifications and permissions
  Future<void> initNotifications() async {
    final isEnabled = await AwesomeNotifications().isNotificationAllowed();

    notificationChannel = NotificationChannel(
      channelGroupKey: 'yaki_group',
      channelKey: 'yaki_channel',
      channelShowBadge: true,
      channelName: 'Basic notifications',
      channelDescription: 'Notification channel for YakiHonne alerts',
      importance: NotificationImportance.High,
      icon: 'resource://drawable/ic_notification',
      ledColor: kPurple,
    );

    await AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [notificationChannel!],
    );

    if (!isEnabled &&
        localDatabaseRepository.getNotificationPrompter() == null) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Vibration,
          NotificationPermission.Sound,
          NotificationPermission.Light,
          NotificationPermission.PreciseAlarms,
        ],
      );
    }

    // Attach global listeners
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Called by UnifiedPush (Android)
  Future<void> onNewEndpoint(String endpoint, String instance) async {
    final token = endpoint.split('token=').last;
    final state = WidgetsBinding.instance.lifecycleState;
    if (token.isNotEmpty && state == AppLifecycleState.resumed) {
      notificationsCubit.setPushNotifications(token);
    }
  }

  /// Called by UnifiedPush (Android)
  Future<void> onMessage(Uint8List message, String instance) async {
    int notificationID = message.hashCode;
    String showTitle = '';
    String showContent = '';
    String eventId = '';

    try {
      final result = utf8.decode(message);
      final jsonMap = json.decode(result);

      notificationID = jsonMap.hashCode;
      showTitle = jsonMap['gcm.notification.title'] ?? 'YakiHonne';
      showContent = jsonMap['gcm.notification.body'] ?? 'New message';
      eventId = jsonMap['event_id'] ?? '';
    } catch (e) {
      showContent = "You've received a message";
    }

    showLocalNotification(
      notificationID,
      showTitle,
      showContent,
      payload: {'id': eventId},
    );
  }

  /// Show a local notification
  Future<void> showLocalNotification(
    int notificationID,
    String title,
    String body, {
    Map<String, String>? payload,
  }) async {
    if (notificationChannel == null) {
      await initNotifications();
    }

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      if (kDebugMode) {
        print('Notifications not allowed');
      }
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        channelKey: 'yaki_channel',
        title: title,
        body: body,
        payload: payload,
        wakeUpScreen: true,
        icon: 'resource://drawable/ic_notification',
        backgroundColor: kPurple,
      ),
    );
  }

  /// Handle notification taps from both platforms
  void handleNotificationTap(String id) {
    if (kDebugMode) {
      print('Notification tapped: $id');
    }

    singleEventCubit.handlePushNotificationEventId(id);
  }

  // ===================== AwesomeNotifications listeners =====================

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.Default) {
      final payload = receivedAction.payload ?? {};

      final id = payload['id'];

      if (id != null && id.isNotEmpty) {
        LocalNotificationManager.instance.handleNotificationTap(id);
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      print('Notification created: ${receivedNotification.id}');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      print('Notification displayed: ${receivedNotification.id}');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (kDebugMode) {
      print('Notification dismissed: ${receivedAction.id}');
    }
  }
}
