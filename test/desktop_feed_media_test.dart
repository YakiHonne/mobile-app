import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/models/app_models/app_customization.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';
import 'package:yakihonne/utils/enums.dart';
import 'package:yakihonne/views/gallery_view/gallery_view.dart';
import 'package:yakihonne/views/widgets/content_renderer/content_renderer.dart';
import 'package:yakihonne/views/widgets/content_renderer/desktop_feed_media.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';

void main() {
  testWidgets('hidden desktop video does not create a player or thumbnail',
      (tester) async {
    nostrRepository = NostrDataRepository();
    await tester.pumpWidget(TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: MediaContainer(
                media: [MapEntry('disposable-video', UrlType.video)],
                hideMedia: true,
                invertColor: false,
              ),
            ),
          ),
        ),
      ),
    ));
    expect(find.byType(DesktopHiddenVideo), findsOneWidget);
    expect(find.byType(CustomVideoPlayer), findsNothing);
    expect(find.text('Click to view'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden gallery videos do not request thumbnails',
      (tester) async {
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: GalleryImageView(
            media: const {'one': UrlType.video, 'two': UrlType.video},
            width: 400,
            height: 180,
            isHidden: true,
            invertColor: false,
            seperatorColor: Colors.white,
            onDownload: (_) {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(DesktopHiddenVideo), findsNWidgets(2));
    expect(find.byType(FutureBuilder<String?>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('video preview bounds and autoplay setting are retained',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = NostrDataRepository();
    nostrRepository = repository;
    for (final enabled in [false, true]) {
      repository.currentAppCustomization =
          AppCustomization(pubkey: 'fixture', enableAutoPlay: enabled);
      await tester.pumpWidget(TranslationProvider(
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 1200,
                child: MediaContainer(
                  media: [MapEntry('', UrlType.video)],
                  hideMedia: false,
                  invertColor: false,
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      final player =
          tester.widget<CustomVideoPlayer>(find.byType(CustomVideoPlayer));
      expect(player.autoPlay, enabled);
      final size = tester.getSize(find.byType(CustomVideoPlayer));
      expect(size.width, 720);
      expect(size.height, closeTo(405, 0.1));
      expect(find.byType(DesktopOpenMediaButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('hidden preview opens only when explicitly activated',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: DesktopHiddenVideo(onOpen: () => opened = true),
          ),
        ),
      ),
    ));
    expect(opened, isFalse);
    await tester.tap(find.text('Click to view'));
    expect(opened, isTrue);
  });
  testWidgets('desktop image exposes a full-view action', (tester) async {
    nostrRepository = NostrDataRepository();
    await tester.pumpWidget(TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: MediaContainer(
                media: [MapEntry('', UrlType.image)],
                hideMedia: false,
                invertColor: false,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopOpenMediaButton), findsOneWidget);
    expect(
        tester.getSize(find.byType(MediaImage)).height, lessThanOrEqualTo(420));
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-view action responds to keyboard activation',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: DesktopOpenMediaButton(onPressed: () => opened = true),
        ),
      ),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened, isTrue);
  });
  testWidgets('desktop gallery exposes its full-view control', (tester) async {
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 180,
            child: GalleryComponent(
              media: const {'': UrlType.image},
              onDownload: (_) {},
              imageDecoration: null,
              imgMore: 0,
              textColor: Colors.white,
              fontSize: 32,
              index: 0,
              isHidden: false,
              invertColor: false,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopOpenMediaButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
