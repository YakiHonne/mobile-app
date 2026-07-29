import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/fluid_content_card.dart';
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
    final fluid = isFluid();

    return SliverPadding(
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: fluid ? kDefaultPadding * 4 : kDefaultPadding,
        top: kDefaultPadding / 2,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (!fluid)
            SliverAppBar(
              toolbarHeight: 45,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: SizedBox(
                height: 36,
                width: double.infinity,
                child: _chipList(context),
              ),
            ),
          if (!fluid)
            const SliverToBoxAdapter(
              child: SizedBox(height: kDefaultPadding / 1.5),
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

  Widget _chipList(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      separatorBuilder: (_, __) => const SizedBox(width: kDefaultPadding / 4),
      itemCount: profileDataList.length,
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
    );
  }

  SliverList _itemsList(ProfileState state) {
    return SliverList.separated(
      separatorBuilder: (context, index) => useFluidCards()
          ? const SizedBox(height: kDefaultPadding / 2)
          : const Divider(
              height: kDefaultPadding * 1.5,
              thickness: 0.5,
            ),
      itemBuilder: (context, index) {
        final event = state.content[index];

        return FluidContentCard(
          child: event.kind == EventKind.REPOST
              ? RepostNoteContainer(
                  key: ValueKey(event.id),
                  event: event,
                  isExtended: true,
                  onMuteActionSuccess: (pubkey, status) {
                    context.read<ProfileCubit>().onRemoveMutedContent(
                          pubkey,
                          true,
                        );
                  },
                )
              : DetailedNoteContainer(
                  key: ValueKey(event.id),
                  note: DetailedNoteModel.fromEvent(event),
                  isMain: false,
                  addLine: false,
                  enableReply: true,
                  isExtended: true,
                  onMuteActionSuccess: (pubkey, status) {
                    context.read<ProfileCubit>().onRemoveMutedContent(
                          pubkey,
                          true,
                        );
                  },
                ),
        );
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
        return FluidContentCard(
          child: event.kind == EventKind.REPOST
              ? RepostNoteContainer(
                  key: ValueKey(event.id),
                  event: event,
                  isExtended: true,
                  onMuteActionSuccess: (pubkey, status) {
                    context.read<ProfileCubit>().onRemoveMutedContent(
                          pubkey,
                          true,
                        );
                  },
                )
              : DetailedNoteContainer(
                  key: ValueKey(event.id),
                  note: DetailedNoteModel.fromEvent(event),
                  isMain: false,
                  addLine: false,
                  enableReply: true,
                  isExtended: true,
                  onMuteActionSuccess: (pubkey, status) {
                    context.read<ProfileCubit>().onRemoveMutedContent(
                          pubkey,
                          true,
                        );
                  },
                ),
        );
      },
    );
  }
}

class ProfileNotesFilter extends StatelessWidget {
  const ProfileNotesFilter({
    super.key,
    required this.profileData,
    required this.onChanged,
  });

  final ProfileData profileData;
  final Function(ProfileData) onChanged;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        return profileDataList.map((type) {
          return PullDownMenuItem.selectable(
            title: type.getDisplayName(context).capitalizeFirst(),
            selected: profileData == type,
            onTap: () => onChanged(type),
            itemTheme: PullDownMenuItemTheme(
              textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        }).toList();
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: showMenu,
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: 50.w,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    profileData.getDisplayName(context).capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(LucideIcons.chevronDown),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
