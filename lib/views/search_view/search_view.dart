// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/search_cubit/search_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../article_view/article_view.dart';
import '../relay_feed_view/relay_feed_view.dart';
import '../widgets/article_container.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/nip05_component.dart';
import '../widgets/note_stats.dart';
import '../widgets/profile_picture.dart';
import '../widgets/tag_container.dart';
import '../widgets/video_common_container.dart';
import '../widgets/video_components/horizontal_video_view.dart';
import '../widgets/video_components/vertical_video_view.dart';

// ignore: must_be_immutable
class SearchView extends HookWidget {
  SearchView({super.key, this.search, this.index}) {
    umamiAnalytics.trackEvent(screenName: 'Search view');
  }

  final String? search;
  final int? index;
  late SearchCubit searchCubit;

  @override
  Widget build(BuildContext context) {
    final contentOptions = [
      context.t.people.capitalizeFirst(),
      context.t.allMedia.capitalizeFirst(),
      context.t.notes.capitalizeFirst(),
      context.t.articles.capitalizeFirst(),
      context.t.videos.capitalizeFirst(),
    ];

    final searchText = useState(search);
    final searchTextEdittingController = useTextEditingController();
    final selectedIndex = useState(index ?? 0);
    final focusNode = useFocusNode();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Small delay to let the widget tree settle before focusing
        Future.delayed(const Duration(milliseconds: 500), () {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
      });

      return null;
    }, []);

    useMemoized(
      () {
        searchCubit = SearchCubit(
          context: context,
        );

        if (searchText.value != null && searchText.value!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
              searchTextEdittingController.text = searchText.value!;
              searchCubit.getItemsBySearch(searchText.value!);
            },
          );
        }
      },
    );

    return BlocProvider(
      create: (context) => searchCubit,
      child: Scaffold(
        body: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _appbar(focusNode, searchTextEdittingController, searchText),
                _tagsList(contentOptions, selectedIndex)
              ];
            },
            body: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                ),
                if (canSign()) ...[
                  _interestsList(searchText, searchTextEdittingController)
                ],
                if (selectedIndex.value != 0 &&
                    searchText.value != null &&
                    searchText.value!.isNotEmpty) ...[
                  _interestRow(searchText),
                ],
                BlocBuilder<SearchCubit, SearchState>(
                  buildWhen: (previous, current) =>
                      previous.profileSearchResult !=
                          current.profileSearchResult ||
                      previous.authors != current.authors ||
                      previous.contentSearchResult !=
                          current.contentSearchResult ||
                      previous.content != current.content,
                  builder: (context, state) {
                    if (selectedIndex.value == 0) {
                      return getProfiles(
                        isTablet: ResponsiveBreakpoints.of(context)
                            .largerThan(MOBILE),
                        searchResultsType: state.profileSearchResult,
                        context: context,
                      );
                    } else {
                      return getContent(
                        isTablet: ResponsiveBreakpoints.of(context)
                            .largerThan(MOBILE),
                        contentType: selectedIndex.value,
                        searchResultsType: state.contentSearchResult,
                        context: context,
                      );
                    }
                  },
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: kBottomNavigationBarHeight +
                        MediaQuery.of(context).padding.bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BlocBuilder<SearchCubit, SearchState> _interestRow(
      ValueNotifier<String?> searchText) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => previous.refresh != current.refresh,
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                const Divider(
                  thickness: 0.5,
                  height: 0,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${searchText.value}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(
                        width: kDefaultPadding / 2,
                      ),
                      _addInterest(searchText),
                    ],
                  ),
                ),
                const Divider(
                  thickness: 0.5,
                  height: 0,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Builder _addInterest(ValueNotifier<String?> searchText) {
    return Builder(
      builder: (context) {
        final isActive =
            canSign() && nostrRepository.interests.contains(searchText.value);

        return TextButton.icon(
          onPressed: () {
            doIfCanSign(
              func: () {
                context.read<SearchCubit>().updateInterest(
                      searchText.value!,
                    );
              },
              context: context,
            );
          },
          label: Icon(
            isActive ? Icons.check : Icons.add,
            size: 15,
            color: Theme.of(context).primaryColorDark,
          ),
          icon: Text(
            isActive ? context.t.notInterested : context.t.interested,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            backgroundColor:
                isActive ? kMainColor : Theme.of(context).cardColor,
          ),
        );
      },
    );
  }

  BlocBuilder<SearchCubit, SearchState> _interestsList(
      ValueNotifier<String?> searchText,
      TextEditingController searchTextEdittingController) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state.interests.isNotEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                    thickness: 0.5,
                    height: 0,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  Text(
                    context.t.interests.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  _scrollableInterestsList(
                      context, state, searchText, searchTextEdittingController),
                  const SizedBox(
                    height: kDefaultPadding / 1.5,
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          );
        }
      },
    );
  }

  ScrollShadow _scrollableInterestsList(
      BuildContext context,
      SearchState state,
      ValueNotifier<String?> searchText,
      TextEditingController searchTextEdittingController) {
    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(
            width: kDefaultPadding / 4,
          ),
          itemBuilder: (context, index) {
            final interest = state.interests[index];
            return _interestContainer(
                searchText, interest, searchTextEdittingController, context);
          },
          itemCount: state.interests.length,
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }

  GestureDetector _interestContainer(
      ValueNotifier<String?> searchText,
      String interest,
      TextEditingController searchTextEdittingController,
      BuildContext context) {
    return GestureDetector(
      onTap: () {
        searchText.value = interest;
        searchTextEdittingController.text = interest;
        context.read<SearchCubit>().getItemsBySearch(interest);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(300),
          color:
              searchText.value == interest ? Theme.of(context).cardColor : null,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Text(
          interest.startsWith('#') ? interest : '#$interest',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  BlocBuilder<SearchCubit, SearchState> _tagsList(
      List<String> contentOptions, ValueNotifier<int> selectedIndex) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return PinnedHeaderSliver(
          child: Column(
            children: [
              _relayConnectivityBox(),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (context, index) => const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    itemBuilder: (context, index) {
                      final title = contentOptions[index];

                      return TagContainer(
                        title: title,
                        isActive: selectedIndex.value == index,
                        onClick: () {
                          selectedIndex.value = index;
                          HapticFeedback.lightImpact();
                        },
                      );
                    },
                    itemCount: contentOptions.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _appbar(
      FocusNode focusNode,
      TextEditingController searchTextEdittingController,
      ValueNotifier<String?> searchText) {
    return SliverAppBar(
      toolbarHeight: kToolbarHeight - 10,
      leadingWidth: 40,
      pinned: true,
      title: Hero(
        tag: 'searchField',
        child: _cupertinoTextfield(
            focusNode, searchTextEdittingController, searchText),
      ),
      titleSpacing: 0,
      actions: const [
        SizedBox(
          width: kDefaultPadding / 2,
        )
      ],
    );
  }

  Widget _cupertinoTextfield(
      FocusNode focusNode,
      TextEditingController searchTextEdittingController,
      ValueNotifier<String?> searchText) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: CupertinoTextField(
            focusNode: focusNode,
            placeholder: context.t.search.capitalizeFirst(),
            controller: searchTextEdittingController,
            cursorColor:
                Theme.of(context).primaryColorDark.withValues(alpha: 0.5),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Icon(
                CupertinoIcons.search,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Row(
                children: [
                  if (state.isSearching) ...[
                    SpinKitCircle(
                      size: 18,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                  ],
                  GestureDetector(
                    onTap: () {
                      searchTextEdittingController.clear();
                      searchText.value = null;
                      context.read<SearchCubit>().getItemsBySearch('');
                    },
                    child: const Icon(
                      Icons.close,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (search) {
              searchText.value = search;

              context.read<SearchCubit>().getItemsBySearch(search);
            },
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        );
      },
    );
  }

  BlocBuilder<SearchCubit, SearchState> _relayConnectivityBox() {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state.relayConnectivity == RelayConnectivity.idle) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            if (state.relayConnectivity == RelayConnectivity.found) {
              YNavigator.pushPage(
                context,
                (context) => RelayFeedView(
                  relay: state.search,
                ),
              );
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            margin: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(
                kDefaultPadding / 2,
              ),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: kDefaultPadding / 4,
              children: [
                if (state.relayConnectivity == RelayConnectivity.searching) ...[
                  SpinKitCircle(
                    color: Theme.of(context).highlightColor,
                    size: 15,
                  ),
                  Flexible(
                    child: Text(
                      context.t.checkingRelayConnectivity,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                if (state.relayConnectivity == RelayConnectivity.notFound) ...[
                  Text(
                    context.t.unreachableRelay,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: kRed,
                        ),
                  ),
                ],
                if (state.relayConnectivity == RelayConnectivity.found) ...[
                  Text(
                    context.t.browseRelay,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Flexible(
                    child: Text(
                      state.search,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: kGreen,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getProfiles({
    required bool isTablet,
    required SearchResultsType searchResultsType,
    required BuildContext context,
  }) {
    if (searchResultsType == SearchResultsType.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding / 2),
          child: ExploreMediaSkeleton(),
        ),
      );
    } else if (searchResultsType == SearchResultsType.noSearch) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          child: SearchIdle(),
        ),
      );
    } else {
      return const UsersList();
    }
  }

  Widget getContent({
    required bool isTablet,
    required int contentType,
    required SearchResultsType searchResultsType,
    required BuildContext context,
  }) {
    if (searchResultsType == SearchResultsType.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding / 2),
          child: ExploreMediaSkeleton(),
        ),
      );
    } else if (searchResultsType == SearchResultsType.noSearch) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
            vertical: kDefaultPadding,
          ),
          child: SearchIdle(),
        ),
      );
    } else {
      return ContentList(
        contentType: contentType,
      );
    }
  }
}

class SearchNoResult extends StatelessWidget {
  const SearchNoResult({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding,
      ),
      child: Column(
        children: [
          Text(
            context.t.noResKeyword.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            context.t.noResKeywordDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SearchIdle extends StatelessWidget {
  const SearchIdle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            FeatureIcons.search,
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Text(
            context.t.searchInNostr.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            context.t.findPeopleContent.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.contentType,
  });

  final int contentType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => previous.content != current.content,
      builder: (context, state) {
        final content = getFilteredContent(state.content, contentType);

        if (content.isEmpty) {
          return const SliverToBoxAdapter(child: SearchNoResult());
        }

        if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
          return _itemsGrid(content);
        } else {
          return _itemsList(content);
        }
      },
    );
  }

  SliverPadding _itemsList(List<dynamic> content) {
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverList.separated(
        itemCount: content.length,
        separatorBuilder: (context, index) => const Divider(
          height: kDefaultPadding,
          thickness: 0.5,
        ),
        itemBuilder: (context, index) {
          final item = content[index];

          return getItem(item);
        },
      ),
    );
  }

  SliverPadding _itemsGrid(List<dynamic> content) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        childCount: content.length,
        crossAxisSpacing: kDefaultPadding / 2,
        mainAxisSpacing: kDefaultPadding / 2,
        itemBuilder: (context, index) {
          final item = content[index];

          return getItem(item);
        },
      ),
    );
  }

  Widget getItem(BaseEventModel item) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (item is Article) {
          return ArticleContainer(
            article: item,
            highlightedTag: '',
            isMuted: state.mutes.contains(item.pubkey),
            isBookmarked: state.bookmarks.contains(item.identifier),
            onClicked: () {
              Navigator.pushNamed(
                context,
                ArticleView.routeName,
                arguments: item,
              );
            },
            isFollowing: contactListCubit.contacts.contains(item.pubkey),
          );
        } else if (item is VideoModel) {
          final video = item;

          return VideoCommonContainer(
            isBookmarked: state.bookmarks.contains(item.id),
            isMuted: state.mutes.contains(video.pubkey),
            isFollowing: contactListCubit.contacts.contains(video.pubkey),
            video: video,
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
        } else if (item is DetailedNoteModel) {
          return DetailedNoteContainer(
            key: ValueKey(item.id),
            note: item,
            isMain: false,
            addLine: false,
            enableReply: true,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  List<dynamic> getFilteredContent(
    List<dynamic> totalContent,
    int contentType,
  ) {
    if (contentType == 3) {
      return totalContent.whereType<Article>().toList();
    } else if (contentType == 4) {
      return totalContent.whereType<VideoModel>().toList();
    } else if (contentType == 2) {
      return totalContent.whereType<DetailedNoteModel>().toList();
    } else if (contentType == 1) {
      return totalContent;
    } else {
      return [];
    }
  }
}

class UsersList extends HookWidget {
  const UsersList({super.key});

  @override
  Widget build(BuildContext context) {
    final contactList = useMemoized(() {
      return contactListCubit.contacts;
    });

    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => previous.authors != current.authors,
      builder: (context, state) {
        if (state.authors.isEmpty) {
          return const SliverToBoxAdapter(child: SearchNoResult());
        }

        return SliverPadding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          sliver: SliverList.separated(
            itemBuilder: (context, index) {
              final user = state.authors[index];

              return SearchAuthorContainer(
                key: ValueKey(user.pubkey),
                youFollow: contactList.contains(user.pubkey),
                metadata: user,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(
              height: kDefaultPadding / 2,
            ),
            itemCount: state.authors.length,
          ),
        );
      },
    );
  }
}

class SearchAuthorContainer extends HookWidget {
  const SearchAuthorContainer({
    super.key,
    required this.metadata,
    required this.youFollow,
    this.onClick,
  });

  final Metadata metadata;
  final Function()? onClick;
  final bool youFollow;

  @override
  Widget build(BuildContext context) {
    final f = useCallback(
      () {
        if (onClick != null) {
          onClick!.call();
        } else {
          openProfileFastAccess(context: context, pubkey: metadata.pubkey);
        }
      },
    );

    return GestureDetector(
      onTap: () => f.call(),
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: <Widget>[
          ProfilePicture3(
            size: 40,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () => f.call(),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metadataRow(context),
                Nip05Component(
                  metadata: metadata,
                  removeSpace: true,
                  useNip05: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row _metadataRow(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            metadata.getName(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (youFollow) ...[
          const SizedBox(
            width: kDefaultPadding / 3,
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 4),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: Text(
              context.t.youFollow.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
        ]
      ],
    );
  }
}

class SearchLoading extends StatelessWidget {
  const SearchLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
      ),
      child: SpinKitThreeBounce(
        color: Theme.of(context).primaryColorDark,
        size: 15,
      ),
    );
  }
}
