import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';

import '../../../logic/add_media_cubit/add_media_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/empty_list.dart';
import 'add_media_bottom_navigation_bar.dart';

class AddMediaMainView extends HookWidget {
  const AddMediaMainView({
    super.key,
    required this.media,
    required this.description,
    required this.isVideo,
    required this.dimensions,
  });

  final ValueNotifier<File?> media;
  final ValueNotifier<bool> isVideo;
  final ValueNotifier<String> description;
  final ValueNotifier<String> dimensions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMediaCubit, AddMediaState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: media.value != null
              ? MediaPreview(
                  media: media.value!,
                  description: description,
                  isVideo: isVideo.value,
                  dimensions: dimensions,
                  onRetake: () {
                    media.value = null;
                    isVideo.value = false;
                    dimensions.value = '';
                  },
                  onEdit: (File image) {
                    media.value = image;
                  },
                )
              : MediaPicker(
                  isVideo: isVideo,
                  onSuccess: (m, iv) {
                    media.value = m;
                    isVideo.value = iv;
                  },
                ),
        );
      },
    );
  }
}

class MediaPreview extends StatelessWidget {
  const MediaPreview({
    super.key,
    required this.media,
    required this.isVideo,
    required this.onRetake,
    required this.description,
    required this.dimensions,
    required this.onEdit,
  });

  final File media;
  final bool isVideo;
  final ValueNotifier<String> description;
  final ValueNotifier<String> dimensions;
  final VoidCallback onRetake;
  final Function(File) onEdit;

  @override
  Widget build(BuildContext context) {
    return isVideo
        ? VideoWidget(
            media: media,
            onRetake: onRetake,
            dimensions: dimensions,
          )
        : PictureWidget(
            media: media,
            onRetake: onRetake,
            description: description,
            dimensions: dimensions,
            onEdit: onEdit,
          );
  }
}

class PictureWidget extends HookWidget {
  const PictureWidget({
    super.key,
    required this.media,
    required this.onRetake,
    required this.onEdit,
    required this.description,
    required this.dimensions,
  });

  final File media;
  final ValueNotifier<String> description;
  final ValueNotifier<String> dimensions;
  final Function() onRetake;
  final Function(File) onEdit;

  @override
  Widget build(BuildContext context) {
    useMemoized(() async {
      final image = await getImageDimensions(media);
      dimensions.value = '${image.width}x${image.height}';
    }, [media]);

    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 4,
        ),
        child: Stack(
          children: [
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(kDefaultPadding),
                image: DecorationImage(
                  image: FileImage(media),
                  fit: BoxFit.contain,
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0, 0.2],
                  colors: [
                    Theme.of(context).cardColor.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: kDefaultPadding / 2,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return MediaDescription(description: description);
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: Text(
                    description.value.isEmpty
                        ? context.t.addDescription
                        : description.value,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: kWhite,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  const VideoWidget({
    super.key,
    required this.media,
    required this.onRetake,
    required this.dimensions,
  });

  final File media;
  final Function() onRetake;
  final ValueNotifier<String> dimensions;

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.media.path));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();
    final size = _videoController!.value.size;
    widget.dimensions.value = '${size.width}x${size.height}';

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 4,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: Theme.of(context).cardColor,
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0, 0.2],
                colors: [
                  Theme.of(context).cardColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
            child: (_videoController != null &&
                    _videoController!.value.isInitialized)
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class MediaPicker extends StatefulWidget {
  const MediaPicker({super.key, this.onSuccess, required this.isVideo});

  final Function(File, bool)? onSuccess;
  final ValueNotifier<bool> isVideo;

  @override
  State<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  CameraController? controller;
  bool isRecording = false;
  bool isFrontCamera = false;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _initializeCamera(cameras.first);
    } else {
      isInitializing = false;
    }
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    controller = CameraController(
      camera,
      ResolutionPreset.high,
    );

    try {
      isInitializing = true;

      await controller!.initialize();

      setState(() {
        isInitializing = false;
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      setState(() {
        isInitializing = false;
      });

      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    }
  }

  Future<void> _switchCamera() async {
    final newCamera = isFrontCamera
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back)
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front);

    await controller!.dispose();

    setState(() {
      isFrontCamera = !isFrontCamera;
    });

    await _initializeCamera(newCamera);
  }

  Future<void> _handleCapture() async {
    if (!widget.isVideo.value) {
      // Take picture
      try {
        final image = await controller!.takePicture();
        widget.onSuccess?.call(File(image.path), false);
        lg.i('Image captured: ${image.path}');
      } catch (e) {
        lg.i('Error taking picture: $e');
      }
    } else {
      // Record video
      if (isRecording) {
        try {
          final video = await controller!.stopVideoRecording();
          widget.onSuccess?.call(File(video.path), true);
          setState(() {
            isRecording = false;
          });
        } catch (e) {
          lg.i('Error stopping video: $e');
        }
      } else {
        try {
          await controller!.startVideoRecording();
          setState(() {
            isRecording = true;
          });
        } catch (e) {
          lg.i('Error starting video: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return Center(
        child: SpinKitCircle(
          color: Theme.of(context).primaryColorDark,
          size: 20,
        ),
      );
    } else if (controller == null) {
      return EmptyList(
        description: context.t.cameraPermission,
        icon: FeatureIcons.media,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: Stack(
          children: [
            // Camera Preview
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CameraPreview(controller!),
                ),
              ),
            ),

            // Buttons overlay
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: _handleCapture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  margin: const EdgeInsets.only(
                    bottom: kDefaultPadding,
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isRecording ? 30 : 60,
                      height: isRecording ? 30 : 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          isRecording ? kDefaultPadding / 2 : 300,
                        ),
                        color: widget.isVideo.value ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: kDefaultPadding / 2,
                  bottom: kDefaultPadding * 1.5,
                ),
                child: GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
