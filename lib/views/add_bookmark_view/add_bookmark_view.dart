// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../utils/utils.dart';
import '../../logic/add_bookmark_cubit/add_bookmark_cubit.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/flash_news_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../widgets/common_thumbnail.dart';
import '../widgets/dotted_container.dart';
import '../widgets/empty_list.dart';

class AddBookmarkView extends StatelessWidget {
  const AddBookmarkView({
    super.key,
    required this.identifier,
    required this.eventPubkey,
    required this.kind,
    required this.model,
  });

  final String identifier;
  final String eventPubkey;
  final int kind;
  final BaseEventModel model;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddBookmarkCubit(
        kind: kind,
        identifier: identifier,
        eventPubkey: eventPubkey,
        model: model,
        nostrRepository: context.read<NostrDataRepository>(),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.40,
            maxChildSize: 0.8,
            expand: false,
            builder: (_, controller) => _addBookmarkColumn(controller),
          ),
        ),
      ),
    );
  }

  Column _addBookmarkColumn(ScrollController controller) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        _addBookmarkAction(),
        BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
          builder: (context, state) {
            return Expanded(
              child: getView(state.isBookmarksLists, controller),
            );
          },
        ),
        const AddBookmarkBottomBar(),
      ],
    );
  }

  BlocBuilder<AddBookmarkCubit, AddBookmarkState> _addBookmarkAction() {
    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      buildWhen: (previous, current) =>
          previous.isBookmarksLists != current.isBookmarksLists,
      builder: (context, state) {
        return SizedBox(
          height: kToolbarHeight - 5,
          child: Center(
            child: Stack(
              children: [
                if (!state.isBookmarksLists)
                  IconButton(
                    onPressed: () {
                      context.read<AddBookmarkCubit>().setView(true);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                Center(
                  child: Text(
                    state.isBookmarksLists
                        ? context.t.bookmarkLists.capitalize()
                        : context.t.submit.capitalize(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getView(bool isCurationsList, ScrollController controller) {
    return isCurationsList
        ? AddBookmarkLists(
            scrollController: controller,
          )
        : SubmitBookmarkList(
            controller: controller,
          );
  }
}

class AddBookmarkLists extends StatelessWidget {
  const AddBookmarkLists({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      builder: (context, state) {
        return ScrollShadow(
          color: Theme.of(context).primaryColorLight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 15.w : kDefaultPadding / 2,
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                const SliverToBoxAdapter(
                    child: SizedBox(height: kDefaultPadding / 2)),
                if (state.bookmarks.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyList(
                      description: context.t.addNewBookmark,
                      icon: FeatureIcons.bookmark,
                    ),
                  )
                else
                  _bookmarksList(state),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SliverList _bookmarksList(AddBookmarkState state) {
    return SliverList.separated(
      separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final model = context.read<AddBookmarkCubit>().model;
        final bookmarkList = state.bookmarks[index];
        final isAbsorbing =
            state.loadingBookmarksList.contains(bookmarkList.identifier);
        final isActive = model is BookmarkOtherType
            ? model.isTag
                ? bookmarkList.bookmarkedTags
                    .where(
                      (element) => element.val == model.val,
                    )
                    .isNotEmpty
                : bookmarkList.bookmarkedUrls
                    .where(
                      (element) => element.val == model.val,
                    )
                    .isNotEmpty
            : !isReplaceable(state.kind)
                ? bookmarkList.bookmarkedEvents.contains(state.eventId)
                : bookmarkList.bookmarkedReplaceableEvents
                    .any((e) => e.identifier == state.eventId);

        return BookmarkListContainer(
          isAbsorbing: isAbsorbing,
          bookmarkList: bookmarkList,
          isActive: isActive,
          onSetBookmark: () => context.read<AddBookmarkCubit>().setBookmark(
                bookmarkListIdentifier: bookmarkList.identifier,
              ),
        );
      },
      itemCount: state.bookmarks.length,
    );
  }
}

class SubmitBookmarkList extends HookWidget {
  const SubmitBookmarkList({super.key, required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      builder: (context, state) {
        return ListView(
          controller: controller,
          padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding / 2),
          children: [
            const SizedBox(height: kDefaultPadding),
            Text(
              context.t.setBookmarkTitleDescription,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kDefaultPadding),
            _buildTextField(
              context,
              hintText: context.t.title.capitalize(),
              onChanged: (title) => context
                  .read<AddBookmarkCubit>()
                  .setText(text: title, isTitle: true),
            ),
            const SizedBox(height: kDefaultPadding / 2),
            _buildTextField(
              context,
              hintText: context.t.descriptionOptional.capitalize(),
              onChanged: (description) => context
                  .read<AddBookmarkCubit>()
                  .setText(text: description, isTitle: false),
              maxLines: 3,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String hintText,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged,
      decoration: InputDecoration(hintText: hintText),
      maxLines: maxLines,
    );
  }
}

// Other classes remain unchanged but are formatted consistently

class BookmarkListContainer extends StatelessWidget {
  const BookmarkListContainer({
    super.key,
    required this.isAbsorbing,
    required this.isActive,
    required this.bookmarkList,
    required this.onSetBookmark,
  });

  final bool isAbsorbing;
  final bool isActive;
  final BookmarkListModel bookmarkList;
  final Function() onSetBookmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CommonThumbnail(
          image: bookmarkList.image,
          width: 50,
          height: 50,
          radius: kDefaultPadding / 2,
          isRound: true,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookmarkList.title.trim().capitalize(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                bookmarkList.description.trim().capitalize(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Builder(
          builder: (context) {
            return AbsorbPointer(
              absorbing: isAbsorbing,
              child: IconButton(
                onPressed: onSetBookmark,
                icon: isAbsorbing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                        ),
                      )
                    : SvgPicture.asset(
                        isActive
                            ? FeatureIcons.bookmarkChecked
                            : FeatureIcons.bookmarkAdd,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).primaryColorDark,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
            );
          },
        )
      ],
    );
  }
}

class AddBookmarkBottomBar extends HookWidget {
  const AddBookmarkBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddBookmarkCubit, AddBookmarkState>(
      buildWhen: (previous, current) =>
          previous.isBookmarksLists != current.isBookmarksLists,
      builder: (context, articleState) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                if (articleState.isBookmarksLists) {
                  context.read<AddBookmarkCubit>().setView(false);
                } else {
                  context.read<AddBookmarkCubit>().addBookmarkList();
                }
              },
              icon: Icon(
                articleState.isBookmarksLists ? Icons.add_rounded : Icons.check,
                size: 20,
              ),
              label: Text(
                articleState.isBookmarksLists
                    ? context.t.addBookmarkList
                    : context.t.submitBookmarkList,
              ),
            ),
          ),
        );
      },
    );
  }
}
