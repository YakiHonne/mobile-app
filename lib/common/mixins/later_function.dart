import 'dart:async';

import 'package:nostr_core_enhanced/nostr/nostr.dart';

mixin LaterFunction {
  int laterTimeMS = 500;
  final Map<Function, Timer> _timersByCallback = {};

  void later(void Function() runFunc, Function? completeFunc) {
    // Use the callback function itself as the key
    _timersByCallback[runFunc]?.cancel();
    _timersByCallback[runFunc] = Timer(Duration(milliseconds: laterTimeMS), () {
      runFunc.call();
      completeFunc?.call();
      _timersByCallback.remove(runFunc);
    });
  }

  void disposeLater() {
    for (final timer in _timersByCallback.values) {
      timer.cancel();
    }
    _timersByCallback.clear();
  }
}

mixin PendingEventsLaterFunction {
  int laterTimeMS = 1200;

  bool latering = false;

  List<Event> pendingEvents = [];

  bool _running = true;

  void later(
    Event event,
    Function(List<Event>) func,
    Function? completeFunc,
  ) {
    pendingEvents.add(event);
    if (latering) {
      return;
    }

    latering = true;
    Future.delayed(Duration(milliseconds: laterTimeMS), () {
      if (!_running) {
        return;
      }

      latering = false;
      func(pendingEvents);
      pendingEvents.clear();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }

  void disposeLater() {
    _running = false;
  }
}
