import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../common/media_handler/media_handler.dart';
import '../../models/video_model.dart';
import '../../utils/utils.dart';
import '../../views/widgets/app_video_player/fullscreen_video_player.dart';
import '../../views/widgets/link_previewer.dart';
import '../../views/widgets/media_components/custom_video_controls.dart';

part 'video_controller_manager_state.dart';

/// Metadata for a desktop session. Inline note videos may have only a URL.
class DesktopVideoSession {
  const DesktopVideoSession({
    required this.url,
    required this.isNetwork,
    this.video,
  });

  final String url;
  final bool isNetwork;
  final VideoModel? video;
}

class _DesktopExternalPlayer {
  _DesktopExternalPlayer(this.account, this.pause);

  final String? account;
  final VoidCallback pause;
}

class VideoControllerManagerCubit extends Cubit<VideoControllerManagerState> {
  VideoControllerManagerCubit({bool? desktopPlayback})
      : desktopPlaybackEnabled = desktopPlayback ?? isDesktopPlatform,
        super(const VideoControllerManagerState());

  final bool desktopPlaybackEnabled;

  // Phones are locked to portraitUp (initializers._configureSystemUI), so
  // fullscreen video must restore that lock on exit; tablets rotate freely.
  static List<DeviceOrientation> get _afterFullScreenOrientations =>
      deviceIsTablet
          ? DeviceOrientation.values
          : const [DeviceOrientation.portraitUp];

  // ── Registry — plain mutable fields, never copied into state ──────────────
  final _videoControllers = <String, VideoPlayerController>{};
  final _chewieControllers = <String, ChewieController>{};

  // url → set of ownerIds currently using it (O(1) ref-count, replaces containsValue scan)
  final _urlOwners = <String, Set<String>>{};

  // original url → fallback url that actually holds the controller. Without
  // this, a widget releasing with its original url leaves the fallback's
  // ExoPlayer instance (and its native buffers) alive forever.
  final _urlAliases = <String, String>{};

  // Per-URL broadcast streams — only that URL's StreamBuilder is woken up
  final _urlStreams = <String, StreamController<void>>{};

  final _inProcessUrls = <String>{};
  final _toBeAdded = <String>{};

  // Resolved URLs currently in a fullscreen route — releaseVideo keeps their
  // controller alive until exitFullScreen.
  final _fullScreenUrls = <String>{};

  /// A desktop player is an additional owner of the existing controller.
  final ValueNotifier<DesktopVideoSession?> desktopNowPlaying =
      ValueNotifier(null);
  static const _desktopOwner = 'desktop-now-playing';
  final _desktopSessions = <String, DesktopVideoSession>{};
  final _desktopListeners = <String, VoidCallback>{};
  final _desktopExternalPlayers = <Object, _DesktopExternalPlayer>{};
  String? _desktopUrl;
  String? _desktopAccount;
  String? _desktopPlayAccount;
  int _desktopPlayGeneration = 0;

  /// Register a widget-owned player that cannot be retained in the video bar.
  Object registerDesktopExternalPlayer(VoidCallback pause) {
    final token = Object();
    if (desktopPlaybackEnabled) {
      _desktopExternalPlayers[token] =
          _DesktopExternalPlayer(currentSigner?.getPublicKey(), pause);
    }
    return token;
  }

  void unregisterDesktopExternalPlayer(Object token) {
    _desktopExternalPlayers.remove(token);
  }

  /// Called when an external player reports that it has started playing.
  void desktopExternalPlayerStarted(Object token) {
    final player = _desktopExternalPlayers[token];
    if (!desktopPlaybackEnabled || player == null) {
      return;
    }
    if (player.account != currentSigner?.getPublicKey()) {
      player.pause();
      return;
    }
    _desktopPlayGeneration++;
    for (final entry in _desktopExternalPlayers.entries.toList()) {
      if (entry.key != token) {
        entry.value.pause();
      }
    }
    for (final controller in _videoControllers.values.toList()) {
      if (controller.value.isPlaying) {
        unawaited(controller.pause());
      }
    }
  }

  void _pauseDesktopExternalPlayers() {
    for (final player in _desktopExternalPlayers.values.toList()) {
      player.pause();
    }
  }

  /// Prevent a slow-loading earlier click from replacing a later selection.
  int reserveDesktopPlay() {
    _desktopPlayAccount = currentSigner?.getPublicKey();
    return ++_desktopPlayGeneration;
  }

  bool isDesktopPlayCurrent(int generation) =>
      desktopPlaybackEnabled && generation == _desktopPlayGeneration;

  void cancelDesktopPlay(int generation) {
    if (generation == _desktopPlayGeneration) {
      _desktopPlayGeneration++;
    }
  }

  Future<void> playDesktopVideoIfCurrent(String url, int generation) async {
    if (!desktopPlaybackEnabled || generation != _desktopPlayGeneration) {
      return;
    }
    if (getVideoController(url) == null) {
      try {
        await watchUrl(url).first.timeout(const Duration(seconds: 12));
      } on TimeoutException {
        return;
      } on StateError {
        return;
      }
    }
    if (generation == _desktopPlayGeneration) {
      await getVideoController(url)?.play();
    }
  }

  void _activateDesktopVideo(String resolved) {
    if (_desktopUrl != resolved) {
      closeDesktopVideo();
    }
    for (final entry in _videoControllers.entries.toList()) {
      if (entry.key != resolved && entry.value.value.isPlaying) {
        unawaited(entry.value.pause());
      }
    }
    final session = _desktopSessions[resolved];
    if (session == null || !_videoControllers.containsKey(resolved)) {
      return;
    }
    _desktopUrl = resolved;
    _desktopAccount = currentSigner?.getPublicKey();
    _urlOwners.putIfAbsent(resolved, () => {}).add(_desktopOwner);
    desktopNowPlaying.value = session;
  }

  void _watchDesktopPlayback(
      String resolved, VideoPlayerController controller) {
    if (!desktopPlaybackEnabled) {
      return;
    }
    var wasPlaying = controller.value.isPlaying;
    void listener() {
      final playing = controller.value.isPlaying;
      if (playing && !wasPlaying) {
        _desktopPlayGeneration++;
        _pauseDesktopExternalPlayers();
        if (_desktopUrl != resolved) {
          _activateDesktopVideo(resolved);
        }
      }
      wasPlaying = playing;
    }

    _desktopListeners[resolved] = listener;
    controller.addListener(listener);
  }

  VideoPlayerController? get desktopVideoController =>
      _desktopUrl == null ? null : _videoControllers[_desktopUrl];

  bool isDesktopVideo(String url) =>
      _desktopUrl != null && (_urlAliases[url] ?? url) == _desktopUrl;

  void closeDesktopVideo() {
    _desktopPlayGeneration++;
    final url = _desktopUrl;
    _desktopUrl = null;
    _desktopAccount = null;
    desktopNowPlaying.value = null;
    if (url != null) {
      _videoControllers[url]?.pause();
      releaseVideo(url: url, id: _desktopOwner);
    }
  }

  void clearDesktopVideoForAccount(String? pubkey) {
    // A pending load can outlive its originating account even when no player
    // has been activated yet. Invalidate its play intent on account change.
    if (_desktopPlayAccount != pubkey) {
      _desktopPlayGeneration++;
      _desktopPlayAccount = pubkey;
    }
    for (final player in _desktopExternalPlayers.values.toList()) {
      if (player.account != pubkey) {
        player.pause();
      }
    }
    if (_desktopUrl != null && _desktopAccount != pubkey) {
      closeDesktopVideo();
    }
  }

  // ── Public getters (unchanged API) ────────────────────────────────────────
  VideoPlayerController? getVideoController(String url) => _videoControllers[
      desktopPlaybackEnabled ? (_urlAliases[url] ?? url) : url];

  ChewieController? getChewieController(String url) => _chewieControllers[
      desktopPlaybackEnabled ? (_urlAliases[url] ?? url) : url];

  /// Returns a stream that emits whenever [url]'s controller changes.
  /// Each widget subscribes only to its own URL — no cross-video rebuilds.
  Stream<void> watchUrl(String url) {
    return (_urlStreams[url] ??= StreamController<void>.broadcast()).stream;
  }

  void _notifyUrl(String url) {
    _urlStreams[url]?.add(null);
  }

  // ── Acquire ───────────────────────────────────────────────────────────────
  Future<void> acquireVideo(
    String url,
    String id, {
    bool autoPlay = false,
    bool isNetwork = true,
    bool looping = true,
    bool showControls = true,
    bool enableSound = true,
    double? aspectRatio,
    bool? removeControls,
    List<String>? fallbackUrls,
    VideoModel? desktopVideo,
    Function(String)? onFallbackUrlCalled,
    Function(String)? onDownloadVideo,
  }) async {
    final resolved = _urlAliases[url] ?? url;
    if (desktopPlaybackEnabled && _videoControllers.containsKey(resolved)) {
      if (desktopVideo != null && desktopPlaybackEnabled) {
        _desktopSessions[resolved] = DesktopVideoSession(
          url: url,
          isNetwork: isNetwork,
          video: desktopVideo,
        );
        if (_desktopUrl == resolved) {
          desktopNowPlaying.value = _desktopSessions[resolved];
        }
      }
      _urlOwners.putIfAbsent(resolved, () => {}).add(id);
      if (resolved != url) {
        onFallbackUrlCalled?.call(resolved);
      }
      _notifyUrl(url);
      return;
    }
    // Register owner
    _urlOwners.putIfAbsent(url, () => {}).add(id);

    // Already loaded or loading — notify widget so it can render the controller
    if (_videoControllers[url] != null || _inProcessUrls.contains(url)) {
      _notifyUrl(url);
      return;
    }

    // Fast-scroll guard — wait to confirm the user is still on this item
    _toBeAdded.add(id);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_toBeAdded.contains(id)) {
      return;
    }

    // Double-check after delay
    if (_videoControllers[url] != null || _inProcessUrls.contains(url)) {
      _notifyUrl(url);
      return;
    }

    try {
      VideoPlayerController? videoController;
      String usedUrl = url;
      _inProcessUrls.add(url);

      if (isNetwork) {
        videoController =
            await _initNetworkVideo(url, enableSound: enableSound);

        if (!_toBeAdded.contains(id)) {
          await videoController?.dispose();
          _inProcessUrls.remove(url);
          return;
        }

        if (videoController == null && fallbackUrls != null) {
          for (final fallbackUrl in fallbackUrls) {
            videoController =
                await _initNetworkVideo(fallbackUrl, enableSound: enableSound);

            if (!_toBeAdded.contains(id)) {
              await videoController?.dispose();
              _inProcessUrls.remove(url);
              return;
            }

            if (videoController != null) {
              usedUrl = fallbackUrl;
              onFallbackUrlCalled?.call(fallbackUrl);
              break;
            }
          }
        }
      } else {
        final file = File(url);
        videoController = enableSound
            ? VideoPlayerController.file(file)
            : VideoPlayerController.file(
                file,
                videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
              );
        await videoController.initialize();

        if (!_toBeAdded.contains(id)) {
          await videoController.dispose();
          _inProcessUrls.remove(url);
          return;
        }
      }

      _inProcessUrls.remove(url);

      if (videoController == null) {
        return;
      }

      if (!enableSound) {
        videoController.setVolume(0);
      }

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: !desktopPlaybackEnabled && autoPlay,
        allowPlaybackSpeedChanging: false,
        showControlsOnInitialize: false,
        showControls: showControls,
        looping: looping,
        aspectRatio: aspectRatio,
        routePageBuilder: (context, animation, secondaryAnimation,
                controllerProvider) =>
            FullScreenVideoPlayer(url: usedUrl, provider: controllerProvider),
        // deviceOrientationsOnEnterFullScreen left null => chewie auto-rotates:
        // landscape videos force landscape, portrait videos stay portrait. On
        // phones we restore the portrait lock on exit (initializers pins
        // phones to portraitUp).
        deviceOrientationsAfterFullScreen: _afterFullScreenOrientations,
        customControls: removeControls != null
            ? TapPlayPauseControls(controller: videoController)
            : CustomCupertinoControls(
                backgroundColor: kBlack,
                iconColor: kWhite,
                onDownload: () => onDownloadVideo?.call(usedUrl),
              ),
      );

      _videoControllers[usedUrl] = videoController;
      _chewieControllers[usedUrl] = chewieController;
      if (desktopPlaybackEnabled) {
        _desktopSessions[usedUrl] = DesktopVideoSession(
          url: url,
          isNetwork: isNetwork,
          video: desktopVideo,
        );
        _watchDesktopPlayback(usedUrl, videoController);
      }
      WakelockPlus.enable();

      // Update owner registration to the resolved URL (may differ via fallback)
      if (usedUrl != url) {
        _urlAliases[url] = usedUrl;
        // Move all owners registered under the original url, not just this
        // one — they all render the fallback controller now.
        final originalOwners = _urlOwners.remove(url);
        _urlOwners.putIfAbsent(usedUrl, () => {})
          ..addAll(originalOwners ?? const {})
          ..add(id);
      }

      // Notify only this URL's subscriber — zero impact on other videos
      _notifyUrl(usedUrl);
      if (desktopPlaybackEnabled && usedUrl != url) {
        _notifyUrl(url);
      }
    } catch (e) {
      lg.i(e);
      _inProcessUrls.remove(url);
    }
  }

  // ── Release ───────────────────────────────────────────────────────────────
  void releaseVideo({required String url, required String id}) {
    _toBeAdded.remove(id);

    // The controller may live under a fallback url (see _urlAliases)
    final resolvedUrl = _urlAliases[url] ?? url;

    final owners = _urlOwners[resolvedUrl];
    if (owners == null) {
      return;
    }

    owners.remove(id);

    // Other widgets still reference this URL — keep controller alive
    if (owners.isNotEmpty) {
      return;
    }

    final fs = _chewieControllers[resolvedUrl]?.isFullScreen ?? false;

    if (_fullScreenUrls.contains(resolvedUrl) || fs) {
      _fullScreenUrls.add(resolvedUrl);
      _urlOwners.remove(resolvedUrl);
      return;
    }

    _disposeUrl(resolvedUrl);
  }

  void _disposeUrl(String resolvedUrl) {
    _urlOwners.remove(resolvedUrl);
    _urlAliases.removeWhere((_, target) => target == resolvedUrl);
    final listener = _desktopListeners.remove(resolvedUrl);
    if (listener != null) {
      _videoControllers[resolvedUrl]?.removeListener(listener);
    }
    _desktopSessions.remove(resolvedUrl);
    _chewieControllers.remove(resolvedUrl)?.dispose();
    _videoControllers.remove(resolvedUrl)?.dispose();

    // Notify before closing so the widget can show the loading placeholder
    _notifyUrl(resolvedUrl);
    _urlStreams.remove(resolvedUrl)?.close();

    if (_videoControllers.isEmpty) {
      WakelockPlus.disable();
    }
  }

  void enterFullScreen(String url) {
    _fullScreenUrls.add(_urlAliases[url] ?? url);
  }

  void exitFullScreen(String url) {
    final resolvedUrl = _urlAliases[url] ?? url;
    _fullScreenUrls.remove(resolvedUrl);

    if ((_urlOwners[resolvedUrl] ?? const <String>{}).isEmpty) {
      _disposeUrl(resolvedUrl);
    }
  }

  // ── Playback helpers ──────────────────────────────────────────────────────
  void pauseVideo(String url) => desktopPlaybackEnabled
      ? getVideoController(url)?.pause()
      : _videoControllers[url]?.pause();

  Future<bool?> downloadVideo(String url, Function(double) onProgress) async {
    return MediaHandler.saveNetworkVideo(
      url,
      onProgress: onProgress,
      showSuccessMessage: false,
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  Future<VideoPlayerController?> _initNetworkVideo(
    String url, {
    bool enableSound = true,
  }) async {
    try {
      bool hasBeenDisposed = false;

      final normalizedUrl = normalizeMediaUrl(url);
      final videoController = enableSound
          ? VideoPlayerController.networkUrl(Uri.parse(normalizedUrl))
          : VideoPlayerController.networkUrl(
              Uri.parse(normalizedUrl),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );

      await videoController.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          videoController.dispose();
          hasBeenDisposed = true;
        },
      );

      return hasBeenDisposed ? null : videoController;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _desktopExternalPlayers.clear();
    desktopNowPlaying.dispose();
    for (final entry in _desktopListeners.entries) {
      _videoControllers[entry.key]?.removeListener(entry.value);
    }
    for (final c in _chewieControllers.values) {
      c.dispose();
    }
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    for (final sc in _urlStreams.values) {
      sc.close();
    }
    WakelockPlus.disable();
    return super.close();
  }
}
