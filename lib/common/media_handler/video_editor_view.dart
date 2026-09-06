import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart' as pve;
import 'package:video_player/video_player.dart';

class VideoEditorView extends StatefulWidget {
  const VideoEditorView({super.key, required this.source});

  final File source;

  @override
  State<VideoEditorView> createState() => _VideoEditorViewState();
}

class _VideoEditorViewState extends State<VideoEditorView> {
  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();
  final _proVideoEditor = pve.ProVideoEditor.instance;
  late final pve.EditorVideo _video = pve.EditorVideo.file(widget.source.path);

  late VideoPlayerController _videoController;
  late pve.VideoMetadata _metadata;
  ProVideoController? _proVideoController;
  List<ImageProvider>? _thumbnails;

  bool _isSeeking = false;
  TrimDurationSpan? _durationSpan;
  TrimDurationSpan? _tempDurationSpan;

  static const _thumbnailCount = 7;

  final _configs = const ProImageEditorConfigs(
    mainEditor: MainEditorConfigs(
      tools: [
        SubEditorMode.cropRotate,
        SubEditorMode.filter,
        SubEditorMode.tune,
        SubEditorMode.text,
        SubEditorMode.paint,
      ],
    ),
    videoEditor: VideoEditorConfigs(
      minTrimDuration: Duration(seconds: 1),
    ),
    imageGeneration: ImageGenerationConfigs(
      captureImageByteFormat: ImageByteFormat.rawStraightRgba,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _metadata = await _proVideoEditor.getMetadata(_video);

    _videoController = VideoPlayerController.file(widget.source);
    await Future.wait([
      _videoController.initialize(),
      _videoController.setLooping(false),
    ]);
    _videoController.addListener(_onDurationChange);

    unawaited(_generateThumbnails());

    if (!mounted) {
      return;
    }
    setState(() {
      _proVideoController = ProVideoController(
        videoPlayer: _buildVideoPlayer(),
        initialResolution: _metadata.resolution,
        videoDuration: _metadata.duration,
        fileSize: _metadata.fileSize,
        thumbnails: _thumbnails,
      );
    });
  }

  Future<void> _generateThumbnails() async {
    if (!mounted) {
      return;
    }
    final width = MediaQuery.sizeOf(context).width /
        _thumbnailCount *
        MediaQuery.devicePixelRatioOf(context);
    final segment = _metadata.duration.inMilliseconds / _thumbnailCount;

    final list = await _proVideoEditor.getThumbnails(
      pve.ThumbnailConfigs(
        video: _video,
        outputSize: Size.square(width),
        timestamps: List.generate(
          _thumbnailCount,
          (i) => Duration(milliseconds: ((i + 0.5) * segment).round()),
        ),
      ),
    );

    _thumbnails = list.map(MemoryImage.new).toList();
    _proVideoController?.thumbnails = _thumbnails;
  }

  void _onDurationChange() {
    final position = _videoController.value.position;
    _proVideoController?.setPlayTime(position);

    if (_durationSpan != null && position >= _durationSpan!.end) {
      _seekToPosition(_durationSpan!);
    } else if (position >= _metadata.duration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: _metadata.duration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;
    if (_isSeeking) {
      _tempDurationSpan = span;
      return;
    }
    _isSeeking = true;

    _proVideoController?.pause();
    _proVideoController?.setPlayTime(span.start);
    await _videoController.pause();
    await _videoController.seekTo(span.start);

    _isSeeking = false;
    if (_tempDurationSpan != null) {
      final next = _tempDurationSpan!;
      _tempDurationSpan = null;
      await _seekToPosition(next);
    }
  }

  Future<void> _generateVideo(CompleteParameters p) async {
    unawaited(_videoController.pause());
    final dir = await getTemporaryDirectory();
    final output =
        '${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final data = pve.VideoRenderData(
      id: _taskId,
      videoSegments: [pve.VideoSegment(video: _video)],
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      imageLayers: p.layers.isNotEmpty
          ? [pve.ImageLayer(image: pve.EditorLayerImage.memory(p.image))]
          : null,
      blur: p.blur,
      colorFilters:
          p.colorFilters.map((m) => pve.ColorFilter(matrix: m)).toList(),
      startTime: p.startTime,
      endTime: p.endTime,
      transform: p.isTransformed
          ? pve.ExportTransform(
              width: p.cropWidth,
              height: p.cropHeight,
              rotateTurns: p.rotateTurns,
              x: p.cropX,
              y: p.cropY,
              flipX: p.flipX,
              flipY: p.flipY,
            )
          : null,
      // ponytail: cap bitrate/fps so the export doubles as a compression pass;
      // raise if users complain about quality.
      bitrate: 6000000,
      maxFrameRate: 30,
    );

    try {
      _outputPath = await _proVideoEditor.renderVideoToFile(output, data);
    } on pve.RenderCanceledException {
      _outputPath = null;
    }
  }

  String? _outputPath;

  void _handleCloseEditor(EditorMode mode) {
    if (mode != EditorMode.main) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, _outputPath == null ? null : File(_outputPath!));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _proVideoController;
    if (controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return ProImageEditor.video(
      controller,
      configs: _configs,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: _generateVideo,
        onCloseEditor: _handleCloseEditor,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: _videoController.pause,
          onPlay: _videoController.play,
          onMuteToggle: (isMuted) =>
              _videoController.setVolume(isMuted ? 0 : 1),
          onTrimSpanUpdate: (_) {
            if (_videoController.value.isPlaying) {
              _proVideoController?.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController.value.size.aspectRatio,
        child: VideoPlayer(_videoController),
      ),
    );
  }
}
