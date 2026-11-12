import 'dart:async';

late final DeepLinkInbox deepLinkInbox;

enum DeepLinkKind { walletConnect, alby, other }

DeepLinkKind classifyDeepLink(Uri uri) {
  if (uri.scheme.toLowerCase() == 'nostr+walletconnect') {
    return DeepLinkKind.walletConnect;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host.toLowerCase() == 'yakihonne.com' ||
          uri.host.toLowerCase() == 'www.yakihonne.com') &&
      (uri.path == '/lightning-wallet/alby' ||
          uri.path.startsWith('/lightning-wallet/alby/'))) {
    return DeepLinkKind.alby;
  }
  return DeepLinkKind.other;
}

/// Subscribes once; app_links includes the launch URI in this stream.
class DeepLinkListener {
  DeepLinkListener(Stream<Uri> links, void Function(Uri) onLink,
      {void Function(Object)? onError})
      : _subscription = links.listen(onLink, onError: onError);

  final StreamSubscription<Uri> _subscription;

  Future<void> dispose() => _subscription.cancel();
}

/// Holds links received before the main view is ready.
/// Link contents stay in memory and are never logged.
class DeepLinkInbox {
  DeepLinkInbox(
    Stream<Uri> links, {
    Uri? initialLink,
    void Function(Object)? onError,
  }) {
    _listener = DeepLinkListener(links, _receiveStreamLink, onError: onError);
    if (initialLink != null) {
      _receive(initialLink);
    }
  }

  late final DeepLinkListener _listener;
  final List<Uri> _pending = [];
  Future<bool> Function(Uri)? _handler;
  bool _draining = false;
  bool _retryRequested = false;
  void _receiveStreamLink(Uri uri) {
    _receive(uri);
  }

  void _receive(Uri uri) {
    // Bound memory use if the main view is unavailable for a long time.
    if (_pending.length == 20) {
      _pending.removeAt(0);
    }
    _pending.add(uri);
    retry();
  }

  void attach(Future<bool> Function(Uri) handler) {
    _handler = handler;
    retry();
  }

  void detach(Future<bool> Function(Uri) handler) {
    if (_handler == handler) {
      _handler = null;
    }
  }

  void retry() {
    _retryRequested = true;
    if (!_draining) {
      unawaited(_drain());
    }
  }

  Future<void> _drain() async {
    _draining = true;
    try {
      while (_retryRequested && _handler != null) {
        _retryRequested = false;
        final handler = _handler!;
        for (final uri in List<Uri>.of(_pending)) {
          if (_handler != handler) {
            break;
          }
          bool consumed;
          try {
            consumed = await handler(uri);
          } catch (_) {
            // Do not expose URI credentials in logs or let one malformed link
            // permanently block later links.
            consumed = true;
          }
          if (consumed) {
            _pending.remove(uri);
          }
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() {
    return _listener.dispose();
  }
}
