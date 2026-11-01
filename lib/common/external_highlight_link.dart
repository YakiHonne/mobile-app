/// Untrusted Safari links only open a draft; they never publish an event.
class ExternalHighlightLink {
  const ExternalHighlightLink({
    required this.selectedText,
    required this.sourceUrl,
    required this.context,
  });

  final String selectedText;
  final String sourceUrl;
  final String? context;

  static bool matches(Uri uri) =>
      uri.scheme == 'yakihonne' && uri.host == 'highlight';

  static ExternalHighlightLink? tryParse(Uri uri) {
    if (!matches(uri) ||
        uri.path.isNotEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment ||
        uri.toString().length > 24000) {
      return null;
    }

    try {
      final params = uri.queryParametersAll;
      if (params.keys.any((key) => !['text', 'url', 'context'].contains(key)) ||
          params.values.any((values) => values.length != 1)) {
        return null;
      }
      final text = uri.queryParameters['text']?.trim();
      final sourceUrl = uri.queryParameters['url'];
      final source = sourceUrl == null ? null : Uri.tryParse(sourceUrl);
      final context = uri.queryParameters['context'];
      if (text == null ||
          text.isEmpty ||
          text.length > 4000 ||
          source == null ||
          !['http', 'https'].contains(source.scheme) ||
          source.host.isEmpty ||
          source.userInfo.isNotEmpty ||
          sourceUrl!.length > 4000 ||
          (context?.length ?? 0) > 6000) {
        return null;
      }

      return ExternalHighlightLink(
        selectedText: text,
        sourceUrl: sourceUrl,
        context: context != null && context.contains(text) ? context : null,
      );
    } on FormatException {
      return null;
    }
  }
}
