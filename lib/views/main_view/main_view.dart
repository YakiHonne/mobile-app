import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../logic/main_cubit/main_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/app_cycle.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../discover_view/discover_view.dart';
import '../dm_view/dm_view.dart';
import '../leading_view/leading_view.dart';
import '../notifications_view/notifications_view.dart';
import '../smart_widgets_view/smart_widgets_search.dart';
import '../wallet_view/wallet_view.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/drawer_view.dart';
import 'widgets/main_view_appbar.dart';

final indexMap = {
  MainViews.leading: 0,
  MainViews.discover: 1,
  MainViews.wallet: 2,
  MainViews.dms: 3,
  MainViews.notifications: 4,
  MainViews.uncensoredNotes: 5,
  MainViews.smartWidgets: 6,
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
      child: MainViewContent(
        mainScrollControllers: mainScrollControllers,
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
    return BlocBuilder<MainCubit, MainState>(
      buildWhen: (previous, current) =>
          previous.isConnected != current.isConnected ||
          previous.mainView != current.mainView, // also rebuild on tab change
      builder: (context, state) {
        final currentIndex = indexMap[state.mainView] ?? 0;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          bottomNavigationBar: MainViewBottomNavigationBar(
            onClicked: () {
              if (mainScrollControllers[currentIndex].hasClients) {
                mainScrollControllers[currentIndex].animateTo(
                  0.0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          floatingActionButton: state.mainView != MainViews.leading
              ? const SizedBox()
              : _createContent(context),
          appBar: MainViewAppBar(
            isConnected: state.isConnected,
            onClicked: () {
              if (mainScrollControllers[currentIndex].hasClients) {
                mainScrollControllers[currentIndex].animateTo(
                  0.0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          drawer: const MainViewDrawer(),
          extendBody: true,
          body: SafeArea(
            child: IndexedStack(
              index: currentIndex,
              children: [
                LeadingView(
                  key: const PageStorageKey('leading'),
                  scrollController: mainScrollControllers[0],
                ),
                DiscoverView(
                  key: const PageStorageKey('discover'),
                  scrollController: mainScrollControllers[1],
                ),
                InternalWalletsView(
                  key: const PageStorageKey('wallet'),
                ),
                DmsView(
                  key: const PageStorageKey('dms'),
                  scrollController: mainScrollControllers[2],
                ),
                NotificationsView(
                  key: const PageStorageKey('notifications'),
                  scrollController: mainScrollControllers[4],
                ),
                SmartWidgetsSearch(
                  key: const PageStorageKey('smartwidgets'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  RepaintBoundary _createContent(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () {
          doIfCanSign(
            func: () {
              HapticFeedback.mediumImpact();
              YNavigator.pushPage(
                context,
                (context) => AddContentView(
                  contentType: AppContentType.values.firstWhere(
                    (e) =>
                        e.name ==
                        nostrRepository
                            .currentAppCustomization?.writingContentType,
                    orElse: () => AppContentType.note,
                  ),
                ),
              );
            },
            context: context,
          );
        },
        child: FloatingActionButton(
          backgroundColor: kMainColor,
          shape: const CircleBorder(),
          heroTag: 'content_creation',
          child: SvgPicture.asset(
            FeatureIcons.addRaw,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () {
            doIfCanSign(
              func: () {
                HapticFeedback.mediumImpact();
                YNavigator.pushPage(
                  context,
                  (context) => AddContentView(),
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
