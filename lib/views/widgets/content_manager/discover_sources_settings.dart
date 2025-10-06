// ignore_for_file: public_member_api_docs, sort_constructors_first, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../dotted_container.dart';
import 'add_discover_filter.dart';
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
    final isLoading = useState(false);

    final tabController = useTabController(
      initialLength: 2,
      initialIndex: dmsCubit.state.index,
    );

    final currentAppSettings = useState(
      appSettingsManagerCubit.getAppSharedSettingsCopy(),
    );

    final favoriteRelays = useState(
      appSettingsManagerCubit.state.favoriteRelays,
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
              tabController, favoriteRelays, currentAppSettings, isLoading),
        ),
      ),
    );
  }

  DraggableScrollableSheet _content(
      TabController tabController,
      ValueNotifier<List<String>> favoriteRelays,
      ValueNotifier<AppSharedSettings> currentAppSettings,
      ValueNotifier<bool> isLoading) {
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
          _views(tabController, scrollController, favoriteRelays,
              currentAppSettings),
          _update(context, isLoading, currentAppSettings, favoriteRelays),
        ],
      ),
    );
  }

  Container _update(
      BuildContext context,
      ValueNotifier<bool> isLoading,
      ValueNotifier<AppSharedSettings> currentAppSettings,
      ValueNotifier<List<String>> favoriteRelays) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom / 2,
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: RegularLoadingButton(
              title: context.t.update.capitalizeFirst(),
              isLoading: isLoading.value,
              onClicked: () async {
                isLoading.value = true;

                await appSettingsManagerCubit.updateSources(
                  settings: currentAppSettings.value,
                  isDiscover: isDiscover,
                  favoriteRelays: favoriteRelays.value,
                );

                isLoading.value = false;

                YNavigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Expanded _views(
      TabController tabController,
      ScrollController scrollController,
      ValueNotifier<List<String>> favoriteRelays,
      ValueNotifier<AppSharedSettings> currentAppSettings) {
    return Expanded(
      child: TabBarView(
        controller: tabController,
        children: [
          RelaySettingsView(
            controller: scrollController,
            isDiscover: isDiscover,
            favoriteRelays: favoriteRelays,
          ),
          ReorderSettingsView(
            currentAppSettings: currentAppSettings,
            controller: scrollController,
            isDiscover: isDiscover,
            favoriteRelays: favoriteRelays,
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
        indicatorColor: kMainColor,
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
