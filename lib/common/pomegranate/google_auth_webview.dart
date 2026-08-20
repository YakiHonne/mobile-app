import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/utils.dart';

enum GoogleAuthWebViewType { login, recovery }

// Real browser user agents — prevents Google's WebView detection.
// Android WebView includes "Version/4.0"; Chrome app omits it.
// iOS WKWebView omits "Safari/"; real Safari includes it.
const _kAndroidUA =
    'Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';
const _kIosUA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Mobile/15E148 Safari/604.1';

// Injected AT_DOCUMENT_START so window.opener is set before any page script runs.
const _kLoginScript = '''
  (function() {
    window.opener = {
      postMessage: function(data, origin) {
        window.flutter_inappwebview.callHandler('GoogleAuthChannel', data);
      }
    };
  })();
''';

// A Pomegranate shard is exactly 104 bytes = 208 hex characters.
const _kRecoveryScript = r'''
  (function() {
    var HEX208 = /^[0-9a-fA-F]{208}$/;
    function tryExtract(d) {
      if (typeof d === 'string') {
        var s = d.trim();
        if (HEX208.test(s)) return s;
        try {
          var parsed = JSON.parse(s);
          if (parsed && typeof parsed === 'object') {
            var v = parsed.shard || parsed.data || parsed.hex || '';
            if (HEX208.test(v)) return v;
          }
        } catch(_) {}
      } else if (d && typeof d === 'object') {
        var v = d.shard || d.data || d.hex || '';
        if (typeof v === 'string' && HEX208.test(v)) return v;
      }
      return null;
    }
    function send(d) {
      var shard = tryExtract(d);
      if (shard) window.flutter_inappwebview.callHandler('GoogleAuthChannel', shard);
    }
    // Operators call window.opener.postMessage (popup pattern) — intercept it.
    window.opener = { postMessage: function(data, origin) { send(data); } };
    // Also catch direct window.postMessage dispatches.
    window.addEventListener('message', function(e) { send(e.data); });
  })();
''';

class GoogleAuthWebView extends StatefulWidget {
  const GoogleAuthWebView({
    super.key,
    required this.url,
    required this.type,
    this.forceAccountPicker = false,
  });

  final String url;
  final GoogleAuthWebViewType type;
  final bool forceAccountPicker;

  /// Guards against two webviews existing at once. The route pops as soon as
  /// the token arrives, but the native view is only released when the exit
  /// transition finishes — pushing again inside that window makes the platform
  /// reuse the same view id and throw `recreating_view`.
  static bool _isOpen = false;

  /// [forceAccountPicker] rewrites the central's Google redirect to add
  /// `prompt=select_account`. Without it Google auto-selects when exactly one
  /// account is signed in, so the user can never choose a different one. The
  /// session is left intact — clearing cookies would work too, but forces a
  /// full re-login every time.
  static Future<String?> show(
    BuildContext context,
    String url,
    GoogleAuthWebViewType type, {
    bool forceAccountPicker = false,
  }) async {
    if (_isOpen) {
      return null;
    }
    _isOpen = true;

    try {
      return await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => GoogleAuthWebView(
            url: url,
            type: type,
            forceAccountPicker: forceAccountPicker,
          ),
        ),
      );
    } finally {
      // Outlive the pop animation so the native view is really gone.
      await Future.delayed(const Duration(milliseconds: 350));
      _isOpen = false;
    }
  }

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  bool _handled = false;

  // Only rewrite the first Google navigation; the reload would otherwise be
  // intercepted again and loop.
  bool _promptAdded = false;

  void _onMessage(List<dynamic> args) {
    lg.i(args);
    if (_handled) {
      return;
    }
    _handled = true;
    final raw = args.isNotEmpty ? args[0] : null;
    // Server may postMessage a plain string token or a {token: "..."} object.
    String token = '';
    if (raw is String) {
      token = raw;
    } else if (raw is Map) {
      token = (raw['token'] ?? raw['shard'] ?? raw['data'] ?? '').toString();
    } else if (raw != null) {
      token = raw.toString();
    }
    if (mounted) {
      Navigator.pop(context, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.type == GoogleAuthWebViewType.login
              ? context.t.loginWithGoogle
              : context.t.recoverWithGoogle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        elevation: 0,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          userAgent: Platform.isIOS ? _kIosUA : _kAndroidUA,
          useShouldOverrideUrlLoading: widget.forceAccountPicker,
        ),
        // The central builds the Google URL server-side (with its own state
        // cookie) and omits `prompt`, so Google skips the chooser whenever
        // exactly one account is signed in. Catch that redirect and re-issue
        // it with the parameter instead of clearing the session.
        shouldOverrideUrlLoading: widget.forceAccountPicker
            ? (controller, action) async {
                final uri = action.request.url;
                if (uri == null ||
                    _promptAdded ||
                    !uri.host.endsWith('accounts.google.com') ||
                    uri.queryParameters.containsKey('prompt')) {
                  return NavigationActionPolicy.ALLOW;
                }

                _promptAdded = true;
                await controller.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri(
                      uri.replace(
                        queryParameters: {
                          ...uri.queryParameters,
                          'prompt': 'select_account',
                        },
                      ).toString(),
                    ),
                  ),
                );
                return NavigationActionPolicy.CANCEL;
              }
            : null,
        initialUserScripts: UnmodifiableListView([
          UserScript(
            source: widget.type == GoogleAuthWebViewType.login
                ? _kLoginScript
                : _kRecoveryScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        ]),
        onWebViewCreated: (ctrl) {
          ctrl.addJavaScriptHandler(
            handlerName: 'GoogleAuthChannel',
            callback: _onMessage,
          );
        },
      ),
    );
  }
}
