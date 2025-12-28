import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:nostr_core_enhanced/utils/string_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../common/functions/queue_manager.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../article_view/article_view.dart';
import '../curation_view/curation_view.dart';
import '../gallery_view/gallery_view.dart';
import '../profile_view/widgets/profile_media.dart';
import '../smart_widgets_view/widgets/global_smart_widget_container.dart';
import '../smart_widgets_view/widgets/smart_widget_checker.dart';
import 'buttons_containers_widgets.dart';
import 'common_thumbnail.dart';
import 'data_providers.dart';
import 'media_components/horizontal_video_view.dart';
import 'media_components/picture_view.dart';
import 'media_components/vertical_video_view.dart';
import 'profile_picture.dart';

class ParsedMediaContainer extends HookWidget {
  const ParsedMediaContainer({
    super.key,
    required this.baseEventModel,
    this.canBeAccesed = true,
    this.inverseContainerColor,
    this.renderSmartWidget = true,
  });

  final bool canBeAccesed;
  final BaseEventModel baseEventModel;
  final bool? inverseContainerColor;
  final bool renderSmartWidget;

  @override
  Widget build(BuildContext context) {
    final image = useState('');
    final title = useState('');
    final description = useState('');

    useMemoized(
      () {
        final data = getBaseEventModelData(baseEventModel);

        if (data.isNotEmpty) {
          image.value = data[0];
          title.value = data[1];
          description.value = data[2];
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: baseEventModel is SmartWidget && renderSmartWidget
          ? GlobalSmartWidgetContainer(
              smartWidgetModel: baseEventModel as SmartWidget,
              canPerformOwnerActions: false,
              isMinimised: true,
            )
          : isMediaModel(baseEventModel)
              ? MediaFeedContainer(item: baseEventModel)
              : GestureDetector(
                  onTap: canBeAccesed
                      ? () {
                          if (baseEventModel is Article) {
                            YNavigator.pushPage(
                              context,
                              (context) => ArticleView(
                                  article: baseEventModel as Article),
                            );
                          } else if (baseEventModel is VideoModel) {
                            YNavigator.pushPage(context, (context) {
                              final video = baseEventModel as VideoModel;
                              if (video.kind == EventKind.VIDEO_HORIZONTAL) {
                                return HorizontalVideoView(video: video);
                              } else {
                                return VerticalVideoView(video: video);
                              }
                            });
                          } else if (baseEventModel is Curation) {
                            YNavigator.pushPage(
                              context,
                              (context) => CurationView(
                                  curation: baseEventModel as Curation),
                            );
                          } else if (baseEventModel is PictureModel) {
                            YNavigator.pushPage(
                              context,
                              (context) => PictureView(
                                  picture: baseEventModel as PictureModel),
                            );
                          } else if (baseEventModel is SmartWidget) {
                            YNavigator.pushPage(
                              context,
                              (context) => SmartWidgetChecker(
                                swm: baseEventModel as SmartWidget,
                                naddr:
                                    (baseEventModel as SmartWidget).getScheme(),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(kDefaultPadding / 1.5),
                      color: inverseContainerColor != null
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Theme.of(context).cardColor,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        _thumbnail(image),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding / 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _createdAt(context),
                                const SizedBox(
                                  height: kDefaultPadding / 4,
                                ),
                                Text(
                                  title.value,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(
                                  height: kDefaultPadding / 2,
                                ),
                                _metadataRow(context),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  MetadataProvider _metadataRow(BuildContext context) {
    return MetadataProvider(
      pubkey: baseEventModel.pubkey,
      search: false,
      child: (metadata, isNip05Valid) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfilePicture2(
              image: metadata.picture,
              pubkey: metadata.pubkey,
              size: 15,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            Flexible(
              child: Text(
                metadata.getName(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      height: 1,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNip05Valid) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 10,
                height: 10,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Row _createdAt(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Text(
          StringUtil.formatTimeDifference(
            baseEventModel.createdAt,
          ),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        if (baseEventModel is! SmartWidget &&
            baseEventModel is! PictureModel) ...[
          DotContainer(
            color: Theme.of(context).highlightColor,
            size: 3,
            isNotMarging: true,
          ),
          Text(
            getAttachedText(context),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ]
      ],
    );
  }

  Stack _thumbnail(ValueNotifier<String> image) {
    return Stack(
      children: [
        CommonThumbnail(
          image: image.value,
          width: 85,
          height: 90,
          isRound: true,
          radius: kDefaultPadding / 2,
          isLeftRound: true,
        ),
        if (baseEventModel is VideoModel || baseEventModel is SmartWidget)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(
                  kDefaultPadding / 3,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBlack.withValues(alpha: 0.7),
                ),
                child: baseEventModel is VideoModel
                    ? const Icon(
                        Icons.play_arrow_rounded,
                        color: kWhite,
                      )
                    : SvgPicture.asset(
                        FeatureIcons.smartWidget,
                        colorFilter: const ColorFilter.mode(
                          kWhite,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  String getAttachedText(BuildContext context) {
    if (baseEventModel is Article) {
      return context.t.readTime(
        time: estimateReadingTime((baseEventModel as Article).content),
      );
    } else if (baseEventModel is Curation) {
      final curation = baseEventModel as Curation;

      return curation.kind == EventKind.CURATION_ARTICLES
          ? context.t
              .articlesNum(number: curation.eventsIds.length.toString())
              .capitalizeFirst()
          : context.t.videosNum(number: curation.eventsIds.length.toString())
        ..capitalizeFirst();
    } else {
      return context.t.watchNow.capitalizeFirst();
    }
  }
}

class UrlPreviewContainer extends HookWidget {
  const UrlPreviewContainer({
    super.key,
    required this.url,
    this.inverseContainerColor,
  });

  final String url;
  final bool? inverseContainerColor;

  @override
  Widget build(BuildContext context) {
    final image = useState('');
    final title = useState('');
    final description = useState('');

    useEffect(() {
      void updateState(dynamic data) {
        if (context.mounted) {
          title.value = data.title ?? '';
          description.value = data.description ?? '';
          image.value = data.image?.url ?? '';
        }
      }

      PreviewQueueManager.instance.addRequest(
        QueueRequest(
          url,
          updateState,
        ),
      );

      return null; // No cleanup needed
    }, [url]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: GestureDetector(
        onTap: () => openWebPage(url: url),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
            color: inverseContainerColor != null
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              _thumbnail(image),
              _infoColumn(context, title, description),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _infoColumn(BuildContext context, ValueNotifier<String> title,
      ValueNotifier<String> description) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getDomainFromUrl(url),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              height: kDefaultPadding / 3,
            ),
            Text(
              title.value.isEmpty
                  ? context.t.noTitle.capitalizeFirst()
                  : title.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).primaryColorDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              description.value.isEmpty
                  ? context.t.noDescription.capitalizeFirst()
                  : description.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  CommonThumbnail _thumbnail(ValueNotifier<String> image) {
    return CommonThumbnail(
      image: image.value,
      width: 80,
      height: 80,
      isRound: true,
      radius: kDefaultPadding / 2,
      isLeftRound: true,
    );
  }
}

class YoutubeVideoContainer extends HookWidget {
  const YoutubeVideoContainer({
    super.key,
    required this.url,
    this.inverseContainerColor,
  });

  final String url;
  final bool? inverseContainerColor;

  @override
  Widget build(BuildContext context) {
    final image = useState('');
    final title = useState('');
    final description = useState('');
    final isVideoActive = useState(false);

    useEffect(() {
      void updateState(dynamic data) {
        if (context.mounted) {
          title.value = data.title ?? '';
          description.value = data.description ?? '';
          image.value = data.image?.url ?? '';
        }
      }

      PreviewQueueManager.instance.addRequest(
        QueueRequest(
          url,
          updateState,
        ),
      );

      return null; // No cleanup needed
    }, [url]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: GestureDetector(
        onTap: () {
          if (!isVideoActive.value) {
            isVideoActive.value = true;
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
            color: inverseContainerColor != null
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 11,
            child: isVideoActive.value
                ? YoutubeVideoPlayer(url: url)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _thumbnail(image)),
                      _infoColumn(context, title, description),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, ValueNotifier<String> title,
      ValueNotifier<String> description) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.value.isEmpty
                ? context.t.noTitle.capitalizeFirst()
                : title.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            description.value.isEmpty
                ? context.t.noDescription.capitalizeFirst()
                : description.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(ValueNotifier<String> image) {
    return Stack(
      children: [
        Positioned.fill(
          child: CommonThumbnail(
            image: image.value,
            width: double.infinity,
            radius: kDefaultPadding / 1.5,
            isTopRound: true,
          ),
        ),
        Align(
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kBlack.withValues(alpha: 0.7),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 40,
              color: kWhite,
            ),
          ),
        ),
      ],
    );
  }
}

class YoutubeVideoPlayer extends HookWidget {
  const YoutubeVideoPlayer({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() {
      final id = getYoutubeVideoId(url);
      return YoutubePlayerController(
        initialVideoId: id,
      );
    }, [url]);

    // Dispose when widget unmounts
    useEffect(() {
      return controller.dispose;
    }, [controller]);

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(kDefaultPadding / 1.5),
      child: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: kRed,
        actionsPadding: const EdgeInsetsGeometry.all(kDefaultPadding / 4),
        progressColors: const ProgressBarColors(
          playedColor: kRed,
          handleColor: kRed,
        ),
      ),
    );
  }
}

class MediaFeedContainer extends HookWidget {
  const MediaFeedContainer({super.key, required this.item});

  final BaseEventModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item is PictureModel) {
          YNavigator.pushPage(
            context,
            (context) => PictureView(picture: item as PictureModel),
          );
        } else {
          final video = item as VideoModel;
          YNavigator.pushPage(
            context,
            (context) => video.isHorizontal
                ? HorizontalVideoView(video: video)
                : VerticalVideoView(video: video),
          );
        }
      },
      child: SizedBox(
        width: 60.w,
        child: AspectRatio(
          aspectRatio: 9 / 11,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: Builder(
              builder: (context) {
                if (item is PictureModel) {
                  final picture = item as PictureModel;
                  return _pictureContainer(context, picture);
                }

                final video = item as VideoModel;

                return _videoContainer(video, context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Stack _videoContainer(VideoModel video, BuildContext context) {
    return Stack(
      children: [
        VideoCard(video: video, isMediaFeed: true),
        _gradient(),
        _info(
          context,
          video.summary.isNotEmpty ? video.summary : video.title,
          true,
        ),
      ],
    );
  }

  GestureDetector _pictureContainer(
      BuildContext context, PictureModel picture) {
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
      child: Stack(
        children: [
          const SizedBox.expand(),
          Positioned.fill(
            child: CommonThumbnail(
              image: picture.getUrl(),
              radius: kDefaultPadding / 2,
              isRound: true,
            ),
          ),
          _gradient(),
          _info(
            context,
            picture.content.isNotEmpty ? picture.content : picture.title,
            false,
          ),
        ],
      ),
    );
  }

  Positioned _info(BuildContext context, String description, bool isVideo) {
    return Positioned(
      bottom: kDefaultPadding / 2,
      left: kDefaultPadding / 2,
      right: kDefaultPadding / 2,
      child: _infoColumn(
        context,
        description,
        isVideo,
      ),
    );
  }

  Positioned _gradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0, 0.5],
            colors: [
              kBlack.withValues(alpha: 0.7),
              kTransparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(
    BuildContext context,
    String description,
    bool isVideo,
  ) {
    return MetadataProvider(
      pubkey: item.pubkey,
      child: (metadata, isNip05Valid) {
        return Row(
          spacing: kDefaultPadding / 4,
          children: [
            ProfilePicture2(
              image: metadata.picture,
              pubkey: metadata.pubkey,
              size: 25,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
            Expanded(
              child: _infoSmallColumn(
                  metadata, context, isNip05Valid, description),
            ),
            if (isVideo)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Theme.of(context).primaryColorDark,
                  size: 16,
                ),
              ),
          ],
        );
      },
    );
  }

  Column _infoSmallColumn(Metadata metadata, BuildContext context,
      bool isNip05Valid, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                metadata.getName(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      height: 1,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNip05Valid) ...[
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              SvgPicture.asset(
                FeatureIcons.verified,
                width: 10,
                height: 10,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ],
        ),
        Text(
          description.isEmpty
              ? context.t.noDescription.capitalizeFirst()
              : description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
      ],
    );
  }
}
