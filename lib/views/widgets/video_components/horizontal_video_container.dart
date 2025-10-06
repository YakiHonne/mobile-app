// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/video_model.dart';
import '../../../utils/utils.dart';
import '../buttons_containers_widgets.dart';
import '../curation_container.dart';
import '../data_providers.dart';
import '../profile_picture.dart';
import '../pull_down_global_button.dart';

class HorizontalVideoContainer extends StatelessWidget {
  const HorizontalVideoContainer({
    super.key,
    required this.video,
    required this.onClicked,
  });

  final VideoModel video;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked,
      child: Padding(
        key: ValueKey(video.id),
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                _videoThumbnail(context),
                Positioned(
                  bottom: kDefaultPadding / 2,
                  right: kDefaultPadding / 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(300),
                      color: kBlack,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding / 6,
                    ),
                    child: Text(
                      formattedTime(timeInSecond: video.duration.toInt()),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: kWhite,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _videoMetadata(context)
          ],
        ),
      ),
    );
  }

  MetadataProvider _videoMetadata(BuildContext context) {
    return MetadataProvider(
      pubkey: video.pubkey,
      search: false,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture2(
              size: 40,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              reduceSize: true,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _videoInfo(context, metadata),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            PullDownGlobalButton(
              model: video,
              enableShare: true,
            ),
          ],
        );
      },
    );
  }

  Expanded _videoInfo(BuildContext context, Metadata metadata) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 8,
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DotContainer(
                color: Theme.of(context).highlightColor,
                size: 3,
              ),
              Text(
                StringUtil.formatTimeDifference(video.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          )
        ],
      ),
    );
  }

  AspectRatio _videoThumbnail(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: video.thumbnail,
        fit: BoxFit.cover,
        cacheManager: imagesCacheManager,
        memCacheWidth: MediaQuery.of(context).size.width.toInt(),
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        errorWidget: (context, url, error) => const NoThumbnailPlaceHolder(
          isError: true,
          isMonoColor: true,
          icon: '',
        ),
      ),
    );
  }
}
