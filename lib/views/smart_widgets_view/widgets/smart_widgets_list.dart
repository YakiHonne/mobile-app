import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/smart_widget_search_cubit/smart_widget_search_cubit.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/tools_view/tools_view.dart';
import '../../widgets/empty_list.dart';

class SmartWidgetsList extends StatelessWidget {
  const SmartWidgetsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<SmartWidgetSearchCubit, SmartWidgetSearchState>(
      builder: (context, state) {
        if (state.isSmartWidgetLoading) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              child: SpinKitThreeBounce(
                color: Theme.of(context).primaryColorDark,
                size: 15,
              ),
            ),
          );
        } else if ((state.dvmSearch.isNotEmpty && state.dvmWidgets.isEmpty) ||
            (state.dvmSearch.isEmpty && state.widgets.isEmpty)) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding,
              ),
              child: EmptyList(
                description: context.t.noToolsAvailable.capitalizeFirst(),
                icon: FeatureIcons.menu,
              ),
            ),
          );
        }

        final widgets =
            state.dvmSearch.isNotEmpty ? state.dvmWidgets : state.widgets;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 2,
          ),
          sliver: isTablet
              ? _buildItemsGrid(widgets, state)
              : _buildItemsList(widgets, state),
        );
      },
    );
  }

  SliverList _buildItemsList(
      List<SmartWidget> widgets, SmartWidgetSearchState state) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        final tool = widgets[index];
        final app = state.apps[tool.identifier];

        return ToolContainer(
          tool: tool,
          appSmartWidget: state.apps[tool.identifier],
          onContentAdded: (val) {},
          canBeBookmarked: tool.getAppUrl() != null,
          isBookmarked: state.bookmarks.contains(tool.identifier),
          onBookmarkSet: () {
            context
                .read<SmartWidgetSearchCubit>()
                .addBookmark(tool.identifier, app?.pubkey ?? tool.pubkey);
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
      itemCount: widgets.length,
    );
  }

  SliverMasonryGrid _buildItemsGrid(
      List<SmartWidget> widgets, SmartWidgetSearchState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: kDefaultPadding / 4,
      crossAxisSpacing: kDefaultPadding / 4,
      childCount: widgets.length,
      itemBuilder: (context, index) {
        final tool = widgets[index];
        final app = state.apps[tool.identifier];

        return ToolContainer(
          tool: tool,
          appSmartWidget: state.apps[tool.identifier],
          onContentAdded: (val) {},
          canBeBookmarked: tool.getAppUrl() != null,
          isBookmarked: state.bookmarks.contains(tool.identifier),
          onBookmarkSet: () {
            context
                .read<SmartWidgetSearchCubit>()
                .addBookmark(tool.identifier, app?.pubkey ?? tool.pubkey);
          },
        );
      },
    );
  }
}
