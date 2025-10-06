// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../models/video_model.dart';
import '../../utils/utils.dart';
import 'content_container.dart';

class VideoCommonContainer extends HookWidget {
  const VideoCommonContainer({
    super.key,
    required this.video,
    required this.onTap,
    this.isBookmarked,
    this.selectedTag,
    this.isMuted,
    this.isFollowing,
    this.reduceImageSize = false,
  });

  final VideoModel video;
  final Function() onTap;
  final bool? isFollowing;
  final bool? isBookmarked;
  final bool? isMuted;
  final String? selectedTag;
  final bool reduceImageSize;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: ContentContainer(
        id: video.id,
        event: video,
        kind: video.kind,
        isSensitive: false,
        isFollowing: isFollowing ?? false,
        createdAt: video.createdAt,
        title: video.title,
        thumbnail: video.thumbnail,
        description: video.summary,
        isBookmarked: isBookmarked ?? false,
        pubkey: video.pubkey,
        contentType: ContentType.video,
        onClicked: onTap,
        attachedText: context.t.watchNow.capitalizeFirst(),
        reduceImageSize: reduceImageSize,
        onProfileClicked: () {
          openProfileFastAccess(context: context, pubkey: video.pubkey);
        },
        isMuted: isMuted,
      ),
    );
  }
}
