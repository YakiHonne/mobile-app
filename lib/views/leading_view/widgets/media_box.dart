// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/leading_cubit/leading_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';
import '../../widgets/pull_down_global_button.dart';
import '../../widgets/video_components/horizontal_video_view.dart';
import '../../widgets/video_components/vertical_video_view.dart';

class MediaBox extends StatelessWidget {
  const MediaBox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadingCubit, LeadingState>(
      builder: (context, state) {
        return SizedBox(
          height: 250,
          child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 2,
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = state.media[index];

              if (item is Article) {
                final article = item;

                return _leadingArticleContainer(article, context);
              } else {
                final video = item as VideoModel;

                return _leadingVideoContainer(video, context);
              }
            },
            itemCount: state.media.length,
          ),
        );
      },
    );
  }

  LeadingMediaContainer _leadingVideoContainer(
      VideoModel video, BuildContext context) {
    return LeadingMediaContainer(
      image: video.thumbnail,
      title: video.title,
      attachedText: context.t.watchNow,
      pubkey: video.pubkey,
      model: video,
      identifier: video.id,
      type: ContentType.video,
      onClick: () => YNavigator.pushPage(
        context,
        (context) => video.isHorizontal
            ? HorizontalVideoView(video: video)
            : VerticalVideoView(video: video),
      ),
    );
  }

  LeadingMediaContainer _leadingArticleContainer(
      Article article, BuildContext context) {
    return LeadingMediaContainer(
      image: article.image,
      title: article.title,
      attachedText: context.t.readTime(
        time: estimateReadingTime(article.content).toString(),
      ),
      pubkey: article.pubkey,
      model: article,
      identifier: article.identifier,
      type: ContentType.article,
      onClick: () => YNavigator.pushPage(
        context,
        (context) => ArticleView(article: article),
      ),
    );
  }
}

class LeadingMediaContainer extends HookWidget {
  const LeadingMediaContainer({
    super.key,
    required this.image,
    required this.title,
    required this.attachedText,
    required this.pubkey,
    required this.identifier,
    required this.type,
    required this.onClick,
    required this.model,
  });

  final String image;
  final String title;
  final String attachedText;
  final String pubkey;
  final String identifier;
  final ContentType type;
  final BaseEventModel model;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        metadataCubit.requestMetadata(pubkey);
      },
    );

    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: AspectRatio(
        aspectRatio: 1 / 1.2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              _thumbnailContainer(context),
              const Divider(
                thickness: 0.3,
                height: 0,
              ),
              const SizedBox(
                height: kDefaultPadding / 8,
              ),
              _infoContainer(context),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _infoContainer(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetadataProvider(
              pubkey: pubkey,
              child: (metadata, isNip05Valid) {
                return Row(
                  children: [
                    ProfilePicture3(
                      size: 20,
                      pubkey: metadata.pubkey,
                      image: metadata.picture,
                      padding: 0,
                      strokeWidth: 0,
                      strokeColor: kTransparent,
                      onClicked: () {},
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    Expanded(
                      child: Text(
                        metadata.getName(),
                        style:
                            Theme.of(context).textTheme.bodySmall!.copyWith(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    attachedText,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: Theme.of(context).primaryColor),
                  ),
                ),
                PullDownGlobalButton(
                  model: model,
                  enableBookmark: true,
                  enableShare: true,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  SizedBox _thumbnailContainer(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CommonThumbnail(
              image: image,
              placeholder: getRandomPlaceholder(
                input: title,
                isPfp: false,
              ),
              width: double.infinity,
              height: 110,
              radius: kDefaultPadding / 2,
              isRound: true,
              isTopRound: true,
              useDefaultNoMedia: false,
            ),
          ),
          if (attachedText == context.t.watchNow)
            Center(
              child: Container(
                padding: const EdgeInsets.all(
                  kDefaultPadding / 3,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBlack.withValues(alpha: 0.7),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: kWhite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
