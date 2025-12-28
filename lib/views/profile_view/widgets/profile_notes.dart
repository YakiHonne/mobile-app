import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/tag_container.dart';

final profileDataList = [
  ProfileData.pinned,
  ProfileData.notes,
  ProfileData.replies,
  ProfileData.mentions
];

class ProfileNotes extends HookWidget {
  const ProfileNotes({
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
                  child: NotesPlaceholder(
                    removePadding: true,
                  ),
                );
              } else {
                if (state.content.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyList(
                      description: context.t
                          .userNoNotes(name: state.user.getName())
                          .capitalizeFirst(),
                      icon: FeatureIcons.note,
                    ),
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
          )
        ],
      ),
    );
  }

  SliverList _itemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      itemBuilder: (context, index) {
        final event = state.content[index];

        if (event.kind == EventKind.REPOST) {
          return RepostNoteContainer(
            key: ValueKey(event.id),
            event: event,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        } else {
          return DetailedNoteContainer(
            key: ValueKey(event.id),
            note: DetailedNoteModel.fromEvent(event),
            isMain: false,
            addLine: false,
            enableReply: true,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        }
      },
      itemCount: state.content.length,
    );
  }

  SliverMasonryGrid _itemsGrid(ProfileState state) {
    return SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      childCount: state.content.length,
      itemBuilder: (context, index) {
        final event = state.content[index];
        if (event.kind == EventKind.REPOST) {
          return RepostNoteContainer(
            key: ValueKey(event.id),
            event: event,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        } else {
          return DetailedNoteContainer(
            key: ValueKey(event.id),
            note: DetailedNoteModel.fromEvent(event),
            isMain: false,
            addLine: false,
            enableReply: true,
            onMuteActionSuccess: (pubkey, status) {
              context.read<ProfileCubit>().onRemoveMutedContent(
                    pubkey,
                    true,
                  );
            },
          );
        }
      },
    );
  }
}
