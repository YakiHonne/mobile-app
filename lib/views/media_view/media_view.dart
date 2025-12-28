import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../logic/main_cubit/main_cubit.dart';
import '../../logic/media_cubit/media_cubit.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../gallery_view/gallery_view.dart';
import '../profile_view/widgets/profile_media.dart';
import '../widgets/classic_footer.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/empty_list.dart';
import '../widgets/media_components/picture_view.dart';

class MediaView extends StatefulWidget {
  const MediaView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  final refreshController = RefreshController();

  void onRefresh() {
    refreshController.resetNoData();
    buildExploreFeed.call(context, false);
    mediaCubit.resetExtra();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();

    super.dispose();
  }

  void buildExploreFeed(BuildContext context, bool isAdding) {
    mediaCubit.buildMediaFeed(
      isAdding: isAdding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      buildWhen: (previous, current) => previous.mainView != current.mainView,
      builder: (context, mainState) {
        return BlocConsumer<MediaCubit, MediaState>(
          listener: (context, state) {
            if (state.onAddingData == UpdatingState.success) {
              refreshController.loadComplete();
            } else if (state.onAddingData == UpdatingState.idle) {
              refreshController.loadNoData();
            }

            if (!state.onLoading) {
              refreshController.refreshCompleted();
            }
          },
          builder: (context, state) {
            return SmartRefresher(
              controller: refreshController,
              scrollController: widget.scrollController,
              enablePullUp: true,
              header: const RefresherClassicHeader(),
              footer: const RefresherClassicFooter(),
              onLoading: () => buildExploreFeed.call(context, true),
              onRefresh: () => onRefresh(),
              child: CustomScrollView(
                slivers: [
                  if (state.onLoading)
                    const SliverToBoxAdapter(
                      child: MediaPlaceholder(),
                    )
                  else if (state.content.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyList(
                        description: context.t.media,
                        icon: FeatureIcons.videoGallery,
                      ),
                    )
                  else
                    MediaGrid(
                      content: state.content,
                      loadVideos: mainState.mainView == MainViews.media,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.content,
    required this.loadVideos,
  });

  final List<BaseEventModel> content;
  final bool loadVideos;

  @override
  Widget build(BuildContext context) {
    final sortedContent = content;

    return BlocProvider.value(
      value: nostrRepository.mainCubit,
      child: SliverGrid(
        gridDelegate: SliverQuiltedGridDelegate(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          repeatPattern: QuiltedGridRepeatPattern.inverted,
          pattern: [
            const QuiltedGridTile(2, 1),
            const QuiltedGridTile(1, 1),
            const QuiltedGridTile(1, 1),
            const QuiltedGridTile(1, 1),
            const QuiltedGridTile(1, 1),
          ],
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = sortedContent.elementAt(index);
            final positionInPattern = index % 10;
            final isLargeTile =
                positionInPattern == 0 || positionInPattern == 7;

            if (item is PictureModel) {
              return GestureDetector(
                onTap: () {
                  YNavigator.pushPage(
                    context,
                    (context) => PictureView(picture: item),
                  );
                },
                onLongPress: () {
                  openGallery(
                    source: MapEntry(item.getUrl(), UrlType.image),
                    index: 0,
                    context: context,
                  );
                },
                child: CommonThumbnail(
                  image: item.getUrl(),
                  radius: 0,
                  isRound: false,
                ),
              );
            }

            final video = item as VideoModel;

            return isLargeTile
                ? BlocBuilder<MainCubit, MainState>(
                    builder: (context, state) {
                      if (loadVideos) {
                        return FeedVideoPlayer(
                          link: item.url,
                          fallbackUrls: video.fallbackUrls,
                          video: video,
                          isTabActive: state.mainView == MainViews.media,
                        );
                      }

                      return const SizedBox();
                    },
                  )
                : VideoCard(video: video);
          },
          childCount: sortedContent.length,
        ),
      ),
    );
  }

  // List<BaseEventModel> _sortMediaContent(List<BaseEventModel> content) {
  //   if (content.length <= 5) {
  //     // For small lists, just sort with priority
  //     return _sortByPriority(content);
  //   }

  //   final result = <BaseEventModel>[];

  //   // Process in groups of 5
  //   for (int i = 0; i < content.length; i += 5) {
  //     final groupEnd = (i + 5 < content.length) ? i + 5 : content.length;
  //     final group = content.sublist(i, groupEnd);

  //     // Find the best item for position 0 (large tile) based on priority
  //     BaseEventModel? bestForLargeTile;
  //     int bestIndex = -1;
  //     int bestPriority = -1;

  //     for (int j = 0; j < group.length; j++) {
  //       final priority = _getMediaPriority(group[j]);
  //       if (priority > bestPriority) {
  //         bestPriority = priority;
  //         bestForLargeTile = group[j];
  //         bestIndex = j;
  //       }
  //     }

  //     // Reorder this group: best item first, then the rest
  //     if (bestForLargeTile != null && bestIndex != -1) {
  //       result.add(bestForLargeTile);
  //       for (int j = 0; j < group.length; j++) {
  //         if (j != bestIndex) {
  //           result.add(group[j]);
  //         }
  //       }
  //     } else {
  //       result.addAll(group);
  //     }
  //   }

  //   return result;
  // }

  // /// Sort a list by priority (for small lists)
  // List<BaseEventModel> _sortByPriority(List<BaseEventModel> content) {
  //   final sorted = List<BaseEventModel>.from(content);
  //   sorted.sort((a, b) => _getMediaPriority(b).compareTo(_getMediaPriority(a)));
  //   return sorted;
  // }

  // /// Returns priority score for media type
  // /// Higher score = higher priority for large tiles
  // /// - Vertical videos: 3 (highest priority)
  // /// - Images: 2
  // /// - Horizontal videos: 1 (lowest priority)
  // int _getMediaPriority(BaseEventModel event) {
  //   if (event is VideoModel) {
  //     return event.isHorizontal ? 1 : 3;
  //   } else if (event is PictureModel) {
  //     return 2;
  //   }
  //   return 0;
  // }
}
