import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmarks_cubit.dart';
import '../../../../models/bookmark_list_model.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/response_snackbar.dart';
import '../home/dashboard_containers.dart';
import 'add_bookmarks_list_view.dart';
import 'bookmarks_list_details.dart';

class BookmarksDashboard extends StatelessWidget {
  const BookmarksDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
      buildWhen: (previous, current) => previous.refresh != current.refresh,
      builder: (context, state) {
        return const BookmarksLists();
      },
    );
  }
}

class BookmarksLists extends HookWidget {
  const BookmarksLists({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
      builder: (context, state) {
        if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
          return const TabletBookmarksList();
        } else {
          return const MobileBookmarksList();
        }
      },
    );
  }
}

class TabletBookmarksList extends StatelessWidget {
  const TabletBookmarksList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BookmarksHeader(),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
          builder: (context, state) {
            if (state.bookmarksLists.isEmpty) {
              return EmptyList(
                description: context.t.noBookmarksListFound.capitalizeFirst(),
                icon: FeatureIcons.bookmark,
              );
            } else {
              return _bookmarksGrid(state, context);
            }
          },
        ),
      ],
    );
  }

  Expanded _bookmarksGrid(DashboardBookmarksState state, BuildContext context) {
    return Expanded(
      child: Scrollbar(
        child: MasonryGridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding,
          ),
          crossAxisSpacing: kDefaultPadding / 2,
          mainAxisSpacing: kDefaultPadding / 2,
          itemBuilder: (_, index) {
            final bookmarkList = state.bookmarksLists[index];

            return BookmarkContainer(
              bookmarkListModel: bookmarkList,
              onClicked: () {
                YNavigator.pushPage(
                  context,
                  (_) => BookmarksListDetails(
                    bookmarkListModel: bookmarkList,
                    bookmarksCubit: context.read<DashboardBookmarksCubit>(),
                  ),
                );
              },
              onDelete: () {
                showCupertinoDeletionDialogue(
                  context: context,
                  title: context.t.deleteBookmarkList.capitalizeFirst(),
                  description:
                      context.t.confirmDeleteBookmarkList.capitalizeFirst(),
                  buttonText: context.t.delete.capitalizeFirst(),
                  onDelete: () {
                    context.read<DashboardBookmarksCubit>().deleteBookmarksList(
                          bookmarkListEventId: bookmarkList.id,
                          bookmarkListIdentifier: bookmarkList.identifier,
                          onSuccess: () {
                            Navigator.pop(context);
                          },
                        );
                  },
                );
              },
            );
          },
          itemCount: state.bookmarksLists.length,
        ),
      ),
    );
  }
}

class MobileBookmarksList extends StatelessWidget {
  const MobileBookmarksList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: BookmarksHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              bottom: kDefaultPadding,
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
            ),
            sliver:
                BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
              builder: (context, state) {
                if (state.bookmarksLists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyList(
                      description:
                          context.t.noBookmarksListFound.capitalizeFirst(),
                      icon: FeatureIcons.bookmark,
                    ),
                  );
                } else {
                  return _bookmarksList(state);
                }
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
        ],
      ),
    );
  }

  SliverList _bookmarksList(DashboardBookmarksState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final bookmarkList = state.bookmarksLists[index];

        return DashboardContentContainer(
          image: bookmarkList.image,
          id: bookmarkList.id,
          content: bookmarkList.title,
          kind: EventKind.CATEGORIZED_BOOKMARK,
          onClick: () {
            YNavigator.pushPage(
              context,
              (_) => BookmarksListDetails(
                bookmarkListModel: bookmarkList,
                bookmarksCubit: context.read<DashboardBookmarksCubit>(),
              ),
            );
          },
          createdAt: bookmarkList.createdAt,
          item: bookmarkList,
          onDeleteItem: (id) {
            YNavigator.pop(context);

            context.read<DashboardBookmarksCubit>().deleteBookmarksList(
                  bookmarkListEventId: bookmarkList.id,
                  bookmarkListIdentifier: bookmarkList.identifier,
                  onSuccess: () {},
                );
          },
          onRefresh: () {},
        );
      },
      itemCount: state.bookmarksLists.length,
    );
  }
}

class BookmarksHeader extends StatelessWidget {
  const BookmarksHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          child: Row(
            children: [
              _bookmarksInfo(context, state),
              _addButton(context),
            ],
          ),
        );
      },
    );
  }

  IconButton _addButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          AddBookmarksListView.routeName,
          arguments: [
            context.read<DashboardBookmarksCubit>(),
          ],
        );
      },
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
      icon: SvgPicture.asset(
        FeatureIcons.addRaw,
        width: 15,
        height: 15,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Expanded _bookmarksInfo(BuildContext context, DashboardBookmarksState state) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.bookmarks.capitalizeFirst(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            context.t.bookmarksListCount(
              number: state.bookmarksLists.length.toString().padLeft(2, '0'),
            ),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

class BookmarkContainer extends StatelessWidget {
  const BookmarkContainer({
    super.key,
    required this.bookmarkListModel,
    required this.onClicked,
    required this.onDelete,
  });

  final BookmarkListModel bookmarkListModel;
  final Function() onClicked;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final String title = bookmarkListModel.title.trim().isEmpty
        ? context.t.noTitle.capitalizeFirst()
        : bookmarkListModel.title.trim().capitalize();
    final String description = bookmarkListModel.description.trim().isEmpty
        ? context.t.noDescription.capitalizeFirst()
        : bookmarkListModel.description.trim().capitalize();

    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
          CommonThumbnail(
            image: bookmarkListModel.image,
            placeholder: bookmarkListModel.placeholder,
            width: 90,
            height: 90,
            radius: kDefaultPadding / 2,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _infoColumn(title, context, description),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: BorderedIconButton(
              onClicked: onDelete,
              primaryIcon: FeatureIcons.trash,
              borderColor: Theme.of(context).primaryColorLight,
              iconColor: kWhite,
              firstSelection: true,
              secondaryIcon: FeatureIcons.trash,
              backGroundColor: kRed,
            ),
          ),
        ],
      ),
    );
  }

  Expanded _infoColumn(String title, BuildContext context, String description) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              context.t.editedOn(
                date: dateFormat2.format(bookmarkListModel.createdAt),
              ),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              context.t.itemsNumber(
                number: (bookmarkListModel.bookmarkedEvents.length +
                        bookmarkListModel.bookmarkedReplaceableEvents.length)
                    .toString()
                    .padLeft(2, '0'),
              ),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
