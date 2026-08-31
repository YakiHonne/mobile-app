// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/notifications_cubit/notifications_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/app_models/extended_model.dart';
import '../../models/event_relation.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../main_view/widgets/app_bar_widgets.dart' show NotificationTypes;
import '../widgets/classic_footer.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import '../widgets/fluid_blur_container.dart';
import '../widgets/no_content_widgets.dart';
import 'widgets/notification_global_container.dart';
import 'widgets/notifications_customization.dart';

class NotificationsView extends HookWidget {
  NotificationsView({
    super.key,
    required this.scrollController,
    this.barsVisible,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Notifications view');
  }

  final ScrollController scrollController;
  final ValueNotifier<bool>? barsVisible;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: 6,
      initialIndex: notificationsCubit.state.index,
    );

    useEffect(() {
      void listener() {
        if (!tabController.indexIsChanging &&
            notificationsCubit.state.index != tabController.index) {
          context.read<NotificationsCubit>().setIndex(tabController.index);
        }
      }

      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) => previous.index != current.index,
      listener: (context, state) {
        tabController.animateTo(state.index);
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      buildWhen: (previous, current) =>
          previous.index != current.index ||
          previous.events != current.events ||
          previous.premiumEvents != current.premiumEvents,
      builder: (context, state) {
        if (isDisconnected() || canRoam()) {
          return const SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VerticalViewModeWidget(),
              ],
            ),
          );
        }

        final tabView = DefaultTabController(
          length: 6,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    SelectedNotifications(
                      index: 0,
                      key: const ValueKey('0'),
                      scrollController: scrollController,
                    ),
                    SelectedNotifications(
                      index: 1,
                      key: const ValueKey('1'),
                      scrollController: scrollController,
                    ),
                    SelectedNotifications(
                      index: 2,
                      key: const ValueKey('2'),
                      scrollController: scrollController,
                    ),
                    SelectedNotifications(
                      index: 3,
                      key: const ValueKey('3'),
                      scrollController: scrollController,
                    ),
                    SelectedNotifications(
                      index: 4,
                      key: const ValueKey('4'),
                      scrollController: scrollController,
                    ),
                    SelectedNotifications(
                      index: 5,
                      key: const ValueKey('5'),
                      scrollController: scrollController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (!isFluid()) {
          return tabView;
        }

        return Stack(
          children: [
            tabView,
            Positioned(
              left: kDefaultPadding / 2,
              right: kDefaultPadding / 2,
              top: MediaQuery.of(context).padding.top +
                  kToolbarHeight +
                  kDefaultPadding / 2,
              child: Align(
                child: ValueListenableBuilder<bool>(
                  valueListenable: barsVisible ?? ValueNotifier(true),
                  builder: (context, visible, child) => IgnorePointer(
                    ignoring: !visible,
                    child: AnimatedSlide(
                      offset: visible ? Offset.zero : const Offset(0, -1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: child,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: 60.w,
                    child: FluidBlurContainer(
                      borderRadius: kDefaultPadding * 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Expanded(child: NotificationTypes()),
                          SizedBox(
                            height: 20,
                            child: VerticalDivider(
                              width: 1,
                              thickness: 0.5,
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          CustomIconButton(
                            onClicked: () => doIfCanSign(
                              func: () => YNavigator.pushPage(
                                context,
                                (context) => const NotificationsCustomization(),
                              ),
                              context: context,
                            ),
                            icon: FeatureIcons.settings,
                            size: 20,
                            backgroundColor: kTransparent,
                            borderColor: kTransparent,
                            vd: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SelectedNotifications extends HookWidget {
  const SelectedNotifications({
    super.key,
    required this.index,
    required this.scrollController,
  });

  final int index;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final controller = useMemoized(() => RefreshController());
    // TabBarView keeps neighboring tabs alive for swiping, so the shared
    // scrollController (used to hide the app bar) can only ever be attached
    // to the currently visible tab — every other tab gets its own, or
    // ScrollController.attach throws '_positions.length == 1'.
    final localScrollController = useMemoized(() => ScrollController());
    useEffect(() => localScrollController.dispose, [localScrollController]);

    final state = context.watch<NotificationsCubit>().state;
    final isLoading = index == 5 ? state.isPremiumLoading : state.isLoading;
    final isActiveTab = index == state.index;
    final usedScrollController =
        isActiveTab ? scrollController : localScrollController;

    useEffect(() {
      if (!isLoading) {
        controller.refreshCompleted();
      }
      return null;
    }, [isLoading]);

    if (index != 5 && enableNotifications()) {
      return const EnableTypeNotifications();
    }

    if (index == 5) {
      if (state.isPremiumLoading && state.premiumEvents.isEmpty) {
        return Center(
          child: SpinKitCircle(
            size: 30,
            color: Theme.of(context).primaryColorDark,
          ),
        );
      }
    } else if (state.isLoading && state.events.isEmpty) {
      return Center(
        child: SpinKitCircle(
          size: 30,
          color: Theme.of(context).primaryColorDark,
        ),
      );
    }

    final usedEvents = useMemoized(
      () => index == 5 ? state.premiumEvents : getUsedEvents(index, state.events),
      [index, state.events, state.premiumEvents],
    );

    final topInset = isFluid()
        ? MediaQuery.of(context).padding.top + kToolbarHeight + 50
        : 0.0;

    return SmartRefresher(
      controller: controller,
      scrollController: usedEvents.isEmpty ? null : usedScrollController,
      enablePullUp: usedEvents.isNotEmpty,
      header: const RefresherClassicHeader(),
      onRefresh: () => index == 5
          ? context.read<NotificationsCubit>().fetchPremiumContent(force: true)
          : context.read<NotificationsCubit>().queryAndSubscribe(isRefresh: true),
      child: usedEvents.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: topInset),
              child: EmptyList(
                description:
                    context.t.noNotificationCanBeFound.capitalizeFirst(),
                icon: FeatureIcons.notification,
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(
                thickness: 0.5,
                height: 0,
              ),
              padding: EdgeInsets.only(
                top: topInset,
                bottom: isFluid()
                    ? kBottomNavigationBarHeight +
                        kDefaultPadding * 2 +
                        MediaQuery.of(context).padding.bottom / 2
                    : kDefaultPadding,
                left: isMobile ? kDefaultPadding / 2 : 20.w,
                right: isMobile ? kDefaultPadding / 2 : 20.w,
              ),
              itemBuilder: (context, index) {
                final ev = usedEvents[index];
                return NotificationGlobalContainer(
                  key: ValueKey(ev.id),
                  mainEvent: ev,
                );
              },
              itemCount: usedEvents.length,
            ),
    );
  }

  bool enableNotifications() {
    final c = nostrRepository.currentAppCustomization;

    return index == 1 && !(c?.notifMentionsReplies ?? false) ||
        index == 2 && !(c?.notifZaps ?? false) ||
        index == 3 && !(c?.notifMentionsReplies ?? false) ||
        index == 4 && !(c?.notifFollowings ?? false);
  }

  List<Event> getUsedEvents(int index, List<Event> events) {
    if (!canSign()) {
      return [];
    }

    final pubkey = currentSigner!.getPublicKey();

    return List<Event>.from(
      index == 0
          ? events
          : index == 1
              ? events.where((event) {
                  if (isInKinds(event)) {
                    return !event.isQuote() &&
                        hasMention(content: event.content, pubkey: pubkey) &&
                        ExtendedEvent.fromEv(event).isUserTagged();
                  } else {
                    return false;
                  }
                })
              : index == 2
                  ? events.where((event) =>
                      event.kind == EventKind.ZAP ||
                      event.kind == EventKind.CASHU_NUTZAP)
                  : index == 3
                      ? events.where((event) {
                          if (isInKinds(event)) {
                            final relation = EventRelation.fromEvent(event);
                            return (relation.replyId != null ||
                                    relation.rootId != null ||
                                    relation.rRootId != null) &&
                                !hasMention(
                                    content: event.content, pubkey: pubkey) &&
                                ExtendedEvent.fromEv(event).isUserTagged();
                          } else {
                            return false;
                          }
                        })
                      : events.where((event) =>
                          (isInKinds(event)) &&
                          !ExtendedEvent.fromEv(event).isUserTagged()),
    );
  }
}

bool isInKinds(Event event) {
  return event.kind == EventKind.LONG_FORM ||
      event.kind == EventKind.CURATION_ARTICLES ||
      event.kind == EventKind.CURATION_VIDEOS ||
      event.kind == EventKind.SMART_WIDGET_ENH ||
      event.kind == EventKind.TEXT_NOTE ||
      event.kind == EventKind.COMMENT ||
      event.kind == EventKind.VIDEO_HORIZONTAL ||
      event.kind == EventKind.VIDEO_VERTICAL;
}

class EnableTypeNotifications extends StatelessWidget {
  const EnableTypeNotifications({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = isFluid()
        ? MediaQuery.of(context).padding.top +
            kToolbarHeight +
            kDefaultPadding * 3
        : kDefaultPadding * 2;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: topInset,
        ),
        children: [
          Text(
            context.t.notifDisabled,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.notifDisabledMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Center(
            child: TextButton(
              onPressed: () {
                YNavigator.pushPage(
                  context,
                  (context) => const NotificationsCustomization(),
                );
              },
              child: Text(
                context.t.settings.capitalizeFirst(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
