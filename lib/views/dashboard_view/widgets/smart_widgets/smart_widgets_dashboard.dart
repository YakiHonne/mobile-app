import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_content_cubit/dashboard_content_cubit.dart';
import '../../../../logic/tools_cubit/tools_cubit.dart';
import '../../../../models/article_model.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../add_content_view/add_content_view.dart';
import '../../../add_content_view/tools_view/tools_view.dart';
import '../../../smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../../widgets/classic_footer.dart';
import '../../../widgets/content_placeholder.dart';
import '../../../widgets/custom_drop_down.dart';
import '../../../widgets/empty_list.dart';
import '../home/dashboard_containers.dart';

class SmartWidgetsDashboard extends StatefulWidget {
  const SmartWidgetsDashboard({super.key, required this.isDraft});

  final bool isDraft;

  @override
  State<SmartWidgetsDashboard> createState() => _SmartWidgetsDashboardState();
}

class _SmartWidgetsDashboardState extends State<SmartWidgetsDashboard> {
  final refreshController = RefreshController();
  bool isMyWidgets = true;

  @override
  void initState() {
    super.initState();

    context.read<DashboardContentCubit>().buildContent(
          re: AppContentType.smartWidget,
          onAdd: false,
          isPublished: true,
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
          isPublished: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!;
    final myWidgets = context.t.myWidgets.capitalizeFirst();
    final mySavedTool = context.t.mySavedTools.capitalizeFirst();

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
        return SmartRefresher(
          controller: refreshController,
          enablePullUp: true,
          header: const RefresherClassicHeader(),
          footer: const RefresherClassicFooter(),
          onLoading: () => buildContent.call(context, true, state.chosenRE),
          onRefresh: () => buildContent.call(context, false, state.chosenRE),
          child: _itemsList(style, state, context, myWidgets, mySavedTool),
        );
      },
    );
  }

  CustomScrollView _itemsList(TextStyle style, DashboardContentState state,
      BuildContext context, String myWidgets, String mySavedTool) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: BlocBuilder<DashboardContentCubit, DashboardContentState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t.smartWidgets.capitalizeFirst(),
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    _globalPulldownButton(context, style),
                  ],
                ),
              );
            },
          ),
        ),
        if ((nostrRepository.userDrafts!.articleDraft.isNotEmpty &&
                state.chosenRE == AppContentType.article) ||
            (nostrRepository.userDrafts!.noteDraft.isNotEmpty &&
                state.chosenRE == AppContentType.note) ||
            (nostrRepository.userDrafts!.smartWidgetsDraft.isNotEmpty &&
                state.chosenRE == AppContentType.smartWidget)) ...[
          SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            sliver: SliverToBoxAdapter(
              child: Text(
                context.t.ongoing.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
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
                      text: context.t.smartWidget.capitalizeFirst(),
                      type: 'Smart Widget',
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding / 2,
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    context.t.saved.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: CustomDropDown(
                    list: [myWidgets, mySavedTool],
                    defaultValue: myWidgets,
                    onChanged: (option) {
                      if (option == myWidgets) {
                        isMyWidgets = true;

                        context.read<DashboardContentCubit>().buildContent(
                              re: AppContentType.smartWidget,
                              onAdd: false,
                              isPublished: true,
                            );
                      } else {
                        isMyWidgets = false;
                        context
                            .read<DashboardContentCubit>()
                            .getSmartWidgetsSavedTools();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isMyWidgets)
          const DashboardSmartWidgetsList()
        else
          const SmartWdigetSavedTool(),
        SliverToBoxAdapter(
          child: SizedBox(
            height: kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom,
          ),
        )
      ],
    );
  }

  PullDownButton _globalPulldownButton(BuildContext context, TextStyle style) {
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
}

class SmartWdigetSavedTool extends HookWidget {
  const SmartWdigetSavedTool({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final savedTools = useState<List<SmartWidget>>(<SmartWidget>[]);

    return BlocProvider(
      create: (context) => ToolsCubit(),
      child: BlocConsumer<ToolsCubit, ToolsState>(
        listener: (context, state) {
          savedTools.value = state.savedTools;
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const SliverToBoxAdapter(child: ContentPlaceholder());
          } else if (savedTools.value.isEmpty) {
            return _noToolsContainer(context);
          }

          return savedTools.value.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    child: EmptyList(
                      description: context.t.noToolsAvailable.capitalizeFirst(),
                      icon: FeatureIcons.menu,
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2),
                  sliver: isTablet
                      ? _itemsGrid(savedTools, state)
                      : _itemsList(savedTools, state),
                );
        },
      ),
    );
  }

  SliverList _itemsList(
      ValueNotifier<List<SmartWidget>> savedTools, ToolsState state) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final tool = savedTools.value[index];
        final app = state.apps[tool.identifier];

        return ToolContainer(
          tool: tool,
          appSmartWidget: state.apps[tool.identifier],
          onContentAdded: (p0) {},
          canBeBookmarked: true,
          canBeRemoved: true,
          isBookmarked: state.bookmarks.contains(tool.identifier),
          onBookmarkSet: () {
            context.read<ToolsCubit>().addBookmark(
                  tool.identifier,
                  app?.pubkey ?? tool.pubkey,
                );
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
      itemCount: savedTools.value.length,
    );
  }

  SliverMasonryGrid _itemsGrid(
      ValueNotifier<List<SmartWidget>> savedTools, ToolsState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 4,
      crossAxisSpacing: kDefaultPadding / 4,
      childCount: savedTools.value.length,
      itemBuilder: (context, index) {
        final tool = savedTools.value[index];
        final app = state.apps[tool.identifier];

        return ToolContainer(
          tool: tool,
          appSmartWidget: state.apps[tool.identifier],
          onContentAdded: (p0) {},
          canBeBookmarked: true,
          canBeRemoved: true,
          isBookmarked: state.bookmarks.contains(tool.identifier),
          onBookmarkSet: () {
            context.read<ToolsCubit>().addBookmark(
                  tool.identifier,
                  app?.pubkey ?? tool.pubkey,
                );
          },
        );
      },
    );
  }

  SliverToBoxAdapter _noToolsContainer(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          spacing: kDefaultPadding / 2,
          children: [
            Text(
              context.t.noToolsAvailable.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            Text(
              context.t.discoverTools.capitalizeFirst(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            TextButton(
              onPressed: () {
                YNavigator.popToRoot(context);
                nostrRepository.mainCubit.updateIndex(
                  MainViews.smartWidgets,
                );
              },
              child: Text(
                context.t.addWidgetTools,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSmartWidgetsList extends StatelessWidget {
  const DashboardSmartWidgetsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<DashboardContentCubit, DashboardContentState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SliverToBoxAdapter(child: ContentPlaceholder());
        } else if (state.content.isEmpty) {
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

  SliverList _itemsList(DashboardContentState state) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final item = state.content[index] as SmartWidget;

        String content = '';
        String id = '';
        String? image;
        int kind = -1;
        bool? isPaid;
        bool? isRepost;
        late Function() onClick;

        content = item.title;
        image = item.smartWidgetBox.image.url;
        kind = EventKind.SMART_WIDGET_ENH;
        id = '$kind:${item.pubkey}:${item.identifier}';

        onClick = () {
          YNavigator.pushPage(
            context,
            (context) => SmartWidgetChecker(
              swm: item,
              naddr: item.getScheme(),
            ),
          );
        };

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
              kind == EventKind.LONG_FORM_DRAFT && (item as Article).isDraft
                  ? Theme.of(context).primaryColor
                  : null,
        );
      },
      itemCount: state.content.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );
  }

  SliverMasonryGrid _itemsGrid(DashboardContentState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final item = state.content[index] as SmartWidget;

        String content = '';
        String id = '';
        String? image;
        int kind = -1;
        bool? isPaid;
        bool? isRepost;
        late Function() onClick;

        content = item.title;
        image = item.smartWidgetBox.image.url;
        kind = EventKind.SMART_WIDGET_ENH;
        id = '$kind:${item.pubkey}:${item.identifier}';

        onClick = () {
          YNavigator.pushPage(
            context,
            (context) => SmartWidgetChecker(
              swm: item,
              naddr: item.getScheme(),
            ),
          );
        };

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
          onDeleteItem: (id) {
            YNavigator.pop(context);
            context.read<DashboardContentCubit>().onDeleteContent(id);
          },
          onRefresh: () {},
          borderColor:
              kind == EventKind.LONG_FORM_DRAFT && (item as Article).isDraft
                  ? Theme.of(context).primaryColor
                  : null,
        );
      },
      childCount: state.content.length,
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
    case AppContentType.picture:
      title = context.t.pictures.capitalizeFirst();
  }

  return title;
}
