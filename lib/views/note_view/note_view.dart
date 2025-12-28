import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../logic/notes_events_cubit/notes_events_cubit.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/detailed_note_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/data_providers.dart';
import '../widgets/note_stats.dart';
import '../widgets/parsed_media_container.dart';

// Constants
const _kScrollDuration = Duration(milliseconds: 300);
const _kFadeDuration = Duration(milliseconds: 300);
const _kStaggerDelay = Duration(milliseconds: 50);

class NoteView extends HookWidget {
  NoteView({
    super.key,
    required this.note,
    this.autoTranslate = false,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Note view');
  }

  static const routeName = '/noteView';
  final DetailedNoteModel note;
  final bool autoTranslate;

  static Route route(RouteSettings settings) {
    final data = settings.arguments! as List;
    return CupertinoPageRoute(
      builder: (_) => NoteView(note: data[0]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentNote = useState(note);
    final isTransitioning = useState(false);
    final rootEvent = useState<String?>(null);
    final threadIds = useState([note.id]);
    final targetKey = useRef(GlobalKey()).value;
    final scrollController = useMemoized(() => ScrollController());

    final loadPrevious = useCallback(
      () async {
        await notesEventsCubit.getNotePrevious(
          currentNote.value,
          (_) {}, // Silent loading
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (targetKey.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey.currentContext!,
            alignment: 0.01,
            duration: _kScrollDuration,
            curve: Curves.easeInOut,
          );
        }
      },
      [currentNote.value.id],
    );

    final loadRootEvent = useCallback(
      () {
        final originId = currentNote.value.originId;
        if (originId == null || originId.isEmpty) {
          return;
        }

        try {
          final isReplaceable = originId.contains(':');
          rootEvent.value = isReplaceable ? originId.split(':').last : originId;
          singleEventCubit.getEvent(rootEvent.value!, isReplaceable);
        } catch (e) {
          lg.i(e);
        }
      },
      [currentNote.value.id],
    );

    final updateNote = useCallback(
      (DetailedNoteModel newNote, {bool isRemoving = false}) async {
        // Start fade out
        isTransitioning.value = true;

        // Wait for fade out
        await Future.delayed(_kFadeDuration);

        // Update note and thread
        currentNote.value = newNote;

        threadIds.value = isRemoving
            ? (threadIds.value.length > 1
                ? threadIds.value.sublist(0, threadIds.value.length - 1)
                : threadIds.value)
            : [...threadIds.value, newNote.id];

        // Reset scroll to top
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }

        // Start fade in
        isTransitioning.value = false;

        // Load data in background
        loadPrevious();
        loadRootEvent();
      },
      [loadPrevious, scrollController],
    );

    useEffect(
      () {
        loadPrevious();
        loadRootEvent();
        return () {
          scrollController.dispose();
        };
      },
      const [],
    );

    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      buildWhen: (prev, curr) =>
          prev.previousNotes[currentNote.value.id] !=
              curr.previousNotes[currentNote.value.id] ||
          prev.mutes != curr.mutes,
      builder: (context, state) {
        final previousNotes = state.previousNotes[currentNote.value.id] ?? [];

        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.thread.capitalizeFirst(),
            onBackClicked: () => _handleBack(context, threadIds, updateNote),
          ),
          body: AnimatedOpacity(
            opacity: isTransitioning.value ? 0.0 : 1.0,
            duration: _kFadeDuration,
            curve: Curves.easeInOut,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: NestedScrollView(
                controller: scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  // Header
                  SliverToBoxAdapter(
                    child: _HeaderContent(
                      note: currentNote.value,
                      previousNotes: previousNotes,
                      rootEvent: rootEvent.value,
                    ),
                  ),

                  // Previous notes with staggered animation
                  if (previousNotes.isNotEmpty)
                    _PreviousNotesList(
                      notes: previousNotes,
                      onNoteSelected: updateNote,
                      isTransitioning: isTransitioning.value,
                    ),

                  // Main note - highlighted
                  SliverToBoxAdapter(
                    key: targetKey,
                    child: DetailedNoteContainer(
                      key: ValueKey(currentNote.value),
                      note: currentNote.value,
                      isMain: true,
                      addLine: false,
                      autoTranslate: autoTranslate,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                  ),
                ],
                body: NoteRepliesList(
                  key: ValueKey('replies_${currentNote.value.id}'),
                  selectedNote: currentNote,
                  setNote: updateNote,
                  isTransitioning: isTransitioning.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBack(
    BuildContext context,
    ValueNotifier<List<String>> threadIds,
    Function(DetailedNoteModel, {bool isRemoving}) updateNote,
  ) async {
    if (threadIds.value.length > 1) {
      final lastId = threadIds.value[threadIds.value.length - 2];
      final event = await nc.db.loadEventById(lastId, false);
      if (event != null) {
        updateNote(DetailedNoteModel.fromEvent(event), isRemoving: true);
      }
    } else {
      YNavigator.pop(context);
    }
  }
}

class _HeaderContent extends HookWidget {
  const _HeaderContent({
    required this.note,
    required this.previousNotes,
    required this.rootEvent,
  });

  final DetailedNoteModel note;
  final List<DetailedNoteModel> previousNotes;
  final String? rootEvent;

  bool get isAddressable =>
      (note.originId ?? '').isNotEmpty && !(note.isOriginEtag ?? false);

  bool get shouldShowIndicator {
    return isAddressable
        ? (previousNotes.isEmpty && note.replyTo.isNotEmpty) ||
            (previousNotes.isNotEmpty && previousNotes.first.replyTo.isNotEmpty)
        : (!note.isRoot && previousNotes.isEmpty) ||
            (previousNotes.isNotEmpty && !previousNotes.first.isRoot);
  }

  @override
  Widget build(BuildContext context) {
    final hasBeenFound = useState(false);

    return Column(
      children: [
        const SizedBox(height: kDefaultPadding / 2),
        if (isAddressable)
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAddressableContainer(),
          ),
        if (!isAddressable && rootEvent != null)
          Align(
            alignment: Alignment.centerLeft,
            child: _buildNonAddressableContainer((hbf) async {
              await Future.delayed(const Duration(milliseconds: 500));
              hasBeenFound.value = hbf;
            }),
          ),
        if (isAddressable
            ? shouldShowIndicator
            : (shouldShowIndicator && !hasBeenFound.value))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: kDefaultPadding / 3),
                Text(
                  context.t.thread,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNonAddressableContainer(Function(bool) eventFound) {
    return SingleEventProvider(
      id: rootEvent!,
      isReplaceable: false,
      child: (event) {
        if (event == null) {
          return const SizedBox.shrink();
        }

        final kind = event.kind;
        if (kind == EventKind.POLL ||
            kind == EventKind.VIDEO_HORIZONTAL ||
            kind == EventKind.VIDEO_VERTICAL ||
            kind == EventKind.PICTURE) {
          final baseEventModel = getBaseEventModel(event);
          eventFound(baseEventModel != null);

          return baseEventModel != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
                  child: ParsedMediaContainer(
                    key: ValueKey(baseEventModel.id),
                    baseEventModel: baseEventModel,
                  ),
                )
              : const SizedBox.shrink();
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddressableContainer() {
    return SingleEventProvider(
      id: rootEvent ?? '',
      isReplaceable: true,
      child: (event) {
        final baseEventModel = getBaseEventModel(event);

        return baseEventModel != null
            ? Padding(
                padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
                child: ParsedMediaContainer(
                  key: ValueKey(baseEventModel.id),
                  baseEventModel: baseEventModel,
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}

class _PreviousNotesList extends HookWidget {
  const _PreviousNotesList({
    required this.notes,
    required this.onNoteSelected,
    required this.isTransitioning,
  });

  final List<DetailedNoteModel> notes;
  final Function(DetailedNoteModel) onNoteSelected;
  final bool isTransitioning;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: _kFadeDuration + (_kStaggerDelay * index),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          child: DetailedNoteContainer(
            key: ValueKey(note.id),
            note: note,
            isMain: false,
            addLine: true,
            extendLine: index == notes.length - 1,
            onClicked: isTransitioning ? null : () => onNoteSelected(note),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
    );
  }
}

class NoteRepliesList extends HookWidget {
  const NoteRepliesList({
    super.key,
    required this.selectedNote,
    required this.setNote,
    required this.isTransitioning,
  });

  final ValueNotifier<DetailedNoteModel> selectedNote;
  final Function(DetailedNoteModel note, {bool isRemoving}) setNote;
  final bool isTransitioning;

  @override
  Widget build(BuildContext context) {
    final replies = useState(<DetailedNoteModel>[]);
    final isLoading = useState(true);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final selectedNoteId = selectedNote.value.id;

    final updateReplies = useCallback(
      () async {
        isLoading.value = true;

        final evs = await notesEventsCubit.loadNoteRelatedEvents(
          id: selectedNoteId,
          type: NoteRelatedEventsType.replies,
        );

        replies.value = evs.map(DetailedNoteModel.fromEvent).toList();
        isLoading.value = false;
      },
      [selectedNoteId],
    );

    useEffect(
      () {
        updateReplies();
        return null;
      },
      [selectedNoteId],
    );

    return BlocListener<NotesEventsCubit, NotesEventsState>(
      listenWhen: (prev, curr) =>
          prev.eventsStats[selectedNoteId] !=
              curr.eventsStats[selectedNoteId] ||
          prev.mutes != curr.mutes ||
          prev.mutesEvents != curr.mutesEvents,
      listener: (_, __) => updateReplies(),
      child: CustomScrollView(
        slivers: [
          if (isLoading.value)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(kDefaultPadding * 2),
                  child: Column(
                    children: [
                      SpinKitCircle(
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      Text(
                        context.t.loading,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (replies.value.isEmpty)
            ..._buildEmptyReplies(context)
          else
            ..._buildRepliesList(context, replies.value, isTablet),
        ],
      ),
    );
  }

  List<Widget> _buildEmptyReplies(BuildContext context) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 2),
          child: Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  LogosIcons.logoMarkWhite,
                  height: 50,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  context.t.noReplies,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: SizedBox(height: kBottomNavigationBarHeight),
      ),
    ];
  }

  List<Widget> _buildRepliesList(
    BuildContext context,
    List<DetailedNoteModel> replyList,
    bool isTablet,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
            top: kDefaultPadding / 2,
            bottom: kDefaultPadding,
          ),
          child: Text(
            context.t.replies.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
      if (isTablet)
        SliverMasonryGrid.count(
          crossAxisCount: 2,
          crossAxisSpacing: kDefaultPadding,
          mainAxisSpacing: kDefaultPadding,
          itemBuilder: (context, index) {
            final reply = replyList[index];
            return _AnimatedReplyItem(
              key: ValueKey(reply.id),
              index: index,
              child: DetailedNoteContainer(
                note: reply,
                isMain: false,
                addLine: false,
                onClicked: isTransitioning ? null : () => setNote(reply),
              ),
            );
          },
          childCount: replyList.length,
        )
      else
        SliverList.separated(
          itemCount: replyList.length,
          itemBuilder: (context, index) {
            final reply = replyList[index];
            return _AnimatedReplyItem(
              key: ValueKey(reply.id),
              index: index,
              child: DetailedNoteContainer(
                note: reply,
                isMain: false,
                addLine: false,
                onClicked: isTransitioning ? null : () => setNote(reply),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(
            height: kDefaultPadding * 1.5,
            thickness: 0.3,
            indent: 45,
          ),
        ),
      const SliverToBoxAdapter(
        child: SizedBox(height: kBottomNavigationBarHeight),
      ),
    ];
  }
}

class _AnimatedReplyItem extends StatelessWidget {
  const _AnimatedReplyItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _kFadeDuration + (_kStaggerDelay * (index * 0.5)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
