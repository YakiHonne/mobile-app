import 'dart:collection';

import 'package:flutter_link_previewer/flutter_link_previewer.dart';

import '../../utils/utils.dart';
import '../../utils/video_utils.dart';

class PreviewQueueManager {
  factory PreviewQueueManager() => instance;
  PreviewQueueManager._internal();

  static final PreviewQueueManager instance = PreviewQueueManager._internal();

  final Queue<QueueRequest> _queue = Queue();
  bool _isProcessing = false;

  void addRequest(QueueRequest request) {
    if (!nostrRepository.previewCache.containsKey(request.url)) {
      _queue.add(request);
      _processQueue();
    } else {
      request.callback(nostrRepository.previewCache[request.url]);
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      final data = await getPreviewData(request.url);
      nostrRepository.previewCache[request.url] = data;
      request.callback(data);
    }

    _isProcessing = false;
  }
}

class VideoThumbnailQueueManager {
  factory VideoThumbnailQueueManager() => instance;
  VideoThumbnailQueueManager._internal();

  static final VideoThumbnailQueueManager instance =
      VideoThumbnailQueueManager._internal();

  final Queue<QueueRequest> _queue = Queue();
  bool _isProcessing = false;

  void addRequest(QueueRequest request) {
    if (!nostrRepository.videoThumbnails.containsKey(request.url)) {
      _queue.add(request);
      _processQueue();
    } else {
      request.callback(nostrRepository.videoThumbnails[request.url]);
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final request = _queue.removeFirst();
      final data = await VideoUtils.getVideoThumbnailImage(
        videoURL: request.url,
        context: gc,
      );
      nostrRepository.videoThumbnails[request.url] = data;
      request.callback(data);
    }

    _isProcessing = false;
  }
}

class QueueRequest {
  QueueRequest(this.url, this.callback);
  final String url;
  final void Function(dynamic) callback;
}
