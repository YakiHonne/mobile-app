import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmarks_cubit.dart';
import '../../logic/dashboard_cubits/dashboard_content_cubit/dashboard_content_cubit.dart';
import '../../logic/dashboard_cubits/dashboard_home_cubit/dashboard_home_cubit.dart';
import '../../utils/utils.dart';
import 'widgets/bookmarks/bookmarks_dashboard.dart';
import 'widgets/content/content_dashboard.dart';
import 'widgets/home/home_dashboard.dart';
import 'widgets/interests/interests_dashboard.dart';
import 'widgets/smart_widgets/smart_widgets_dashboard.dart';

class DashboardView extends HookWidget {
  DashboardView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Dashboard view');
  }

  @override
  Widget build(BuildContext context) {
    final ssc = useState(CustomSegmentedController<int>());
    final selectedDashboardType = useState(DashboardType.home);

    final isDraft = useState(false);
    bool isDraftChosen = false;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DashboardHomeCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => DashboardContentCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (context) => DashboardBookmarksCubit(),
          lazy: false,
        ),
      ],
      child: Scaffold(
        appBar: DashboardAppBar(
          selectedType: selectedDashboardType,
          onSelectType: (type) {
            selectedDashboardType.value = type;

            HapticFeedback.lightImpact();

            if (!isDraftChosen) {
              isDraft.value = false;
            }

            isDraftChosen = false;
          },
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: BlocBuilder<DashboardContentCubit, DashboardContentState>(
            builder: (context, state) {
              return getView(
                selectedDashboardType.value,
                () {
                  isDraft.value = true;
                  isDraftChosen = true;
                  ssc.value.value = 1;
                  selectedDashboardType.value = DashboardType.content;
                },
                isDraft.value,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getView(
    DashboardType type,
    Function() onDraftClicked,
    bool isDraft,
  ) {
    switch (type) {
      case DashboardType.home:
        return HomeDashboard(
          key: const ValueKey('home_dashboard'),
          onDraftClicked: onDraftClicked,
        );
      case DashboardType.content:
        return ContentDashboard(
          key: const ValueKey('content_dashboard'),
          isDraft: isDraft,
        );
      case DashboardType.smart:
        return SmartWidgetsDashboard(
          key: const ValueKey('smart_widgets_dashboard'),
          isDraft: isDraft,
        );
      case DashboardType.bookmarks:
        return const BookmarksDashboard(
          key: ValueKey('bookmarks_dashboard'),
        );
      case DashboardType.interests:
        return const InterestsDashboard(
          key: ValueKey('interests_dashboard'),
        );
    }
  }
}

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.selectedType,
    required this.onSelectType,
  });

  final ValueNotifier<DashboardType> selectedType;
  final Function(DashboardType) onSelectType;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: selector(context),
      centerTitle: true,
    );
  }

  Widget selector(BuildContext context) {
    final types = DashboardType.values.toList();

    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final items = <PullDownMenuEntry>[];

        for (int i = 0; i < types.length; i++) {
          final type = types[i];
          final isSelected = selectedType.value == type;

          items.add(
            PullDownMenuItem.selectable(
              title: getType(type, context),
              selected: isSelected,
              onTap: () {
                onSelectType.call(type);
              },
              itemTheme: PullDownMenuItemTheme(
                textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          );
        }

        return items;
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: showMenu,
        child: SizedBox(
          width: 50.w,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    getType(selectedType.value, context),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getType(DashboardType type, BuildContext context) {
    String title = '';

    switch (type) {
      case DashboardType.home:
        title = context.t.home.capitalizeFirst();
      case DashboardType.content:
        title = context.t.content.capitalizeFirst();
      case DashboardType.smart:
        title = context.t.smartWidget.capitalizeFirst();
      case DashboardType.bookmarks:
        title = context.t.bookmarks.capitalizeFirst();
      case DashboardType.interests:
        title = context.t.interests.capitalizeFirst();
    }

    return title;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
