import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/utils/constants.dart';

/// [appVersion] is hand-maintained and had already drifted from pubspec once
/// (v2.0.6+198 vs 2.0.6+200). It reaches users through the settings screen,
/// the version-news popup and the umami user-agent, so a stale value
/// misattributes analytics rather than failing loudly.
void main() {
  test('appVersion matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final version = pubspec
        .firstWhere((l) => l.startsWith('version:'))
        .split(':')
        .last
        .trim();

    expect(appVersion, 'v$version');
  });
}
