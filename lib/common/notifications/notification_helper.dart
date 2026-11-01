import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

class NotificationHelper {
  factory NotificationHelper() => sharedInstance;

  NotificationHelper._internal();
  static final NotificationHelper sharedInstance =
      NotificationHelper._internal();

  String serverPubkey =
      'e3593b53fe645f71d23fa666659cdff22aeb9ebff301cea686f23dfed6924738';

  // String serverPubkey =
  //     'a4f46cb124eaa5eef7a9cbed0707b8a80868ac7d1e2163869a46048b3438f656';

  Timer? timer;
  List<String> toRelays = DEFAULT_BOOTSTRAP_RELAYS;

  Event? unSendNotification;
  bool forwardedToAmber = false;
  bool _connectListenerRegistered = false;
  bool _heartBeatInFlight = false;
  String deviceId = '';
  String? configuredPubkey;

  Future<void> init() async {
    startHeartBeat();
    if (!_connectListenerRegistered) {
      _connectListenerRegistered = true;
      nc.addConnectStatusListener(
        (relay, status) async {
          if (status == 1 && toRelays.contains(relay)) {
            final pendingEvent = unSendNotification;
            if (pendingEvent != null) {
              final res = await NostrFunctionsRepository.sendEvent(
                event: pendingEvent,
                setProgress: false,
                relyOnUnsentEvents: false,
              );

              if (res && identical(unSendNotification, pendingEvent)) {
                unSendNotification = null;
              }
            }
          }
        },
      );
    }
  }

  void startHeartBeat() {
    if (timer?.isActive ?? false) {
      return;
    }

    if (!isPushNotificationEnabled() || !canSign()) {
      return;
    }

    timer = Timer.periodic(
      const Duration(minutes: 3),
      (Timer t) => unawaited(_heartBeat()),
    );
  }

  void _stopHeartBeat() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    timer = null;
  }

  bool isPushNotificationEnabled() {
    final pn =
        nostrRepository.currentAppCustomization?.enablePushNotification ??
            false;

    return pn;
  }

  Future<Event?> _encode(
    String receiver,
    String content,
  ) async {
    try {
      final enContent = await currentSigner!.encrypt04(content, receiver);
      final tags = Nip4.toTags(receiver, '', null);

      if (enContent == null) {
        return null;
      }

      if (currentSigner is AmberEventSigner) {
        forwardedToAmber = true;
      }

      final event = await Event.genEvent(
        kind: EventKind.PUSH_CONFIG,
        tags: tags,
        content: enContent,
        signer: currentSigner,
      );

      if (currentSigner is AmberEventSigner) {
        await Future.delayed(const Duration(seconds: 1));
        forwardedToAmber = false;
      }

      return event;
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  Future<void> _heartBeat() async {
    if (!isPushNotificationEnabled()) {
      _stopHeartBeat();
      return;
    }
    if (_heartBeatInFlight || !canSign()) {
      return;
    }

    _heartBeatInFlight = true;
    try {
      final map = {'online': 1};
      final event = await _encode(serverPubkey, jsonEncode(map));
      if (event != null && isPushNotificationEnabled()) {
        await NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
          relyOnUnsentEvents: false,
        );
      }
    } finally {
      _heartBeatInFlight = false;
    }
  }

  Future<void> setOffline() async {
    _stopHeartBeat();
    if (!isPushNotificationEnabled()) {
      return;
    }

    if (!forwardedToAmber) {
      final map = {'online': 0};
      final event = await _encode(
        serverPubkey,
        jsonEncode(map),
      );

      if (event != null) {
        final isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
          relyOnUnsentEvents: false,
        );

        lg.i(isSuccessful
            ? 'Notification event sent successfully'
            : 'Failed to send notification event');
      }
    }
  }

  Future<bool> logout() async {
    _stopHeartBeat();
    deviceId = '';
    configuredPubkey = null;

    if (canSign()) {
      final map = {'online': 0, 'deviceId': ''};
      unSendNotification = null;
      final event = await _encode(serverPubkey, jsonEncode(map));

      if (event != null) {
        unSendNotification = event;
        final isSuccessful = await NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
          timeout: 4,
          relyOnUnsentEvents: false,
        );
        if (isSuccessful && identical(unSendNotification, event)) {
          unSendNotification = null;
        }
        return isSuccessful;
      }
    }

    return false;
  }

  Future<void> setNotification(
    String deviceId,
    List<int> kinds,
  ) async {
    if (!isPushNotificationEnabled()) {
      return;
    }

    this.deviceId = deviceId;
    configuredPubkey = currentSigner?.getPublicKey();

    if (serverPubkey.isEmpty || forwardedToAmber) {
      forwardedToAmber = false;
      return;
    }

    final c = nostrRepository.currentAppCustomization;

    final map = {
      'online': deviceId.isEmpty ? 0 : 1,
      'kinds': kinds,
      'deviceId': deviceId,
      if (Platform.isAndroid || Platform.isIOS)
        'deviceOs': Platform.isAndroid ? 'android' : 'ios',
      'enableMaxMentions': c?.notifMaxMentions ?? true,
    };

    final event = await _encode(serverPubkey, jsonEncode(map));

    unSendNotification = event;
    if (isPushNotificationEnabled()) {
      await init();
    } else if (identical(unSendNotification, event)) {
      unSendNotification = null;
    }

    if (event != null && isPushNotificationEnabled()) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
        relyOnUnsentEvents: false,
      );
      if (isSuccessful && identical(unSendNotification, event)) {
        unSendNotification = null;
      }

      lg.i(isSuccessful
          ? 'Notification event sent successfully'
          : 'Failed to send notification event');
    }

    return;
  }
}
