import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_content_cubit/dashboard_content_cubit.dart';
import '../../../../models/article_model.dart';
import '../../../../models/curation_model.dart';
import '../../../../models/detailed_note_model.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../models/video_model.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../add_content_view/add_content_view.dart';
import '../../../article_view/article_view.dart';
import '../../../curation_view/curation_view.dart';
import '../../../note_view/note_view.dart';
import '../../../smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../../widgets/classic_footer.dart';
import '../../../widgets/content_placeholder.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/tag_container.dart';
import '../../../widgets/video_components/horizontal_video_view.dart';
import '../../../widgets/video_components/vertical_video_view.dart';
import '../home/dashboard_containers.dart';

final dashboardArticleFilter = [
  'Published',
  'Drafts',
];

class ContentDashboard extends StatefulWidget {
  const ContentDashboard({super.key, required this.isDraft});

  final bool isDraft;

  @override
  State<ContentDashboard> createState() => _ContentDashboardState();
}

class _ContentDashboardState extends State<ContentDashboard> {
  final refreshController = RefreshController();
  bool isPublished = true;
  String selectedArticleType = dashboardArticleFilter.first;
  AppContentType selectedContentType = AppContentType.article;
  final contentTypes = [
    AppContentType.article,
    AppContentType.note,
    AppContentType.curation,
    AppContentType.video,
  ];

  @override
  void initState() {
    super.initState();
    isPublished = !widget.isDraft;
    selectedArticleType =
        isPublished ? dashboardArticleFilter[0] : dashboardArticleFilter[1];

    context.read<DashboardContentCubit>().buildContent(
          re: AppContentType.article,
          onAdd: false,
          isPublished: isPublished,
        );
  }

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  void buildContent(
    BuildContext context,
    bool isAdding,
    AppContentType re,
  ) {
    context.read<DashboardContentCubit>().buildContent(
          re: re,
          onAdd: isAdding,
          isPublished: isPublished,
        );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!;

    return BlocConsumer<DashboardContentCubit, DashboardContentState>(
      listener: (context, state) {
        if (state.updatingState == UpdatingState.success) {
          refreshController.loadComplete();
        } else if (state.updatingState == UpdatingState.idle) {
          refreshController.loadNoData();
        }

        if (!state.isLoading) {
          refreshController.refreshCompleted();
        }
      },
      buildWhen: (previous, current) => previous.isLoading != current.isLoading,
      builder: (context, state) {
        return DefaultTabController(
          length: 4,
          child: SmartRefresher(
            controller: refreshController,
            enablePullUp: true,
            header: const RefresherClassicHeader(),
            footer: const RefresherClassicFooter(),
            onLoading: () => buildContent.call(context, true, state.chosenRE),
            onRefresh: () => buildContent.call(context, false, state.chosenRE),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _appbar(context),
                _pulldownButton(style),
                if ((nostrRepository.userDrafts!.articleDraft.isNotEmpty &&
                        state.chosenRE == AppContentType.article) ||
                    (nostrRepository.userDrafts!.noteDraft.isNotEmpty &&
                        state.chosenRE == AppContentType.note) ||
                    (nostrRepository.userDrafts!.smartWidgetsDraft.isNotEmpty &&
                        state.chosenRE == AppContentType.smartWidget)) ...[
                  _ongoing(context),
                  if (nostrRepository.userDrafts!.articleDraft.isNotEmpty &&
                      state.chosenRE == AppContentType.article) ...[
                    _articleDraft(),
                  ] else if (nostrRepository.userDrafts!.noteDraft.isNotEmpty &&
                      state.chosenRE == AppContentType.note) ...[
                    _noteDraft(),
                  ] else if (nostrRepository
                          .userDrafts!.smartWidgetsDraft.isNotEmpty &&
                      state.chosenRE == AppContentType.smartWidget) ...[
                    _smartWidgetDraft(),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.all(kDefaultPadding / 2),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.t.saved.capitalizeFirst(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                if (state.isLoading)
                  const SliverToBoxAdapter(child: ContentPlaceholder())
                else
                  const DashboardContentList(),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _smartWidgetDraft() {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          int count = 0;

          try {
            final sm = nostrRepository
                .userDrafts!.smartWidgetsDraft.entries.first.value;

            final smartWidget = SWAutoSaveModel.fromJson(sm);

            final c = smartWidget.content['components'] as List? ?? [];

            for (final t in c) {
              final leftSideLength = (t?['left_side'] as List? ?? []).length;

              final rightSideLength = (t['right_side'] as List? ?? []).length;

              count += leftSideLength + rightSideLength;
            }
          } catch (_) {}

          return Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
            ),
            child: GestureDetector(
              onTap: () {
                YNavigator.pushPage(
                  context,
                  (context) => AddContentView(
                    contentType: AppContentType.smartWidget,
                    selectFirstSmartWidgetDraft: true,
                  ),
                );
              },
              child: DashboardDraftContainer(
                createdAt: DateTime.now(),
                article: null,
                text: context.t.componentsSMCount(
                  number: count.toString(),
                ),
                type: 'Smart Widget',
              ),
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _noteDraft() {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          final note = nostrRepository.userDrafts!.noteDraft;

          return Padding(
            padding: const EdgeInsets.all(
              kDefaultPadding / 2,
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
    );
  }

  SliverPadding _ongoing(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverToBoxAdapter(
        child: Text(
          context.t.ongoing.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _articleDraft() {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          final article = ArticleAutoSaveModel.fromJson(
            nostrRepository.userDrafts!.articleDraft,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: GestureDetector(
              onTap: () {
                YNavigator.pushPage(
                  context,
                  (context) => AddContentView(
                    contentType: AppContentType.article,
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
    );
  }

  SliverToBoxAdapter _pulldownButton(TextStyle style) {
    return SliverToBoxAdapter(
      child: BlocBuilder<DashboardContentCubit, DashboardContentState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    getTitle(state.chosenRE, context),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (state.chosenRE == AppContentType.article) ...[
                  _propertiesPulldownButton(context),
                ],
                _postPulldownButton(context, style),
              ],
            ),
          );
        },
      ),
    );
  }

  PullDownButton _postPulldownButton(BuildContext context, TextStyle style) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [
          PullDownMenuItem(
            onTap: () {
              YNavigator.pop(context);

              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  contentType: AppContentType.note,
                ),
              );
            },
            title: context.t.postNote.capitalizeFirst(),
            iconWidget: SvgPicture.asset(
              FeatureIcons.addNote,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            itemTheme: PullDownMenuItemTheme(
              textStyle: style,
            ),
          ),
          PullDownMenuItem(
            onTap: () {
              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  contentType: AppContentType.article,
                ),
              );
            },
            title: context.t.postArticle.capitalizeFirst(),
            iconWidget: SvgPicture.asset(
              FeatureIcons.addArticle,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            itemTheme: PullDownMenuItemTheme(
              textStyle: style,
            ),
          ),
          PullDownMenuItem(
            onTap: () {
              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  contentType: AppContentType.smartWidget,
                ),
              );
            },
            iconWidget: SvgPicture.asset(
              FeatureIcons.addSmartWidget,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            title: context.t.postSmartWidget.capitalizeFirst(),
            itemTheme: PullDownMenuItemTheme(
              textStyle: style,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
        icon: SvgPicture.asset(
          FeatureIcons.addRaw,
          width: 15,
          height: 15,
          colorFilter: const ColorFilter.mode(
            kWhite,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  PullDownButton _propertiesPulldownButton(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return [
          ...dashboardArticleFilter.map(
            (e) => PullDownMenuItem.selectable(
              onTap: () {
                selectedArticleType = e;

                isPublished = e == dashboardArticleFilter.first;

                buildContent(
                  context,
                  false,
                  AppContentType.article,
                );
              },
              selected: e == selectedArticleType,
              title: e.capitalize(),
              itemTheme: PullDownMenuItemTheme(
                textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: e == selectedArticleType
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
        ),
        icon: SvgPicture.asset(
          FeatureIcons.properties,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  SliverAppBar _appbar(BuildContext context) {
    return SliverAppBar(
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      titleSpacing: 0,
      title: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(
              width: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final type = contentTypes[index];

              return TagContainer(
                title: getContentType(type, context).capitalizeFirst(),
                isActive: selectedContentType == type,
                style: Theme.of(context).textTheme.labelLarge,
                onClick: () {
                  setState(() {
                    selectedContentType = type;
                  });

                  isPublished = true;

                  context.read<DashboardContentCubit>().buildContent(
                        re: type,
                        onAdd: false,
                        isPublished: isPublished,
                      );
                },
              );
            },
            itemCount: contentTypes.length,
          ),
        ),
      ),
    );
  }

  String getContentType(AppContentType type, BuildContext context) {
    String title = '';

    switch (type) {
      case AppContentType.article:
        title = context.t.articles.capitalizeFirst();
      case AppContentType.note:
        title = context.t.notes.capitalizeFirst();
      case AppContentType.curation:
        title = context.t.curations.capitalizeFirst();
      case AppContentType.video:
        title = context.t.videos.capitalizeFirst();
      case AppContentType.smartWidget:
        title = context.t.smartWidget.capitalizeFirst();
    }
    return title;
  }
}

class DashboardContentList extends StatelessWidget {
  const DashboardContentList({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<DashboardContentCubit, DashboardContentState>(
      builder: (context, state) {
        if (state.content.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyList(
              description: context.t
                  .noContentCanBeFound(type: context.t.content.toLowerCase())
                  .capitalizeFirst(),
              icon: FeatureIcons.contentClosed,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          sliver: isTablet ? _itemsGrid(state) : _itemsList(state),
        );
      },
    );
  }

  Widget _buildDashboardItem(BuildContext context, dynamic item) {
    String content = '';
    String id = '';
    String? image;
    int kind = -1;
    bool? isPaid;
    bool? isRepost;
    late Function() onClick;

    if (item is Article) {
      content = item.title;
      image = item.image;
      kind = item.isDraft ? EventKind.LONG_FORM_DRAFT : EventKind.LONG_FORM;
      id = '$kind:${item.pubkey}:${item.identifier}';
      onClick = () {
        YNavigator.pushPage(
          context,
          (context) => item.isDraft
              ? AddContentView(
                  article: item,
                  contentType: AppContentType.article,
                )
              : ArticleView(article: item),
        );
      };
    } else if (item is Curation) {
      content = item.title;
      image = item.image;
      kind = item.kind;
      id = '$kind:${item.pubkey}:${item.identifier}';
      onClick = () {
        YNavigator.pushPage(context, (context) => CurationView(curation: item));
      };
    } else if (item is VideoModel) {
      content = item.title;
      image = item.thumbnail;
      kind = item.kind;
      id = item.id;
      onClick = () {
        YNavigator.pushPage(
          context,
          (context) => kind == EventKind.VIDEO_HORIZONTAL
              ? HorizontalVideoView(video: item)
              : VerticalVideoView(video: item),
        );
      };
    } else if (item is SmartWidget) {
      content = item.title;
      image = item.smartWidgetBox.image.url;
      kind = EventKind.SMART_WIDGET_ENH;
      id = '$kind:${item.pubkey}:${item.identifier}';
      onClick = () {
        YNavigator.pushPage(
          context,
          (context) => SmartWidgetChecker(
            swm: item,
            naddr: item.getNaddr(),
          ),
        );
      };
    } else if (item is DetailedNoteModel) {
      content = item.content;
      kind = EventKind.TEXT_NOTE;
      id = item.id;
      isPaid = item.isPaid;
      onClick = () {
        YNavigator.pushPage(context, (context) => NoteView(note: item));
      };
    } else if (item is RepostModel) {
      final event = item.getRepostedEvent();
      if (event == null) {
        return const SizedBox.shrink();
      }

      isRepost = true;
      final note = DetailedNoteModel.fromEvent(event);
      content = note.content;
      kind = EventKind.TEXT_NOTE;
      id = item.id;
      isPaid = note.isPaid;
      onClick = () {
        YNavigator.pushPage(context, (context) => NoteView(note: note));
      };
    }

    return DashboardContentContainer(
      image: image,
      id: id,
      content: content,
      kind: kind,
      onClick: onClick,
      createdAt: item.createdAt,
      item: item,
      isPaid: isPaid,
      isRepost: isRepost,
      isHiddenType: true,
      onDeleteItem: (id) {
        YNavigator.pop(context);
        context.read<DashboardContentCubit>().onDeleteContent(id);
      },
      onRefresh: () {},
      borderColor:
          kind == EventKind.LONG_FORM_DRAFT && (item is Article && item.isDraft)
              ? Theme.of(context).primaryColor
              : null,
    );
  }

  SliverList _itemsList(DashboardContentState state) {
    return SliverList.separated(
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, state.content[index]),
      itemCount: state.content.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
    );
  }

  SliverMasonryGrid _itemsGrid(DashboardContentState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      childCount: state.content.length,
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, state.content[index]),
    );
  }
}

String getTitle(AppContentType re, BuildContext context) {
  String title = context.t.articles.capitalizeFirst();

  switch (re) {
    case AppContentType.article:
      title = context.t.articles.capitalizeFirst();
    case AppContentType.curation:
      title = context.t.curations.capitalizeFirst();
    case AppContentType.video:
      title = context.t.videos.capitalizeFirst();
    case AppContentType.smartWidget:
      title = context.t.widgets.capitalizeFirst();
    case AppContentType.note:
      title = context.t.notes.capitalizeFirst();
  }

  return title;
}
