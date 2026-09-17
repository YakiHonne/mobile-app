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
import '../widgets/content_placeholder.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/data_providers.dart';
import '../widgets/fluid_scaffold.dart';
import '../widgets/note_stats.dart';
import '../widgets/parsed_media_container.dart';
import '../widgets/response_snackbar.dart';
import 'widgets/nested_reply_item.dart';

// Constants
const _kFadeDuration = Duration(milliseconds: 300);
const _kStaggerDelay = Duration(milliseconds: 50);
const _kParentPeek = 0.015;
const _kSearchReservedPx = 48.0;

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

    // Just fetch the parents. Positioning is handled by the center-anchored
    // CustomScrollView below: the main note is the `center` sliver, so parents
    // grow upward above it without ever moving it — no scroll chasing needed.
    final isThreadSearching = useState(false);

    final loadPrevious = useCallback(
      () => notesEventsCubit.getNotePrevious(
        currentNote.value,
        (loading) => isThreadSearching.value = loading,
        isActive: () => context.mounted,
      ),
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
        if (!context.mounted) {
          return;
        }
        // Start fade out
        isTransitioning.value = true;

        // Wait for fade out
        await Future.delayed(_kFadeDuration);

        if (!context.mounted) {
          return;
        }

        // Update note and thread
        currentNote.value = newNote;

        threadIds.value = isRemoving
            ? (threadIds.value.length > 1
                ? threadIds.value.sublist(0, threadIds.value.length - 1)
                : threadIds.value)
            : [...threadIds.value, newNote.id];

        // Snap back to the anchor (main note at top) for the newly selected
        // note. The center sliver keeps it pinned while parents/replies load.
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }

        // Fetch surrounding context in the background — the anchor absorbs the
        // height changes, so nothing jumps.
        loadRootEvent();
        loadPrevious();

        // Start fade in.
        isTransitioning.value = false;
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

    // Replies for the current main note (lifted out of the old NoteRepliesList
    // so they can live in the same CustomScrollView as the center anchor).
    final replies = useState(<DetailedNoteModel>[]);
    final isRepliesLoading = useState(true);
    final cachedReplies =
        useMemoized(() => <String, List<DetailedNoteModel>>{});

    final updateReplies = useCallback(
      () async {
        if (!context.mounted) {
          return;
        }

        // loadNoteRelatedEvents only reads what's already cached locally —
        // it doesn't wait on the network fetch. Until that fetch has landed
        // at least once (eventsStats[id] goes from absent to set, including
        // an explicitly-empty result for a note with zero replies), keep
        // showing the skeleton instead of flashing an empty state.
        final hasFetched =
            notesEventsCubit.state.eventsStats[currentNote.value.id] != null;
        if (!hasFetched) {
          isRepliesLoading.value = true;
        }

        final evs = await notesEventsCubit.loadNoteRelatedEvents(
          id: currentNote.value.id,
          type: NoteRelatedEventsType.replies,
        );

        if (!context.mounted) {
          return;
        }
        replies.value = evs.map(DetailedNoteModel.fromEvent).toList();
        if (hasFetched) {
          isRepliesLoading.value = false;
        }
      },
      [currentNote.value.id],
    );

    useEffect(
      () {
        updateReplies();
        return null;
      },
      [currentNote.value.id],
    );

    return BlocConsumer<NotesEventsCubit, NotesEventsState>(
      listenWhen: (prev, curr) => prev.deletedNotes != curr.deletedNotes,
      listener: (context, state) {
        if (state.deletedNotes.contains(currentNote.value.id)) {
          YNavigator.pop(context);
        }
      },
      buildWhen: (prev, curr) =>
          prev.previousNotes[currentNote.value.id] !=
              curr.previousNotes[currentNote.value.id] ||
          prev.mutes != curr.mutes ||
          prev.mutesEvents.contains(currentNote.value.id) !=
              curr.mutesEvents.contains(currentNote.value.id),
      builder: (context, state) {
        final previousNotes = state.previousNotes[currentNote.value.id] ?? [];
        final mutedThread = state.mutesEvents.contains(currentNote.value.id);
        final mediaQuery = MediaQuery.of(context);
        final viewportHeight =
            mediaQuery.size.height - kToolbarHeight - mediaQuery.padding.top;
        final searchAnchor =
            (_kSearchReservedPx / viewportHeight).clamp(0.0, 1.0);

        return FluidScaffold(
          title: context.t.thread.capitalizeFirst(),
          onBackClicked: () => _handleBack(context, threadIds, updateNote),
          body: AnimatedOpacity(
            opacity: isTransitioning.value ? 0.0 : 1.0,
            duration: _kFadeDuration,
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ).copyWith(top: fluidScaffoldTopInset(context)),
              child: BlocListener<NotesEventsCubit, NotesEventsState>(
                listenWhen: (prev, curr) =>
                    prev.eventsStats[currentNote.value.id] !=
                        curr.eventsStats[currentNote.value.id] ||
                    prev.mutes != curr.mutes ||
                    prev.mutesEvents != curr.mutesEvents,
                listener: (_, __) => updateReplies(),
                child: CustomScrollView(
                  controller: scrollController,
                  center: targetKey,
                  anchor: currentNote.value.isRoot
                      ? 0.0
                      : (isThreadSearching.value &&
                              (previousNotes.isEmpty ||
                                  !previousNotes.first.isRoot))
                          ? searchAnchor
                          : _kParentPeek,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeaderContent(
                        note: currentNote.value,
                        rootEvent: rootEvent.value,
                      ),
                    ),

                    if (isThreadSearching.value &&
                        (previousNotes.isEmpty || !previousNotes.first.isRoot))
                      const SliverToBoxAdapter(
                        child: _ThreadSearchIndicator(),
                      ),

                    if (previousNotes.isNotEmpty)
                      _PreviousNotesSliver(
                        notes: previousNotes,
                        onNoteSelected: updateNote,
                        isTransitioning: isTransitioning.value,
                      ),

                    // Main note - the center anchor (always present).
                    SliverToBoxAdapter(
                      key: targetKey,
                      child: mutedThread
                          ? MutedNote(id: currentNote.value.id)
                          : DetailedNoteContainer(
                              key: ValueKey(currentNote.value),
                              note: currentNote.value,
                              isMain: true,
                              addLine: false,
                              autoTranslate:
                                  nostrRepository.getAutoTranslationStatus(),
                            ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: kDefaultPadding / 2),
                    ),

                    // Replies
                    if (!mutedThread)
                      ..._buildReplySlivers(
                        context,
                        replies: replies.value,
                        isLoading: isRepliesLoading.value,
                        cachedReplies: cachedReplies,
                        setNote: updateNote,
                        isTransitioning: isTransitioning.value,
                      ),
                  ],
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

class _ThreadSearchIndicator extends StatelessWidget {
  const _ThreadSearchIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: kDefaultPadding / 2,
        children: [
          SpinKitCircle(
            color: Theme.of(context).primaryColor,
            size: 15,
          ),
          Text(
            context.t.loadingThread,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ],
      ),
    );
  }
}

class MutedNote extends StatelessWidget {
  const MutedNote({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.only(top: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      ),
      child: Row(
        spacing: kDefaultPadding / 2,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: kDefaultPadding / 4,
              children: [
                Text(context.t.threadMuted),
                Text(
                  context.t.threadMutedDescription,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ],
            ),
          ),
          CustomIconButton(
            onClicked: () {
              showCupertinoCustomDialogue(
                context: context,
                title: context.t.threadMuted.capitalizeFirst(),
                description: context.t.threadMutedDescription,
                buttonText: context.t.unmute.capitalizeFirst(),
                buttonTextColor: kGreen,
                setDescriptionMaxLine: true,
                onClicked: () => setMuteStatus(
                  muteKey: id,
                  isPubkey: false,
                  onSuccess: () {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
            icon: FeatureIcons.unmute,
            size: 20,
            vd: -2,
            backgroundColor: kTransparent,
          ),
        ],
      ),
    );
  }
}

class _HeaderContent extends HookWidget {
  const _HeaderContent({
    required this.note,
    required this.rootEvent,
  });

  final DetailedNoteModel note;
  final String? rootEvent;

  bool get isAddressable =>
      (note.originId ?? '').isNotEmpty && !(note.isOriginEtag ?? false);

  @override
  Widget build(BuildContext context) {
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
            child: _buildNonAddressableContainer((_) {}),
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
      author: note.rootPubkey,
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

class _PreviousNotesSliver extends StatelessWidget {
  const _PreviousNotesSliver({
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
        final note = notes[notes.length - 1 - index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(note.id),
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
            note: note,
            isMain: false,
            addLine: true,
            extendLine: index == 0,
            onClicked: isTransitioning ? null : () => onNoteSelected(note),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
    );
  }
}

List<Widget> _buildReplySlivers(
  BuildContext context, {
  required List<DetailedNoteModel> replies,
  required bool isLoading,
  required Map<String, List<DetailedNoteModel>> cachedReplies,
  required Function(DetailedNoteModel note, {bool isRemoving}) setNote,
  required bool isTransitioning,
}) {
  final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
  final useSingleColumn =
      nostrRepository.currentAppCustomization?.useSingleColumnFeed ?? false;

  if (isLoading) {
    return [
      const SliverToBoxAdapter(
        child: NotesPlaceholder(),
      ),
    ];
  }

  if (replies.isEmpty) {
    return _buildEmptyReplies(context);
  }

  return _buildRepliesList(context, replies, isTablet, useSingleColumn,
      cachedReplies, setNote, isTransitioning);
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
  bool useSingleColumn,
  Map<String, List<DetailedNoteModel>> cachedReplies,
  Function(DetailedNoteModel note, {bool isRemoving}) setNote,
  bool isTransitioning,
) {
  final isNested = nostrRepository.getNestedRepliesStatus();

  return [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: kDefaultPadding / 2,
          bottom: kDefaultPadding,
          right: kDefaultPadding,
        ),
        child: Text(
          context.t.replies.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    ),
    if (isTablet && !useSingleColumn)
      SliverMasonryGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: kDefaultPadding,
        mainAxisSpacing: kDefaultPadding,
        itemBuilder: (context, index) {
          final reply = replyList[index];
          return _AnimatedReplyItem(
            key: ValueKey(reply.id),
            index: index,
            child: isNested
                ? NestedReplyItem(
                    note: reply,
                    setNote: setNote,
                    isTransitioning: isTransitioning,
                    cachedReplies: cachedReplies,
                  )
                : DetailedNoteContainer(
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
            child: isNested
                ? NestedReplyItem(
                    note: reply,
                    setNote: setNote,
                    isTransitioning: isTransitioning,
                    cachedReplies: cachedReplies,
                  )
                : DetailedNoteContainer(
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
