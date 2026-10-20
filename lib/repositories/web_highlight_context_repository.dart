import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../common/browser_highlight_share.dart';

/// Reads public HTML without using the app's API headers or browser cookies.
class WebHighlightContextRepository {
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  static const _maxBytes = 2 * 1024 * 1024;
  static const _blocks = 'p, blockquote, li, pre, td, div';

  Future<String?> loadParagraph({
    required String sourceUrl,
    required String selectedText,
    TextFragmentSelector? selector,
  }) async {
    try {
      return await _load(sourceUrl, selectedText, selector)
          .timeout(const Duration(seconds: 8));
    } on Exception {
      // Unreadable pages still leave a usable quote and source URL in the draft.
      return null;
    } finally {
      close();
    }
  }

  void close() => _client.close(force: true);

  Future<String?> _load(String sourceUrl, String selectedText,
      TextFragmentSelector? selector) async {
    var uri = Uri.tryParse(sourceUrl);
    for (var redirects = 0; redirects <= 3; redirects++) {
      if (uri == null || !await _isPublicUrl(uri)) {
        return null;
      }
      final request = await _client.getUrl(uri.replace(fragment: ''));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'text/html');
      final response = await request.close();
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) {
          return null;
        }
        uri = uri.resolve(location);
        continue;
      }
      final mime = response.headers.contentType?.mimeType;
      if (response.statusCode != HttpStatus.ok ||
          (mime != 'text/html' && mime != 'application/xhtml+xml') ||
          response.contentLength > _maxBytes) {
        return null;
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > _maxBytes) {
          return null;
        }
        bytes.addAll(chunk);
      }
      final encoding = Encoding.getByName(
              response.headers.contentType?.charset ?? 'utf-8') ??
          utf8;
      return paragraphFromHtml(
        encoding.decode(bytes),
        selectedText,
        selector: selector,
      );
    }
    return null;
  }

  static Future<bool> _isPublicUrl(Uri uri) async {
    if (!['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 80 && uri.port != 443)) {
      return false;
    }
    final addresses = await InternetAddress.lookup(uri.host);
    return addresses.isNotEmpty &&
        addresses.every((address) {
          if (address.isLoopback ||
              address.isLinkLocal ||
              address.isMulticast) {
            return false;
          }
          final bytes = address.rawAddress;
          if (address.type == InternetAddressType.IPv4) {
            return bytes[0] != 0 &&
                bytes[0] != 10 &&
                bytes[0] != 127 &&
                !(bytes[0] == 169 && bytes[1] == 254) &&
                !(bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) &&
                !(bytes[0] == 192 && bytes[1] == 168) &&
                !(bytes[0] == 100 && bytes[1] >= 64 && bytes[1] <= 127) &&
                bytes[0] < 224;
          }
          // IPv6 global unicast only; excludes local and IPv4-mapped addresses.
          return (bytes[0] & 0xe0) == 0x20;
        });
  }

  static String? paragraphFromHtml(String source, String selectedText,
      {TextFragmentSelector? selector}) {
    final exact = selectedText.trim();
    final normalizedQuote = normalizeHighlightText(exact);
    if (normalizedQuote.isEmpty ||
        exact.length > 4000 ||
        (selector != null && !selector.matchesQuote(exact))) {
      return null;
    }
    final document = html.parse(source);
    for (final element in document.querySelectorAll(
        'script, style, noscript, template, nav, header, footer, form, '
        '[hidden], [aria-hidden="true"]')) {
      element.remove();
    }

    String? matchedParagraph;
    var matches = 0;
    for (final block in document.querySelectorAll(_blocks)) {
      // Use a single leaf block, never the common ancestor of paragraphs.
      if (block.querySelector(_blocks) != null || _isHidden(block)) {
        continue;
      }
      final paragraph = normalizeHighlightText(_visibleText(block));
      if (paragraph.length > 6000) {
        continue;
      }
      var offset = paragraph.indexOf(normalizedQuote);
      while (offset >= 0) {
        final before = paragraph.substring(0, offset);
        final after = paragraph.substring(offset + normalizedQuote.length);
        if (selector == null || selector.matchesContext(before, after)) {
          matches++;
          if (matches > 1) {
            return null;
          }
          // Preserve the user's exact quote, including its line breaks.
          matchedParagraph = '$before$exact$after';
        }
        offset = paragraph.indexOf(normalizedQuote, offset + 1);
      }
    }
    return matchedParagraph == exact ? null : matchedParagraph;
  }

  static bool _isHidden(Element element) {
    Element? ancestor = element;
    while (ancestor != null) {
      final style = ancestor.attributes['style'] ?? '';
      if (RegExp(r'(display\s*:\s*none|visibility\s*:\s*hidden)',
              caseSensitive: false)
          .hasMatch(style)) {
        return true;
      }
      ancestor = ancestor.parent;
    }
    return false;
  }

  static String _visibleText(Node node) {
    if (node is Text) {
      return node.data;
    }
    if (node is Element && (node.localName == 'br' || _isHidden(node))) {
      return node.localName == 'br' ? ' ' : '';
    }
    return node.nodes.map(_visibleText).join();
  }
}
