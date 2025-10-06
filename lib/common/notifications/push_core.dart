import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:unifiedpush/unifiedpush.dart';

import '../../utils/utils.dart';
import 'local_notification_manager.dart';
import 'up_functions.dart';

class PushCore {
  PushCore._internal();

  static final PushCore sharedInstance = PushCore._internal();

  static const MethodChannel _platform = MethodChannel('apn_notifications');

  Future<void> setup() async {
    if (Platform.isIOS) {
      _platform.setMethodCallHandler(_platformCallHandler);
      await _platform.invokeMethod('requestNotificationPermission');
    } else if (Platform.isAndroid) {
      setAndroidCallHandler();
    }
  }

  static Future<void> setAndroidCallHandler() async {
    LocalNotificationManager.instance;

    await UnifiedPush.initialize(
      onNewEndpoint: LocalNotificationManager.instance.onNewEndpoint,
      onMessage: LocalNotificationManager.instance.onMessage,
      onRegistrationFailed: UPFunctions.onRegistrationFailed,
      onUnregistered: UPFunctions.onUnregistered,
    );

    UPFunctions.initRegisterApp();
  }

  static Future<dynamic> _platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onAPNToken':
        final registrationID = call.arguments as String? ?? '';
        final cleanedID = registrationID.replaceAll(RegExp(r'\s+'), '');
        notificationsCubit.setPushNotifications(cleanedID);
      case 'onAPNTokenError':
      case 'onNotificationReceived':
      case 'onNotificationTapped':
      // final userInfo = call.arguments as Map<dynamic, dynamic>;
      // lg.i(userInfo);
      default:
    }
  }
}
