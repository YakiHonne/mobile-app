import 'dart:ui';

import 'package:nostr_core_enhanced/nostr/nostr.dart';

class ZapEventSubscription {
  ZapEventSubscription({
    required this.future,
    required this.cancel,
  });

  final Future<Event?> future;
  final VoidCallback cancel;
}
