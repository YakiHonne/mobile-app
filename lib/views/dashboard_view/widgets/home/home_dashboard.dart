// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:numeral/numeral.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_home_cubit/dashboard_home_cubit.dart';
import '../../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../../models/app_models/diverse_functions.dart';
import '../../../../models/article_model.dart';
import '../../../../models/curation_model.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../models/video_model.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../add_content_view/add_content_view.dart';
import '../../../article_view/article_view.dart';
import '../../../curation_view/curation_view.dart';
import '../../../main_view/widgets/drawer_view.dart';
import '../../../points_management_view/points_management_view.dart';
import '../../../points_management_view/widgets/points_login_popup.dart';
import '../../../profile_view/profile_view.dart';
import '../../../profile_view/widgets/profile_connections_view.dart';
import '../../../widgets/classic_footer.dart';
import '../../../widgets/modal_with_blur.dart';
import '../../../widgets/profile_picture.dart';
import '../../../widgets/video_components/horizontal_video_view.dart';
import '../../../widgets/video_components/vertical_video_view.dart';
import 'dashboard_containers.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key, required this.onDraftClicked});

  final Function() onDraftClicked;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final refreshController = RefreshController();

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final widgets = <Widget>[];
    const spacer = SliverToBoxAdapter(
      child: SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    final containerDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      color: Theme.of(context).cardColor,
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: 0.3,
      ),
    );

    widgets.add(spacer);

    widgets.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Text(
            context.t.home.capitalizeFirst(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );

    widgets.add(spacer);
    widgets.add(spacer);

    widgets.add(
      Builder(
        builder: (context) {
          final metadata = nostrRepository.currentMetadata;

          return SliverToBoxAdapter(
            child: Container(
              decoration: containerDecoration,
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              margin: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: Row(
                children: [
                  ProfilePicture2(
                    size: 55,
                    pubkey: metadata.pubkey,
                    image: metadata.picture,
                    padding: 0,
                    strokeWidth: 3,
                    strokeColor: Theme.of(context).cardColor,
                    onClicked: () => YNavigator.pushPage(
                      context,
                      (context) => ProfileView(
                        pubkey: metadata.pubkey,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata.getName(),
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          context.t.joinedOn(
                            date: dateFormat6.format(
                              DateTime.now(),
                            ),
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium!
                              .copyWith(
                                  color: Theme.of(context).highlightColor),
                        ),
                      ],
                    ),
                  ),
                  if (canSign()) ...[
                    BlocBuilder<PointsManagementCubit, PointsManagementState>(
                      builder: (context, state) {
                        return Builder(
                          builder: (context) {
                            void onNavigate() {
                              if (state.userGlobalStats != null) {
                                Navigator.pushNamed(
                                  context,
                                  PointsStatisticsView.routeName,
                                );
                              }
                            }

                            return GestureDetector(
                              onTap: onNavigate,
                              behavior: HitTestBehavior.translucent,
                              child: Row(
                                children: [
                                  if (state.userGlobalStats != null)
                                    GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: onNavigate,
                                      child: PointsPercentage(
                                        currentXp: state.currentXp,
                                        nextLevelXp: state.nextLevelXp,
                                        additionalXp: state.additionalXp,
                                        currentLevelXp: state.currentLevelXp,
                                        currentLevel: state.currentLevel,
                                        percentage: state.percentage,
                                        backgroundColor: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        Scaffold.of(context).closeDrawer();
                                        showBlurredModal(
                                          context: context,
                                          view: const PointsLoginPopup(),
                                        );
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                        ),
                                        alignment: Alignment.center,
                                        child: SvgPicture.asset(
                                          FeatureIcons.reward,
                                          width: 25,
                                          height: 25,
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).primaryColorDark,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(
                                    width: kDefaultPadding / 2,
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    widgets.add(spacer);

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          void followingFollowers(bool isFollowers) {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return ProfileConnectionsView(
                  pubkey: currentSigner!.getPublicKey(),
                  isFollowers: isFollowers,
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          }

          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    child: DashboardStatsContainer(
                      firstVal: (state.stats['followings'] ?? 0).numeral(),
                      firstdesc: context.t.followings.capitalizeFirst(),
                      icon: FeatureIcons.user,
                      onClicked: () => followingFollowers(false),
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: DashboardStatsContainer(
                      firstVal: (state.stats['followers'] ?? 0).numeral(),
                      firstdesc: context.t.followers.capitalizeFirst(),
                      icon: FeatureIcons.user,
                      onClicked: () => followingFollowers(true),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    widgets.add(spacer);

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: Row(
                children: [
                  Expanded(
                    child: DashboardStatsContainer(
                      firstVal: (state.stats['notes'] ?? 0).numeral(),
                      firstdesc: context.t.notes.capitalizeFirst(),
                      icon: FeatureIcons.uncensoredNote,
                      onClicked: () {
                        YNavigator.pushPage(
                          context,
                          (context) => ProfileView(
                            pubkey: currentSigner!.getPublicKey(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: DashboardStatsContainer(
                      firstVal: (state.stats['replies'] ?? 0).numeral(),
                      firstdesc: context.t.replies.capitalizeFirst(),
                      icon: FeatureIcons.uncensoredNote,
                      onClicked: () {
                        YNavigator.pushPage(
                          context,
                          (context) => ProfileView(
                            pubkey: currentSigner!.getPublicKey(),
                            index: 1,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    widgets.add(spacer);

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: DashboardStatsContainer(
                firstVal: (state.stats['zaps_received_count'] ?? 0).numeral(),
                firstdesc: context.t.zapReceived.capitalizeFirst(),
                secondVal: (state.stats['zaps_received'] ?? 0).numeral(),
                secondDesc: context.t.totalAmount.capitalizeFirst(),
                icon: FeatureIcons.zap,
                onClicked: () {},
              ),
            ),
          );
        },
      ),
    );

    widgets.add(spacer);

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          return SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: DashboardStatsContainer(
                firstVal: (state.stats['zaps_sent_count'] ?? 0).numeral(),
                firstdesc: context.t.zapSent.capitalizeFirst(),
                secondVal: (state.stats['zaps_sent'] ?? 0).numeral(),
                secondDesc: context.t.totalAmount.capitalizeFirst(),
                icon: FeatureIcons.zap,
                onClicked: () {},
              ),
            ),
          );
        },
      ),
    );

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          if (state.latest.isNotEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      context.t.latest.capitalizeFirst(),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    if (isTablet)
                      MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: MasonryGridView.builder(
                          shrinkWrap: true,
                          primary: false,
                          gridDelegate:
                              const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                          ),
                          mainAxisSpacing: kDefaultPadding / 2,
                          crossAxisSpacing: kDefaultPadding / 2,
                          itemBuilder: (context, index) {
                            final item = state.latest[index];
                            String content = '';
                            String id = '';
                            String image = '';
                            int kind = -1;
                            late Function() onClick;

                            if (item is Article) {
                              content = item.title;
                              image = item.image;
                              kind = EventKind.LONG_FORM;
                              id = '$kind:${item.pubkey}:${item.identifier}';
                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) => ArticleView(article: item),
                                );
                              };
                            } else if (item is Curation) {
                              content = item.title;
                              image = item.image;
                              kind = item.kind;
                              id = '$kind:${item.pubkey}:${item.identifier}';
                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) => CurationView(curation: item),
                                );
                              };
                            } else if (item is VideoModel) {
                              content = item.title;
                              image = item.thumbnail;
                              kind = item.kind;
                              id = item.id;

                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) =>
                                      kind == EventKind.VIDEO_HORIZONTAL
                                          ? HorizontalVideoView(video: item)
                                          : VerticalVideoView(video: item),
                                );
                              };
                            }

                            return DashboardContentContainer(
                              content: content,
                              createdAt: item.createdAt,
                              id: id,
                              image: image,
                              kind: kind,
                              onClick: onClick,
                              item: item,
                              onDeleteItem: (id) {
                                YNavigator.pop(context);
                                context
                                    .read<DashboardHomeCubit>()
                                    .onDeleteContent(id);
                              },
                            );
                          },
                          itemCount: state.latest.length,
                        ),
                      )
                    else
                      MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          separatorBuilder: (context, index) => const SizedBox(
                            height: kDefaultPadding / 2,
                          ),
                          itemBuilder: (context, index) {
                            final item = state.latest[index];
                            String content = '';
                            String id = '';
                            String image = '';
                            int kind = -1;
                            late Function() onClick;

                            if (item is Article) {
                              content = item.title;
                              image = item.image;
                              kind = EventKind.LONG_FORM;
                              id = '$kind:${item.pubkey}:${item.identifier}';
                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) => ArticleView(article: item),
                                );
                              };
                            } else if (item is Curation) {
                              content = item.title;
                              image = item.image;
                              kind = item.kind;
                              id = '$kind:${item.pubkey}:${item.identifier}';
                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) => CurationView(curation: item),
                                );
                              };
                            } else if (item is VideoModel) {
                              content = item.title;
                              image = item.thumbnail;
                              kind = item.kind;
                              id = item.id;

                              onClick = () {
                                YNavigator.pushPage(
                                  context,
                                  (context) =>
                                      kind == EventKind.VIDEO_HORIZONTAL
                                          ? HorizontalVideoView(video: item)
                                          : VerticalVideoView(video: item),
                                );
                              };
                            }

                            return DashboardContentContainer(
                              content: content,
                              createdAt: item.createdAt,
                              id: id,
                              image: image,
                              kind: kind,
                              onClick: onClick,
                              item: item,
                              onDeleteItem: (id) {
                                YNavigator.pop(context);
                                context
                                    .read<DashboardHomeCubit>()
                                    .onDeleteContent(id);
                              },
                            );
                          },
                          itemCount: state.latest.length,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return const SliverToBoxAdapter();
        },
      ),
    );

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          if (state.drafts.isNotEmpty ||
              nostrRepository.userDrafts!.articleDraft.isNotEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      'Drafts',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    if (nostrRepository.userDrafts!.articleDraft.isNotEmpty ||
                        nostrRepository.userDrafts!.noteDraft.isNotEmpty ||
                        nostrRepository
                            .userDrafts!.smartWidgetsDraft.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t.ongoing.capitalizeFirst(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      color: kMainColor,
                                    ),
                              ),
                              if (nostrRepository
                                  .userDrafts!.articleDraft.isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    final article =
                                        ArticleAutoSaveModel.fromJson(
                                      nostrRepository.userDrafts!.articleDraft,
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: kDefaultPadding / 2,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          YNavigator.pushPage(
                                            context,
                                            (context) => AddContentView(
                                              contentType:
                                                  AppContentType.article,
                                            ),
                                          );
                                        },
                                        child: DashboardDraftContainer(
                                          createdAt: DateTime.now(),
                                          article: null,
                                          text: article.title,
                                          type: 'Article',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (nostrRepository
                                  .userDrafts!.noteDraft.isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    final note =
                                        nostrRepository.userDrafts!.noteDraft;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: kDefaultPadding / 2,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          YNavigator.pushPage(
                                            context,
                                            (context) => AddContentView(
                                              contentType: AppContentType.note,
                                            ),
                                          );
                                        },
                                        child: DashboardDraftContainer(
                                          createdAt: DateTime.now(),
                                          article: null,
                                          text: note.trim(),
                                          type: 'Note',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              if (nostrRepository.userDrafts!.smartWidgetsDraft
                                  .isNotEmpty) ...[
                                Builder(
                                  builder: (context) {
                                    int count = 0;

                                    try {
                                      final sm = nostrRepository
                                          .userDrafts!
                                          .smartWidgetsDraft
                                          .entries
                                          .first
                                          .value;

                                      final smartWidget =
                                          SWAutoSaveModel.fromJson(sm);

                                      final c = smartWidget
                                              .content['components'] as List? ??
                                          [];

                                      for (final t in c) {
                                        final leftSideLength =
                                            (t?['left_side'] as List? ?? [])
                                                .length;

                                        final rightSideLength =
                                            (t['right_side'] as List? ?? [])
                                                .length;

                                        count +=
                                            leftSideLength + rightSideLength;
                                      }
                                    } catch (_) {}

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: kDefaultPadding / 2,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          YNavigator.pushPage(
                                            context,
                                            (context) => AddContentView(
                                              contentType:
                                                  AppContentType.smartWidget,
                                              selectFirstSmartWidgetDraft: true,
                                            ),
                                          );
                                        },
                                        child: DashboardDraftContainer(
                                          createdAt: DateTime.now(),
                                          article: null,
                                          text: context.t
                                              .componentsSMCount(
                                                  number: '$count')
                                              .capitalizeFirst(),
                                          type: 'Smart Widget',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ],
                    if (state.drafts.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          final length = state.drafts.length;
                          final seeMore = length > 4;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.t.saved.capitalizeFirst(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .highlightColor,
                                          ),
                                    ),
                                  ),
                                  if (seeMore)
                                    TextButton.icon(
                                      onPressed: () {
                                        widget.onDraftClicked.call();
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: kTransparent,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                      icon: Text(
                                        context.t.seeAll.capitalizeFirst(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColorDark,
                                            ),
                                      ),
                                      label: Icon(
                                        Icons.keyboard_arrow_right_rounded,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              MediaQuery.removePadding(
                                context: context,
                                removeBottom: true,
                                child: isTablet
                                    ? MasonryGridView.builder(
                                        shrinkWrap: true,
                                        primary: false,
                                        gridDelegate:
                                            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                        ),
                                        mainAxisSpacing: kDefaultPadding / 2,
                                        crossAxisSpacing: kDefaultPadding / 2,
                                        itemBuilder: (context, index) {
                                          final draft = state.drafts[index];

                                          return DashboardDraftContainer(
                                            createdAt: draft.createdAt,
                                            article: draft,
                                            text: draft.title,
                                            type: 'Article',
                                          );
                                        },
                                        itemCount: seeMore ? 4 : length,
                                      )
                                    : ListView.separated(
                                        primary: false,
                                        shrinkWrap: true,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                          height: kDefaultPadding / 2,
                                        ),
                                        itemBuilder: (context, index) {
                                          final draft = state.drafts[index];

                                          return DashboardDraftContainer(
                                            createdAt: draft.createdAt,
                                            article: draft,
                                            text: draft.title,
                                            type: 'Article',
                                          );
                                        },
                                        itemCount: seeMore ? 4 : length,
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return const SliverToBoxAdapter();
        },
      ),
    );

    widgets.add(
      BlocBuilder<DashboardHomeCubit, DashboardHomeState>(
        builder: (context, state) {
          if (state.popular.isNotEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: kDefaultPadding,
                    ),
                    Text(
                      context.t.popularNotes.capitalizeFirst(),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: isTablet
                          ? MasonryGridView.builder(
                              shrinkWrap: true,
                              primary: false,
                              gridDelegate:
                                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                              ),
                              mainAxisSpacing: kDefaultPadding / 2,
                              crossAxisSpacing: kDefaultPadding / 2,
                              itemBuilder: (context, index) {
                                final note = state.popular[index];

                                return DashboardNoteContainer(note: note);
                              },
                              itemCount: state.popular.length,
                            )
                          : ListView.separated(
                              primary: false,
                              shrinkWrap: true,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: kDefaultPadding / 2,
                              ),
                              itemBuilder: (context, index) {
                                final note = state.popular[index];

                                return DashboardNoteContainer(note: note);
                              },
                              itemCount: state.popular.length,
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SliverToBoxAdapter();
        },
      ),
    );

    widgets.add(
      SliverToBoxAdapter(
        child: SizedBox(
          height: kBottomNavigationBarHeight +
              MediaQuery.of(context).padding.bottom,
        ),
      ),
    );

    return SmartRefresher(
      enablePullUp: true,
      controller: refreshController,
      header: const RefresherClassicHeader(),
      onRefresh: () async {
        context.read<DashboardHomeCubit>().init();
        await Future.delayed(const Duration(seconds: 1));
        refreshController.refreshCompleted();
      },
      child: CustomScrollView(
        slivers: widgets,
      ),
    );
  }
}

class DashboardStatsContainer extends StatelessWidget {
  const DashboardStatsContainer({
    super.key,
    required this.icon,
    required this.firstVal,
    required this.firstdesc,
    required this.onClicked,
    this.secondVal,
    this.secondDesc,
  });

  final String icon;
  final String firstVal;
  final String firstdesc;
  final Function() onClicked;
  final String? secondVal;
  final String? secondDesc;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstVal ',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    firstdesc,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(color: Theme.of(context).highlightColor),
                  ),
                ],
              ),
            ),
            if (secondVal != null) ...[
              const SizedBox(
                width: kDefaultPadding,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$secondVal ',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      secondDesc!,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: Theme.of(context).highlightColor),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
