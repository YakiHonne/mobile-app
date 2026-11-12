import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/leading_cubit/leading_cubit.dart';
import '../../../logic/main_cubit/main_cubit.dart';
import '../../../models/detailed_note_model.dart';
import '../../../utils/utils.dart';
import '../../leading_view/widgets/media_box.dart';
import '../../widgets/content_placeholder.dart';
import '../../widgets/suggestions_box/multi_suggestion_box.dart';
import '../../widgets/suggestions_box/related_content.dart';
import 'desktop_density.dart';
import 'workspace_discovery.dart';
import 'workspace_trending_source.dart';

/// The Home feed's supplementary sections, independently scrollable from it.
class DesktopHomeSidebar extends HookWidget {
  const DesktopHomeSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final density = DesktopDensityScope.of(context);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          suggestionsBoxCubit.initLeading();
        }
      });
      return null;
    }, const []);

    return BlocBuilder<MainCubit, MainState>(
      buildWhen: (previous, current) => previous.pubKey != current.pubKey,
      builder: (context, account) => ListView(
        key: PageStorageKey('desktop-home-sidebar-${account.pubKey}'),
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
        children: [
          BlocBuilder<LeadingCubit, LeadingState>(
            builder: (context, state) {
              if (!state.onMediaLoading && state.media.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: Text(context.t.suggestions.capitalizeFirst(),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  SizedBox(height: density.sectionHeadingGap),
                  SizedBox(
                    height: 250,
                    child: state.onMediaLoading
                        ? const LeadingMediaPlaceholder()
                        : const MediaBox(desktopPane: true),
                  ),
                  SizedBox(height: density.sectionGap),
                ],
              );
            },
          ),
          _DesktopTopNotes(key: ValueKey(account.pubKey)),
          for (var index = 1; index <= 5; index++)
            MultiSuggestionBox(
              index: index,
              isLeading: true,
              desktopPane: true,
            ),
        ],
      ),
    );
  }
}

class _DesktopTopNotes extends StatefulWidget {
  const _DesktopTopNotes({super.key});

  @override
  State<_DesktopTopNotes> createState() => _DesktopTopNotesState();
}

class _DesktopTopNotesState extends State<_DesktopTopNotes>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<DetailedNoteModel>> _notes =
      loadDesktopTrending(desktopCanShowTrendingNote);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<DetailedNoteModel>>(
      future: _notes,
      builder: (context, snapshot) => _buildNotes(context, snapshot),
    );
  }

  Widget _buildNotes(
      BuildContext context, AsyncSnapshot<List<DetailedNoteModel>> snapshot) {
    final density = DesktopDensityScope.of(context);
    final notes = (snapshot.data ?? const <DetailedNoteModel>[])
        .where(desktopCanShowTrendingNote)
        .take(5)
        .toList();
    final loading = snapshot.connectionState != ConnectionState.done;
    if (!loading && notes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Text('${context.t.top} ${context.t.notes}'.capitalizeFirst(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ),
        SizedBox(height: density.sectionHeadingGap),
        if (loading || notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Text(context.t.loading,
                style: Theme.of(context).textTheme.bodySmall),
          )
        else
          SuggestedNotes(notes: notes, desktopPane: true),
        SizedBox(height: density.sectionGap),
      ],
    );
  }
}
