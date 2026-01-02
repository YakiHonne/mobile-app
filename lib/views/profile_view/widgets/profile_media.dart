import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../common/functions/queue_manager.dart';
import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../logic/video_controller_manager_cubit/video_controller_manager_cubit.dart';
import '../../../models/picture_model.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../gallery_view/gallery_view.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/picture_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';
import '../../widgets/tag_container.dart';

final profileDataList = [
  ProfileData.allMedia,
  ProfileData.pictures,
  ProfileData.videos,
];

/// Custom video player for media feed that fills available space
/// Custom video player for media feed that fills available space
/// Only plays when tab is active and video is visible
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    super.key,
    required this.link,
    required this.video,
    this.fallbackUrls,
    this.isTabActive = true, // Add this parameter
  });

  final String link;
  final List<String>? fallbackUrls;
  final VideoModel video;
  final bool isTabActive;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late String _ownerId;
  late String _usedUrl;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _ownerId = '${widget.link}_${DateTime.now().microsecondsSinceEpoch}';
    _usedUrl = widget.link;

    videoControllerManagerCubit.acquireVideo(
      _usedUrl,
      _ownerId,
      removeControls: true,
      looping: true,
      enableSound: false,
      fallbackUrls: widget.fallbackUrls,
      onFallbackUrlCalled: (url) {
        _usedUrl = url;
      },
    );
  }

  @override
  void didUpdateWidget(FeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle tab changes
    if (oldWidget.isTabActive != widget.isTabActive) {
      _handlePlaybackState();
    }
  }

  void _handlePlaybackState() {
    if (!mounted) {
      return;
    }

    final chewieController =
        videoControllerManagerCubit.getChewieController(_usedUrl);

    if (chewieController == null) {
      return;
    }

    final videoController = chewieController.videoPlayerController;
    final shouldPlay = widget.isTabActive && _isVisible;

    if (shouldPlay && !videoController.value.isPlaying) {
      videoController.play();
    } else if (!shouldPlay && videoController.value.isPlaying) {
      videoController.pause();
    }
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

        if (chewieController == null) {
          return ColoredBox(
            color: Theme.of(context).cardColor,
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: SpinKitCircle(
                  color: Theme.of(context).primaryColorDark,
                  size: 20,
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            YNavigator.pushPage(
              context,
              (context) => VerticalVideoView(
                video: widget.video,
                enableSound: true,
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: VisibilityDetector(
            key: ValueKey(widget.link),
            onVisibilityChanged: (info) {
              if (!mounted) {
                return;
              }

              _isVisible = info.visibleFraction > 0.5;
              _handlePlaybackState();
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final videoController = chewieController.videoPlayerController;
                final videoAspect = videoController.value.aspectRatio;
                final containerAspect =
                    constraints.maxWidth / constraints.maxHeight;

                // Calculate scale to cover container
                final scale = containerAspect > videoAspect
                    ? containerAspect / videoAspect
                    : videoAspect / containerAspect;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: scale,
                      child: AbsorbPointer(
                        child: Chewie(
                          controller: chewieController,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class ProfileMedia extends StatelessWidget {
  const ProfileMedia({
    super.key,
    required this.profileData,
    required this.onProfileDataChanged,
  });

  final ProfileData profileData;
  final Function(ProfileData) onProfileDataChanged;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          sliver: SliverAppBar(
            floating: true,
            toolbarHeight: 45,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: SizedBox(
              height: 36,
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                itemBuilder: (context, index) {
                  final type = profileDataList[index];

                  return TagContainer(
                    title: type.getDisplayName(context),
                    isActive: type == profileData,
                    style: Theme.of(context).textTheme.labelLarge,
                    backgroundColor: type == profileData
                        ? Theme.of(context).cardColor
                        : Colors.transparent,
                    textColor: Theme.of(context).primaryColorDark,
                    onClick: () {
                      onProfileDataChanged(type);
                      HapticFeedback.lightImpact();
                    },
                  );
                },
                itemCount: profileDataList.length,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: kDefaultPadding / 2),
        ),
        _mediaGridDelegate(context: context),
      ],
    );
  }

  Widget _mediaGridDelegate({
    required BuildContext context,
  }) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SliverToBoxAdapter(
            child: MediaPlaceholder(),
          );
        }

        if (state.content.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyList(
              description: context.t
                  .userNoNotes(name: state.user.getName())
                  .capitalizeFirst(),
              icon: FeatureIcons.note,
            ),
          );
        }

        return ProfileMediaGrid(content: state.content);
      },
    );
  }

  /// Sorts media content to prioritize vertical videos for large tiles (position 0 in each group of 5)
  /// Priority order for large tiles: vertical videos > images > horizontal videos
}

class ProfileMediaGrid extends HookWidget {
  const ProfileMediaGrid({
    super.key,
    required this.content,
  });

  final List<Event> content;

  @override
  Widget build(BuildContext context) {
    final sortedContent = useMemoized(
      () {
        return _sortMediaContent(content);
      },
    );

    return SliverGrid(
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: [
          const QuiltedGridTile(2, 1), // Item 0: Large vertical
          const QuiltedGridTile(1, 1), // Item 1: Small
          const QuiltedGridTile(1, 1), // Item 2: Small
          const QuiltedGridTile(1, 1), // Item 3: Small
          const QuiltedGridTile(1, 1), // Item 4: Small
        ],
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = sortedContent.elementAt(index);
          final positionInPattern = index % 10;

          final isLargeTile = positionInPattern == 0 || positionInPattern == 7;

          // Handle pictures
          if (event.kind == EventKind.PICTURE) {
            final picture = PictureModel.fromEvent(event);

            return GestureDetector(
              onTap: () {
                YNavigator.pushPage(
                  context,
                  (context) => PictureView(picture: picture),
                );
              },
              onLongPress: () {
                openGallery(
                  source: MapEntry(picture.getUrl(), UrlType.image),
                  index: 0,
                  context: context,
                );
              },
              child: CommonThumbnail(
                image: picture.getUrl(),
                radius: 0,
                isRound: false,
              ),
            );
          }

          final video = VideoModel.fromEvent(event);

          return isLargeTile
              ? FeedVideoPlayer(
                  link: video.url,
                  fallbackUrls: video.fallbackUrls,
                  video: video,
                )
              : VideoCard(video: video);
        },
        childCount: sortedContent.length,
      ),
    );
  }

  List<Event> _sortMediaContent(List<Event> content) {
    if (content.length <= 5) {
      // For small lists, just sort with priority
      return _sortByPriority(content);
    }

    final result = <Event>[];

    // Process in groups of 5
    for (int i = 0; i < content.length; i += 5) {
      final groupEnd = (i + 5 < content.length) ? i + 5 : content.length;
      final group = content.sublist(i, groupEnd);

      // Find the best item for position 0 (large tile) based on priority
      Event? bestForLargeTile;
      int bestIndex = -1;
      int bestPriority = -1;

      for (int j = 0; j < group.length; j++) {
        final priority = _getMediaPriority(group[j]);
        if (priority > bestPriority) {
          bestPriority = priority;
          bestForLargeTile = group[j];
          bestIndex = j;
        }
      }

      // Reorder this group: best item first, then the rest
      if (bestForLargeTile != null && bestIndex != -1) {
        result.add(bestForLargeTile);
        for (int j = 0; j < group.length; j++) {
          if (j != bestIndex) {
            result.add(group[j]);
          }
        }
      } else {
        result.addAll(group);
      }
    }

    return result;
  }

  /// Sort a list by priority (for small lists)
  List<Event> _sortByPriority(List<Event> content) {
    final sorted = List<Event>.from(content);
    sorted.sort((a, b) => _getMediaPriority(b).compareTo(_getMediaPriority(a)));
    return sorted;
  }

  /// Returns priority score for media type
  /// Higher score = higher priority for large tiles
  /// - Vertical videos: 3 (highest priority)
  /// - Images: 2
  /// - Horizontal videos: 1 (lowest priority)
  int _getMediaPriority(Event event) {
    if (VideoModel.isVideo(event.kind)) {
      final video = VideoModel.fromEvent(event);
      return video.isHorizontal ? 1 : 3;
    } else if (event.kind == EventKind.PICTURE) {
      return 2;
    }
    return 0;
  }
}

class VideoCard extends HookWidget {
  const VideoCard({
    super.key,
    required this.video,
    this.isMediaFeed = false,
  });

  final VideoModel video;
  final bool isMediaFeed;

  @override
  Widget build(BuildContext context) {
    final videoThumbnail = video.thumbnail;
    final memThumbnail = useState<String?>(null);

    useMemoized(
      () {
        if (videoThumbnail.isEmpty) {
          VideoThumbnailQueueManager.instance.addRequest(
            QueueRequest(
              video.url,
              (data) {
                if (context.mounted) {
                  memThumbnail.value = data;
                }
              },
            ),
          );
        }
      },
    );

    return GestureDetector(
      onTap: () {
        YNavigator.pushPage(
          context,
          (context) => video.isHorizontal
              ? HorizontalVideoView(video: video)
              : VerticalVideoView(video: video),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoThumbnail.isNotEmpty ||
              (memThumbnail.value != null && memThumbnail.value!.isNotEmpty))
            CommonThumbnail(
              image: videoThumbnail,
              memoryUrl: memThumbnail.value,
              radius: isMediaFeed ? kDefaultPadding / 2 : 0,
              isRound: isMediaFeed,
              fit: BoxFit.cover,
            )
          else
            Center(
              child: SpinKitCircle(
                size: 20,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
          if (!isMediaFeed)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoThumbnailCard extends HookWidget {
  const VideoThumbnailCard({
    super.key,
    required this.url,
    required this.onTap,
  });

  final String url;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final memThumbnail = useState<String?>(null);

    useMemoized(() {
      VideoThumbnailQueueManager.instance.addRequest(
        QueueRequest(
          url,
          (data) {
            if (context.mounted) {
              memThumbnail.value = data;
            }
          },
        ),
      );
    }, [url]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: kBlack,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (memThumbnail.value != null && memThumbnail.value!.isNotEmpty)
              CommonThumbnail(
                image: '',
                memoryUrl: memThumbnail.value,
                radius: kDefaultPadding / 2,
                isRound: true,
                fit: BoxFit.contain,
              )
            else
              Center(
                child: SvgPicture.asset(
                  FeatureIcons.videoLink,
                  width: 30,
                  height: 30,
                  colorFilter: const ColorFilter.mode(
                    kWhite,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            Positioned(
              top: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
