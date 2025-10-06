// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/utils.dart';

NotificationChannel? notificationChannel;

class LocalNotificationManager {
  LocalNotificationManager._init() {
    initNotifications();
  }

  static LocalNotificationManager get instance => _instance;

  static final LocalNotificationManager _instance =
      LocalNotificationManager._init();

  Future<void> onNewEndpoint(String endpoint, String instance) async {
    final token = endpoint.split('token=').last;
    final state = WidgetsBinding.instance.lifecycleState;
    if (token.isNotEmpty && state == AppLifecycleState.resumed) {
      notificationsCubit.setPushNotifications(token);
    }
  }

  Future<void> onMessage(Uint8List message, String instance) async {
    int notificationID = message.hashCode;
    String showTitle = '';
    String showContent = '';

    try {
      final result = utf8.decode(message);

      final jsonMap = json.decode(result);

      notificationID = jsonMap.hashCode;
      showTitle = jsonMap['gcm.notification.title'] ?? 'YakiHonne';
      showContent = jsonMap['gcm.notification.body'] ?? 'default';
    } catch (e) {
      showContent = "You've received a message";
    }

    showLocalNotification(notificationID, showTitle, showContent);
  }

  Future<void> initNotifications() async {
    final isEnabled = await AwesomeNotifications().isNotificationAllowed();

    notificationChannel = NotificationChannel(
      channelGroupKey: 'yaki_group',
      channelKey: 'yaki_channel',
      channelShowBadge: true,
      channelName: 'Basic notifications',
      channelDescription: 'Notification channel for basic notifications',
      importance: NotificationImportance.High,
      icon: 'resource://drawable/ic_notification',
      ledColor: kPurple,
    );

    AwesomeNotifications().initialize(
      'resource://drawable/ic_notification',
      [notificationChannel!],
    );

    if (!isEnabled &&
        localDatabaseRepository.getNotificationPrompter() == null) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Vibration,
          NotificationPermission.Badge,
          NotificationPermission.Light,
          NotificationPermission.Sound,
          NotificationPermission.PreciseAlarms,
        ],
      );
    }

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  Future<void> showLocalNotification(
    int notificationID,
    String showTitle,
    String showContent,
  ) async {
    if (notificationChannel == null) {
      await LocalNotificationManager.instance.initNotifications();
    }

    if (await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch % 10000,
          channelKey: 'yaki_channel',
          title: showTitle,
          body: showContent,
          payload: {},
          wakeUpScreen: true,
          icon: 'resource://drawable/ic_notification',
          backgroundColor: kPurple,
        ),
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (kDebugMode) {
      print('Background notification action: ${receivedAction.actionType}');
    }

    // Handle the notification action here
    // This runs even when app is closed/background
    if (receivedAction.actionType == ActionType.Default) {
      // User tapped the notification
      // You can navigate to specific screens here
    }
  }

  // ✅ Background notification created handler
  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      print('Background notification created: ${receivedNotification.id}');
    }
  }

  // ✅ Background notification displayed handler
  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    if (kDebugMode) {
      print('Background notification displayed: ${receivedNotification.id}');
    }
  }

  // ✅ Background notification dismissed handler
  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    if (kDebugMode) {
      print('Background notification dismissed: ${receivedAction.id}');
    }
  }
}

// // ignore_for_file: unused_local_variable

// import 'dart:async';
// import 'dart:convert';

// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import '../../utils/utils.dart';

// NotificationChannel? notificationChannel;

// class LocalNotificationManager {
//   LocalNotificationManager._init() {
//     initNotifications();
//   }

//   static LocalNotificationManager get instance => _instance;

//   static final LocalNotificationManager _instance =
//       LocalNotificationManager._init();

//   Future<void> onNewEndpoint(String endpoint, String instance) async {
//     final token = endpoint.split('token=').last;
//     final state = WidgetsBinding.instance.lifecycleState;
//     if (token.isNotEmpty && state == AppLifecycleState.resumed) {
//       notificationsCubit.setPushNotifications(token);
//     }
//   }

//   Future<void> onMessage(Uint8List message, String instance) async {
//     int notificationID = message.hashCode;
//     String showTitle = '';
//     String showContent = '';

//     try {
//       final result = utf8.decode(message);

//       final jsonMap = json.decode(result);

//       notificationID = jsonMap.hashCode;
//       showTitle = jsonMap['gcm.notification.title'] ?? 'YakiHonne';
//       showContent = jsonMap['gcm.notification.body'] ?? 'default';
//     } catch (e) {
//       showContent = "You've received a message";
//     }

//     showLocalNotification(notificationID, showTitle, showContent);
//   }

//   Future<void> initNotifications() async {
//     final isEnabled = await AwesomeNotifications().isNotificationAllowed();

//     notificationChannel = NotificationChannel(
//       channelGroupKey: 'yaki_group',
//       channelKey: 'yaki_channel',
//       channelShowBadge: true,
//       channelName: 'Basic notifications',
//       channelDescription: 'Notification channel for basic notifications',
//       importance: NotificationImportance.High,
//       icon: 'resource://drawable/ic_notification',
//       enableVibration: true,
//       enableLights: true,
//       playSound: true,
//       // Critical settings for killed app
//       onlyAlertOnce: true,
//       criticalAlerts: true, // Enable critical alerts
//       defaultRingtoneType: DefaultRingtoneType.Notification,
//     );

//     AwesomeNotifications().initialize(
//       'resource://drawable/ic_notification',
//       [notificationChannel!],
//     );

//     if (!isEnabled &&
//         localDatabaseRepository.getNotificationPrompter() == null) {
//       await AwesomeNotifications().requestPermissionToSendNotifications(
//         permissions: [
//           NotificationPermission.Vibration,
//           NotificationPermission.Badge,
//           NotificationPermission.Light,
//           NotificationPermission.Sound,
//           NotificationPermission.PreciseAlarms,
//         ],
//       );
//     }

//     AwesomeNotifications().setListeners(
//       onActionReceivedMethod: onActionReceivedMethod,
//       onNotificationCreatedMethod: onNotificationCreatedMethod,
//       onNotificationDisplayedMethod: onNotificationDisplayedMethod,
//       onDismissActionReceivedMethod: onDismissActionReceivedMethod,
//     );
//   }

//   @pragma('vm:entry-point')
//   static Future<void> onActionReceivedMethod(
//     ReceivedAction receivedAction,
//   ) async {
//     if (kDebugMode) {
//       print('Background notification action: ${receivedAction.actionType}');
//     }

//     // Handle the notification action here
//     // This runs even when app is closed/background
//     if (receivedAction.actionType == ActionType.Default) {
//       // User tapped the notification
//       // You can navigate to specific screens here
//     }
//   }

//   // ✅ Background notification created handler
//   @pragma('vm:entry-point')
//   static Future<void> onNotificationCreatedMethod(
//     ReceivedNotification receivedNotification,
//   ) async {
//     if (kDebugMode) {
//       print('Background notification created: ${receivedNotification.id}');
//     }
//   }

//   // ✅ Background notification displayed handler
//   @pragma('vm:entry-point')
//   static Future<void> onNotificationDisplayedMethod(
//     ReceivedNotification receivedNotification,
//   ) async {
//     if (kDebugMode) {
//       print('Background notification displayed: ${receivedNotification.id}');
//     }
//   }

//   // ✅ Background notification dismissed handler
//   @pragma('vm:entry-point')
//   static Future<void> onDismissActionReceivedMethod(
//     ReceivedAction receivedAction,
//   ) async {
//     if (kDebugMode) {
//       print('Background notification dismissed: ${receivedAction.id}');
//     }
//   }

//   Future<void> showLocalNotification(
//     int notificationID,
//     String showTitle,
//     String showContent,
//   ) async {
//     if (notificationChannel == null) {
//       await LocalNotificationManager.instance.initNotifications();
//     }

//     if (await AwesomeNotifications().isNotificationAllowed()) {
//       await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: DateTime.now().millisecondsSinceEpoch % 10000,
//           channelKey: 'yaki_channel',
//           title: showTitle,
//           body: showContent,
//           payload: {},
//           wakeUpScreen: true,
//           icon: 'resource://drawable/ic_notification',
//         ),
//       );
//     }
//   }
// }
