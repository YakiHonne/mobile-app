import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/leading_cubit/leading_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/suggestions_box/multi_suggestion_box.dart';

class LeadingFeed extends StatelessWidget {
  const LeadingFeed({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return BlocBuilder<LeadingCubit, LeadingState>(
      builder: (context, state) {
        if (isTablet && !useSingleColumn) {
          return _gridItems(state);
        } else {
          return _listItems(state);
        }
      },
    );
  }

  SliverPadding _listItems(LeadingState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverList.separated(
        itemCount: state.content.length,
        separatorBuilder: (context, index) {
          if (index > 0 &&
              index % suggestionLeadingSeparatorCount == 0 &&
              index < suggestionLeadingSeparatorCount * 6) {
            return MultiSuggestionBox(
              index: index ~/ suggestionLeadingSeparatorCount,
              isLeading: true,
            );
          } else {
            return const Divider(
              thickness: 0.3,
              height: kDefaultPadding * 1.5,
            );
          }
        },
        itemBuilder: (context, index) {
          final event = state.content[index];

          if (event.kind == EventKind.REPOST) {
            return RepostNoteContainer(
              key: PageStorageKey<String>('item_${event.id}'),
              event: event,
              onMuteActionSuccess: (pubkey, status) {
                if (status) {
                  context.read<LeadingCubit>().onRemoveMutedContent(pubkey);
                }
              },
            );
          } else {
            try {
              return DetailedNoteContainer(
                key: PageStorageKey<String>('item_${event.id}'),
                note: DetailedNoteModel.fromEvent(event),
                isMain: false,
                addLine: false,
                enableReply: true,
                shouldConsiderHiddenReply: true,
                onMuteActionSuccess: (pubkey, status) {
                  if (status) {
                    context.read<LeadingCubit>().onRemoveMutedContent(pubkey);
                  }
                },
              );
            } catch (e, stack) {
              lg.i(stack);
              return const SizedBox();
            }
          }
        },
      ),
    );
  }

  SliverPadding _gridItems(LeadingState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        itemBuilder: (context, index) {
          final event = state.content[index];

          if (event.kind == EventKind.REPOST) {
            return RepostNoteContainer(
              key: PageStorageKey<String>('item_${event.id}'),
              event: event,
            );
          } else {
            return DetailedNoteContainer(
              key: PageStorageKey<String>('item_${event.id}'),
              note: DetailedNoteModel.fromEvent(event),
              isMain: false,
              addLine: false,
              enableReply: true,
              shouldConsiderHiddenReply: true,
            );
          }
        },
        childCount: state.content.length,
        crossAxisSpacing: kDefaultPadding,
        mainAxisSpacing: kDefaultPadding,
      ),
    );
  }
}
