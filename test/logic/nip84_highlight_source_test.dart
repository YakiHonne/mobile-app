import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/nip84_highlight.dart';

void main() {
  group('Nip84HighlightSource external webpages', () {
    test('publishes a normalized source r tag', () {
      final source = Nip84HighlightSource.tryExternal(
        'https://example.com/article?utm_source=newsletter&page=2#quote',
      );

      expect(source?.toTag(const []), [
        'r',
        'https://example.com/article?page=2',
        'source',
      ]);
    });

    test('rejects non-web source URLs', () {
      expect(Nip84HighlightSource.tryExternal('nostr:note1example'), isNull);
      expect(Nip84HighlightSource.tryExternal('example.com/article'), isNull);
    });
  });
}
