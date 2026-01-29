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
  VideoControllerManagerCubit()
      : super(const VideoControllerManagerState(
          chewieControllers: {},
          videoControllers: {},
          videoIds: {},
        ));

  VideoPlayerController? getVideoController(String url) =>
      state.videoControllers[url];
  ChewieController? getChewieController(String url) =>
      state.chewieControllers[url];
  final toBeAdded = <String>{};
  final inProcessUrls = <String>{};

  /// Acquire (increments usage count, initializes if needed)
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
    // If already loaded or loading, just register the new ID
    if (state.videoControllers[url] != null || inProcessUrls.contains(url)) {
      if (!state.videoIds.containsKey(id)) {
        final videoIds = Map<String, String>.from(state.videoIds);
        videoIds[id] = url;
        _emit(videoIds: videoIds);
      }
      return;
    }

    // In case of fast scrolling, we wait to make sure the user is on the view
    toBeAdded.add(id);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!toBeAdded.contains(id)) {
      return;
    }

    // Double check after delay
    if (state.videoControllers[url] != null || inProcessUrls.contains(url)) {
      if (!state.videoIds.containsKey(id)) {
        final videoIds = Map<String, String>.from(state.videoIds);
        videoIds[id] = url;
        _emit(videoIds: videoIds);
      }
      return;
    }

    try {
      VideoPlayerController? videoController;
      String usedUrl = url;
      inProcessUrls.add(url);

      if (isNetwork) {
        videoController =
            await _initNetworkVideo(url, enableSound: enableSound);
        // User scrolled away during initialization check
        if (!toBeAdded.contains(id)) {
          await videoController?.dispose();
          inProcessUrls.remove(url);
          return;
        }

        if (videoController == null) {
          if (fallbackUrls != null && fallbackUrls.isNotEmpty) {
            for (final fallbackUrl in fallbackUrls) {
              videoController = await _initNetworkVideo(
                fallbackUrl,
                enableSound: enableSound,
              );
              if (!toBeAdded.contains(id)) {
                await videoController?.dispose();
                inProcessUrls.remove(url);
                return;
              }

              if (videoController != null) {
                usedUrl = fallbackUrl;
                onFallbackUrlCalled?.call(fallbackUrl);
                break;
              }
            }
          }
        }
      } else {
        final file = File(url);
        // When sound is disabled, mix with other audio to avoid interrupting background music
        videoController = enableSound
            ? VideoPlayerController.file(file)
            : VideoPlayerController.file(
                file,
                videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
              );
        await videoController.initialize();
        if (!toBeAdded.contains(id)) {
          await videoController.dispose();
          inProcessUrls.remove(url);
          return;
        }
      }

      inProcessUrls.remove(url);

      if (videoController == null) {
        return;
      }

      if (!enableSound) {
        videoController.setVolume(0);
      }

      final videoControllers =
          Map<String, VideoPlayerController>.from(state.videoControllers);
      final chewieControllers =
          Map<String, ChewieController>.from(state.chewieControllers);

      videoControllers[usedUrl] = videoController;

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: autoPlay,
        allowPlaybackSpeedChanging: false,
        showControlsOnInitialize: false,
        showControls: showControls,
        looping: looping,
        aspectRatio: aspectRatio,
        routePageBuilder:
            (context, animation, secondaryAnimation, controllerProvider) =>
                FullScreenVideoPlayer(url: url, provider: controllerProvider),
        deviceOrientationsOnEnterFullScreen: Platform.isAndroid
            ? <DeviceOrientation>[
                DeviceOrientation.portraitUp,
              ]
            : null,
        customControls: removeControls != null
            ? TapPlayPauseControls(controller: videoController)
            : CustomCupertinoControls(
                backgroundColor: kBlack,
                iconColor: kWhite,
                onDownload: () => onDownloadVideo?.call(usedUrl),
              ),
      );

      chewieControllers[usedUrl] = chewieController;

      final videoIds = Map<String, String>.from(state.videoIds);
      videoIds[id] = usedUrl;

      _emit(
        videoControllers: videoControllers,
        chewieControllers: chewieControllers,
        videoIds: videoIds,
      );
    } catch (e) {
      lg.i(e);
      inProcessUrls.remove(url);
    }
  }

  Future<void> downloadVideo(String url, Function(double) onProgress) async {
    await MediaHandler.saveNetworkVideo(
      url,
      onProgress: onProgress,
      showSuccessMessage: false,
    );
  }

  Future<VideoPlayerController?> _initNetworkVideo(
    String url, {
    bool enableSound = true,
  }) async {
    try {
      bool hasBeenDisposed = false;

      // When sound is disabled, mix with other audio to avoid interrupting background music
      final videoController = enableSound
          ? VideoPlayerController.networkUrl(Uri.parse(url))
          : VideoPlayerController.networkUrl(
              Uri.parse(url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );

      await videoController.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          videoController.dispose();
          hasBeenDisposed = true;
          return;
        },
      );

      if (hasBeenDisposed) {
        return null;
      }

      return videoController;
    } catch (e) {
      return null;
    }
  }

  void releaseVideo({
    required String url,
    required String id,
  }) {
    toBeAdded.remove(id);
    final currentUrl = state.videoIds[id];

    if (currentUrl == null) {
      return;
    }

    // Remove the ID association first
    final videoIds = Map<String, String>.from(state.videoIds);
    videoIds.remove(id);

    // Check if any other ID is still using this URL
    final isStillInUse = videoIds.containsValue(url);

    if (isStillInUse) {
      // Just update the videoIds, don't dispose the controller
      _emit(videoIds: videoIds);
      return;
    }

    // Safe to dispose
    state.chewieControllers[url]?.dispose();
    state.videoControllers[url]?.dispose();

    final chewieControllers =
        Map<String, ChewieController>.from(state.chewieControllers);
    final videoControllers =
        Map<String, VideoPlayerController>.from(state.videoControllers);

    chewieControllers.remove(url);
    videoControllers.remove(url);

    _emit(
      chewieControllers: chewieControllers,
      videoControllers: videoControllers,
      videoIds: videoIds,
    );
  }

  void pauseVideo(String url) {
    state.videoControllers[url]?.pause();
  }

  void _emit({
    Map<String, VideoPlayerController>? videoControllers,
    Map<String, ChewieController>? chewieControllers,
    Map<String, String>? videoIds,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        videoControllers: videoControllers,
        chewieControllers: chewieControllers,
        videoIds: videoIds,
      ));
    }
  }

  @override
  Future<void> close() {
    for (final controller in state.chewieControllers.values) {
      controller.dispose();
    }
    for (final controller in state.videoControllers.values) {
      controller.dispose();
    }
    return super.close();
  }
}
