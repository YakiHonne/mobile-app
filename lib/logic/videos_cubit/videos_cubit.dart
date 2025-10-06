import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'videos_state.dart';

class VideosCubit extends Cubit<VideosState> {
  VideosCubit({required bool isHorizontal})
      : super(
          VideosState(
              isHorizontalLoading: true,
              isVerticalLoading: true,
              horizontalVideos: const [],
              verticalVideos: const [],
              loadingHorizontalState: UpdatingState.success,
              loadingVerticalState: UpdatingState.success,
              isHorizontalVideoSelected: isHorizontal,
              refresh: false),
        ) {
    mutesSubscription = nostrRepository.mutesStream.listen(
      (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription mutesSubscription;

  void initView({required bool loadHorizontal, required bool loadVertical}) {
    if (!isClosed) {
      emit(
        state.copyWith(
          isHorizontalLoading: loadHorizontal ? loadHorizontal : null,
          loadingHorizontalState: loadHorizontal ? UpdatingState.success : null,
          isVerticalLoading: loadVertical ? loadVertical : null,
          loadingVerticalState: loadVertical ? UpdatingState.success : null,
        ),
      );
    }

    NostrFunctionsRepository.getVideos(
      loadHorizontal: loadHorizontal,
      loadVertical: loadVertical,
      limit: 20,
      onHorizontalVideos: (videos) {
        sort(videos);

        if (!isClosed) {
          emit(
            state.copyWith(
              isHorizontalLoading: false,
              horizontalVideos: videos,
            ),
          );
        }
      },
      onVerticalVideos: (videos) {
        sort(videos);

        if (!isClosed) {
          emit(
            state.copyWith(
              isVerticalLoading: false,
              verticalVideos: videos,
            ),
          );
        }
      },
      onDone: () {
        for (final e in state.horizontalVideos) {
          nostrRepository.videos[e.id] = e;
        }

        if (!isClosed) {
          emit(
            state.copyWith(
              isVerticalLoading: false,
              isHorizontalLoading: false,
            ),
          );
        }
      },
    );
  }

  void loadMore() {
    final hor = state.isHorizontalVideoSelected;

    if (hor && state.horizontalVideos.isEmpty ||
        !hor && state.verticalVideos.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingHorizontalState: hor ? UpdatingState.idle : null,
            loadingVerticalState: !hor ? UpdatingState.idle : null,
          ),
        );
      }

      return;
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          loadingHorizontalState: hor ? UpdatingState.progress : null,
          loadingVerticalState: !hor ? UpdatingState.progress : null,
        ),
      );
    }

    final createdAt = hor
        ? state.horizontalVideos.last.createdAt
        : state.verticalVideos.last.createdAt;

    final oldVideos = hor
        ? List<VideoModel>.from(state.horizontalVideos)
        : List<VideoModel>.from(state.verticalVideos);
    List<VideoModel> onGoingVideo = [];

    NostrFunctionsRepository.getVideos(
      loadHorizontal: hor,
      loadVertical: !hor,
      limit: 20,
      until: createdAt.toSecondsSinceEpoch() - 1,
      onHorizontalVideos: (videos) {
        onGoingVideo = videos;
        sort(onGoingVideo);

        final updateVideos = [...oldVideos, ...onGoingVideo];
        if (!isClosed) {
          emit(
            state.copyWith(
              loadingHorizontalState: UpdatingState.success,
              horizontalVideos: updateVideos,
            ),
          );
        }
      },
      onVerticalVideos: (videos) {
        onGoingVideo = videos;
        sort(onGoingVideo);
        if (!isClosed) {
          emit(
            state.copyWith(
              loadingVerticalState: UpdatingState.success,
              verticalVideos: oldVideos..insertAll(0, onGoingVideo),
            ),
          );
        }
      },
      onDone: () {
        if (onGoingVideo.isNotEmpty && hor) {
          for (final e in onGoingVideo) {
            nostrRepository.videos[e.id] = e;
          }
        } else if (onGoingVideo.isEmpty) {
          if (!isClosed) {
            emit(
              state.copyWith(
                loadingVerticalState: !hor ? UpdatingState.idle : null,
                loadingHorizontalState: hor ? UpdatingState.idle : null,
              ),
            );
          }
        }
      },
    );
  }

  void setIsHorizontal(bool isHorizontal) {
    if (!isClosed) {
      emit(
        state.copyWith(
          isHorizontalVideoSelected: isHorizontal,
        ),
      );
    }
  }

  Future<void> shareLink(RenderBox? renderBox, VideoModel video) async {
    final res = await externalShearableLink(
      kind: video.kind,
      pubkey: video.pubkey,
      id: video.id,
    );

    Share.share(
      res,
      subject: 'Check out www.yakihonne.com for me more videos.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  void sort(List<VideoModel> videos) {
    videos.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }

  @override
  Future<void> close() {
    mutesSubscription.cancel();
    return super.close();
  }
}
