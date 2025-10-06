import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/smart_widgets_cubit/smart_widgets_cubit.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';
import '../smart_widgets_view/widgets/global_smart_widget_container.dart';
import 'classic_footer.dart';
import 'dotted_container.dart';
import 'empty_list.dart';

class SmartWidgetSelection extends StatefulWidget {
  const SmartWidgetSelection({
    super.key,
    required this.onWidgetAdded,
  });

  final Function(SmartWidget) onWidgetAdded;

  @override
  State<SmartWidgetSelection> createState() =>
      _SmartWidgetZapPollSelectionState();
}

class _SmartWidgetZapPollSelectionState extends State<SmartWidgetSelection>
    with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    super.initState();
  }

  void onRefresh({required Function onInit}) {
    refreshController.resetNoData();
    onInit.call();
    refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocProvider(
      create: (context) => SmartWidgetsCubit(),
      child: BlocConsumer<SmartWidgetsCubit, SmartWidgetsState>(
        listener: (context, state) {
          if (state.loadingState == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.loadingState == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          return DraggableScrollableSheet(
            initialChildSize: 0.80,
            minChildSize: 0.40,
            maxChildSize: 0.80,
            expand: false,
            builder: (context, scrollController) => ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
              child: NestedScrollView(
                controller: scrollController,
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _appBar(context),
                  ];
                },
                body: _content(state, isTablet, scrollController),
              ),
            ),
          );
        },
      ),
    );
  }

  Builder _content(SmartWidgetsState state, bool isTablet,
      ScrollController scrollController) {
    return Builder(
      builder: (context) {
        if (state.isLoading) {
          return Center(
            child: SpinKitPulse(
              color: Theme.of(context).primaryColorDark,
              size: 20,
            ),
          );
        } else if (state.widgets.isEmpty) {
          return EmptyList(
            description: context.t.noSmartWidgetCanBeFound.capitalizeFirst(),
            icon: FeatureIcons.smartWidget,
          );
        } else {
          return SmartRefresher(
            controller: refreshController,
            enablePullDown: false,
            enablePullUp: true,
            header: const MaterialClassicHeader(
              color: kPurple,
            ),
            footer: const RefresherClassicFooter(),
            onLoading: () => context
                .read<SmartWidgetsCubit>()
                .getSmartWidgets(isAdd: true, isSelf: false),
            onRefresh: () => onRefresh(
              onInit: () => context
                  .read<SmartWidgetsCubit>()
                  .getSmartWidgets(isAdd: false, isSelf: false),
            ),
            child: isTablet
                ? _itemsGrid(scrollController, state)
                : _itemList(state, scrollController),
          );
        }
      },
    );
  }

  ListView _itemList(
      SmartWidgetsState state, ScrollController scrollController) {
    return ListView.separated(
      itemCount: state.widgets.length,
      controller: scrollController,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final w = state.widgets[index];

        return GlobalSmartWidgetContainer(
          smartWidgetModel: w,
          onClicked: () {
            widget.onWidgetAdded.call(w);
          },
        );
      },
    );
  }

  MasonryGridView _itemsGrid(
      ScrollController scrollController, SmartWidgetsState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      controller: scrollController,
      itemCount: state.widgets.length,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final w = state.widgets[index];

        return GlobalSmartWidgetContainer(
          smartWidgetModel: w,
          onClicked: () {
            widget.onWidgetAdded.call(w);
          },
        );
      },
    );
  }

  SliverAppBar _appBar(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      elevation: 5,
      pinned: true,
      actions: const [SizedBox.shrink()],
      titleSpacing: 0,
      toolbarHeight: 64,
      flexibleSpace: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(),
            _tabBar(context),
          ],
        ),
      ),
    );
  }

  TabBar _tabBar(BuildContext context) {
    return TabBar(
      labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
      dividerColor: Theme.of(context).primaryColorLight,
      controller: tabController,
      labelPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 4,
      ),
      unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
      onTap: (index) {
        if (index == 0) {
          context
              .read<SmartWidgetsCubit>()
              .getSmartWidgets(isAdd: false, isSelf: false);
        } else {
          context
              .read<SmartWidgetsCubit>()
              .getSmartWidgets(isAdd: false, isSelf: true);
        }
      },
      tabs: [
        Tab(
          height: 35,
          child: Text(
            context.t.communityWidgets.capitalizeFirst(),
          ),
        ),
        Tab(
          height: 35,
          child: Text(
            context.t.myWidgets.capitalizeFirst(),
          ),
        ),
      ],
    );
  }
}
