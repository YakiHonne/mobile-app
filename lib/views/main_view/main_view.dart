import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
import '../discover_view/discover_view.dart' hide LeadingNewContentBox;
import '../discover_view/discover_view.dart' as discover;
import '../dm_view/dm_view.dart';
import '../leading_view/leading_view.dart';
import '../media_view/media_view.dart';
import '../notifications_view/notifications_view.dart';
import '../smart_widgets_view/smart_widgets_search.dart';
import '../wallet_cashu_view/cashu_view.dart';
import '../wallet_view/wallet_view.dart';
import '../widgets/app_icon.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/drawer_view.dart';
import 'widgets/feature_tour.dart';
import 'widgets/flip_to_share_wrapper.dart';
import 'widgets/main_view_appbar.dart';

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
        if (!controller.hasClients) {
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
                scrollController: mainScrollControllers[2],
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

        return Scaffold(
          resizeToAvoidBottomInset: true,
          drawerScrimColor: isGlass ? Colors.transparent : null,
          bottomNavigationBar: isGlass
              ? null
              : MainViewBottomNavigationBar(onClicked: onScrollTop),
          floatingActionButton: isGlass
              ? null
              : (showFab
                  ? _createContent(context, state.mainView)
                  : const SizedBox()),
          appBar: isGlass
              ? null
              : MainViewAppBar(
                  isConnected: state.isConnected,
                  scrollControllers: mainScrollControllers,
                  onClicked: onScrollTop,
                ),
          drawer: const MainViewDrawer(),
          extendBody: isGlass,
          body: isGlass
              ? Stack(
                  children: [
                    body,
                    // App bar — slides up off-screen
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRect(
                        child: IgnorePointer(
                          ignoring: !barsVisible.value,
                          child: AnimatedSlide(
                            offset: barsVisible.value
                                ? Offset.zero
                                : const Offset(0, -1),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: FluidMainViewAppBar(
                              isConnected: state.isConnected,
                              scrollControllers: mainScrollControllers,
                              onClicked: onScrollTop,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // New content overlay — floats above nav bar when visible,
                    // drops to above safe area when nav bar is hidden.
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: 0,
                      right: 0,
                      bottom: barsVisible.value
                          ? MediaQuery.of(context).padding.bottom / 2 +
                              kDefaultPadding / 4 +
                              kBottomNavigationBarHeight +
                              kDefaultPadding
                          : MediaQuery.of(context).padding.bottom +
                              kDefaultPadding / 2,
                      child: _FluidNewContentOverlay(
                        key: ValueKey(state.mainView),
                        mainView: state.mainView,
                        scrollController: mainScrollControllers[
                            (indexMap[state.mainView] ?? 0).clamp(
                                0, mainScrollControllers.length - 1)],
                        barsVisible: barsVisible,
                      ),
                    ),
                    // Nav bar — slides down off-screen, clipped at screen edge
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRect(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom / 2 +
                                kDefaultPadding / 4,
                          ),
                          child: IgnorePointer(
                            ignoring: !barsVisible.value,
                            child: AnimatedSlide(
                              offset: barsVisible.value
                                  ? Offset.zero
                                  : const Offset(0, 2),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: Center(
                                child: FluidBottomNavigationBar(
                                  onClicked: onScrollTop,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : body,
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
