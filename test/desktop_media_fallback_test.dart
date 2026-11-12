import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/views/widgets/desktop_media_fallback.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/widgets/parsed_media_container.dart';

void main() {
  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    testWidgets('unsupported media avoids plugin initialization on $platform',
        (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [
                SizedBox(
                    height: 120,
                    child: AudioDisplayer(url: 'https://example.com/audio')),
                SizedBox(
                    height: 120,
                    child:
                        CustomVideoPlayer(link: 'https://example.com/video')),
                SizedBox(
                    height: 120,
                    child:
                        RegularVideoPlayer(link: 'https://example.com/video')),
                SizedBox(
                    height: 120,
                    child: YoutubeVideoPlayer(
                        url: 'https://youtube.com/watch?v=fixture')),
              ]),
            ),
          ),
        ),
      ));
      expect(find.byType(DesktopMediaFallback), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
