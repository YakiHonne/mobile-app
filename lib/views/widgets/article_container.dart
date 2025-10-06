// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../utils/utils.dart';
import 'content_container.dart';

class ArticleContainer extends HookWidget {
  const ArticleContainer({
    super.key,
    required this.article,
    required this.isFollowing,
    required this.highlightedTag,
    required this.isBookmarked,
    required this.onClicked,
    this.isMuted,
    this.reduceImageSize = false,
  });

  final Article article;
  final bool isFollowing;
  final String highlightedTag;
  final bool isBookmarked;
  final bool? isMuted;
  final Function() onClicked;
  final bool reduceImageSize;

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      id: article.identifier,
      isSensitive: article.isSensitive,
      isFollowing: isFollowing,
      createdAt: article.createdAt,
      event: article,
      kind: EventKind.LONG_FORM,
      title: article.title,
      thumbnail: article.image,
      description: article.summary,
      isBookmarked: isBookmarked,
      pubkey: article.pubkey,
      contentType: ContentType.article,
      onClicked: onClicked,
      reduceImageSize: reduceImageSize,
      attachedText:
          context.t.readTime(time: estimateReadingTime(article.content)),
      onProfileClicked: () {
        openProfileFastAccess(context: context, pubkey: article.pubkey);
      },
      isMuted: isMuted,
    );
  }
}

class PublishDateRow extends StatelessWidget {
  const PublishDateRow({
    super.key,
    required this.publishedAtDate,
    required this.createdAtDate,
  });

  final DateTime publishedAtDate;
  final DateTime createdAtDate;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.t
          .createdAtEditedAt(
            date1: dateFormat2.format(publishedAtDate),
            date2: dateFormat2.format(createdAtDate),
          )
          .capitalizeFirst(),
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
      triggerMode: TooltipTriggerMode.tap,
      child: Text(
        dateFormat3.format(publishedAtDate),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
