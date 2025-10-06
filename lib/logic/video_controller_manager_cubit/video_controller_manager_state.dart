// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'video_controller_manager_cubit.dart';

class VideoControllerManagerState extends Equatable {
  final Map<String, VideoPlayerController> videoControllers;
  final Map<String, ChewieController> chewieControllers;
  final Map<String, String> videoIds;

  const VideoControllerManagerState({
    required this.videoControllers,
    required this.chewieControllers,
    required this.videoIds,
  });

  @override
  List<Object> get props => [
        videoControllers,
        chewieControllers,
        videoIds,
      ];

  VideoControllerManagerState copyWith({
    Map<String, VideoPlayerController>? videoControllers,
    Map<String, ChewieController>? chewieControllers,
    Map<String, String>? videoIds,
    Set<String>? fullscreenVideos,
  }) {
    return VideoControllerManagerState(
      videoControllers: videoControllers ?? this.videoControllers,
      chewieControllers: chewieControllers ?? this.chewieControllers,
      videoIds: videoIds ?? this.videoIds,
    );
  }
}
