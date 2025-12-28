import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/curation_model.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../curation_view/curation_view.dart';
import '../../smart_widgets_view/widgets/global_smart_widget_container.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/tag_container.dart';

final profileDataList = [
  ProfileData.curations,
  ProfileData.smartWidgets,
];

class ProfileOthers extends StatelessWidget {
  const ProfileOthers({
    super.key,
    required this.profileData,
    required this.onProfileDataChanged,
  });

  final ProfileData profileData;
  final Function(ProfileData) onProfileDataChanged;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;
    final isCuration = profileData == ProfileData.curations;

    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverAppBar(
            toolbarHeight: 45,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: SizedBox(
              height: 36,
              width: double.infinity,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) => const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                itemBuilder: (context, index) {
                  final type = profileDataList[index];

                  return TagContainer(
                    title: type.getDisplayName(context),
                    isActive: type == profileData,
                    style: Theme.of(context).textTheme.labelLarge,
                    backgroundColor: type == profileData
                        ? Theme.of(context).cardColor
                        : Colors.transparent,
                    textColor: Theme.of(context).primaryColorDark,
                    onClick: () {
                      onProfileDataChanged(type);
                      HapticFeedback.lightImpact();
                    },
                  );
                },
                itemCount: profileDataList.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: kDefaultPadding / 2),
          ),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const SliverToBoxAdapter(
                  child: ContentPlaceholder(
                    removePadding: true,
                  ),
                );
              } else {
                if (state.content.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyList(
                      description: isCuration
                          ? context.t
                              .userNoCurations(name: state.user.getName())
                              .capitalizeFirst()
                          : context.t.userNoSmartWidgets(
                              name: state.user.getName(),
                            ),
                      icon: isCuration
                          ? FeatureIcons.selfArticles
                          : FeatureIcons.smartWidget,
                    ),
                  );
                } else {
                  if (isTablet && !useSingleColumn) {
                    if (isCuration) {
                      return _curationsItemsGrid(state);
                    } else {
                      return _smItemsGrid(state);
                    }
                  } else {
                    if (isCuration) {
                      return _curationsItemsList(state);
                    } else {
                      return _smItemsList(state);
                    }
                  }
                }
              }
            },
          )
        ],
      ),
    );
  }

  SliverList _curationsItemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final event = state.content.elementAt(index);
        final curation = Curation.fromEvent(event, '');

        return CurationContainer(
          curation: curation,
          isFollowing: contactListCubit.contacts.contains(curation.pubkey),
          isBookmarked: state.bookmarks.contains(curation.identifier),
          isProfileAccessible: false,
          onClicked: () {
            Navigator.pushNamed(
              context,
              CurationView.routeName,
              arguments: curation,
            );
          },
          padding: 0,
        );
      },
      itemCount: state.content.length,
    );
  }

  SliverMasonryGrid _curationsItemsGrid(ProfileState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final event = state.content.elementAt(index);
        final curation = Curation.fromEvent(event, '');

        return CurationContainer(
          curation: curation,
          isFollowing: contactListCubit.contacts.contains(curation.pubkey),
          isProfileAccessible: false,
          isBookmarked: state.bookmarks.contains(curation.identifier),
          onClicked: () {
            Navigator.pushNamed(
              context,
              CurationView.routeName,
              arguments: curation,
            );
          },
          padding: 0,
        );
      },
      childCount: state.content.length,
    );
  }

  SliverList _smItemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 1.5,
      ),
      itemBuilder: (context, index) {
        final event = state.content[index];
        final smartWidget = SmartWidget.fromEvent(event);

        return GlobalSmartWidgetContainer(
          smartWidgetModel: smartWidget,
          canPerformOwnerActions: state.isSameUser,
        );
      },
      itemCount: state.content.length,
    );
  }

  SliverMasonryGrid _smItemsGrid(ProfileState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemBuilder: (context, index) {
        final event = state.content[index];
        final smartWidget = SmartWidget.fromEvent(event);

        return GlobalSmartWidgetContainer(
          smartWidgetModel: smartWidget,
          canPerformOwnerActions: state.isSameUser,
        );
      },
      childCount: state.content.length,
    );
  }
}
