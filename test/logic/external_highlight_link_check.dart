// Standalone pure-Dart checks (bypass unrelated app native-asset build hooks):
// dart --disable-dart-dev test/logic/external_highlight_link_check.dart
// ignore: avoid_relative_lib_imports
import '../../lib/common/external_highlight_link.dart';

void main() {
  Uri link(Map<String, String> params) => Uri(
        scheme: 'yakihonne',
        host: 'highlight',
        queryParameters: params,
      );
  void check(bool condition, String message) {
    if (!condition) {
      throw StateError(message);
    }
  }

  final payload = {
    'text': '你好 & café',
    'url': 'https://example.com/article?q=a%26b#section',
    'context': 'Before 你好 & café after.',
  };
  final parsed = ExternalHighlightLink.tryParse(link(payload));
  check(parsed?.selectedText == payload['text'], 'Unicode selection roundtrip');
  check(parsed?.sourceUrl == payload['url'], 'Source query roundtrip');
  check(parsed?.context == payload['context'], 'Paragraph context preserved');
  check(
    ExternalHighlightLink.tryParse(link({...payload, 'context': 'unrelated'}))
            ?.context ==
        null,
    'Unrelated context must be discarded',
  );
  for (final invalid in [
    Uri.parse('https://highlight?text=hello&url=https://example.com'),
    Uri.parse('yakihonne://highlight/other?text=hello&url=https://example.com'),
    Uri.parse('yakihonne://highlight?text=a&text=b&url=https://example.com'),
    Uri.parse('yakihonne://user@highlight?text=a&url=https://example.com'),
    link({...payload, 'text': '  '}),
    link({...payload, 'text': 'a' * 4001}),
    link({...payload, 'url': 'javascript:alert(1)'}),
    link({...payload, 'url': 'https://user:pass@example.com'}),
    link({...payload, 'context': 'a' * 6001}),
    link({...payload, 'publish': 'true'}),
    link({'text': 'a'}),
  ]) {
    check(ExternalHighlightLink.tryParse(invalid) == null, 'Reject invalid link');
  }
}
