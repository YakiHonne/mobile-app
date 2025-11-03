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
import '../widgets/classic_footer.dart';
import '../widgets/empty_list.dart';
import '../widgets/no_content_widgets.dart';
import 'widgets/notification_global_container.dart';
import 'widgets/notifications_customization.dart';

class NotificationsView extends HookWidget {
  NotificationsView({
    super.key,
    required this.scrollController,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Notifications view');
  }

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: 5,
      initialIndex: notificationsCubit.state.index,
    );

    useEffect(() {
      void listener() {
        if (!tabController.indexIsChanging &&
            dmsCubit.state.index != tabController.index) {
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
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      buildWhen: (previous, current) =>
          previous.index != current.index || previous.events != current.events,
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

        return DefaultTabController(
          length: 5,
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
                  ],
                ),
              ),
            ],
          ),
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

    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.isLoading != current.isLoading,
      listener: (context, state) {
        if (!state.isLoading) {
          controller.refreshCompleted();
        }
      },
      buildWhen: (previous, current) =>
          previous.events != current.events ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (enableNotifications()) {
          return const EnableTypeNotifications();
        }

        if (state.isLoading && state.events.isEmpty) {
          return Center(
            child: SpinKitCircle(
              size: 30,
              color: Theme.of(context).primaryColorDark,
            ),
          );
        }

        final usedEvents = getUsedEvents(index, state.events);

        if (usedEvents.isEmpty) {
          return SmartRefresher(
            controller: controller,
            onRefresh: () =>
                context.read<NotificationsCubit>().queryAndSubscribe(),
            child: EmptyList(
              description: context.t.noNotificationCanBeFound.capitalizeFirst(),
              icon: FeatureIcons.notification,
            ),
          );
        }

        return SmartRefresher(
          controller: controller,
          scrollController: scrollController,
          enablePullUp: true,
          header: const RefresherClassicHeader(),
          onRefresh: () =>
              context.read<NotificationsCubit>().queryAndSubscribe(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(
              thickness: 0.5,
              height: 0,
            ),
            padding: EdgeInsets.only(
              bottom: kDefaultPadding,
              top: kDefaultPadding / 2,
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
      },
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
                  ? events.where((event) => event.kind == EventKind.ZAP)
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
      event.kind == EventKind.VIDEO_HORIZONTAL ||
      event.kind == EventKind.VIDEO_VERTICAL;
}

class EnableTypeNotifications extends StatelessWidget {
  const EnableTypeNotifications({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding * 2,
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
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
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
