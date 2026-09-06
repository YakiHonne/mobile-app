import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `fallback_strategy: base_locale` means a key missing from a locale renders
/// English instead of failing the build — silent in analyze, silent in slang,
/// silent at runtime. This is the only thing that catches it.
void main() {
  Set<String> keysOf(String locale) {
    final raw = File('lib/i18n/$locale.json').readAsStringSync();
    return (json.decode(raw) as Map<String, dynamic>).keys.toSet();
  }

  final base = keysOf('en');

  for (final locale in ['ar', 'es', 'fr', 'hi', 'it', 'ja', 'pt', 'ru', 'th', 'zh']) {
    test('$locale has every en key', () {
      expect(base.difference(keysOf(locale)), isEmpty);
    });
  }
}
