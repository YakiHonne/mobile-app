// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../dotted_container.dart';
import 'dicover_settings_views/relay_settings_view.dart';
import 'dicover_settings_views/reorder_settings_view.dart';

class DiscoverSourcesSettings extends HookWidget {
  const DiscoverSourcesSettings({
    super.key,
    required this.isDiscover,
  });

  final bool isDiscover;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(
      initialLength: 2,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DefaultTabController(
        length: 2,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          child: _content(
            tabController,
          ),
        ),
      ),
    );
  }

  DraggableScrollableSheet _content(
    TabController tabController,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: ModalBottomSheetAppbar(
              title: context.t.customizeYourFeed.capitalizeFirst(),
              isBack: false,
            ),
          ),
          _tabBar(tabController, context),
          _views(
            tabController,
            scrollController,
          ),
        ],
      ),
    );
  }

  Expanded _views(
    TabController tabController,
    ScrollController scrollController,
  ) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          RelaySettingsView(
            controller: scrollController,
          ),
          ReorderSettingsView(
            controller: scrollController,
            isDiscover: isDiscover,
          ),
        ],
      ),
    );
  }

  SizedBox _tabBar(TabController tabController, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        padding: EdgeInsets.zero,
        labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
              fontWeight: FontWeight.w600,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
        indicatorColor: Theme.of(context).primaryColor,
        dividerColor: Theme.of(context).dividerColor,
        tabAlignment: TabAlignment.fill,
        tabs: [
          AppSettingsTab(
            title: context.t.relaysFeed.capitalizeFirst(),
          ),
          AppSettingsTab(
            title: context.t.communityFeed.capitalizeFirst(),
          ),
        ],
      ),
    );
  }
}

class AppSettingsTab extends StatelessWidget {
  const AppSettingsTab({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Builder(
        builder: (context) {
          return Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}
