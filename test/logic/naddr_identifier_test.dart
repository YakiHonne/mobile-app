import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:yakihonne/views/widgets/content_renderer/content_renderer.dart';

void main() {
  test('invalid naddr decoding falls back instead of throwing', () {
    expect(decodeNaddrIdentifier(Nip19.decodeShareableEntity('naddr1invalid')), isNull);
    expect(decodeNaddrIdentifier({'prefix': 'naddr', 'special': null}), isNull);
    expect(
      decodeNaddrIdentifier({
        'prefix': 'naddr',
        'special': 'invalid',
        'author': 'author',
        'kind': 30023,
      }),
      isNull,
    );
    expect(
      decodeNaddrIdentifier({
        'prefix': 'naddr',
        'special': '74657374',
        'author': 'author',
        'kind': 30023,
      }),
      'test',
    );
  });
}
