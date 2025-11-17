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
import '../widgets/empty_list.dart';
import '../widgets/note_stats.dart';
import '../widgets/parsed_media_container.dart';

// Constants
const _kLoadingDelay = Duration(milliseconds: 500);
const _kScrollDuration = Duration(milliseconds: 200);
const _kAnimationDuration = Duration(milliseconds: 300);

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
    final isLoading = useState(!note.isRoot);
    final rootEvent = useState<String?>(null);
    final threadIds = useState([note.id]);
    final targetKey = useRef(GlobalKey()).value;

    final loadPrevious = useCallback(
      () async {
        isLoading.value = true;
        await notesEventsCubit.getNotePrevious(
          currentNote.value,
          (val) => isLoading.value = val,
        );

        await Future.delayed(_kLoadingDelay);

        if (targetKey.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey.currentContext!,
            alignment: 0.01,
            duration: _kScrollDuration,
            curve: Curves.easeInOut,
          );
        }
      },
      [currentNote, isLoading],
    );

    final updateNote = useCallback(
      (DetailedNoteModel newNote, {bool isRemoving = false}) {
        isLoading.value = false;
        currentNote.value = newNote;
        if (!isRemoving) {
          threadIds.value = [...threadIds.value, newNote.id];
        } else {
          threadIds.value = threadIds.value.length > 1
              ? threadIds.value.sublist(0, threadIds.value.length - 1)
              : threadIds.value;
        }

        loadPrevious();
      },
      [loadPrevious],
    );

    final loadRootEvent = useCallback(
      () {
        if ((currentNote.value.originId ?? '').isNotEmpty) {
          try {
            final isReplaceable = currentNote.value.originId!.contains(':');
            if (isReplaceable) {
              rootEvent.value = currentNote.value.originId!.split(':').last;
            } else {
              rootEvent.value = currentNote.value.originId;
            }

            singleEventCubit.getEvent(rootEvent.value!, isReplaceable);
          } catch (e) {
            lg.i(e);
          }
        }
      },
      [currentNote],
    );

    useEffect(
      () {
        loadPrevious();
        loadRootEvent();
        return null;
      },
      [],
    );

    return BlocBuilder<NotesEventsCubit, NotesEventsState>(
      buildWhen: (prev, curr) =>
          _shouldRebuild(prev, curr, currentNote.value.id),
      builder: (context, state) => Scaffold(
        appBar: CustomAppBar(
          title: context.t.thread.capitalizeFirst(),
          onBackClicked: () => _handleBack(context, threadIds, updateNote),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: _HeaderContent(
                  note: currentNote.value,
                  isLoading: isLoading.value,
                  previousNotes:
                      state.previousNotes[currentNote.value.id] ?? [],
                  rootEvent: rootEvent.value,
                ),
              ),
              if (state.previousNotes[currentNote.value.id]?.isNotEmpty ??
                  false) ...[
                SliverToBoxAdapter(
                  child: _PreviousNotesList(
                    notes: state.previousNotes[currentNote.value.id]!,
                    onNoteSelected: updateNote,
                  ),
                ),
              ],
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
            ],
            body: NoteRepliesList(
              selectedNote: currentNote,
              setNote: updateNote,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldRebuild(
          NotesEventsState prev, NotesEventsState curr, String noteId) =>
      prev.previousNotes[noteId] != curr.previousNotes[noteId] ||
      prev.mutes != curr.mutes;

  Future<void> _handleBack(
    BuildContext context,
    ValueNotifier<List<String>> threadIds,
    Function(
      DetailedNoteModel, {
      bool isRemoving,
    }) updateNote,
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
    required this.isLoading,
    required this.previousNotes,
    required this.rootEvent,
  });

  final DetailedNoteModel note;
  final bool isLoading;
  final List<DetailedNoteModel> previousNotes;
  final String? rootEvent;

  /// check if root is addressable (["a", kind:pubkey:dtag])
  bool get isAddressable =>
      (note.originId ?? '').isNotEmpty && !note.isOriginEtag!;

  @override
  Widget build(BuildContext context) {
    final showLoading =
        useState(_shouldShowLoading(isAddressable, note, previousNotes));

    return Column(
      children: [
        const SizedBox(height: kDefaultPadding / 2),

        // 🔹 Addressable root
        if (isAddressable) _addressableContainer(),

        // 🔹 Root is ["e", <event_id>, ...] → fetch first
        if (!isAddressable && rootEvent != null)
          _nonAddressableContainer(showLoading),

        // 🔹 Loading indicator
        if (showLoading.value) _loadingPreviewPosts(context),

        const SizedBox(height: kDefaultPadding / 1.5),
      ],
    );
  }

  Row _loadingPreviewPosts(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.t.loadingPreviousPosts.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(width: kDefaultPadding / 3),
        if (isLoading)
          SpinKitCircle(color: Theme.of(context).primaryColor, size: 20)
        else
          Icon(
            Icons.arrow_downward_rounded,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
      ],
    );
  }

  SingleEventProvider _nonAddressableContainer(
      ValueNotifier<bool> showLoading) {
    return SingleEventProvider(
      id: rootEvent!,
      isReplaceable: false,
      child: (event) {
        if (event == null) {
          return const SizedBox.shrink();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (showLoading.value) {
            showLoading.value = false;
          }
        });
        // check if fetched event is a poll
        if (event.kind == EventKind.POLL ||
            event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final baseEventModel = getBaseEventModel(event);

          return AnimatedSwitcher(
            duration: _kAnimationDuration,
            child: baseEventModel != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      bottom: kDefaultPadding / 2,
                    ),
                    child: ParsedMediaContainer(
                      key: ValueKey(baseEventModel.id),
                      baseEventModel: baseEventModel,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }
        // not a poll → show nothing
        return const SizedBox.shrink();
      },
    );
  }

  SingleEventProvider _addressableContainer() {
    return SingleEventProvider(
      id: rootEvent ?? '',
      isReplaceable: true,
      child: (event) {
        final baseEventModel = getBaseEventModel(event);

        return AnimatedSwitcher(
          duration: _kAnimationDuration,
          child: baseEventModel != null
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: kDefaultPadding / 2,
                  ),
                  child: ParsedMediaContainer(
                    key: ValueKey(baseEventModel.id),
                    baseEventModel: baseEventModel,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  bool _shouldShowLoading(
    bool isAddressable,
    DetailedNoteModel note,
    List<DetailedNoteModel> previousNotes,
  ) {
    return isAddressable
        ? (previousNotes.isEmpty && note.replyTo.isNotEmpty) ||
            (previousNotes.isNotEmpty && previousNotes.first.replyTo.isNotEmpty)
        : (!note.isRoot && previousNotes.isEmpty) ||
            (previousNotes.isNotEmpty && !previousNotes.first.isRoot);
  }
}

class _PreviousNotesList extends StatelessWidget {
  const _PreviousNotesList({
    required this.notes,
    required this.onNoteSelected,
  });

  final List<DetailedNoteModel> notes;
  final Function(DetailedNoteModel) onNoteSelected;

  @override
  Widget build(BuildContext context) => SizeChangedLayoutNotifier(
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            itemBuilder: (context, index) => DetailedNoteContainer(
              key: ValueKey(notes[index].id),
              note: notes[index],
              isMain: false,
              addLine: true,
              extendLine: index == notes.length - 1,
              onClicked: () => onNoteSelected(notes[index]),
            ),
            separatorBuilder: (_, __) =>
                const SizedBox(height: kDefaultPadding / 2),
          ),
        ),
      );
}

class NoteRepliesList extends HookWidget {
  const NoteRepliesList({
    super.key,
    required this.selectedNote,
    required this.setNote,
  });

  final ValueNotifier<DetailedNoteModel> selectedNote;
  final Function(DetailedNoteModel note, {bool isRemoving}) setNote;

  @override
  Widget build(BuildContext context) {
    final replies = useState(<DetailedNoteModel>[]);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final updateReplies = useCallback(
      () async {
        final evs = await notesEventsCubit.loadNoteRelatedEvents(
          id: selectedNote.value.id,
          type: NoteRelatedEventsType.replies,
        );

        replies.value = evs.map(DetailedNoteModel.fromEvent).toList();
      },
      [selectedNote],
    );

    useEffect(
      () {
        updateReplies();
        return null;
      },
      [selectedNote.value.id],
    );

    return BlocListener<NotesEventsCubit, NotesEventsState>(
      listenWhen: (prev, curr) =>
          prev.eventsStats[selectedNote.value.id] !=
              curr.eventsStats[selectedNote.value.id] ||
          prev.mutes != curr.mutes ||
          prev.mutesEvents != curr.mutesEvents,
      listener: (_, __) => updateReplies(),
      child: CustomScrollView(
        slivers: replies.value.isEmpty
            ? [
                SliverToBoxAdapter(
                  child: EmptyListWithLogo(description: context.t.noReplies),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kBottomNavigationBarHeight),
                ),
              ]
            : [
                const SliverToBoxAdapter(
                  child: SizedBox(height: kDefaultPadding / 2),
                ),
                SliverToBoxAdapter(
                  child: Text(
                    context.t.replies.capitalizeFirst(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kDefaultPadding / 2),
                ),
                if (isTablet)
                  SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: kDefaultPadding,
                    mainAxisSpacing: kDefaultPadding,
                    itemBuilder: (context, index) => DetailedNoteContainer(
                      key: ValueKey(replies.value[index].id),
                      note: replies.value[index],
                      isMain: false,
                      addLine: false,
                      onClicked: () => setNote(replies.value[index]),
                    ),
                    childCount: replies.value.length,
                  )
                else
                  SliverList.separated(
                    itemCount: replies.value.length,
                    itemBuilder: (context, index) => DetailedNoteContainer(
                      key: ValueKey(replies.value[index].id),
                      note: replies.value[index],
                      isMain: false,
                      addLine: false,
                      onClicked: () => setNote(replies.value[index]),
                    ),
                    separatorBuilder: (_, __) => const Divider(
                      height: kDefaultPadding * 1.5,
                      thickness: 0.3,
                      indent: 45,
                    ),
                  ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: kBottomNavigationBarHeight)),
              ],
      ),
    );
  }
}
