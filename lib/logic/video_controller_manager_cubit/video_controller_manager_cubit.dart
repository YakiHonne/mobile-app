import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../common/media_handler/media_handler.dart';
import '../../utils/utils.dart';
import '../../views/widgets/app_video_player/fullscreen_video_player.dart';
import '../../views/widgets/link_previewer.dart';
import '../../views/widgets/media_components/custom_video_controls.dart';

part 'video_controller_manager_state.dart';

class VideoControllerManagerCubit extends Cubit<VideoControllerManagerState> {
  VideoControllerManagerCubit() : super(const VideoControllerManagerState());

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

  // ── Public getters (unchanged API) ────────────────────────────────────────
  VideoPlayerController? getVideoController(String url) =>
      _videoControllers[url];

  ChewieController? getChewieController(String url) => _chewieControllers[url];

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
    bool looping = false,
    bool showControls = true,
    bool enableSound = true,
    double? aspectRatio,
    bool? removeControls,
    List<String>? fallbackUrls,
    Function(String)? onFallbackUrlCalled,
    Function(String)? onDownloadVideo,
  }) async {
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
        autoPlay: autoPlay,
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
    _chewieControllers.remove(resolvedUrl)?.dispose();
    _videoControllers.remove(resolvedUrl)?.dispose();

    // Notify before closing so the widget can show the loading placeholder
    _notifyUrl(resolvedUrl);
    _urlStreams.remove(resolvedUrl)?.close();
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
  void pauseVideo(String url) => _videoControllers[url]?.pause();

  Future<void> downloadVideo(String url, Function(double) onProgress) async {
    await MediaHandler.saveNetworkVideo(
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
    for (final c in _chewieControllers.values) {
      c.dispose();
    }
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    for (final sc in _urlStreams.values) {
      sc.close();
    }
    return super.close();
  }
}
