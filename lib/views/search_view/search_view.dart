// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/search_cubit/search_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../routes/pages_router.dart';
import '../../utils/theme/glass_settings.dart';
import '../../utils/utils.dart';
import '../article_view/article_view.dart';
import '../media_view/media_view.dart';
import '../relay_feed_view/relay_feed_view.dart';
import '../settings_view/widgets/relays_update.dart';
import '../widgets/app_icon.dart';
import '../widgets/article_container.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/content_placeholder.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/fluid_blur_container.dart';
import '../widgets/fluid_content_card.dart';
import '../widgets/fluid_glass_tab_bar.dart';
import '../widgets/media_components/horizontal_video_view.dart';
import '../widgets/media_components/vertical_video_view.dart';
import '../widgets/nip05_component.dart';
import '../widgets/note_stats.dart';
import '../widgets/profile_picture.dart';
import '../widgets/subscription_badge_view.dart';
import '../widgets/tag_container.dart';
import '../widgets/video_common_container.dart';

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
      context.t.notes.capitalizeFirst(),
      context.t.articles.capitalizeFirst(),
      context.t.media.capitalizeFirst(),
    ];

    final searchText = useState(search);
    final searchTextEdittingController = useTextEditingController();
    final selectedIndex = useState(index ?? 0);
    final focusNode = useFocusNode();
    // FluidGlassTabBar is controller-driven; selectedIndex stays the source of
    // truth for the body, the controller only mirrors it for the glass pill.
    final tabController = useTabController(
      initialLength: contentOptions.length,
      initialIndex: index ?? 0,
    );

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
              searchCubit.getItemsBySearch(searchText.value);
            },
          );
        }
      },
    );

    final isGlass = isFluid();

    return BlocProvider(
      create: (context) => searchCubit,
      child: Scaffold(
        body: isGlass
            ? _buildGlassBody(
                context,
                focusNode,
                searchTextEdittingController,
                searchText,
                selectedIndex,
                contentOptions,
                tabController,
              )
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _appbar(focusNode, searchTextEdittingController, searchText,
                        context),
                    _tagsList(contentOptions, selectedIndex)
                  ];
                },
                body: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SizedBox(height: kDefaultPadding / 2),
                    ),
                    if (canSign())
                      _interestsList(searchText, searchTextEdittingController),
                    if (selectedIndex.value != 0 &&
                        searchText.value != null &&
                        searchText.value!.isNotEmpty)
                      _interestRow(searchText),
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
    );
  }

  Widget _buildGlassBody(
    BuildContext context,
    FocusNode focusNode,
    TextEditingController searchTextEdittingController,
    ValueNotifier<String?> searchText,
    ValueNotifier<int> selectedIndex,
    List<String> contentOptions,
    TabController tabController,
  ) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // Search bar: safe area + toolbar content height + vertical padding
    final searchBarHeight =
        safeTop + (kToolbarHeight - 10) + kDefaultPadding / 2;
    // Tab pill bottom offset clears the main glass nav bar
    final tabPillBottom = safeBottom;
    // Content inset: top clears search bar, bottom clears tab pill + nav bar
    const tabPillHeight = 38.0;
    final contentBottomInset =
        tabPillBottom + tabPillHeight + kDefaultPadding / 2;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: searchBarHeight)),
            SliverToBoxAdapter(child: _relayConnectivityBox()),
            if (canSign())
              _interestsList(searchText, searchTextEdittingController),
            if (selectedIndex.value != 0 &&
                searchText.value != null &&
                searchText.value!.isNotEmpty)
              _interestRow(searchText),
            BlocBuilder<SearchCubit, SearchState>(
              buildWhen: (previous, current) =>
                  previous.profileSearchResult != current.profileSearchResult ||
                  previous.authors != current.authors ||
                  previous.contentSearchResult != current.contentSearchResult ||
                  previous.content != current.content,
              builder: (context, state) {
                if (selectedIndex.value == 0) {
                  return getProfiles(
                    isTablet:
                        ResponsiveBreakpoints.of(context).largerThan(MOBILE),
                    searchResultsType: state.profileSearchResult,
                    context: context,
                  );
                } else {
                  return getContent(
                    isTablet:
                        ResponsiveBreakpoints.of(context).largerThan(MOBILE),
                    contentType: selectedIndex.value,
                    searchResultsType: state.contentSearchResult,
                    context: context,
                  );
                }
              },
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: contentBottomInset),
            ),
          ],
        ),
        // Floating glass search bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: safeTop + kDefaultPadding / 4,
              bottom: kDefaultPadding / 4,
              left: kDefaultPadding / 4,
              right: kDefaultPadding / 4,
            ),
            child: Row(
              spacing: kDefaultPadding / 4,
              children: [
                AppIconButton(
                  icon: FeatureIcons.arrowLeft,
                  onClicked: () => Navigator.pop(context),
                  size: 40,
                  iconSize: 20,
                ),
                Expanded(
                  child: _glassSearchBar(
                    focusNode,
                    searchTextEdittingController,
                    searchText,
                  ),
                ),
                AppIconButton(
                  icon: FeatureIcons.settings,
                  onClicked: () {
                    YNavigator.push(
                      context,
                      SlideupPageRoute(
                        builder: (context) => RelayUpdateView(initialIndex: 2),
                        settings: const RouteSettings(),
                      ),
                    );
                  },
                  size: 40,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),

        // Floating glass tab pill at the bottom
        Positioned(
          bottom: tabPillBottom,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 90.w,
              child: FluidGlassTabBar(
                floating: true,
                barHeight: tabPillHeight,
                controller: tabController,
                onTap: (i) {
                  selectedIndex.value = i;
                  HapticFeedback.lightImpact();
                },
                tabs: [
                  for (final option in contentOptions) GlassTab(label: option),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BlocBuilder<SearchCubit, SearchState> _interestRow(
      ValueNotifier<String?> searchText) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (previous, current) => previous.refresh != current.refresh,
      builder: (context, state) {
        final tag = searchText.value?.startsWith('#') ?? false
            ? searchText.value!
            : '#${searchText.value!}';

        final row = Row(
          children: [
            Expanded(
              child: Text(
                tag,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            _addInterest(searchText),
          ],
        );

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 4,
            ),
            child: isFluid()
                ? FluidCardContainer(
                    borderRadius: kDefaultPadding / 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding / 4,
                    ),
                    child: row,
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                      vertical: kDefaultPadding / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(kDefaultPadding),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: row,
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

        return AppIconButton(
          onClicked: () {
            doIfCanSign(
              func: () {
                context.read<SearchCubit>().updateInterest(
                      searchText.value!,
                    );
              },
              context: context,
            );
          },
          icon: isActive ? FeatureIcons.trash : FeatureIcons.add,
          size: 36,
          iconSize: 18,
          buttonStatus: isActive ? ButtonStatus.active : ButtonStatus.inactive,
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
                  if (!isFluid())
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
      color: isFluid()
          ? Colors.transparent
          : Theme.of(context).scaffoldBackgroundColor,
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
    final label = Text(
      interest.startsWith('#') ? interest : '#$interest',
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );

    return GestureDetector(
      onTap: () {
        searchText.value = interest;
        searchTextEdittingController.text = interest;
        context.read<SearchCubit>().getItemsBySearch(interest);
      },
      child: isFluid()
          ? FluidCardContainer(
              borderRadius: 300,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 1.5,
                vertical: kDefaultPadding / 4,
              ),
              child: label,
            )
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 1.5,
                vertical: kDefaultPadding / 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(300),
                color: searchText.value == interest
                    ? Theme.of(context).cardColor
                    : null,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
              child: label,
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
      ValueNotifier<String?> searchText,
      BuildContext context) {
    return SliverAppBar(
      toolbarHeight: kToolbarHeight - 10,
      leadingWidth: 40,
      pinned: true,
      title: _cupertinoTextfield(
          focusNode, searchTextEdittingController, searchText),
      titleSpacing: 0,
      actions: [
        CustomIconButton(
            onClicked: () {
              YNavigator.push(
                context,
                SlideupPageRoute(
                  builder: (context) => RelayUpdateView(initialIndex: 2),
                  settings: const RouteSettings(),
                ),
              );
            },
            icon: FeatureIcons.settings,
            size: kDefaultPadding,
            backgroundColor: kTransparent),
        const SizedBox(
          width: kDefaultPadding / 2,
        )
      ],
    );
  }

  /// Fluid-mode search field. [GlassSearchBar] has no accessory slot, so the
  /// `isSearching` spinner lives beside it in the header row instead of inside
  /// the pill — see [_searchingSpinner]. Its built-in clear button fires
  /// `onChanged('')`, which resets the results the same way the normal path's
  /// × does.
  Widget _glassSearchBar(
    FocusNode focusNode,
    TextEditingController searchTextEdittingController,
    ValueNotifier<String?> searchText,
  ) {
    return Builder(builder: (context) {
      void search(String value) {
        searchText.value = value.isEmpty ? null : value;
        context.read<SearchCubit>().getItemsBySearch(value);
      }

      // GlassTextField wraps a bare CupertinoTextField and exposes no
      // cursorColor/selectionColor, so the caret and the selection band fall
      // back to CupertinoTheme.primaryColor — activeBlue. Overriding it here is
      // the only hook; it tints the caret, the band and the drag handles
      // together.
      return CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(
          primaryColor: Theme.of(context).primaryColorDark,
        ),
        child: GlassTextField.search(
          controller: searchTextEdittingController,
          focusNode: focusNode,
          placeholder: context.t.search.capitalizeFirst(),
          height: 40,
          useOwnLayer: true,
          settings: GlassSettings.searchBar(context),
          // No glow, no press-scale: they read as the field lighting up under
          // the finger while the user types.
          interactionBehavior: GlassInteractionBehavior.none,
          shape: const LiquidRoundedRectangle(borderRadius: 20),
          textStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon: Icon(
            LucideIcons.search,
            size: 20,
            color: Theme.of(context).highlightColor,
          ),
          suffixIcon: _searchSuffix(searchTextEdittingController),
          onSuffixTap: () {
            if (searchTextEdittingController.text.isEmpty) {
              return;
            }

            searchTextEdittingController.clear();
            search('');
          },
          onChanged: search,
        ),
      );
    });
  }

  /// Spinner and clear × share the one suffix slot. Both are laid out
  /// unconditionally at a fixed width — `isSearching` flips on every keystroke,
  /// so anything that resized here would make the field breathe while typing.
  Widget _searchSuffix(TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding / 4,
      children: [
        BlocBuilder<SearchCubit, SearchState>(
          buildWhen: (previous, current) =>
              previous.isSearching != current.isSearching,
          builder: (context, state) => AnimatedOpacity(
            opacity: state.isSearching ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: SpinKitCircle(
              size: 18,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => AnimatedOpacity(
            opacity: value.text.isEmpty ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              LucideIcons.x,
              size: 18,
              color: Theme.of(context).highlightColor,
            ),
          ),
        ),
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
                LucideIcons.search,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                      LucideIcons.x,
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
      return SliverToBoxAdapter(
        child: contentType == 3
            ? const MediaPlaceholder()
            : const Padding(
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
          AppIcon(
            FeatureIcons.search,
            size: 40,
            color: Theme.of(context).primaryColorDark,
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

        if (contentType == 3) {
          return MediaGrid(
            content: content,
            loadVideos: true,
          );
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
        separatorBuilder: (context, index) => useFluidCards()
            ? const SizedBox(height: kDefaultPadding / 2)
            : const Divider(
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
    return FluidContentCard(
      child: BlocBuilder<SearchCubit, SearchState>(
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
              isExtended: true,
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  List<BaseEventModel> getFilteredContent(
    List<BaseEventModel> totalContent,
    int contentType,
  ) {
    if (contentType == 2) {
      return totalContent.whereType<Article>().toList();
    } else if (contentType == 3) {
      return totalContent
          .where((element) => element is VideoModel || element is PictureModel)
          .toList();
    } else if (contentType == 1) {
      return totalContent.whereType<DetailedNoteModel>().toList();
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
    this.hasAction = false,
    this.isAdded = false,
  });

  final Metadata metadata;
  final Function()? onClick;
  final bool youFollow;
  final bool hasAction;
  final bool isAdded;

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
          if (hasAction)
            CustomIconButton(
              onClicked: onClick ?? () {},
              icon: isAdded
                  ? FeatureIcons.profileRemove
                  : FeatureIcons.profileAdd,
              size: 17,
              backgroundColor: isAdded
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
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
        const SizedBox(width: kDefaultPadding / 4),
        SubscriptionBadgeView(pubkey: metadata.pubkey, size: 16),
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
