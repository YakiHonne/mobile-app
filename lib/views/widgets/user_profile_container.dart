// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:numeral/numeral.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../utils/utils.dart';
import 'data_providers.dart';
import 'profile_picture.dart';

class UserProfileContainer extends HookWidget {
  const UserProfileContainer({
    super.key,
    required this.pubkey,
    required this.currentUserPubKey,
    required this.isFollowing,
    required this.isDisabled,
    required this.onClicked,
    required this.zaps,
    required this.isPending,
    this.message = '',
  });

  final String pubkey;
  final String currentUserPubKey;
  final bool isFollowing;
  final bool isDisabled;
  final bool isPending;
  final String message;
  final num zaps;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 10.w : 0,
          ),
          child: Row(
            children: [
              if (zaps != 0) ...[
                _zapAmount(context),
              ],
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              ProfilePicture2(
                size: 35,
                image: metadata.picture,
                pubkey: metadata.pubkey,
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
                width: kDefaultPadding / 2,
              ),
              _zapInfo(metadata, context),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              AbsorbPointer(
                absorbing: isDisabled,
                child: TextButton(
                  onPressed: onClicked,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    backgroundColor: isDisabled
                        ? Theme.of(context).highlightColor
                        : isFollowing
                            ? Theme.of(context).cardColor
                            : Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    isPending
                        ? isFollowing
                            ? context.t.pendingUnfollowing.capitalizeFirst()
                            : context.t.pendingFollowing.capitalizeFirst()
                        : isFollowing
                            ? context.t.unfollow.capitalizeFirst()
                            : context.t.follow.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: isFollowing
                              ? Theme.of(context).primaryColorDark
                              : kWhite,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Expanded _zapInfo(Metadata metadata, BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _zapMessage(context, metadata),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _zapMessage(BuildContext context, Metadata metadata) {
    return Container(
      decoration: message.isNotEmpty
          ? BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
            )
          : null,
      padding: message.isNotEmpty
          ? const EdgeInsets.all(kDefaultPadding / 3)
          : EdgeInsets.zero,
      margin: message.isNotEmpty
          ? const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 4,
            )
          : EdgeInsets.zero,
      child: Text(
        message.isNotEmpty ? message : metadata.about,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  SizedBox _zapAmount(BuildContext context) {
    return SizedBox(
      width: 55,
      child: Row(
        children: [
          SvgPicture.asset(
            FeatureIcons.zapAmount,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(nostrRepository.currentContext()).primaryColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Expanded(
            child: Text(
              zaps.numeral(digits: 0),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserNoteStatContainer extends HookWidget {
  const UserNoteStatContainer({
    super.key,
    required this.pubkey,
    required this.currentUserPubKey,
    required this.isFollowing,
    required this.isDisabled,
    required this.isPending,
    required this.event,
    required this.onClicked,
  });

  final String pubkey;
  final String currentUserPubKey;
  final bool isFollowing;
  final bool isDisabled;
  final bool isPending;
  final Event event;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      loadNip05: false,
      child: (metadata, isNip05Valid) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 10.w : 0,
          ),
          child: Row(
            children: [
              if (event.kind == EventKind.REACTION)
                ReactionIcon(event: event)
              else if (event.kind == EventKind.REPOST)
                SvgPicture.asset(
                  FeatureIcons.repost,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                )
              else
                SvgPicture.asset(
                  FeatureIcons.quote,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              ProfilePicture2(
                size: 35,
                image: metadata.picture,
                pubkey: metadata.pubkey,
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
                width: kDefaultPadding / 2,
              ),
              _userInfo(metadata, context),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              _isFollowing(context),
            ],
          ),
        );
      },
    );
  }

  AbsorbPointer _isFollowing(BuildContext context) {
    return AbsorbPointer(
      absorbing: isDisabled,
      child: TextButton(
        onPressed: onClicked,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: isDisabled
              ? Theme.of(context).highlightColor
              : isFollowing
                  ? Theme.of(context).cardColor
                  : Theme.of(context).primaryColor,
        ),
        child: Text(
          isPending
              ? isFollowing
                  ? context.t.pendingUnfollowing.capitalizeFirst()
                  : context.t.pendingFollowing.capitalizeFirst()
              : isFollowing
                  ? context.t.unfollow.capitalizeFirst()
                  : context.t.follow.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color:
                    isFollowing ? Theme.of(context).primaryColorDark : kWhite,
              ),
        ),
      ),
    );
  }

  Expanded _userInfo(Metadata metadata, BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metadata.about.trim().isNotEmpty)
                  Text(
                    metadata.about.trim(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReactionIcon extends StatelessWidget {
  const ReactionIcon({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final icon = getIcon(event);
    final emoji = getEmoji(event);
    final imageUrl = getCustomEmoji(event);

    if (emoji != null) {
      return _emoji(emoji);
    } else if (imageUrl != null) {
      return _extendedImage(imageUrl, icon);
    } else {
      return _svgImage(icon);
    }
  }

  SvgPicture _svgImage(String icon) {
    return SvgPicture.asset(
      icon,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        Theme.of(nostrRepository.currentContext()).primaryColor,
        BlendMode.srcIn,
      ),
    );
  }

  SizedBox _emoji(String emoji) {
    return SizedBox(
      width: 20,
      height: 20,
      child: FittedBox(
        child: Text(
          emoji.trim(),
          style: const TextStyle(
            fontSize: 20 * 6,
            height: 1.0,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      ),
    );
  }

  ExtendedImage _extendedImage(String imageUrl, String icon) {
    return ExtendedImage.network(
      imageUrl,
      width: 20,
      height: 20,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 0.5,
                ),
              ),
            );

          case LoadState.failed:
            return SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(nostrRepository.currentContext()).primaryColor,
                BlendMode.srcIn,
              ),
            );

          case LoadState.completed:
            return null;
        }
      },
    );
  }

  String getIcon(Event? reactionEvent) {
    return reactionEvent != null
        ? FeatureIcons.heartFilled
        : FeatureIcons.heart;
  }

  String? getEmoji(Event? reactionEvent) {
    final emoji = reactionEvent != null &&
            reactionEvent.content.isNotEmpty &&
            reactionEvent.content != '+' &&
            reactionEvent.content != '-' &&
            reactionEvent.content.length <= 2
        ? reactionEvent.content
        : null;

    return emoji;
  }

  String? getCustomEmoji(Event? reactionEvent) {
    return reactionEvent != null &&
            reactionEvent.content.isNotEmpty &&
            reactionEvent.content.startsWith(':') &&
            reactionEvent.content.endsWith(':')
        ? reactionEvent.getCustomEmojiUrl(reactionEvent.content)
        : null;
  }
}
