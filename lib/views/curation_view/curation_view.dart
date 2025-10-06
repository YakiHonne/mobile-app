// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/curation_cubit/curation_cubit.dart';
import '../../logic/settings_cubit/settings_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/curation_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../utils/utils.dart';
import '../article_view/article_view.dart';
import '../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../widgets/article_container.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/content_renderer/content_renderer.dart';
import '../widgets/content_stats.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/data_providers.dart';
import '../widgets/empty_list.dart';
import '../widgets/no_content_widgets.dart';
import '../widgets/profile_picture.dart';
import '../widgets/video_common_container.dart';
import '../widgets/video_components/horizontal_video_view.dart';
import '../widgets/video_components/vertical_video_view.dart';

class CurationView extends HookWidget {
  static const routeName = '/curationView';
  static Route route(RouteSettings settings) {
    final curation = settings.arguments! as Curation;

    return CupertinoPageRoute(
      builder: (_) => CurationView(
        curation: curation,
      ),
    );
  }

  final Curation curation;

  CurationView({
    super.key,
    required this.curation,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Curation view');
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    return BlocProvider(
      create: (context) => CurationCubit(
        curation: curation,
        nostrRepository: context.read<NostrDataRepository>(),
      )..initView(),
      child: BlocBuilder<CurationCubit, CurationState>(
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(title: context.t.curation.capitalizeFirst()),
            bottomNavigationBar: Visibility(
              visible: !isUserMuted(curation.pubkey),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: SizedBox(
                height: kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    const Divider(
                      height: 0,
                      thickness: 0.5,
                    ),
                    SizedBox(
                      height: kBottomNavigationBarHeight,
                      child: ContentStats(
                        attachedEvent: curation,
                        pubkey: curation.pubkey,
                        kind: curation.kind,
                        identifier: curation.identifier,
                        createdAt: curation.createdAt,
                        title: curation.title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: isUserMuted(curation.pubkey)
                ? Center(
                    child: MutedUserContent(
                      pubkey: curation.pubkey,
                    ),
                  )
                : Stack(
                    children: [
                      CurationContentView(
                        scrollController: scrollController,
                        curation: curation,
                      ),
                      ResetScrollButton(scrollController: scrollController),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class CurationContentView extends StatelessWidget {
  const CurationContentView({
    super.key,
    required this.scrollController,
    required this.curation,
  });

  final ScrollController scrollController;
  final Curation curation;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Scrollbar(
      controller: scrollController,
      child: NestedScrollView(
        controller: scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _curationInfoContainer(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<CurationCubit, CurationState>(
                      buildWhen: (previous, current) =>
                          previous.articles != current.articles ||
                          previous.videos != current.videos,
                      builder: (context, state) {
                        final length = state.isArticlesCuration
                            ? state.articles.length
                            : state.videos.length;
                        return Text(
                          context.t.itemsNumber(number: length.toString()),
                          textAlign: TextAlign.start,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: BlocBuilder<CurationCubit, CurationState>(
          buildWhen: (previous, current) =>
              previous.articles != current.articles ||
              previous.videos != current.videos ||
              previous.isArticleLoading != current.isArticleLoading ||
              previous.mutes != current.mutes,
          builder: (context, state) {
            if (state.isArticleLoading) {
              return const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(kDefaultPadding / 2),
                  child: Column(
                    children: [ExploreMediaSkeleton()],
                  ),
                ),
              );
            } else if (state.isArticlesCuration
                ? state.articles.isEmpty
                : state.videos.isEmpty) {
              return EmptyList(
                description: state.isArticlesCuration
                    ? context.t.noArticlesInCuration.capitalizeFirst()
                    : context.t.noVideosInCuration.capitalizeFirst(),
                icon: FeatureIcons.curations,
              );
            } else {
              if (curation.isArticleCuration()) {
                if (isTablet) {
                  return _articlesItemsGrid(state);
                } else {
                  return _articlesItemsList(state);
                }
              } else {
                if (isTablet) {
                  return _videosItemsGrid(state);
                } else {
                  return _videosItemsList(state);
                }
              }
            }
          },
        ),
      ),
    );
  }

  ListView _videosItemsList(CurationState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        thickness: 0.3,
        height: kDefaultPadding * 1.5,
      ),
      itemCount: state.videos.length,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final video = state.videos[index];

        return VideoCommonContainer(
          isBookmarked: false,
          video: video,
          isMuted: nostrRepository.mutes.contains(video.pubkey),
          isFollowing: contactListCubit.contacts.contains(video.pubkey),
          onTap: () {
            Navigator.pushNamed(
              context,
              video.isHorizontal
                  ? HorizontalVideoView.routeName
                  : VerticalVideoView.routeName,
              arguments: [video],
            );
          },
        );
      },
    );
  }

  MasonryGridView _videosItemsGrid(CurationState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: state.videos.length,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final video = state.videos[index];

        return VideoCommonContainer(
          isBookmarked: false,
          video: video,
          isMuted: nostrRepository.mutes.contains(video.pubkey),
          isFollowing: contactListCubit.contacts.contains(video.pubkey),
          onTap: () {
            Navigator.pushNamed(
              context,
              video.isHorizontal
                  ? HorizontalVideoView.routeName
                  : VerticalVideoView.routeName,
              arguments: [video],
            );
          },
        );
      },
    );
  }

  ListView _articlesItemsList(CurationState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        thickness: 0.3,
        height: kDefaultPadding * 1.5,
      ),
      itemCount: state.articles.length,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      itemBuilder: (context, index) {
        final article = state.articles[index];

        return ArticleContainer(
          article: article,
          highlightedTag: '',
          isMuted: state.mutes.contains(article.pubkey),
          isBookmarked: false,
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          },
          isFollowing: contactListCubit.contacts.contains(article.pubkey),
        );
      },
    );
  }

  MasonryGridView _articlesItemsGrid(CurationState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: state.articles.length,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
      ),
      itemBuilder: (context, index) {
        final article = state.articles[index];

        return ArticleContainer(
          article: article,
          highlightedTag: '',
          isMuted: state.mutes.contains(article.pubkey),
          isBookmarked: false,
          onClicked: () {
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          },
          isFollowing: contactListCubit.contacts.contains(article.pubkey),
        );
      },
    );
  }

  SliverPadding _curationInfoContainer() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverToBoxAdapter(
        child: BlocBuilder<CurationCubit, CurationState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CurationHeader(curation: curation),
                Divider(
                  thickness: 0.3,
                  height: kDefaultPadding,
                  color: Theme.of(context).dividerColor,
                ),
                _titleItem(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                _postedFromItem(context),
                if (curation.description.isNotEmpty) ...[
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  SelectableText(
                    curation.description.trim(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ],
                const SizedBox(
                  height: kDefaultPadding,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: MediaImage(
                        url: curation.image,
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Row _postedFromItem(BuildContext context) {
    return Row(
      children: [
        Text(
          '${context.t.postedFrom.capitalize()} ',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Flexible(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, appClientsState) {
              if (curation.client.isEmpty ||
                  !curation.client
                      .contains(EventKind.APPLICATION_INFO.toString())) {
                return Text(
                  curation.client.isEmpty ? 'N/A' : curation.client,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: kMainColor,
                      ),
                );
              } else {
                final appApplication = appClientsState
                    .appClients[context.read<CurationCubit>().identifier];

                return Text(
                  appApplication == null
                      ? 'N/A'
                      : appApplication.name.trim().capitalize(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: kMainColor,
                      ),
                );
              }
            },
          ),
        ),
        DotContainer(
          color: Theme.of(context).highlightColor,
          size: 2,
        ),
        Text(
          StringUtil.formatTimeDifference(
            curation.createdAt,
          ),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Builder _titleItem() {
    return Builder(
      builder: (context) {
        final title = curation.title.trim();
        return SelectableText(
          title.isEmpty ? context.t.noTitle.capitalizeFirst() : title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w800,
                color: title.isEmpty
                    ? Theme.of(context).highlightColor
                    : Theme.of(context).primaryColorDark,
              ),
        );
      },
    );
  }
}

class CurationHeader extends HookWidget {
  const CurationHeader({
    super.key,
    required this.curation,
  });

  final Curation curation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurationCubit, CurationState>(
      builder: (context, state) {
        return MetadataProvider(
          pubkey: curation.pubkey,
          child: (metadata, isNip05Valid) {
            return Row(
              children: [
                ProfilePicture3(
                  size: 40,
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
                _postedByInfo(context, metadata, isNip05Valid),
                const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                _actionsRow(context, metadata, state),
              ],
            );
          },
        );
      },
    );
  }

  AbsorbPointer _actionsRow(
      BuildContext context, Metadata metadata, CurationState state) {
    return AbsorbPointer(
      absorbing: !canSign(),
      child: Row(
        children: [
          _followButton(),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          _zapButton(context, metadata, state),
        ],
      ),
    );
  }

  NewBorderedIconButton _zapButton(
      BuildContext context, Metadata metadata, CurationState state) {
    return NewBorderedIconButton(
      onClicked: () {
        showModalBottomSheet(
          elevation: 0,
          context: context,
          builder: (_) {
            return SendZapsView(
              metadata: metadata,
              isZapSplit: curation.zapsSplits.isNotEmpty,
              zapSplits: curation.zapsSplits,
              aTag:
                  '${curation.kind}:${curation.pubkey}:${curation.identifier}',
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      icon: FeatureIcons.zaps,
      buttonStatus:
          !state.canBeZapped ? ButtonStatus.disabled : ButtonStatus.inactive,
    );
  }

  BlocBuilder<CurationCubit, CurationState> _followButton() {
    return BlocBuilder<CurationCubit, CurationState>(
      builder: (context, state) {
        return Builder(
          builder: (context) {
            final isDisabled = !canSign() || state.isSameCurationAuthor;

            return AbsorbPointer(
              absorbing: isDisabled,
              child: TextButton(
                onPressed: () {
                  if (!canSign()) {
                  } else {
                    context.read<CurationCubit>().setFollowingState();
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
        );
      },
    );
  }

  Expanded _postedByInfo(
      BuildContext context, Metadata metadata, bool isNip05Valid) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.postedBy.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kMainColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (isNip05Valid)
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                const SizedBox.shrink()
            ],
          ),
        ],
      ),
    );
  }
}
