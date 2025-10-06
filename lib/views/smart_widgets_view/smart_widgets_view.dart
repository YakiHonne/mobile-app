// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/smart_widgets_cubit/smart_widgets_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../utils/utils.dart';
import '../widgets/classic_footer.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/empty_list.dart';
import 'widgets/global_smart_widget_container.dart';
import 'widgets/smart_widget_checker.dart';

class SmartWidgetsView extends StatefulWidget {
  const SmartWidgetsView({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<SmartWidgetsView> createState() => _SmartWidgetsViewState();
}

class _SmartWidgetsViewState extends State<SmartWidgetsView>
    with TickerProviderStateMixin {
  final refreshController = RefreshController();
  late TabController tabController;
  late bool isConnected;
  int index = 0;
  SmartWidgetType smartWidgetType = SmartWidgetType.community;

  @override
  void initState() {
    isConnected = canSign();
    tabController = TabController(
      length: isConnected ? 2 : 1,
      vsync: this,
    );

    super.initState();
  }

  void onRefresh({required Function() onInit}) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        nostrRepository.mainCubit.updateIndex(MainViews.leading);
      },
      child: BlocProvider(
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
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [_checkSmartWidget(context)];
              },
              body: Builder(
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
                      description:
                          context.t.noPollsCanBeFound.capitalizeFirst(),
                      icon: FeatureIcons.polls,
                    );
                  } else {
                    return _items(context, isTablet, state);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  SmartRefresher _items(
      BuildContext context, bool isTablet, SmartWidgetsState state) {
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
      child: isTablet ? _itemsGrid(state) : _itemsList(state),
    );
  }

  ListView _itemsList(SmartWidgetsState state) {
    return ListView.separated(
      itemCount: state.widgets.length,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final widget = state.widgets[index];

        return GlobalSmartWidgetContainer(
          smartWidgetModel: widget,
          canPerformOwnerActions: true,
        );
      },
    );
  }

  MasonryGridView _itemsGrid(SmartWidgetsState state) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      itemCount: state.widgets.length,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      itemBuilder: (context, index) {
        final widget = state.widgets[index];

        return GlobalSmartWidgetContainer(
          smartWidgetModel: widget,
          canPerformOwnerActions: true,
        );
      },
    );
  }

  SliverToBoxAdapter _checkSmartWidget(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.t.checkSmartWidget.capitalizeFirst(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ),
            CustomIconButton(
              backgroundColor: Theme.of(context).cardColor,
              onClicked: () {
                Navigator.pushNamed(
                  context,
                  SmartWidgetChecker.routeName,
                );
              },
              icon: FeatureIcons.swChecker,
              size: 20,
              vd: -1,
            ),
          ],
        ),
      ),
    );
  }
}
