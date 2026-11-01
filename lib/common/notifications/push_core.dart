import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:unifiedpush/unifiedpush.dart';

import '../../utils/utils.dart';
import 'local_notification_manager.dart';
import 'up_functions.dart';

/// Handles communication between the native platform and Flutter
/// for push notifications (APNs / UnifiedPush).
class PushCore {
  PushCore._internal();

  static final PushCore sharedInstance = PushCore._internal();

  static const MethodChannel _channel = MethodChannel('apn_notifications');
  Future<void>? _setupInFlight;
  bool _isSetup = false;
  int _generation = 0;

  /// Initializes push handling depending on the platform.
  Future<void> setup() async {
    if (_isSetup) {
      return;
    }

    final inFlight = _setupInFlight;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (e) {
        lg.e('Error initializing push notifications: $e');
      }
      return;
    }

    final generation = _generation;
    final task = _setupPlatform();
    _setupInFlight = task;
    try {
      await task;
      if (generation == _generation) {
        _isSetup = true;
      }
    } catch (e) {
      lg.e('Error initializing push notifications: $e');
    } finally {
      if (identical(_setupInFlight, task)) {
        _setupInFlight = null;
      }
    }
  }

  Future<void> _setupPlatform() async {
    if (Platform.isIOS) {
      await _setupIOS();
    } else if (Platform.isAndroid) {
      await _setupAndroid();
    }
  }

  /// Stops push endpoint registration when the user disables push.
  Future<void> disable() async {
    _generation++;
    _isSetup = false;
    final runningSetup = _setupInFlight;
    if (runningSetup != null) {
      try {
        await runningSetup;
      } catch (_) {
        // Continue with platform unregistration after a failed setup attempt.
      }
    }

    if (Platform.isAndroid) {
      try {
        await UPFunctions.unregister();
      } catch (e) {
        lg.e('Error unregistering UnifiedPush: $e');
      }
    }
  }

  /// Initializes APNs on iOS and listens for events from native side.
  Future<void> _setupIOS() async {
    _channel.setMethodCallHandler(_handleNativeCall);

    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      lg.e('Error requesting APN permission: $e');
    }
  }

  /// Initializes UnifiedPush (FOSS FCM) on Android.
  Future<void> _setupAndroid() async {
    await UnifiedPush.initialize(
      onNewEndpoint: LocalNotificationManager.instance.onNewEndpoint,
      onMessage: LocalNotificationManager.instance.onMessage,
      onRegistrationFailed: UPFunctions.onRegistrationFailed,
      onUnregistered: UPFunctions.onUnregistered,
    );

    await UPFunctions.initRegisterApp();
  }

  /// Handles calls coming from the native platform (iOS side).
  static Future<dynamic> _handleNativeCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onAPNToken':
          final rawToken = call.arguments as String? ?? '';
          final cleanedToken = rawToken.replaceAll(RegExp(r'\s+'), '');
          notificationsCubit.setPushNotifications(cleanedToken);
        case 'onNotificationTapped':
          final args = _parseArgs(call.arguments);
          final id = args['event_id'];

          if (id != null && id.isNotEmpty) {
            LocalNotificationManager.instance.handleNotificationTap(id);
          }

        default:
          lg.w('Unknown method call from native: ${call.method}');
      }
    } catch (e, st) {
      lg.e('Error in _handleNativeCall: $e\n$st');
    }
  }

  /// Safely parse notification payloads from native side
  static Map<String, dynamic> _parseArgs(dynamic args) {
    if (args == null) {
      return {};
    }
    if (args is String) {
      try {
        return jsonDecode(args) as Map<String, dynamic>;
      } catch (_) {
        return {'message': args};
      }
    }
    if (args is Map) {
      return args.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }
}
