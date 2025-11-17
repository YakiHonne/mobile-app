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
import '../../views/widgets/video_components/custom_video_controls.dart';

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

  /// Acquire (increments usage count, initializes if needed)
  Future<void> acquireVideo(
    String url,
    String id, {
    bool autoPlay = false,
    bool isNetwork = true,
    bool? removeControls,
    List<String>? fallbackUrls,
    Function(String)? onFallbackUrlCalled,
    Function(String)? onDownloadVideo,
  }) async {
    if (state.videoControllers[url] != null) {
      return;
    }

    // In case of fast scrolling, we wait to make sure the user is on the view
    toBeAdded.add(url);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!toBeAdded.contains(url)) {
      return;
    }

    try {
      VideoPlayerController? videoController;
      String usedUrl = url;
      if (isNetwork) {
        videoController = await _initNetworkVideo(url);

        if (videoController == null) {
          if (fallbackUrls != null && fallbackUrls.isNotEmpty) {
            for (final fallbackUrl in fallbackUrls) {
              videoController = await _initNetworkVideo(fallbackUrl);

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
        videoController = VideoPlayerController.file(file);
        await videoController.initialize();
      }

      if (videoController == null) {
        return;
      }

      if (autoPlay) {
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
    }
  }

  Future<void> downloadVideo(String url, Function(double) onProgress) async {
    await MediaHandler.saveNetworkVideo(
      url,
      onProgress: onProgress,
      showSuccessMessage: false,
    );
  }

  Future<VideoPlayerController?> _initNetworkVideo(String url) async {
    try {
      bool hasBeenDisposed = false;
      final videoController = VideoPlayerController.networkUrl(Uri.parse(url));
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
      lg.i(e);
      return null;
    }
  }

  void releaseVideo({
    required String url,
    required String id,
  }) {
    toBeAdded.remove(url);
    final currentUrl = state.videoIds[id];

    if (currentUrl == null) {
      return;
    }

    state.chewieControllers[url]?.dispose();
    state.videoControllers[url]?.dispose();

    final chewieControllers =
        Map<String, ChewieController>.from(state.chewieControllers);
    final videoControllers =
        Map<String, VideoPlayerController>.from(state.videoControllers);
    final videoIds = Map<String, String>.from(state.videoIds);

    chewieControllers.remove(url);
    videoControllers.remove(url);
    videoIds.remove(id);

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
