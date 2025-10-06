// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
// import 'package:last_pod_player/last_pod_player.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/horizontal_video_cubit/horizontal_video_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../buttons_containers_widgets.dart';
import '../content_stats.dart';
import '../custom_app_bar.dart';
import '../data_providers.dart';
import '../link_previewer.dart';
import '../no_content_widgets.dart';
import '../profile_picture.dart';
import 'video_description.dart';

class VerticalVideoView extends StatelessWidget {
  static const routeName = '/verticalVideoView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments! as List;

    return CupertinoPageRoute(
      builder: (_) => VerticalVideoView(
        video: items[0],
      ),
    );
  }

  final VideoModel video;

  VerticalVideoView({
    super.key,
    required this.video,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Video view');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HorizontalVideoCubit(
        video: video,
      )..initView(),
      child: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
        builder: (context, state) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: kBlack,
            appBar: CustomAppBar(
              title: context.t.video.capitalizeFirst(),
              color: kTransparent,
            ),
            bottomNavigationBar: _bottomNavBar(context),
            body: BlocBuilder<HorizontalVideoCubit, HorizontalVideoState>(
              builder: (context, state) {
                return isUserMuted(video.pubkey)
                    ? Center(
                        child: MutedUserContent(
                          pubkey: video.pubkey,
                        ),
                      )
                    : _content(context, state);
              },
            ),
          );
        },
      ),
    );
  }

  Stack _content(BuildContext context, HorizontalVideoState state) {
    return Stack(
      children: [
        _videoPlayer(),
        _gradient(),
        Positioned(
          bottom: kDefaultPadding,
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _videoInfo(context, state),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    _videoInfoColumn(context, state),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    _videoTags(),
                  ],
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
            ],
          ),
        )
      ],
    );
  }

  GestureDetector _videoInfoColumn(
      BuildContext context, HorizontalVideoState state) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) {
            return HVDescription(
              createdAt: video.createdAt,
              description: video.summary,
              title: video.title,
              tags: video.tags,
              upvotes: state.votes.values
                  .map((element) => element.vote)
                  .toList()
                  .length
                  .toString(),
              views: state.viewsCount.length.toString(),
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (video.title.isNotEmpty) ...[
            Text(
              video.title.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Theme.of(context).primaryColorLight,
                    blurRadius: 2,
                  )
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          _videoStats(context, state),
        ],
      ),
    );
  }

  Builder _videoTags() {
    return Builder(
      builder: (context) {
        final tags = video.tags;

        return SizedBox(
          height: 24,
          child: ScrollShadow(
            color: Theme.of(context).primaryColorLight,
            size: 10,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              separatorBuilder: (context, index) {
                return const SizedBox(
                  width: kDefaultPadding / 4,
                );
              },
              itemBuilder: (context, index) {
                final tag = tags[index];
                if (tag.trim().isEmpty) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: InfoRoundedContainer(
                    tag: tag,
                    useOpacity: true,
                    color: Theme.of(context).highlightColor,
                    textColor: Theme.of(context).primaryColorDark,
                    onClicked: () {
                      YNavigator.pushPage(
                        context,
                        (context) => SearchView(
                          search: tag,
                          index: 3,
                        ),
                        type: PushPageType.opacity,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Row _videoStats(BuildContext context, HorizontalVideoState state) {
    return Row(
      children: [
        Text(
          context.t
              .viewsNumber(
                number: state.viewsCount.length.toString(),
              )
              .capitalizeFirst(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            shadows: [
              Shadow(
                color: Theme.of(context).primaryColorLight,
                blurRadius: 2,
              )
            ],
          ),
        ),
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 3,
        ),
        Text(
          StringUtil.formatTimeDifference(
            video.createdAt,
          ),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            shadows: [
              Shadow(
                color: Theme.of(context).primaryColorLight,
                blurRadius: 2,
              )
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Text(
          context.t.moreDots.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Theme.of(context).primaryColorLight,
                blurRadius: 2,
              )
            ],
          ),
        ),
      ],
    );
  }

  MetadataProvider _videoInfo(
      BuildContext context, HorizontalVideoState state) {
    return MetadataProvider(
      pubkey: video.pubkey,
      search: false,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture2(
              size: 30,
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
            Flexible(
              child: Text(
                metadata.getName(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: kWhite,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).primaryColorLight,
                      blurRadius: 2,
                    )
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNip05Valid)
              Row(
                children: [
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  SvgPicture.asset(
                    FeatureIcons.verified,
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(
                      kMainColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Builder(
              builder: (context) {
                final isDisabled = !canSign() || state.isSameArticleAuthor;

                return AbsorbPointer(
                  absorbing: isDisabled,
                  child: TextButton(
                    onPressed: () {
                      if (!canSign()) {
                      } else {
                        context
                            .read<HorizontalVideoCubit>()
                            .setFollowingState();
                      }
                    },
                    style: TextButton.styleFrom(
                      visualDensity: const VisualDensity(
                        vertical: -1,
                      ),
                      backgroundColor: isDisabled
                          ? Theme.of(context).highlightColor
                          : state.isFollowingAuthor
                              ? Theme.of(context).cardColor
                              : kMainColor,
                    ),
                    child: Text(
                      state.isFollowingAuthor
                          ? context.t.unfollow.capitalizeFirst()
                          : context.t.follow.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: state.isFollowingAuthor
                                ? Theme.of(context).primaryColorDark
                                : kWhite,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            NewBorderedIconButton(
              onClicked: () {
                showModalBottomSheet(
                  elevation: 0,
                  context: context,
                  builder: (_) {
                    return SendZapsView(
                      metadata: state.author,
                      isZapSplit: video.zapsSplits.isNotEmpty,
                      zapSplits: video.zapsSplits,
                      eventId: state.video.id,
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: FeatureIcons.zaps,
              buttonStatus: !state.canBeZapped
                  ? ButtonStatus.disabled
                  : ButtonStatus.inactive,
            ),
          ],
        );
      },
    );
  }

  Positioned _gradient() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kBlack,
                kBlack.withValues(alpha: 0.1),
                kTransparent,
                kBlack.withValues(alpha: 0.1),
                kBlack,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }

  Visibility _bottomNavBar(BuildContext context) {
    return Visibility(
      visible: !isUserMuted(video.pubkey),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
        child: Column(
          children: [
            const Divider(
              height: 0,
              thickness: 0.5,
            ),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: ContentStats(
                attachedEvent: video,
                pubkey: video.pubkey,
                kind: video.kind,
                identifier: video.id,
                createdAt: video.createdAt,
                title: video.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LayoutBuilder _videoPlayer() {
    return LayoutBuilder(
      builder: (context, constraints) => CustomVideoPlayer(
        link: video.url,
        ratio: constraints.maxWidth / constraints.maxHeight,
        removePadding: true,
        removeBorders: true,
        removeControls: true,
        autoPlay: true,
      ),
    );
  }
}
