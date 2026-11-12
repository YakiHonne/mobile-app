import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/add_content_view/widgets/add_media_main_view.dart';
import 'package:yakihonne/views/widgets/desktop_media_fallback.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('local video avoids unsupported playback on $platform',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final dimensions = ValueNotifier('');
      addTearDown(dimensions.dispose);
      await tester.pumpWidget(TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: VideoWidget(
              media: File('/fixture/video.mp4'),
              dimensions: dimensions,
              onRetake: () {},
            ),
          ),
        ),
      ));
      expect(find.byType(DesktopMediaFallback), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
