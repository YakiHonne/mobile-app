import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../logic/discover_cubit/discover_cubit.dart';
import '../../logic/leading_cubit/leading_cubit.dart';
import '../../logic/main_cubit/main_cubit.dart';
import '../../logic/media_cubit/media_cubit.dart';
import '../../logic/theme_cubit/theme_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/app_cycle.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../add_content_view/add_media_view.dart';
import '../discover_view/discover_view.dart' as discover;
import '../discover_view/discover_view.dart' hide LeadingNewContentBox;
import '../dm_view/dm_view.dart';
import '../leading_view/leading_view.dart';
import '../media_view/media_view.dart';
import '../notifications_view/notifications_view.dart';
import '../smart_widgets_view/smart_widgets_search.dart';
import '../wallet_cashu_view/cashu_view.dart';
import '../wallet_view/wallet_view.dart';
import '../widgets/app_icon.dart';
import '../widgets/fluid_scaffold.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/drawer_view.dart';
import 'widgets/feature_tour.dart';
import 'widgets/flip_to_share_wrapper.dart';
import 'widgets/main_view_appbar.dart';

/// Side inset that parks the new-content pill in the gap between the collapsed
/// tab pill and the "+" pill, matching the Apple Podcasts mini-player layout.
const _kCollapsedPillInset = kGlassNavCollapsedPillWidth + kDefaultPadding / 2;

/// Matches Flutter's own drawer slide.
const _kDrawerAnimation = Duration(milliseconds: 246);

final indexMap = {
  MainViews.leading: 0,
  MainViews.media: 1,
  MainViews.wallet: 2,
  MainViews.dms: 3,
  MainViews.notifications: 4,
  MainViews.smartWidgets: 5,
  MainViews.articles: 6,
};

class MainView extends HookWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize hooks at the top level of build
    final mainScrollControllers = useMemoized(
        () => [
              ScrollController(),
              ScrollController(),
              ScrollController(),
              ScrollController(),
              ScrollController(),
              ScrollController(),
              ScrollController(),
            ],
        []);

    // Dispose ScrollControllers to prevent memory leaks
    useEffect(() {
      return () {
        for (final controller in mainScrollControllers) {
          controller.dispose();
        }
      };
    }, [mainScrollControllers]);

    return BlocProvider(
      create: (context) {
        YakihonneCycle(buildContext: context);

        nostrRepository.mainCubit = MainCubit(context: context);

        return nostrRepository.mainCubit;
      },
      child: FlipToShareWrapper(
        child: MainViewContent(
          mainScrollControllers: mainScrollControllers,
        ),
      ),
    );
  }
}

class MainViewContent extends HookWidget {
  const MainViewContent({
    required this.mainScrollControllers,
    super.key,
  });

  final List<ScrollController> mainScrollControllers;

  @override
  Widget build(BuildContext context) {
    final barsVisible = useState(true);
    // Published by the glass nav bar so the new-content pill can drop into the
    // gap between the collapsed tab pill and the "+" pill.
    final navCollapsed = useState(false);
    final isGlass = context.watch<ThemeCubit>().state.isFluid;

    // The tour pins these on screen while it measures its targets.
    useEffect(() {
      mainBarsVisible = barsVisible;
      return () => mainBarsVisible = null;
    }, [barsVisible]);

    // Read current view index at hook level (outside BlocBuilder)
    final mainState = context.watch<MainCubit>().state;
    final currentIndex = indexMap[mainState.mainView] ?? 0;

    // Scroll listener — valid here since we're inside a HookWidget.build
    useEffect(() {
      if (!isGlass) {
        return null;
      }
      final safeIndex = currentIndex.clamp(0, mainScrollControllers.length - 1);
      final controller = mainScrollControllers[safeIndex];

      void listener() {
        // Not `hasClients`: that still passes with two attached scrollables,
        // and `position` throws "Too many elements" on those.
        if (controller.positions.length != 1) {
          return;
        }
        final dir = controller.position.userScrollDirection;
        if (dir == ScrollDirection.reverse && barsVisible.value) {
          barsVisible.value = false;
        } else if (dir == ScrollDirection.forward && !barsVisible.value) {
          barsVisible.value = true;
        }
      }

      controller.addListener(listener);
      barsVisible.value = true;
      return () => controller.removeListener(listener);
    }, [currentIndex, isGlass]);

    return BlocBuilder<MainCubit, MainState>(
      buildWhen: (previous, current) =>
          previous.isConnected != current.isConnected ||
          previous.mainView != current.mainView,
      builder: (context, state) {
        final currentIndex = indexMap[state.mainView] ?? 0;
        final isGlass = context.read<ThemeCubit>().state.isFluid;

        void onScrollTop() {
          // Re-tapping the active tab (or the app bar) also brings the bars —
          // and with them the source-filter row — back if a scroll hid them.
          barsVisible.value = true;
          if (mainScrollControllers[currentIndex].hasClients) {
            mainScrollControllers[currentIndex].animateTo(
              0.0,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
            );
          }
        }

        final showFab = state.mainView == MainViews.leading ||
            state.mainView == MainViews.media;

        final body = SafeArea(
          top: !isGlass,
          bottom: !isGlass,
          child: IndexedStack(
            index: currentIndex,
            children: [
              LeadingView(
                key: const PageStorageKey('leading'),
                scrollController: mainScrollControllers[0],
                barsVisible: barsVisible,
              ),
              MediaView(
                key: const PageStorageKey('media'),
                scrollController: mainScrollControllers[1],
                barsVisible: barsVisible,
              ),
              BlocBuilder<MainCubit, MainState>(
                builder: (context, state) => _walletWidget(state),
              ),
              DmsView(
                key: const PageStorageKey('dms'),
                // Index must match indexMap[MainViews.dms]; anything else
                // hands the bars a controller nothing is scrolling.
                scrollController: mainScrollControllers[3],
              ),
              NotificationsView(
                key: const PageStorageKey('notifications'),
                barsVisible: barsVisible,
                scrollController: mainScrollControllers[4],
              ),
              SmartWidgetsSearch(
                key: const PageStorageKey('smartwidgets'),
              ),
              DiscoverView(
                key: const PageStorageKey('discover'),
                barsVisible: barsVisible,
                scrollController: mainScrollControllers[6],
              ),
            ],
          ),
        );

        final glassScrollController = mainScrollControllers[
            currentIndex.clamp(0, mainScrollControllers.length - 1)];

        // Content-aware brightness anchors its initial (and post-theme-change)
        // verdict on MediaQuery.platformBrightness — the *device* setting. On a
        // dark-mode phone running the light theme that starts the bar dark, so
        // pin it to the app theme and let sampling take over from there.
        final glassBody = MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(platformBrightness: Theme.of(context).brightness),
          child: GlassContentAwareScope(
            // The scaffold background is painted outside the sampled boundary,
            // so the capture is transparent wherever the feed doesn't paint.
            // Without this the scope fills those pixels from the device
            // brightness and votes dark over a light feed.
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: GlassScaffold(
              // Sampling off: the edge fade repaints the scaffold colour
              // directly instead of a captured texture frozen at the old
              // theme, so it tracks theme changes immediately.
              enableBackgroundSampling: false,
              bottomEdgeFade: true,
              topEdgeFade: true,
              contentAwareBrightness: true,
              bottomBarHeight: kBottomNavigationBarHeight + kDefaultPadding / 2,
              appBar: FluidMainViewAppBar(
                isConnected: state.isConnected,
                scrollControllers: mainScrollControllers,
                onClicked: onScrollTop,
              ),
              bottomBar: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: kMaxBottomBarWidth),
                  child: LiquidGlassBottomNavigationBar(
                    key: TourKeys.navBar,
                    onClicked: onScrollTop,
                    scrollController: glassScrollController,
                    isCollapsed: navCollapsed,
                  ),
                ),
              ),
              bodyOverlays: [
                // New content pill. Expanded it floats above the nav bar;
                // collapsed it drops to bar level and insets either side so
                // it sits in the gap between the tab pill and the "+".
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  left: navCollapsed.value ? _kCollapsedPillInset : 0,
                  right: navCollapsed.value ? _kCollapsedPillInset : 0,
                  bottom: _newContentPillBottom(
                    context,
                    collapsed: navCollapsed.value,
                  ),
                  // Capped and centered like the bar itself, so the collapsed
                  // pill still lands in the gap between the tab pill and the
                  // "+" instead of drifting into a tablet's empty gutter.
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: kMaxBottomBarWidth),
                      child: _FluidNewContentOverlay(
                        key: ValueKey(state.mainView),
                        mainView: state.mainView,
                        scrollController: glassScrollController,
                        barsVisible: barsVisible,
                      ),
                    ),
                  ),
                ),
              ],
              body: body,
            ),
          ),
        );

        return isGlass
            ? ValueListenableBuilder<bool>(
                valueListenable: mainDrawerOpen,
                builder: (context, drawerOpen, _) => PopScope(
                  canPop: !drawerOpen,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop) {
                      mainDrawerOpen.value = false;
                    }
                  },
                  child: Stack(
                    children: [
                      // Drawer sits behind the body; the body slides right to
                      // reveal it. The drawer itself eases in with a light
                      // zoom + slide, and reverses on close.
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSlide(
                          duration: _kDrawerAnimation,
                          curve: Curves.fastOutSlowIn,
                          offset: Offset(drawerOpen ? 0 : -0.15, 0),
                          child: AnimatedScale(
                            duration: _kDrawerAnimation,
                            curve: Curves.fastOutSlowIn,
                            alignment: Alignment.centerLeft,
                            scale: drawerOpen ? 1 : 0.92,
                            child: AnimatedOpacity(
                              duration: _kDrawerAnimation,
                              opacity: drawerOpen ? 1 : 0,
                              child: const MainViewDrawer(),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSlide(
                        duration: _kDrawerAnimation,
                        curve: Curves.fastOutSlowIn,
                        offset: Offset(
                          drawerOpen
                              ? kMainDrawerWidth /
                                  MediaQuery.sizeOf(context).width
                              : 0,
                          0,
                        ),
                        child: Stack(
                          children: [
                            glassBody,
                            // Scrim: dims (or in dark mode, lifts) the pushed
                            // body, and takes the tap that closes the drawer.
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !drawerOpen,
                                child: AnimatedOpacity(
                                  duration: _kDrawerAnimation,
                                  curve: Curves.fastOutSlowIn,
                                  opacity: drawerOpen ? 1 : 0,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => mainDrawerOpen.value = false,
                                    child: ColoredBox(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Scaffold(
                key: mainScaffoldKey,
                resizeToAvoidBottomInset: true,
                bottomNavigationBar:
                    MainViewBottomNavigationBar(onClicked: onScrollTop),
                floatingActionButton: showFab
                    ? _createContent(context, state.mainView)
                    : const SizedBox(),
                appBar: MainViewAppBar(
                  isConnected: state.isConnected,
                  scrollControllers: mainScrollControllers,
                  onClicked: onScrollTop,
                ),
                drawer: const MainViewDrawer(),
                body: body,
              );
      },
    );
  }

  Widget _walletWidget(MainState state) {
    if (state.isCashuWallet) {
      return const CashuWalletView(
        key: PageStorageKey('cashu'),
      );
    } else {
      return InternalWalletsView(
        key: const PageStorageKey('wallet'),
      );
    }
  }

  /// Bottom inset for the new-content pill, measured from the raw Stack the
  /// `GlassScaffold` `bodyOverlays` live in.
  ///
  /// `GlassScaffold` wraps its bottom bar in `SafeArea(bottom: android)`, so
  /// on Android the bar — and with it the tab and "+" pills — sits
  /// `padding.bottom` above the screen's bottom edge, while the overlay is not.
  /// Add that offset back, then anchor to the bar's own geometry: the pill
  /// bottoms float `kDefaultPadding` (the package `verticalPadding`) above the
  /// bar's bottom edge. Collapsed, the pill drops to bar level to sit in the
  /// gap; expanded, it floats above the whole bar.
  double _newContentPillBottom(BuildContext context, {required bool collapsed}) {
    if (collapsed) {
      final safeBottom = defaultTargetPlatform == TargetPlatform.android
          ? MediaQuery.of(context).padding.bottom
          : 0.0;
      return safeBottom + kDefaultPadding;
    }
    return fluidBottomBarInset(context, above: kDefaultPadding / 2);
  }

  RepaintBoundary _createContent(BuildContext context, MainViews mainView) {
    final isMedia = mainView == MainViews.media;

    return RepaintBoundary(
      child: GestureDetector(
        key: TourKeys.create,
        onLongPress: () {
          doIfCanSign(
            func: () {
              HapticFeedback.mediumImpact();

              final addContent = AddContentView(
                contentType: AppContentType.values.firstWhere(
                  (e) =>
                      e.name ==
                      nostrRepository
                          .currentAppCustomization?.writingContentType,
                  orElse: () => AppContentType.note,
                ),
              );

              final addMedia = AddMediaView();

              YNavigator.pushPage(
                context,
                (_) => isMedia ? addMedia : addContent,
              );
            },
            context: context,
          );
        },
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).primaryColor,
          shape: const CircleBorder(),
          heroTag: 'content_creation',
          child: AppIcon(
            isMedia ? FeatureIcons.mediaAdd : FeatureIcons.addRaw,
            size: isMedia ? 25 : 22,
            color: kWhite,
          ),
          onPressed: () {
            doIfCanSign(
              func: () {
                HapticFeedback.mediumImpact();
                HapticFeedback.mediumImpact();

                final addContent = AddContentView();

                final addMedia = AddMediaView();

                YNavigator.pushPage(
                  context,
                  (_) => isMedia ? addMedia : addContent,
                );
              },
              context: context,
            );
          },
        ),
      ),
    );
  }
}

class _FluidNewContentOverlay extends HookWidget {
  const _FluidNewContentOverlay({
    super.key,
    required this.mainView,
    required this.scrollController,
    required this.barsVisible,
  });

  final MainViews mainView;
  final ScrollController scrollController;
  final ValueNotifier<bool> barsVisible;

  @override
  Widget build(BuildContext context) {
    if (mainView == MainViews.leading) {
      final isShowing = useState(leadingCubit.state.extraContent.isNotEmpty);

      return BlocConsumer<LeadingCubit, LeadingState>(
        listenWhen: (p, c) => p.extraContent != c.extraContent,
        listener: (context, state) {
          isShowing.value = state.extraContent.isNotEmpty;
        },
        builder: (context, state) {
          return LeadingNewContentBox(
            extraContent: state.extraContent,
            isShowing: isShowing,
            onClicked: () {
              barsVisible.value = true;
              leadingCubit.appendExtra(() {
                scrollController.jumpTo(0);
              });
            },
          );
        },
      );
    }

    if (mainView == MainViews.media) {
      final isShowing = useState(mediaCubit.state.extraContent.isNotEmpty);

      return BlocConsumer<MediaCubit, MediaState>(
        listenWhen: (p, c) => p.extraContent != c.extraContent,
        listener: (context, state) {
          isShowing.value = state.extraContent.isNotEmpty;
        },
        builder: (context, state) {
          return discover.LeadingNewContentBox(
            extraContent: state.extraContent,
            isShowing: isShowing,
            onClicked: () {
              barsVisible.value = true;
              mediaCubit.appendExtra();
              scrollController.jumpTo(0);
            },
          );
        },
      );
    }

    if (mainView == MainViews.articles) {
      final isShowing = useState(discoverCubit.state.extraContent.isNotEmpty);

      return BlocConsumer<DiscoverCubit, DiscoverState>(
        listenWhen: (p, c) => p.extraContent != c.extraContent,
        listener: (context, state) {
          isShowing.value = state.extraContent.isNotEmpty;
        },
        builder: (context, state) {
          return discover.LeadingNewContentBox(
            extraContent: state.extraContent,
            isShowing: isShowing,
            onClicked: () {
              barsVisible.value = true;
              discoverCubit.appendExtra();
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
