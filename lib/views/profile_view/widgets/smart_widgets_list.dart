// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../smart_widgets_view/widgets/global_smart_widget_container.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';

class ProfileSmartWidgets extends StatelessWidget {
  const ProfileSmartWidgets({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return Scrollbar(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) =>
            previous.isLoading != current.isLoading ||
            previous.content != current.content ||
            previous.user != current.user ||
            previous.mutes != current.mutes ||
            previous.bookmarks != current.bookmarks,
        builder: (context, state) {
          if (state.isLoading) {
            return const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
                child: ContentPlaceholder(),
              ),
            );
          } else {
            if (state.content.isEmpty) {
              return EmptyList(
                description: context.t.userNoSmartWidgets(
                  name: state.user.getName(),
                ),
                icon: FeatureIcons.smartWidget,
              );
            } else {
              if (isTablet && !useSingleColumn) {
                return _itemsGrid(state);
              } else {
                return _itemsList(state);
              }
            }
          }
        },
      ),
    );
  }

  ListView _itemsList(ProfileState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 1.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
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

  MasonryGridView _itemsGrid(ProfileState state) {
    return MasonryGridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding,
      mainAxisSpacing: kDefaultPadding,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
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
}
