// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:override_text_scale_factor/override_text_scale_factor.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../common/media_handler/media_handler.dart';
import '../../logic/video_controller_manager_cubit/video_controller_manager_cubit.dart';
import '../../utils/utils.dart';
import '../gallery_view/gallery_view.dart';
import '../profile_view/widgets/profile_media.dart';
import 'content_renderer/url_type_checker.dart';
import 'media_components/video_download.dart';
import 'seek_bar.dart';

class LinkPreviewer extends HookWidget {
  const LinkPreviewer({
    super.key,
    required this.url,
    required this.onOpen,
    this.textStyle,
    this.isScreenshot,
    required this.urlType,
    this.checkType,
    this.inverseNoteColor,
    this.disableUrlParsing,
  });

  final String url;
  final Function()? onOpen;
  final TextStyle? textStyle;
  final bool? isScreenshot;
  final UrlType urlType;
  final bool? checkType;
  final bool? inverseNoteColor;
  final bool? disableUrlParsing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          if (disableUrlParsing != null && disableUrlParsing!) {
            return UrlDisplayer(
              url: url,
              onOpen: onOpen,
              textStyle: textStyle,
            );
          }

          if (checkType != null) {
            return _futureBuilder();
          } else {
            return _builder();
          }
        },
      ),
    );
  }

  Builder _builder() {
    return Builder(
      builder: (context) {
        if (urlType == UrlType.image) {
          return ImageDisplayer(
            link: url,
            isScreenshot: isScreenshot,
          );
        } else if (urlType == UrlType.video) {
          return CustomVideoPlayer(link: url);
        } else if (urlType == UrlType.audio) {
          try {
            return AudioDisplayer(
              url: url,
              inverseNoteColor: inverseNoteColor,
            );
          } catch (e) {
            return UrlDisplayer(
              url: url,
              onOpen: onOpen,
              textStyle: textStyle,
            );
          }
        } else {
          return UrlDisplayer(
            url: url,
            onOpen: onOpen,
            textStyle: textStyle,
          );
        }
      },
    );
  }

  FutureBuilder<UrlType> _futureBuilder() {
    return FutureBuilder(
      future: UrlTypeChecker.getUrlType(url),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == UrlType.image) {
          return ImageDisplayer(
            link: url,
            isScreenshot: isScreenshot,
          );
        } else if (urlType == UrlType.audio) {
          try {
            return AudioDisplayer(
              url: url,
              inverseNoteColor: inverseNoteColor,
            );
          } catch (e) {
            return UrlDisplayer(
              url: url,
              onOpen: onOpen,
              textStyle: textStyle,
            );
          }
        } else if (snapshot.hasData && snapshot.data == UrlType.video) {
          return CustomVideoPlayer(link: url);
        } else {
          return UrlDisplayer(
            url: url,
            onOpen: onOpen,
            textStyle: textStyle,
          );
        }
      },
    );
  }
}

class AudioDisplayer extends StatefulWidget {
  const AudioDisplayer({
    super.key,
    this.inverseNoteColor,
    required this.url,
  });

  final bool? inverseNoteColor;
  final String url;

  @override
  State<AudioDisplayer> createState() => _AudioDisplayerState();
}

class _AudioDisplayerState extends State<AudioDisplayer>
    with WidgetsBindingObserver {
  final _player = ja.AudioPlayer();
  final combinedController = StreamController<PositionData>();

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      if (kDebugMode) {
        print('A stream error occurred: $e');
      }
    });

    try {
      await _player.setAudioSource(ja.AudioSource.uri(Uri.parse(widget.url)));
      _player.positionStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration ?? Duration.zero,
            ),
          );
        },
      );
      _player.bufferedPositionStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration ?? Duration.zero,
            ),
          );
        },
      );
      _player.durationStream.listen(
        (event) {
          combinedController.add(
            PositionData(
              _player.position,
              _player.bufferedPosition,
              _player.duration ?? Duration.zero,
            ),
          );
        },
      );
    } on ja.PlayerException catch (e) {
      if (kDebugMode) {
        print('Error loading audio source: $e');
      }
    }
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: widget.inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ControlButtons(_player),
          StreamBuilder<PositionData>(
            stream: combinedController.stream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                duration: positionData?.duration ?? Duration.zero,
                position: positionData?.position ?? Duration.zero,
                bufferedPosition:
                    positionData?.bufferedPosition ?? Duration.zero,
                onChangeEnd: _player.seek,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final ja.AudioPlayer player;

  const ControlButtons(this.player, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(
            Icons.volume_up,
          ),
          iconSize: 25,
          visualDensity: const VisualDensity(vertical: -2),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: context.t.adjustVolume.capitalizeFirst(),
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),

        StreamBuilder<ja.PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ja.ProcessingState.loading ||
                processingState == ja.ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 20,
                height: 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            } else if (playing != true) {
              return IconButton(
                visualDensity: const VisualDensity(vertical: -2),
                icon: const Icon(Icons.play_arrow),
                iconSize: 25,
                onPressed: player.play,
              );
            } else if (processingState != ja.ProcessingState.completed) {
              return IconButton(
                visualDensity: const VisualDensity(vertical: -2),
                icon: const Icon(Icons.pause),
                iconSize: 25,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                visualDensity: const VisualDensity(vertical: -2),
                icon: const Icon(Icons.replay),
                iconSize: 25,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),

        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            visualDensity: const VisualDensity(vertical: -2),
            icon: Text('${snapshot.data?.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: context.t.adjustSpeed.capitalizeFirst(),
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
      ],
    );
  }
}

class UrlDisplayer extends HookWidget {
  const UrlDisplayer({
    super.key,
    required this.url,
    required this.onOpen,
    this.textStyle,
  });

  final String url;
  final Function()? onOpen;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpen?.call(),
      child: Text(url, style: textStyle),
    );
  }
}

class ImageDisplayer extends StatelessWidget {
  const ImageDisplayer({
    super.key,
    required this.link,
    this.isScreenshot,
  });

  final String link;
  final bool? isScreenshot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GalleryImageView(
            media: {link: UrlType.image},
            invertColor: false,
            isHidden: false,
            seperatorColor: Theme.of(context).primaryColorLight,
            width: MediaQuery.of(context).size.width,
            imageDecoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff8E2DE2),
                  Color(0xff4B1248),
                ],
              ),
            ),
            onDownload: MediaUtils.shareImage,
            height: 180,
          ),
        ),
      ),
    );
  }
}

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({
    super.key,
    required this.link,
    this.ratio,
    this.removePadding,
    this.removeControls,
    this.removeBorders,
    this.autoPlay = true,
    this.fallbackUrls,
    this.enableSound = true,
  });

  final String link;
  final double? ratio;

  final bool? removePadding;
  final bool? removeControls;
  final bool? removeBorders;
  final bool autoPlay;
  final List<String>? fallbackUrls;
  final bool enableSound;

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late bool autoplay;

  @override
  void initState() {
    super.initState();
    if (videoControllerManagerCubit.getVideoController(widget.link) != null) {
      autoplay = true;
    } else {
      autoplay = widget.autoPlay;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.removePadding != null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: AspectRatio(
        aspectRatio: widget.ratio ?? (16 / 9),
        child: Center(
          child: autoplay
              ? _container(context, autoplay)
              : VideoThumbnailCard(
                  url: widget.link,
                  onTap: () {
                    setState(() {
                      autoplay = true;
                    });
                  },
                ),
        ),
      ),
    );
  }

  Container _container(BuildContext context, bool autoplay) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.removeBorders != null
            ? null
            : BorderRadius.circular(kDefaultPadding / 2),
        color: kBlack,
        border: widget.removeBorders != null
            ? null
            : Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 3),
      child: widget.link.isEmpty
          ? Center(
              child: Text(
                context.t.errorLoadingVideo,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kWhite,
                    ),
              ),
            )
          : getVideoPlayer(widget.fallbackUrls, autoplay),
    );
  }

  Widget getVideoPlayer(List<String>? fallbackUrls, bool autoplay) {
    try {
      // return AppVideoPlayer(
      //   url: widget.link,
      //   ratio: widget.ratio,
      // );
      return OverrideTextScaleFactor(
        child: RegularVideoPlayer(
          link: widget.link,
          removeControls: widget.removeControls,
          autoPlay: autoplay,
          fallbackUrls: fallbackUrls,
          enableSound: widget.enableSound,
        ),
      );
    } catch (_) {
      return Center(
        child: Text(
          context.t.errorLoadingVideo,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: kWhite,
              ),
        ),
      );
    }
  }
}

class RegularVideoPlayer extends StatefulWidget {
  const RegularVideoPlayer({
    super.key,
    required this.link,
    this.isNetwork = true,
    this.removeControls,
    this.autoPlay,
    this.loop,
    this.fallbackUrls,
    this.enableSound = true,
  });

  final String link;
  final bool isNetwork;
  final bool? removeControls;
  final bool? autoPlay;
  final bool? loop;
  final List<String>? fallbackUrls;
  final bool enableSound;

  @override
  State<RegularVideoPlayer> createState() => _RegularVideoPlayerState();
}

class _RegularVideoPlayerState extends State<RegularVideoPlayer> {
  late String _ownerId;
  late String _usedUrl;

  @override
  void initState() {
    super.initState();
    _ownerId = '${widget.link}_${DateTime.now().microsecondsSinceEpoch}';

    _usedUrl = widget.link;

    videoControllerManagerCubit.acquireVideo(
      _usedUrl,
      _ownerId,
      autoPlay: widget.autoPlay ?? false,
      removeControls: widget.removeControls,
      isNetwork: widget.isNetwork,
      fallbackUrls: widget.fallbackUrls,
      enableSound: widget.enableSound,
      onFallbackUrlCalled: (url) {
        _usedUrl = url;
      },
      onDownloadVideo: (url) {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return VideoDownload(
              url: _usedUrl,
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          enableDrag: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
    );
  }

  @override
  void dispose() {
    videoControllerManagerCubit.releaseVideo(url: _usedUrl, id: _ownerId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoControllerManagerCubit,
        VideoControllerManagerState>(
      buildWhen: (previous, current) =>
          current.chewieControllers[_usedUrl] !=
              previous.chewieControllers[_usedUrl] ||
          current.videoControllers[_usedUrl] !=
              previous.videoControllers[_usedUrl],
      builder: (context, state) {
        final chewieController =
            videoControllerManagerCubit.getChewieController(_usedUrl);

        return VisibilityDetector(
          key: ValueKey(widget.link),
          onVisibilityChanged: (info) {
            final isVisible = info.visibleFraction > 0.5;

            if (!isVisible) {
              videoControllerManagerCubit.pauseVideo(widget.link);
            }
          },
          child: chewieController != null
              ? Chewie(controller: chewieController)
              : const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: SpinKitCircle(
                      color: kWhite,
                      size: 20,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class TapPlayPauseControls extends StatefulWidget {
  final VideoPlayerController controller;

  const TapPlayPauseControls({super.key, required this.controller});

  @override
  State<TapPlayPauseControls> createState() => _TapPlayPauseControlsState();
}

class _TapPlayPauseControlsState extends State<TapPlayPauseControls> {
  bool _showIcon = false;
  bool _isPlaying = false;

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _isPlaying = false;
      } else {
        widget.controller.play();
        _isPlaying = true;
      }

      _showIcon = true;
    });

    // hide the icon after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showIcon = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // invisible layer that catches taps
          const SizedBox.expand(),

          // fading overlay icon
          Center(
            child: AnimatedOpacity(
              opacity: _showIcon ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white.withValues(alpha: 0.8),
                size: 65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
