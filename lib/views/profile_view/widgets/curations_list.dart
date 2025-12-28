// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/curation_model.dart';
import '../../../utils/utils.dart';
import '../../curation_view/curation_view.dart';
import '../../widgets/curation_container.dart';
import '../../widgets/empty_list.dart';

class ProfileCurations extends StatelessWidget {
  const ProfileCurations({
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
            previous.content != current.content ||
            previous.bookmarks != current.bookmarks ||
            previous.mutes != current.mutes ||
            previous.user != current.user,
        builder: (context, state) {
          if (state.content.isEmpty) {
            return EmptyList(
              icon: FeatureIcons.selfArticles,
              description: context.t
                  .userNoCurations(name: state.user.getName())
                  .capitalizeFirst(),
            );
          } else {
            if (isTablet && !useSingleColumn) {
              return _itemsGrid(state);
            } else {
              return _itemsList(state);
            }
          }
        },
      ),
    );
  }

  ListView _itemsList(ProfileState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding,
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

  MasonryGridView _itemsGrid(ProfileState state) {
    return MasonryGridView.builder(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
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
      itemCount: state.content.length,
    );
  }
}
