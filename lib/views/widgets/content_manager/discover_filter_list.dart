// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../app_icon.dart';
import '../custom_icon_buttons.dart';
import '../dotted_container.dart';
import '../fluid_pull_down_button.dart';
import '../fluid_sheet.dart';
import '../modal_sheet_container.dart';
import 'add_discover_filter.dart';

class AppFilterList extends StatelessWidget {
  const AppFilterList({super.key, required this.viewType});

  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
    return ModalSheetContainer(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              children: [
                ModalBottomSheetAppbar(
                  title: context.t.filters.capitalizeFirst(),
                  isBack: false,
                ),
                if (viewType == ViewDataTypes.articles)
                  _discoverList(scrollController)
                else if (viewType == ViewDataTypes.notes)
                  _notesList(scrollController)
                else
                  _mediaList(scrollController),
                _addFilter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Container _addFilter(BuildContext context) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: RegularLoadingButton(
              title: context.t.addFilter.capitalizeFirst(),
              isLoading: false,
              onClicked: () {
                YNavigator.pop(context);
                showAppModalSheet(
                  context: context,
                  builder: (_) {
                    if (viewType == ViewDataTypes.articles) {
                      return AddDiscoverFilter(
                        discoverFilter: DiscoverFilter.defaultFilter(),
                      );
                    } else if (viewType == ViewDataTypes.notes) {
                      return AddNotesFilter(
                        notesFilter: NotesFilter.defaultFilter(),
                      );
                    } else {
                      return AddMediaFilter(
                        mediaFilter: MediaFilter.defaultFilter(),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _discoverFilterItem(
    MapEntry<String, NotesFilter> f,
    BuildContext context,
    AppSettingsManagerState state,
  ) {
    return GestureDetector(
      onTap: () {
        appSettingsManagerCubit.setFilter(
          id: f.key,
          viewType: viewType,
        );

        YNavigator.pop(context);
      },
      child: FilterContainer(
        title: f.value.title.capitalizeFirst(),
        selectedFilter: state.selectedNotesFilter,
        id: f.key,
        onDelete: () {
          appSettingsManagerCubit.deleteFilter(
            id: f.key,
            viewType: viewType,
          );
        },
        onEdit: () {
          YNavigator.pop(context);

          showAppModalSheet(
            context: context,
            builder: (_) {
              return AddNotesFilter(
                notesFilter: f.value,
              );
            },
          );
        },
      ),
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _discoverList(
      ScrollController scrollController) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final df = state.discoverFilters.entries.toList();

        return Expanded(
          child: ScrollShadow(
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 4,
            child: ListView.separated(
              controller: scrollController,
              itemBuilder: (context, index) {
                final f = df[index];

                return _notesFilterItem(f, context, state);
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 4,
              ),
              itemCount: df.length,
            ),
          ),
        );
      },
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _notesList(
      ScrollController scrollController) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final nf = state.notesFilters.entries.toList();

        return Expanded(
          child: ScrollShadow(
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 4,
            child: ListView.separated(
              controller: scrollController,
              itemBuilder: (context, index) {
                final f = nf[index];

                return _discoverFilterItem(f, context, state);
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 4,
              ),
              itemCount: nf.length,
            ),
          ),
        );
      },
    );
  }

  GestureDetector _notesFilterItem(
    MapEntry<String, DiscoverFilter> f,
    BuildContext context,
    AppSettingsManagerState state,
  ) {
    return GestureDetector(
      onTap: () {
        appSettingsManagerCubit.setFilter(
          id: f.key,
          viewType: viewType,
        );

        YNavigator.pop(context);
      },
      child: FilterContainer(
        title: f.value.title.capitalizeFirst(),
        selectedFilter: state.selectedDiscoverFilter,
        id: f.key,
        onDelete: () {
          appSettingsManagerCubit.deleteFilter(
            id: f.key,
            viewType: viewType,
          );
        },
        onEdit: () {
          YNavigator.pop(context);

          showAppModalSheet(
            context: context,
            builder: (_) {
              return AddDiscoverFilter(
                discoverFilter: f.value,
              );
            },
          );
        },
      ),
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _mediaList(
      ScrollController scrollController) {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final nf = state.mediaFilters.entries.toList();

        return Expanded(
          child: ScrollShadow(
            color: Theme.of(context).scaffoldBackgroundColor,
            size: 4,
            child: ListView.separated(
              controller: scrollController,
              itemBuilder: (context, index) {
                final f = nf[index];

                return _mediaFilterItem(f, context, state);
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 4,
              ),
              itemCount: nf.length,
            ),
          ),
        );
      },
    );
  }

  GestureDetector _mediaFilterItem(
    MapEntry<String, MediaFilter> f,
    BuildContext context,
    AppSettingsManagerState state,
  ) {
    return GestureDetector(
      onTap: () {
        appSettingsManagerCubit.setFilter(
          id: f.key,
          viewType: viewType,
        );

        YNavigator.pop(context);
      },
      child: FilterContainer(
        title: f.value.title.capitalizeFirst(),
        selectedFilter: state.selectedDiscoverFilter,
        id: f.key,
        onDelete: () {
          appSettingsManagerCubit.deleteFilter(
            id: f.key,
            viewType: viewType,
          );
        },
        onEdit: () {
          YNavigator.pop(context);

          showAppModalSheet(
            context: context,
            builder: (_) {
              return AddMediaFilter(
                mediaFilter: f.value,
              );
            },
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
      ),
    );
  }
}

class FilterContainer extends StatelessWidget {
  const FilterContainer({
    super.key,
    required this.id,
    required this.title,
    required this.selectedFilter,
    required this.onEdit,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String selectedFilter;
  final Function() onEdit;
  final Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        spacing: kDefaultPadding / 2,
        children: [
          const SizedBox(
            width: 0,
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Opacity(
            opacity: selectedFilter == id ? 1 : 0,
            child: const Icon(
              LucideIcons.check,
              size: 20,
            ),
          ),
          _pulldownButton(context),
        ],
      ),
    );
  }

  FluidPullDownButton _pulldownButton(BuildContext context) {
    return FluidPullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            onTap: onEdit,
            title: context.t.edit.capitalizeFirst(),
            iconWidget: AppIcon(
              FeatureIcons.editArticle,
              size: 20,
              color: Theme.of(context).primaryColorDark,
            ),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
          ),
          PullDownMenuItem(
            onTap: onDelete,
            title: context.t.delete.capitalizeFirst(),
            isDestructive: true,
            iconWidget: const AppIcon(
              FeatureIcons.trash,
              size: 20,
              color: kRed,
            ),
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => CustomIconButton(
        onClicked: showMenu,
        size: 20,
        backgroundColor: kTransparent,
        vd: -4,
        icon: FeatureIcons.more,
      ),
    );
  }
}
