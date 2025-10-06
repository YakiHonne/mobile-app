// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmark_details_cubit/bookmark_details_cubit.dart';
import '../../../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmarks_cubit.dart';
import '../../../../models/app_models/popup_menu_common_item.dart';
import '../../../../models/article_model.dart';
import '../../../../models/bookmark_list_model.dart';
import '../../../../models/curation_model.dart';
import '../../../../models/detailed_note_model.dart';
import '../../../../models/flash_news_model.dart';
import '../../../../models/video_model.dart';
import '../../../../repositories/nostr_data_repository.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../article_view/article_view.dart';
import '../../../curation_view/curation_view.dart';
import '../../../gallery_view/gallery_view.dart';
import '../../../note_view/note_view.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/response_snackbar.dart';
import '../../../widgets/video_components/horizontal_video_view.dart';
import '../../../widgets/video_components/vertical_video_view.dart';
import '../home/dashboard_containers.dart';

class BookmarksListDetails extends HookWidget {
  BookmarksListDetails({
    super.key,
    required this.bookmarkListModel,
    required this.bookmarksCubit,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Bookmarks details view');
  }

  static const routeName = '/bookmarksListDetails';
  static Route route(RouteSettings settings) {
    final bookmarkListModel =
        (settings.arguments! as List).first as BookmarkListModel;
    final bookmarksCubit =
        (settings.arguments! as List)[1] as DashboardBookmarksCubit;

    return CupertinoPageRoute(
      builder: (_) => BookmarksListDetails(
        bookmarkListModel: bookmarkListModel,
        bookmarksCubit: bookmarksCubit,
      ),
    );
  }

  final BookmarkListModel bookmarkListModel;
  final DashboardBookmarksCubit bookmarksCubit;

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final bookmarkType = useState(bookmarksTypes.first);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bookmarksCubit),
        BlocProvider(
          create: (context) => BookmarkDetailsCubit(
            nostrRepository: context.read<NostrDataRepository>(),
            bookmarkListModel: bookmarkListModel,
          ),
        )
      ],
      child: Scaffold(
        body: Stack(
          children: [
            _nestedScrollView(scrollController, bookmarkType),
            ResetScrollButton(scrollController: scrollController),
          ],
        ),
      ),
    );
  }

  NestedScrollViewPlus _nestedScrollView(
      ScrollController scrollController, ValueNotifier<String> bookmarkType) {
    return NestedScrollViewPlus(
      controller: scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          BookmarksListDetailsAppbar(
            scrollController: scrollController,
          ),
          _bookmarkListInfo(),
          _bookmarkListOptions(context, bookmarkType),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
          _bookmarkListItems(),
        ];
      },
      body: Container(),
    );
  }

  BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState> _bookmarkListItems() {
    return BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
      builder: (context, state) {
        if (state.isLoading || state.content.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyList(
              description: context.t.noElementsInBookmarks.capitalizeFirst(),
              icon: FeatureIcons.bookmark,
            ),
          );
        } else {
          if (!ResponsiveBreakpoints.of(context).isMobile) {
            return _itemsGrid(state);
          } else {
            return _itemsList(state);
          }
        }
      },
    );
  }

  Widget _buildBookmarkItem(BuildContext context, dynamic item) {
    String content = '';
    String id = '';
    String? image;
    int kind = -1;
    late Function() onClick;

    if (item is Article) {
      content = item.title;
      image = item.image;
      kind = item.isDraft ? EventKind.LONG_FORM_DRAFT : EventKind.LONG_FORM;
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
          (context) => kind == EventKind.VIDEO_HORIZONTAL
              ? HorizontalVideoView(video: item)
              : VerticalVideoView(video: item),
        );
      };
    } else if (item is DetailedNoteModel) {
      content = item.content;
      kind = EventKind.TEXT_NOTE;
      id = item.id;
      onClick = () {
        YNavigator.pushPage(
          context,
          (context) => NoteView(note: item),
        );
      };
    }

    return DashboardBookmarkContainer(
      isBookmarked: true,
      image: image,
      id: id,
      content: content,
      kind: kind,
      onClick: onClick,
      createdAt: item.createdAt,
      item: item,
      onBookmark: () => PdmCommonActions.bookmarkBaseEventModel(context, item),
    );
  }

  SliverPadding _itemsList(BookmarkDetailsState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      sliver: SliverList.separated(
        itemCount: state.content.length,
        itemBuilder: (context, index) =>
            _buildBookmarkItem(context, state.content[index]),
        separatorBuilder: (context, index) =>
            const SizedBox(height: kDefaultPadding / 2),
      ),
    );
  }

  SliverMasonryGrid _itemsGrid(BookmarkDetailsState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 2,
      crossAxisSpacing: kDefaultPadding / 2,
      childCount: state.content.length,
      itemBuilder: (context, index) =>
          _buildBookmarkItem(context, state.content[index]),
    );
  }

  SliverToBoxAdapter _bookmarkListOptions(
      BuildContext context, ValueNotifier<String> bookmarkType) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.t.list.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PullDownButton(
              animationBuilder: (context, state, child) {
                return child;
              },
              routeTheme: PullDownMenuRouteTheme(
                backgroundColor: Theme.of(context).cardColor,
              ),
              itemBuilder: (context) {
                return [
                  ...bookmarksTypes.map(
                    (e) => PullDownMenuItem.selectable(
                      onTap: () {
                        context
                            .read<BookmarkDetailsCubit>()
                            .filterBookmarksByType(e);
                        bookmarkType.value = e;
                      },
                      selected: e == bookmarkType.value,
                      title: e,
                      itemTheme: PullDownMenuItemTheme(
                        textStyle: Theme.of(context).textTheme.labelMedium,
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
            ),
          ],
        ),
      ),
    );
  }

  BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState> _bookmarkListInfo() {
    return BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.bookmarkListModel.title.trim().capitalize(),
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (state.bookmarkListModel.description
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: kDefaultPadding / 4,
                        ),
                        Text(
                          state.bookmarkListModel.description.trim(),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: Theme.of(context).highlightColor),
                        ),
                      ],
                      const SizedBox(
                        height: kDefaultPadding / 4,
                      ),
                      Row(
                        children: [
                          Text(
                            context.t.itemsNumber(
                              number: state.content.length
                                  .toString()
                                  .padLeft(2, '0'),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    color: Theme.of(context).highlightColor),
                          ),
                          const DotContainer(color: kLightPurple),
                          Text(
                            context.t.editedOn(
                              date: dateFormat2.format(
                                state.bookmarkListModel.createdAt,
                              ),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: kMainColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: kDefaultPadding / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BookmarksListDetailsAppbar extends HookWidget {
  const BookmarksListDetailsAppbar({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final percentage = useState(0.0);
    useMemoized(
      () {
        scrollController.addListener(
          () {
            percentage.value = scrollController.offset > 100
                ? 1
                : scrollController.offset <= 0
                    ? 0
                    : scrollController.offset / 100;
          },
        );
      },
    );

    return BlocBuilder<BookmarkDetailsCubit, BookmarkDetailsState>(
      builder: (context, state) {
        return SliverAppBar(
          expandedHeight: kToolbarHeight + 50,
          pinned: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          stretch: true,
          title: Opacity(
            opacity: percentage.value,
            child: Text(
              context.t.bookmarkLists.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          centerTitle: true,
          leading: FadeInRight(
            duration: const Duration(milliseconds: 500),
            from: 30,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context)
                      .primaryColorLight
                      .withValues(alpha: 0.7),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            _deleteButton(context, state),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
          ],
          flexibleSpace: _flexibleAppbar(state),
        );
      },
    );
  }

  FlexibleSpaceBar _flexibleAppbar(BookmarkDetailsState state) {
    return FlexibleSpaceBar(
      centerTitle: false,
      background: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (state.bookmarkListModel.image.isNotEmpty) {
                              openGallery(
                                source: MapEntry(
                                  state.bookmarkListModel.image,
                                  UrlType.image,
                                ),
                                context: context,
                                index: 0,
                              );
                            }
                          },
                          child: Container(
                            foregroundDecoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).scaffoldBackgroundColor,
                                  kTransparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: const [
                                  0.1,
                                  0.5,
                                ],
                              ),
                            ),
                            child: CommonThumbnail(
                              image: state.bookmarkListModel.image,
                              placeholder: state.bookmarkListModel.placeholder,
                              width: double.infinity,
                              height: constraints.maxHeight,
                              radius: 0,
                              isRound: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BorderedIconButton _deleteButton(
      BuildContext context, BookmarkDetailsState state) {
    return BorderedIconButton(
      onClicked: () {
        showCupertinoDeletionDialogue(
          context: context,
          title: context.t.deleteBookmarkList.capitalizeFirst(),
          description: context.t.confirmDeleteBookmarkList.capitalizeFirst(),
          buttonText: context.t.delete,
          onDelete: () {
            context.read<DashboardBookmarksCubit>().deleteBookmarksList(
                  bookmarkListEventId: state.bookmarkListModel.id,
                  bookmarkListIdentifier: state.bookmarkListModel.identifier,
                  onSuccess: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                );
          },
        );
      },
      primaryIcon: FeatureIcons.trash,
      borderColor: Theme.of(context).primaryColorLight,
      iconColor: kWhite,
      firstSelection: true,
      secondaryIcon: FeatureIcons.trash,
      backGroundColor: kRed,
    );
  }
}

class DashboardBookmarkContainer extends StatelessWidget {
  const DashboardBookmarkContainer({
    super.key,
    required this.image,
    required this.id,
    required this.content,
    required this.createdAt,
    required this.kind,
    required this.item,
    required this.onClick,
    required this.isBookmarked,
    required this.onBookmark,
  });

  final String? image;
  final String id;
  final String content;
  final DateTime createdAt;
  final int kind;

  final BaseEventModel item;
  final Function() onClick;
  final Function() onBookmark;
  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null)
              CommonThumbnail(
                image: image!,
                placeholder: getRandomPlaceholder(input: id, isPfp: false),
                width: 40,
                height: 40,
                radius: kDefaultPadding / 2,
                isRound: true,
              )
            else
              ContentTypeIconBox(
                icon: getIcon(),
              ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            _bookmarkInfo(context),
            GestureDetector(
              onTap: onBookmark,
              child: SvgPicture.asset(
                isBookmarked
                    ? FeatureIcons.bookmarkFilledWhite
                    : FeatureIcons.bookmarkEmptyWhite,
                width: 25,
                height: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _bookmarkInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.t.publishedOn(
                  date: dateFormat2.format(createdAt),
                ),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.3,
                  ),
                ),
                margin: const EdgeInsets.only(
                  left: kDefaultPadding / 2,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 8,
                  horizontal: kDefaultPadding / 2,
                ),
                child: Text(
                  getType(context),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  String getIcon() {
    switch (kind) {
      case EventKind.TEXT_NOTE:
        return FeatureIcons.uncensoredNote;
      case EventKind.SMART_WIDGET_ENH:
        return FeatureIcons.smartWidget;

      default:
        return FeatureIcons.add;
    }
  }

  String getType(BuildContext context) {
    String type = '';

    switch (kind) {
      case EventKind.LONG_FORM:
        type = context.t.article.capitalizeFirst();
      case EventKind.LONG_FORM_DRAFT:
        type = context.t.draft.capitalizeFirst();
      case EventKind.CURATION_ARTICLES:
        type = context.t.curation.capitalizeFirst();
      case EventKind.CURATION_VIDEOS:
        type = context.t.curation.capitalizeFirst();
      case EventKind.VIDEO_HORIZONTAL:
        type = context.t.video.capitalizeFirst();
      case EventKind.VIDEO_VERTICAL:
        type = context.t.video.capitalizeFirst();
      case EventKind.SMART_WIDGET_ENH:
        type = context.t.smartWidget.capitalizeFirst();
      case EventKind.TEXT_NOTE:
        type = context.t.note.capitalizeFirst();
      case EventKind.CATEGORIZED_BOOKMARK:
        final bookmark = item as BookmarkListModel;
        type = context.t.itemsNumber(
            number:
                '${bookmark.bookmarkedEvents.length + bookmark.bookmarkedReplaceableEvents.length}');
    }

    return type;
  }
}
