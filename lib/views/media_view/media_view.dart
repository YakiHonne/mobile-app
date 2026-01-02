import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    final autoPlay =
        nostrRepository.currentAppCustomization?.enableAutoPlay ?? true;

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
              return PictureWidget(item: item);
            }

            final video = item as VideoModel;

            return VideoWidget(
              video: video,
              isLargeTile: isLargeTile,
              loadVideos: loadVideos,
              autoPlay: autoPlay,
              itemUrl: item.url,
            );
          },
          childCount: sortedContent.length,
        ),
      ),
    );
  }
}

class VideoWidget extends HookWidget {
  const VideoWidget({
    super.key,
    required this.video,
    required this.isLargeTile,
    required this.loadVideos,
    required this.autoPlay,
    required this.itemUrl,
  });

  final VideoModel video;
  final bool isLargeTile;
  final bool loadVideos;
  final bool autoPlay;
  final String itemUrl;

  @override
  Widget build(BuildContext context) {
    final isDisplayed = useState(!video.contentWarning);

    return GestureDetector(
      onTap: () {
        if (!isDisplayed.value) {
          isDisplayed.value = !isDisplayed.value;
        }
      },
      child: isDisplayed.value
          ? Builder(
              builder: (context) {
                return isLargeTile
                    ? BlocBuilder<MainCubit, MainState>(
                        builder: (context, state) {
                          if (loadVideos) {
                            if (autoPlay) {
                              return FeedVideoPlayer(
                                link: itemUrl,
                                fallbackUrls: video.fallbackUrls,
                                video: video,
                                isTabActive: state.mainView == MainViews.media,
                              );
                            } else {
                              return VideoCard(video: video);
                            }
                          }

                          return const SizedBox();
                        },
                      )
                    : VideoCard(video: video);
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                FeatureIcons.notVisible,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
    );
  }
}

class PictureWidget extends HookWidget {
  const PictureWidget({
    super.key,
    required this.item,
  });

  final PictureModel item;

  @override
  Widget build(BuildContext context) {
    final isDisplayed = useState(!item.hasContentWarning);

    return GestureDetector(
      onTap: () {
        if (!isDisplayed.value) {
          isDisplayed.value = true;
          return;
        }

        YNavigator.pushPage(
          context,
          (context) => PictureView(picture: item),
        );
      },
      onLongPress: () {
        if (isDisplayed.value) {
          openGallery(
            source: MapEntry(item.getUrl(), UrlType.image),
            index: 0,
            context: context,
          );
        }
      },
      child: isDisplayed.value
          ? CommonThumbnail(
              image: item.getUrl(),
              radius: 0,
              isRound: false,
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                FeatureIcons.notVisible,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
    );
  }
}
