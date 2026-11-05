// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart' as wakelock;
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/logic/theme_cubit/theme_cubit.dart';
import 'package:yakihonne/logic/video_controller_manager_cubit/video_controller_manager_cubit.dart';
import 'package:yakihonne/models/video_model.dart';
import 'package:yakihonne/views/add_content_view/widgets/add_media_main_view.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_now_playing.dart';
import 'package:yakihonne/views/widgets/link_previewer.dart';
import 'package:yakihonne/views/widgets/media_components/vertical_video_view.dart';

class _Wakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}
}

class _ThemeCubit extends Fake implements ThemeCubit {
  @override
  bool get isDark => true;

  @override
  ThemeState get state => ThemeState(
        textScaleFactor: 1,
        mode: AppThemeMode.graphite,
        isFluid: true,
        fluidCards: true,
        glassQuality: GlassQuality.minimal,
        theme: ThemeData.dark(),
        primaryColor: Colors.orange,
      );
}

class _VideoPlatform extends VideoPlayerPlatform {
  int creates = 0;
  int disposals = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    creates++;
    return creates;
  }

  @override
  Widget buildView(int playerId) => const SizedBox();

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(640, 360),
        duration: const Duration(minutes: 2),
      ));
  @override
  Future<void> dispose(int playerId) async {
    disposals++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
}

VideoModel _video(String url) => VideoModel(
      id: 'event',
      pubkey: 'author',
      identifier: '',
      kind: 21,
      title: 'Video',
      summary: '',
      alt: '',
      thumbnail: '',
      placeHolder: '',
      createdAt: DateTime(2026),
      publishedAt: DateTime(2026),
      url: url,
      duration: 120,
      mimeType: 'video/mp4',
      tags: const [],
      pTags: const [],
      zapsSplits: const [],
      fallbackUrls: const [],
      contentWarning: false,
      relays: const {},
      stringifiedEvent: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('desktop playback tracks the played video and pauses the previous one',
      () async {
    final platform = _VideoPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    currentSigner = null;
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    const firstUrl = 'https://example.com/first.mp4';
    const secondUrl = 'https://example.com/second.mp4';

    await manager.acquireVideo(firstUrl, 'first', autoPlay: true);
    await manager.acquireVideo(secondUrl, 'second', autoPlay: true);
    expect(manager.getChewieController(firstUrl)!.autoPlay, isFalse);
    final first = manager.getVideoController(firstUrl)!;
    final second = manager.getVideoController(secondUrl)!;
    expect(first.value.isPlaying, isFalse);
    expect(second.value.isPlaying, isFalse);
    expect(manager.desktopNowPlaying.value, isNull);

    final earlier = manager.reserveDesktopPlay();
    manager.reserveDesktopPlay();
    await manager.playDesktopVideoIfCurrent(firstUrl, earlier);
    expect(first.value.isPlaying, isFalse);
    final pendingForPreviousAccount = manager.reserveDesktopPlay();
    manager.clearDesktopVideoForAccount('another-account');
    await manager.playDesktopVideoIfCurrent(
        firstUrl, pendingForPreviousAccount);
    expect(first.value.isPlaying, isFalse);
    await first.play();
    expect(manager.desktopNowPlaying.value?.url, firstUrl);
    expect(manager.desktopNowPlaying.value?.video, isNull);
    expect(first.value.isPlaying, isTrue);
    var externalPauses = 0;
    final external = manager.registerDesktopExternalPlayer(() {
      externalPauses++;
    });
    manager.desktopExternalPlayerStarted(external);
    expect(first.value.isPlaying, isFalse);
    expect(manager.desktopNowPlaying.value?.url, firstUrl);
    await first.play();
    expect(externalPauses, 1);
    final otherExternal = manager.registerDesktopExternalPlayer(() {});
    manager.desktopExternalPlayerStarted(otherExternal);
    expect(externalPauses, 2);
    expect(first.value.isPlaying, isFalse);
    manager.unregisterDesktopExternalPlayer(external);
    manager.unregisterDesktopExternalPlayer(otherExternal);
    await second.play();
    expect(first.value.isPlaying, isFalse);
    expect(second.value.isPlaying, isTrue);
    expect(manager.desktopNowPlaying.value?.url, secondUrl);

    manager.releaseVideo(url: secondUrl, id: 'second');
    expect(manager.desktopVideoController, same(second));
    manager.closeDesktopVideo();
    expect(manager.desktopNowPlaying.value, isNull);
    expect(manager.getVideoController(secondUrl), isNull);
    manager.releaseVideo(url: firstUrl, id: 'first');
    for (var i = 0; i < 20 && platform.disposals < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(platform.disposals, 2);
    await manager.close();
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  test('mobile controllers do not use desktop single-player coordination',
      () async {
    final platform = _VideoPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    final manager = VideoControllerManagerCubit(desktopPlayback: false);
    var externalPauses = 0;
    final external = manager.registerDesktopExternalPlayer(() {
      externalPauses++;
    });
    const firstUrl = 'https://example.com/mobile-first.mp4';
    const secondUrl = 'https://example.com/mobile-second.mp4';
    await manager.acquireVideo(firstUrl, 'first', autoPlay: true);
    await manager.acquireVideo(secondUrl, 'second');
    expect(manager.getChewieController(firstUrl)!.autoPlay, isTrue);
    final first = manager.getVideoController(firstUrl)!;
    final second = manager.getVideoController(secondUrl)!;
    await first.play();
    await second.play();
    manager.desktopExternalPlayerStarted(external);
    expect(externalPauses, 0);
    expect(first.value.isPlaying, isTrue);
    expect(second.value.isPlaying, isTrue);
    expect(manager.desktopNowPlaying.value, isNull);
    manager.releaseVideo(url: firstUrl, id: 'first');
    manager.releaseVideo(url: secondUrl, id: 'second');
    for (var i = 0; i < 20 && platform.disposals < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(platform.disposals, 2);
    await manager.close();
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  test('account switch cancels a play request while the video loads', () async {
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    final platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    currentSigner = null;
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    const url = 'https://example.com/loading.mp4';
    final generation = manager.reserveDesktopPlay();
    final loading = manager.acquireVideo(url, 'page');
    final playing = manager.playDesktopVideoIfCurrent(url, generation);
    manager.clearDesktopVideoForAccount('another-account');
    await loading;
    await playing;
    expect(manager.getVideoController(url)!.value.isPlaying, isFalse);
    expect(manager.desktopNowPlaying.value, isNull);
    manager.releaseVideo(url: url, id: 'page');
    for (var i = 0; i < 20 && platform.disposals == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(platform.disposals, 1);
    await manager.close();
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  test('vertical video ratio tolerates empty and unbounded layouts', () {
    expect(
        verticalVideoAspectRatio(
            const BoxConstraints.tightFor(width: 300, height: 600)),
        0.5);
    expect(
        verticalVideoAspectRatio(
            const BoxConstraints.tightFor(width: 300, height: 0)),
        9 / 16);
    expect(
        verticalVideoAspectRatio(
            const BoxConstraints.tightFor(width: 0, height: 600)),
        9 / 16);
    expect(verticalVideoAspectRatio(const BoxConstraints()), 9 / 16);
  });

  testWidgets('desktop editor preview pauses and can resume', (tester) async {
    final platform = _VideoPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    currentSigner = null;
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    videoControllerManagerCubit = manager;
    const url = 'https://example.com/feed.mp4';
    await tester.runAsync(() => manager.acquireVideo(url, 'feed'));
    final dimensions = ValueNotifier('');
    await tester.pumpWidget(TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: VideoWidget(
            media: File('/tmp/preview.mp4'),
            onRetake: () {},
            dimensions: dimensions,
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(dimensions.value, '640.0x360.0');
    await tester.runAsync(() => manager.getVideoController(url)!.play());
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(manager.getVideoController(url)!.value.isPlaying, isFalse);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    manager.releaseVideo(url: url, id: 'feed');
    await tester.runAsync(() async {
      for (var i = 0; i < 20 && platform.disposals < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await manager.close();
    });
    dimensions.dispose();
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  testWidgets('video player survives a transient invalid aspect ratio',
      (tester) async {
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    videoControllerManagerCubit = manager;
    Widget player(double ratio) => TranslationProvider(
          child: MaterialApp(
            home: Scaffold(body: CustomVideoPlayer(link: '', ratio: ratio)),
          ),
        );

    for (final ratio in [0.5, double.infinity, double.nan, 0.0]) {
      await tester.pumpWidget(player(ratio));
      expect(tester.takeException(), isNull);
      final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
      expect(aspect.aspectRatio, ratio == 0.5 ? 0.5 : 16 / 9);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await manager.close();
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  testWidgets('player stays below the panes without shrinking the rail',
      (tester) async {
    final platform = _VideoPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    videoControllerManagerCubit = manager;
    const url = 'https://example.com/video.mp4';
    themeCubit = _ThemeCubit();
    await tester.runAsync(() => manager.acquireVideo(
          url,
          'page',
          desktopVideo: _video(url)
              .copyWith(title: 'A long video title that must fit neatly'),
        ));

    const rail = Key('rail');
    const panes = Key('panes');
    await tester.pumpWidget(TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          body: Row(children: [
            SizedBox(
                key: rail,
                width: 80,
                height: double.infinity,
                child: ColoredBox(color: Colors.blue)),
            Expanded(
              child: DesktopContentArea(
                content: ColoredBox(key: panes, color: Colors.red),
                player: DesktopNowPlayingBar(),
              ),
            ),
          ]),
        ),
      ),
    ));
    expect(tester.getSize(find.byKey(panes)).height, 600);
    expect(tester.getSize(find.byType(DesktopNowPlayingBar)).height, 0);

    await tester.runAsync(() => manager.getVideoController(url)!.play());
    await tester.pump();
    expect(tester.takeException(), isNull);
    final railRect = tester.getRect(find.byKey(rail));
    final panesRect = tester.getRect(find.byKey(panes));
    final barRect = tester.getRect(find.byType(DesktopNowPlayingBar));
    expect(railRect.height, 600);
    expect(barRect.height, 70);
    expect(barRect.left, panesRect.left);
    expect(barRect.right, panesRect.right);
    expect(barRect.top, panesRect.bottom);
    expect(barRect.bottom, railRect.bottom);
    expect(find.byIcon(LucideIcons.video), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.byTooltip('close'), findsOneWidget);

    tester.view.physicalSize = const Size(1153, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(DesktopNowPlayingBar)).width,
        tester.getRect(find.byKey(panes)).width);

    manager.closeDesktopVideo();
    await tester.pump();
    expect(tester.getSize(find.byKey(panes)).height, 600);
    await tester.pumpWidget(const SizedBox.shrink());
    manager.releaseVideo(url: url, id: 'page');
    await tester.runAsync(() async {
      for (var i = 0; i < 10 && platform.disposals == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await manager.close();
    });
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });

  test('playing video owns the controller until closed', () async {
    final platform = _VideoPlatform();
    final previousPlatform = VideoPlayerPlatform.instance;
    final previousWakelock = wakelock.wakelockPlusPlatformInstance;
    VideoPlayerPlatform.instance = platform;
    wakelock.wakelockPlusPlatformInstance = _Wakelock();
    currentSigner = null;
    final manager = VideoControllerManagerCubit(desktopPlayback: true);
    const url = 'https://example.com/video.mp4';
    expect(manager.desktopNowPlaying.value, isNull);
    await manager.acquireVideo(url, 'page', desktopVideo: _video(url));
    await manager.getVideoController(url)!.play();
    final controller = manager.desktopVideoController;
    manager.releaseVideo(url: url, id: 'page');
    expect(manager.desktopVideoController, same(controller));
    expect(platform.disposals, 0);
    await manager.acquireVideo(url, 'reopened');
    expect(platform.creates, 1);
    manager.releaseVideo(url: url, id: 'reopened');
    manager.closeDesktopVideo();
    for (var i = 0; i < 10 && platform.disposals == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(manager.desktopNowPlaying.value, isNull);
    expect(manager.getVideoController(url), isNull);
    expect(platform.disposals, 1);

    await manager.acquireVideo(url, 'second-page', desktopVideo: _video(url));
    await manager.getVideoController(url)!.play();
    manager.releaseVideo(url: url, id: 'second-page');
    manager.clearDesktopVideoForAccount(null);
    expect(manager.desktopNowPlaying.value, isNotNull);
    manager.clearDesktopVideoForAccount('another-account');
    expect(manager.desktopNowPlaying.value, isNull);
    expect(manager.getVideoController(url), isNull);
    for (var i = 0; i < 10 && platform.disposals < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(platform.disposals, 2);
    await manager.close();
    VideoPlayerPlatform.instance = previousPlatform;
    wakelock.wakelockPlusPlatformInstance = previousWakelock;
  });
}
