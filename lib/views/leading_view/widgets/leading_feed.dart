import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/leading_cubit/leading_cubit.dart';
import '../../../logic/theme_cubit/theme_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_content_card.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/suggestions_box/multi_suggestion_box.dart';
import 'paid_note_ad_card.dart';

class LeadingFeed extends StatelessWidget {
  const LeadingFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final useSingleColumn =
        nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

    return BlocBuilder<LeadingCubit, LeadingState>(
      builder: (context, state) {
        if (isTablet && !useSingleColumn) {
          return _gridItems(context, state);
        } else {
          return _listItems(state);
        }
      },
    );
  }

  SliverPadding _listItems(LeadingState state) {
    final adGap = subscriptionCubit.isBasic ? 15 : 7;
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
          }

          if (!subscriptionCubit.isPremium &&
              state.paidNoteAds.isNotEmpty &&
              index > 0 &&
              index % adGap == 0) {
            final ad =
                state.paidNoteAds[(index ~/ adGap) % state.paidNoteAds.length];
            return PaidNoteAdCard(event: ad);
          }

          return BlocBuilder<ThemeCubit, ThemeState>(
            buildWhen: (previous, current) =>
                previous.fluidCards != current.fluidCards,
            builder: (context, state) {
              return useFluidCards()
                  ? const SizedBox(
                      height: kDefaultPadding / 2,
                    )
                  : const Divider(
                      thickness: 0.3,
                      height: kDefaultPadding * 1.5,
                    );
            },
          );
        },
        itemBuilder: (context, index) {
          final event = state.content[index];

          Widget child;

          if (event.kind == EventKind.REPOST) {
            child = RepostNoteContainer(
              key: PageStorageKey<String>('item_${event.id}'),
              event: event,
              isExtended: true,
              onMuteActionSuccess: (pubkey, status) {
                if (status) {
                  context.read<LeadingCubit>().onRemoveMutedContent(pubkey);
                }
              },
            );
          } else {
            try {
              child = DetailedNoteContainer(
                key: PageStorageKey<String>('item_${event.id}'),
                note: DetailedNoteModel.fromEvent(event),
                isMain: false,
                isExtended: true,
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

          return FluidContentCard(child: child);
        },
      ),
    );
  }

  SliverPadding _gridItems(BuildContext context, LeadingState state) {
    final adGap = subscriptionCubit.isBasic ? 15 : 7;
    final showAds =
        !subscriptionCubit.isPremium && state.paidNoteAds.isNotEmpty;

    // Interleave paid note ads into the flat content list so grid mode gets
    // the same tier-based pacing as list mode (no separator slot in a grid).
    final cells = <_GridCell>[];
    var adIndex = 0;
    for (var i = 0; i < state.content.length; i++) {
      cells.add(_GridCell.content(state.content[i]));
      if (showAds && (i + 1) % adGap == 0) {
        cells.add(
          _GridCell.ad(state.paidNoteAds[adIndex % state.paidNoteAds.length]),
        );
        adIndex++;
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: feedGridColumns(context),
        itemBuilder: (context, index) {
          final cell = cells[index];
          final event = cell.event;

          if (cell.isAd) {
            return PaidNoteAdCard(event: event);
          }

          return FluidContentCard(
            child: event.kind == EventKind.REPOST
                ? RepostNoteContainer(
                    key: PageStorageKey<String>('item_${event.id}'),
                    isExtended: true,
                    event: event,
                  )
                : DetailedNoteContainer(
                    key: PageStorageKey<String>('item_${event.id}'),
                    note: DetailedNoteModel.fromEvent(event),
                    isMain: false,
                    addLine: false,
                    enableReply: true,
                    isExtended: true,
                    shouldConsiderHiddenReply: true,
                  ),
          );
        },
        childCount: cells.length,
        crossAxisSpacing: kDefaultPadding,
        mainAxisSpacing: kDefaultPadding,
      ),
    );
  }
}

class _GridCell {
  const _GridCell.content(this.event) : isAd = false;
  const _GridCell.ad(this.event) : isAd = true;

  final Event event;
  final bool isAd;
}
