/// A browser quote shared with its source URL, optionally using a text fragment.
class BrowserHighlightShare {
  const BrowserHighlightShare({
    required this.selectedText,
    required this.sourceUrl,
    this.selector,
  });

  final String selectedText;
  final String sourceUrl;
  final TextFragmentSelector? selector;

  bool get hasTextFragment => selector != null;

  static BrowserHighlightShare? tryParse(String content) {
    if (content.length > 24000) {
      return null;
    }

    final urls =
        RegExp(r'''https?://[^\s<>"“”]+''').allMatches(content).toList();
    final fragmentUrls =
        urls.where((match) => match.group(0)!.contains(':~:text=')).toList();
    final candidates = fragmentUrls.isEmpty ? urls : fragmentUrls;
    if (candidates.length != 1) {
      return null;
    }

    final match = candidates.single;
    final uri = Uri.tryParse(match.group(0)!);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.toString().length > 4000) {
      return null;
    }

    final selector = TextFragmentSelector.fromUri(uri);
    if (uri.fragment.contains(':~:') && selector == null) {
      return null;
    }
    var quote = content.replaceRange(match.start, match.end, '').trim();
    for (final pair in const [('"', '"'), ('“', '”'), ('«', '»')]) {
      if (quote.length >= 2 &&
          quote.startsWith(pair.$1) &&
          quote.endsWith(pair.$2)) {
        quote = quote.substring(1, quote.length - 1).trim();
        break;
      }
    }
    // A range selector only contains the beginning and end of the quote.
    // Never join those pieces and treat them as the user's full selection.
    if (quote.isEmpty && selector?.end == null) {
      quote = selector?.start ?? '';
    }
    if (quote.isEmpty ||
        quote.length > 4000 ||
        (selector != null && !selector.matchesQuote(quote))) {
      return null;
    }

    final directiveStart = uri.fragment.indexOf(':~:');
    return BrowserHighlightShare(
      selectedText: quote,
      sourceUrl: directiveStart < 0
          ? uri.toString()
          : directiveStart == 0
              ? uri.toString().split('#').first
              : uri
                  .replace(fragment: uri.fragment.substring(0, directiveStart))
                  .toString(),
      selector: selector,
    );
  }
}

class TextFragmentSelector {
  const TextFragmentSelector({
    required this.start,
    this.end,
    this.prefix,
    this.suffix,
  });

  final String start;
  final String? end;
  final String? prefix;
  final String? suffix;

  static TextFragmentSelector? fromUri(Uri uri) {
    final offset = uri.fragment.indexOf(':~:');
    if (offset < 0) {
      return null;
    }
    final directives = uri.fragment
        .substring(offset + 3)
        .split('&')
        .where((value) => value.startsWith('text='))
        .toList();
    if (directives.length != 1) {
      return null;
    }
    final parts = directives.single.substring(5).split(',');
    String? prefix;
    String? suffix;
    try {
      if (parts.length > 1 && parts.first.endsWith('-')) {
        prefix = Uri.decodeComponent(
            parts.removeAt(0).replaceFirst(RegExp(r'-$'), ''));
      }
      if (parts.length > 1 && parts.last.startsWith('-')) {
        suffix = Uri.decodeComponent(parts.removeLast().substring(1));
      }
      if (parts.isEmpty ||
          parts.length > 2 ||
          parts.any((part) => part.isEmpty) ||
          prefix == '' ||
          suffix == '') {
        return null;
      }
      return TextFragmentSelector(
        start: Uri.decodeComponent(parts.first),
        end: parts.length == 2 ? Uri.decodeComponent(parts.last) : null,
        prefix: prefix,
        suffix: suffix,
      );
    } on FormatException {
      return null;
    }
  }

  bool matchesQuote(String quote) {
    final normalized = normalizeHighlightText(quote).toLowerCase();
    final normalizedStart = normalizeHighlightText(start).toLowerCase();
    return end == null
        ? normalized == normalizedStart
        : normalized.startsWith(normalizedStart) &&
            normalized.endsWith(normalizeHighlightText(end!).toLowerCase());
  }

  bool matchesContext(String before, String after) =>
      (prefix == null ||
          normalizeHighlightText(before)
              .toLowerCase()
              .endsWith(normalizeHighlightText(prefix!).toLowerCase())) &&
      (suffix == null ||
          normalizeHighlightText(after)
              .toLowerCase()
              .startsWith(normalizeHighlightText(suffix!).toLowerCase()));
}

String normalizeHighlightText(String text) =>
    text.replaceAll(RegExp(r'[\s\u00a0]+'), ' ').trim();
