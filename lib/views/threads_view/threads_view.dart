// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../models/detailed_note_model.dart';
import '../../utils/utils.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_list.dart';
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
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final f = useCallback(
      () async {
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

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.thread.capitalizeFirst(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: contentReplies.value.isEmpty
                ? EmptyListWithLogo(description: context.t.noReplies)
                : isTablet
                    ? _itemsGrid(contentReplies)
                    : _itemsList(contentReplies),
          ),
          ResetScrollButton(scrollController: controller),
        ],
      ),
    );
  }

  ListView _itemsList(ValueNotifier<List<DetailedNoteModel>> contentReplies) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(
        thickness: 0.5,
        height: kDefaultPadding,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
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
      ValueNotifier<List<DetailedNoteModel>> contentReplies) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding,
      mainAxisSpacing: kDefaultPadding,
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
