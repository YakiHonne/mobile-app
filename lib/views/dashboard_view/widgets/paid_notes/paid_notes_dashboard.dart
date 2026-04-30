import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/write_note_cubit/write_note_cubit.dart';
import '../../../../models/detailed_note_model.dart';
import '../../../../models/unpaid_note.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/empty_list.dart';
import '../../../write_note_view/widgets/paid_note_process.dart';
import '../home/dashboard_containers.dart';

class PaidNotesDashboard extends StatefulWidget {
  const PaidNotesDashboard({
    super.key,
    required this.isDraft,
  });

  final bool isDraft;

  @override
  State<PaidNotesDashboard> createState() => _PaidNotesDashboardState();
}

class _PaidNotesDashboardState extends State<PaidNotesDashboard> {
  List<UnpaidNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    if (currentSigner != null) {
      setState(() {
        _notes = localDatabaseRepository
            .getUnpaidNotes(currentSigner!.getPublicKey());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    if (_notes.isEmpty) {
      return EmptyList(
        title: context.t.noPaidNotesCanBeFound,
        description: 'You have no pending paid notes.',
        icon: FeatureIcons.wallet,
      );
    }

    return isTablet ? _itemsGrid(_notes) : _itemsList(_notes);
  }

  Widget _buildDashboardItem(BuildContext context, UnpaidNote unpaidNote) {
    final event = unpaidNote.event;
    final note = DetailedNoteModel.fromEvent(event);

    void onClick() {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return BlocProvider(
            create: (_) {
              final cubit = WriteNoteCubit(null, isMention: false);
              cubit.toBeSubmittedEvent = unpaidNote.event;
              cubit.relays = unpaidNote.relays;
              return cubit;
            },
            child: const PaidNoteProcess(
              checkZap: true,
            ),
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ).then((_) {
        _loadNotes();
      });
    }

    return DashboardContentContainer(
      image: null,
      id: note.id,
      content: note.content,
      kind: EventKind.TEXT_NOTE,
      onClick: onClick,
      createdAt: note.createdAt,
      enableStats: false,
      date: dateFormat4.format(note.createdAt),
      item: note,
      isPaid: true,
      isHiddenType: true,
      onDeleteItem: (id) async {
        await localDatabaseRepository.removeUnpaidNote(
          currentSigner!.getPublicKey(),
          event.id,
        );

        if (context.mounted) {
          YNavigator.pop(context);
        }

        _loadNotes();
      },
      onRefresh: () {},
    );
  }

  ListView _itemsList(List<UnpaidNote> notes) {
    return ListView.separated(
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, notes[index]),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
    );
  }

  MasonryGridView _itemsGrid(List<UnpaidNote> notes) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemCount: notes.length,
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ),
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, notes[index]),
    );
  }
}
