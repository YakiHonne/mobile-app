import 'dart:async';

import 'package:flutter/services.dart';

/// Readiness handshake and link delivery shared by the Windows and Linux
/// runners.
///
/// Windows uses [ready] so a second launch can forward a Nostr URL only after
/// the first window's Dart listener is subscribed. Linux uses [links] to
/// receive remote command lines the runner buffered before Dart was ready; the
/// primary launch still arrives through process arguments.
///
/// Link contents stay in memory and are never logged.
class DesktopLinkChannel {
  DesktopLinkChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('yakihonne/link_readiness') {
    _channel.setMethodCallHandler(_handleCall);
  }

  final MethodChannel _channel;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  final List<Uri> _early = [];
  bool _hasListener = false;
  bool _disposed = false;

  static const _earlyLimit = 20;

  /// Remote links, including ones buffered here before a listener attached.
  Stream<Uri> get links {
    if (!_hasListener) {
      _hasListener = true;
      _controller.onListen = () {
        final pending = List<Uri>.of(_early);
        _early.clear();
        pending.forEach(_controller.add);
      };
    }
    return _controller.stream;
  }

  /// Tells the native runner that the Dart link listener is subscribed.
  ///
  /// Never throws: a missing handler (older runner or a test) is harmless.
  Future<void> ready() async {
    try {
      await _channel.invokeMethod<void>('ready');
    } on MissingPluginException {
      // No native readiness channel on this build; links still arrive through
      // process arguments (Linux) or the app_links stream (Windows).
    } on PlatformException {
      // The runner reports readiness failures itself; do not surface a second
      // error to the user here.
    }
  }

  Future<dynamic> _handleCall(MethodCall call) async {
    if (call.method != 'link') {
      return null;
    }
    final value = call.arguments;
    if (value is! String) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'nostr') {
      return null;
    }
    if (_disposed) {
      return null;
    }
    if (_hasListener && _controller.hasListener) {
      _controller.add(uri);
    } else {
      if (_early.length == _earlyLimit) {
        _early.removeAt(0);
      }
      _early.add(uri);
    }
    return null;
  }

  Future<void> dispose() async {
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _controller.close();
  }
}
