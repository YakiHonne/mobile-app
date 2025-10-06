// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'videos_cubit.dart';

class VideosState extends Equatable {
  final bool isHorizontalLoading;
  final bool isVerticalLoading;
  final List<VideoModel> horizontalVideos;
  final List<VideoModel> verticalVideos;
  final bool isHorizontalVideoSelected;
  final UpdatingState loadingHorizontalState;
  final UpdatingState loadingVerticalState;
  final bool refresh;

  const VideosState({
    required this.isHorizontalLoading,
    required this.isVerticalLoading,
    required this.horizontalVideos,
    required this.verticalVideos,
    required this.isHorizontalVideoSelected,
    required this.loadingHorizontalState,
    required this.loadingVerticalState,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        isHorizontalLoading,
        isVerticalLoading,
        horizontalVideos,
        verticalVideos,
        isHorizontalVideoSelected,
        loadingHorizontalState,
        loadingVerticalState,
        refresh,
      ];

  VideosState copyWith({
    bool? isHorizontalLoading,
    bool? isVerticalLoading,
    List<VideoModel>? horizontalVideos,
    List<VideoModel>? verticalVideos,
    bool? isHorizontalVideoSelected,
    UpdatingState? loadingHorizontalState,
    UpdatingState? loadingVerticalState,
    bool? refresh,
  }) {
    return VideosState(
      isHorizontalLoading: isHorizontalLoading ?? this.isHorizontalLoading,
      isVerticalLoading: isVerticalLoading ?? this.isVerticalLoading,
      horizontalVideos: horizontalVideos ?? this.horizontalVideos,
      verticalVideos: verticalVideos ?? this.verticalVideos,
      isHorizontalVideoSelected:
          isHorizontalVideoSelected ?? this.isHorizontalVideoSelected,
      loadingHorizontalState:
          loadingHorizontalState ?? this.loadingHorizontalState,
      loadingVerticalState: loadingVerticalState ?? this.loadingVerticalState,
      refresh: refresh ?? this.refresh,
    );
  }
}
