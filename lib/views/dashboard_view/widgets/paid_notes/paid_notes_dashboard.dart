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
import '../../../widgets/fluid_scaffold.dart';
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
      return Padding(
        padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
        child: EmptyList(
          title: context.t.noPaidNotesCanBeFound,
          description: 'You have no pending paid notes.',
          icon: FeatureIcons.wallet,
        ),
      );
    }

    if (isDesktopPlatform) {
      return DesktopPaneGridBuilder(
          builder: (context, columns) =>
              _itemsGrid(context, _notes, columns: columns));
    }
    return isTablet ? _itemsGrid(context, _notes) : _itemsList(context, _notes);
  }

  Widget _buildDashboardItem(BuildContext context, UnpaidNote unpaidNote) {
    final event = unpaidNote.event;
    final note = DetailedNoteModel.fromEvent(event);

    void onClick() {
      showAdaptiveModal(
        context,
        dialogHeight: 620,
        builder: (_) {
          return BlocProvider(
            create: (_) {
              final cubit =
                  WriteNoteCubit(null, isMention: false, isQuote: false);
              cubit.toBeSubmittedEvent = unpaidNote.event;
              cubit.relays = unpaidNote.relays;
              return cubit;
            },
            child: const PaidNoteProcess(
              checkZap: true,
            ),
          );
        },
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

  ListView _itemsList(BuildContext context, List<UnpaidNote> notes) {
    return ListView.separated(
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, notes[index]),
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ).copyWith(top: kDefaultPadding + fluidScaffoldTopInset(context)),
      itemCount: notes.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
    );
  }

  MasonryGridView _itemsGrid(BuildContext context, List<UnpaidNote> notes,
      {int columns = 2}) {
    return MasonryGridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: kDefaultPadding / 2,
      mainAxisSpacing: kDefaultPadding / 2,
      itemCount: notes.length,
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding,
        horizontal: kDefaultPadding / 2,
      ).copyWith(top: kDefaultPadding + fluidScaffoldTopInset(context)),
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, notes[index]),
    );
  }
}
