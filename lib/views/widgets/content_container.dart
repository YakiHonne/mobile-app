// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/string_utils.dart';

import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../models/flash_news_model.dart';
import '../../utils/utils.dart';
import 'buttons_containers_widgets.dart';
import 'common_thumbnail.dart';
import 'content_stats.dart';
import 'data_providers.dart';
import 'muted_mark.dart';
import 'profile_picture.dart';

class ContentContainer extends HookWidget {
  final bool isSensitive;
  final bool isFollowing;
  final bool isBookmarked;
  final DateTime createdAt;
  final String title;
  final String description;
  final String thumbnail;
  final String pubkey;
  final ContentType contentType;
  final String id;
  final String attachedText;
  final BaseEventModel event;
  final int kind;
  final Function() onClicked;
  final Function() onProfileClicked;

  final bool reduceImageSize;
  final bool? isMuted;
  final String? extra;

  const ContentContainer({
    super.key,
    required this.isSensitive,
    required this.isFollowing,
    required this.isBookmarked,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.pubkey,
    required this.contentType,
    required this.id,
    required this.attachedText,
    required this.event,
    required this.kind,
    required this.onClicked,
    required this.onProfileClicked,
    this.reduceImageSize = false,
    this.isMuted,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final displaySensitiveContent = useState(false);

    final Widget main = BlocBuilder<MetadataCubit, MetadataState>(
      builder: (metadata, state) {
        return MetadataProvider(
          pubkey: pubkey,
          child: (metadata, nip05) => SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfilePicture3(
                      size: 30,
                      image: metadata.picture,
                      pubkey: metadata.pubkey,
                      padding: 0,
                      strokeWidth: 0,
                      strokeColor: kTransparent,
                      onClicked: onProfileClicked,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 3,
                    ),
                    _contentRow(metadata, context),
                    if (isMuted != null && isMuted!) ...[
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                      MutedMark(
                        kind: getRawContentName(contentType),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 4,
                      ),
                    ],
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                _infoRow(metadata),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                ContentStats(
                  attachedEvent: event,
                  pubkey: event.pubkey,
                  kind: kind,
                  identifier: id,
                  createdAt: event.createdAt,
                  title: title,
                  isInside: false,
                ),
              ],
            ),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: !isSensitive || displaySensitiveContent.value ? onClicked : null,
      behavior: HitTestBehavior.translucent,
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: isSensitive && !displaySensitiveContent.value,
              child: main,
            ),
            if (isSensitive && !displaySensitiveContent.value)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    border: Border.all(
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                  child: _blurredContainer(context, displaySensitiveContent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ClipRRect _blurredContainer(
      BuildContext context, ValueNotifier<bool> displaySensitiveContent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t.sensitiveContent.capitalizeFirst(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              TextButton(
                onPressed: () {
                  displaySensitiveContent.value = true;
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                ),
                child: Text(
                  context.t.reveal.capitalizeFirst(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _infoRow(Metadata metadata) {
    return Row(
      children: [
        _titleDesc(),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        _thumbnail(metadata),
      ],
    );
  }

  Expanded _titleDesc() {
    return Expanded(
      flex: 12,
      child: Builder(
        builder: (context) {
          final t = title.trim();
          final d = description.trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  return Text(
                    t,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  );
                },
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                d.isEmpty ? context.t.noDescription.capitalizeFirst() : d,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                      fontStyle:
                          d.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          );
        },
      ),
    );
  }

  Flexible _thumbnail(Metadata metadata) {
    return Flexible(
      flex: reduceImageSize ? 2 : 3,
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, cts) {
                  return CommonThumbnail(
                    image: thumbnail.isEmpty ? metadata.picture : thumbnail,
                    placeholder: getRandomPlaceholder(
                      input: id,
                      isPfp: false,
                    ),
                    width: cts.maxWidth,
                    height: cts.maxWidth,
                    radius: kDefaultPadding,
                    isRound: true,
                  );
                },
              ),
              if (contentType == ContentType.video)
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
        ),
      ),
    );
  }

  Expanded _contentRow(Metadata metadata, BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _userInfo(metadata, context),
                _createdAt(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row _createdAt(BuildContext context) {
    return Row(
      children: [
        Text(
          StringUtil.formatTimeDifference(createdAt),
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: Theme.of(context).highlightColor),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 3,
        ),
        Text(
          attachedText,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: kMainColor),
        ),
      ],
    );
  }

  Row _userInfo(Metadata metadata, BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w700,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (isFollowing) ...[
          const SizedBox(width: kDefaultPadding / 4),
          SvgPicture.asset(
            FeatureIcons.userFollowed,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ],
      ],
    );
  }
}

String getRawContentName(ContentType contentType) {
  if (contentType == ContentType.article) {
    return 'article';
  } else if (contentType == ContentType.curation) {
    return 'curation';
  } else if (contentType == ContentType.video) {
    return 'video';
  } else {
    return 'note';
  }
}
