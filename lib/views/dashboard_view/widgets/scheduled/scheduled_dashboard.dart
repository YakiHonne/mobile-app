import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_scheduled_cubit/dashboard_scheduled_cubit.dart';
import '../../../../models/dvm_pending_pages_result.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/fluid_scaffold.dart';
import '../../../widgets/fluid_sheet.dart';
import '../../../widgets/modal_sheet_container.dart';
import '../../../widgets/parsed_content_display.dart';
import '../home/dashboard_containers.dart';

class ScheduledDashboard extends StatefulWidget {
  const ScheduledDashboard({super.key, this.isModal = false});

  /// Rendered in a sheet rather than a FluidScaffold — no glass app bar to
  /// clear, so the top inset is skipped.
  final bool isModal;

  @override
  State<ScheduledDashboard> createState() => _ScheduledDashboardState();
}

class _ScheduledDashboardState extends State<ScheduledDashboard> {
  @override
  void initState() {
    context.read<DashboardScheduledCubit>().getScheduledNotes();
    super.initState();
  }

  void _showRescheduleDatePicker(BuildContext context, DvmPendingItem result) {
    DateTime? selectedDate =
        DateTime.fromMillisecondsSinceEpoch(result.scheduledAt * 1000);
    showCupertinoModalPopup(
      context: context,
      builder: (_) => ModalSheetContainer(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          children: [
            const ModalBottomSheetHandle(),
            Text(
              context.t.reschedule.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: selectedDate,
                minimumDate:
                    DateTime.now().subtract(const Duration(seconds: 1)),
                onDateTimeChanged: (value) {
                  selectedDate = value;
                },
              ),
            ),
            SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    if (selectedDate != null) {
                      await context
                          .read<DashboardScheduledCubit>()
                          .rescheduleNote(result, selectedDate!);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    context.t.reschedule.capitalizeFirst(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isModal) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        // minChildSize left at its 0.25 default: a downward drag runs well past
        // the initial size, then the host sheet's drag-to-dismiss takes over,
        // instead of jamming against a high floor.
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.7],
        expand: false,
        builder: (context, scrollController) => _content(context,
            scrollController: scrollController),
      );
    }

    return _content(context);
  }

  Widget _content(BuildContext context, {ScrollController? scrollController}) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocBuilder<DashboardScheduledCubit, DashboardScheduledState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _centered(
            scrollController,
            SpinKitCircle(
              color: Theme.of(context).primaryColor,
              size: 25,
            ),
          );
        }

        if (state.notes.isEmpty) {
          return _centered(
            scrollController,
            EmptyList(
              title: context.t.noScheduledNotesFound,
              description: context.t.noScheduledNotesFoundDesc,
              icon: FeatureIcons.calendar,
            ),
          );
        }

        return isTablet
            ? _itemsGrid(state.notes, scrollController)
            : _itemsList(state.notes, scrollController);
      },
    );
  }

  /// In a drag sheet the placeholder has to sit in a scrollable, otherwise the
  /// sheet has nothing to attach the drag gesture to.
  Widget _centered(ScrollController? scrollController, Widget child) {
    if (scrollController == null) {
      return Center(child: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, DvmPendingItem result) {
    String? image;

    final note = result.toDetailedNoteModel();

    final content = note.content;
    final id = note.id;
    final isPaid = note.isPaid;
    void onClick() {
      showAppModalSheet(
        context: context,
        builder: (_) {
          return ParsedContentDisplay(content: content);
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    return DashboardContentContainer(
      image: image,
      id: id,
      content: content,
      kind: EventKind.TEXT_NOTE,
      onClick: onClick,
      createdAt: note.createdAt,
      enableStats: false,
      date: context.t.scheduledOn(date: dateFormat3.format(note.createdAt)),
      item: note,
      isPaid: isPaid,
      isScheduled: true,
      isHiddenType: true,
      onPublish: () {
        context.read<DashboardScheduledCubit>().publishNote(result);
      },
      onReschedule: () {
        _showRescheduleDatePicker(context, result);
      },
      onDeleteItem: (id) async {
        final isSuccessful = await context
            .read<DashboardScheduledCubit>()
            .deleteNote(result.jobId);

        if (isSuccessful && context.mounted) {
          YNavigator.pop(context);
        }
      },
      onRefresh: () {},
    );
  }

  ListView _itemsList(
      List<DvmPendingItem> notes, ScrollController? scrollController) {
    return ListView.separated(
      controller: scrollController,
      itemBuilder: (context, index) =>
          _buildDashboardItem(context, notes[index]),
      padding: EdgeInsets.symmetric(
        vertical: kDefaultPadding +
            (widget.isModal ? 0 : fluidScaffoldTopInset(context)),
        horizontal: kDefaultPadding / 2,
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDefaultPadding / 2),
    );
  }

  MasonryGridView _itemsGrid(
      List<DvmPendingItem> notes, ScrollController? scrollController) {
    return MasonryGridView.count(
      controller: scrollController,
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
