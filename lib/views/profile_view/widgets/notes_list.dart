// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/profile_cubit/profile_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/classic_footer.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/note_stats.dart';

class ProfileNotes extends StatefulWidget {
  const ProfileNotes({
    super.key,
  });

  @override
  State<ProfileNotes> createState() => _ProfileNotesState();
}

class _ProfileNotesState extends State<ProfileNotes> {
  final refreshController = RefreshController();

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
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return Scrollbar(
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.notesLoading == UpdatingState.success) {
            refreshController.loadComplete();
          } else if (state.notesLoading == UpdatingState.idle) {
            refreshController.loadNoData();
          }
        },
        buildWhen: (previous, current) =>
            previous.isNotesLoading != current.isNotesLoading ||
            previous.notesLoading != current.notesLoading ||
            previous.mutes != current.mutes ||
            previous.notes != current.notes ||
            previous.user != current.user,
        builder: (context, state) {
          if (state.isNotesLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              child: NotesPlaceholder(
                useColumn: false,
              ),
            );
          } else {
            if (state.notes.isEmpty) {
              return EmptyList(
                description: context.t
                    .userNoNotes(name: state.user.getName())
                    .capitalizeFirst(),
                icon: FeatureIcons.note,
              );
            } else {
              return _items(context, isTablet, useSingleColumn, state);
            }
          }
        },
      ),
    );
  }

  SmartRefresher _items(BuildContext context, bool isTablet,
      bool useSingleColumn, ProfileState state) {
    return SmartRefresher(
      controller: refreshController,
      enablePullDown: false,
      enablePullUp: true,
      header: const MaterialClassicHeader(
        color: kMainColor,
      ),
      footer: const RefresherClassicFooter(),
      onLoading: () => context.read<ProfileCubit>().getMoreNotes(false),
      child:
          isTablet && !useSingleColumn ? _itemsGrid(state) : _itemsList(state),
    );
  }

  ListView _itemsList(ProfileState state) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        height: kDefaultPadding * 1.5,
        thickness: 0.5,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final event = state.notes[index];

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
      itemCount: state.notes.length,
    );
  }

  MasonryGridView _itemsGrid(ProfileState state) {
    return MasonryGridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) {
        final event = state.notes[index];
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
      itemCount: state.notes.length,
    );
  }
}
