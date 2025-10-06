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
  Timer? timer;
  List<String> toRelays = DEFAULT_BOOTSTRAP_RELAYS;

  Event? unSendNotification;
  bool forwardedToAmber = false;

  Future<void> init() async {
    startHeartBeat();
    nc.addConnectStatusListener(
      (relay, status) async {
        if (status == 1 && toRelays.contains(relay)) {
          if (unSendNotification != null) {
            final res = await NostrFunctionsRepository.sendEvent(
              event: unSendNotification!,
              setProgress: false,
              relyOnUnsentEvents: false,
            );

            if (res) {
              unSendNotification = null;
            }
          }
        }
      },
    );
  }

  void startHeartBeat() {
    if (timer == null || timer!.isActive) {
      timer = Timer.periodic(
        const Duration(minutes: 3),
        (Timer t) {
          _heartBeat();
        },
      );
    }
  }

  void _stopHeartBeat() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
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
        forwardedToAmber = false;
      }

      return event;
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  Future<void> _heartBeat() async {
    final map = {'online': 1};
    final event = await _encode(serverPubkey, jsonEncode(map));
    if (event != null) {
      NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
        relyOnUnsentEvents: false,
      );
    }
  }

  Future<void> setOffline() async {
    if (!forwardedToAmber) {
      final map = {'online': 0};
      _stopHeartBeat();
      final event = await _encode(
        serverPubkey,
        jsonEncode(map),
      );

      if (event != null) {
        NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
          relyOnUnsentEvents: false,
        );
      }
    }
  }

  Future<bool> logout() async {
    if (canSign()) {
      final map = {'online': 0, 'deviceId': ''};
      final event = await _encode(serverPubkey, jsonEncode(map));
      _stopHeartBeat();

      if (event != null) {
        return NostrFunctionsRepository.sendEvent(
          event: event,
          setProgress: false,
          timeout: 4,
          relyOnUnsentEvents: false,
        );
      }
    }

    return false;
  }

  Future<bool> setNotification(
    String deviceId,
    List<int> kinds,
  ) async {
    if (serverPubkey.isEmpty || forwardedToAmber) {
      forwardedToAmber = false;
      return false;
    }

    final map = {
      'online': deviceId.isEmpty ? 0 : 1,
      'kinds': kinds,
      'deviceId': deviceId,
      if (Platform.isAndroid || Platform.isIOS)
        'deviceOs': Platform.isAndroid ? 'android' : 'ios'
    };

    final event = await _encode(serverPubkey, jsonEncode(map));

    unSendNotification = event;

    if (event != null) {
      return NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
        relyOnUnsentEvents: false,
      );
    }

    return false;
  }
}
