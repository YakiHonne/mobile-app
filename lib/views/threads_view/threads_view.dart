// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../models/detailed_note_model.dart';
import '../../utils/utils.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/empty_list.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/note_stats.dart';

class ContentThreadsView extends HookWidget {
  ContentThreadsView({
    super.key,
    required this.aTag,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Threads view');
  }

  final String aTag;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final contentReplies = useState(<DetailedNoteModel>[]);
    final isTablet = deviceIsTablet;

    final f = useCallback(
      () async {
        notesEventsCubit.getSpecificContentStats(aTag,
            r: true, includeComments: true);

        final events = await notesEventsCubit.loadNoteRelatedEvents(
          id: aTag,
          type: NoteRelatedEventsType.replies,
        );

        final filtered = events
            .where(
              (element) => element.reply == null,
            )
            .toList();

        contentReplies.value = filtered
            .map(
              (e) => DetailedNoteModel.fromEvent(e),
            )
            .toList();
      },
    );

    useMemoized(() {
      f.call();
    });

    return FluidScaffold(
      title: context.t.thread.capitalizeFirst(),
      body: Stack(
        children: [
          Positioned.fill(
            child: contentReplies.value.isEmpty
                ? EmptyListWithLogo(description: context.t.noReplies)
                : isTablet
                    ? _itemsGrid(context, contentReplies)
                    : _itemsList(context, contentReplies),
          ),
          ResetScrollButton(scrollController: controller),
        ],
      ),
    );
  }

  ListView _itemsList(
    BuildContext context,
    ValueNotifier<List<DetailedNoteModel>> contentReplies,
  ) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        thickness: 0.5,
        height: kDefaultPadding,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2).copyWith(
        top: kDefaultPadding / 2 + fluidScaffoldTopInset(context),
      ),
      itemBuilder: (context, index) {
        final reply = contentReplies.value[index];

        return DetailedNoteContainer(
          key: ValueKey(reply.id),
          note: reply,
          isMain: false,
          addLine: false,
        );
      },
      itemCount: contentReplies.value.length,
    );
  }

  MasonryGridView _itemsGrid(
    BuildContext context,
    ValueNotifier<List<DetailedNoteModel>> contentReplies,
  ) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding,
      mainAxisSpacing: kDefaultPadding,
      padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
      itemBuilder: (context, index) {
        final reply = contentReplies.value[index];

        return DetailedNoteContainer(
          key: ValueKey(reply.id),
          note: reply,
          isMain: false,
          addLine: false,
        );
      },
      itemCount: contentReplies.value.length,
    );
  }
}
