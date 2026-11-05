import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/detailed_note_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../../widgets/fluid_content_card.dart';
import '../../widgets/fluid_source_filter_row.dart';
import '../../widgets/note_stats.dart';
import '../../widgets/tag_container.dart';
import 'desktop_density.dart';
import 'workspace_feed.dart';
import 'workspace_trending_source.dart';

bool desktopCanShowTrendingNote(DetailedNoteModel note) {
  if (note.isPaid ||
      note.isPremium ||
      isUserMuted(note.pubkey) ||
      isThreadMutedById(note.id)) {
    return false;
  }
  try {
    final event = jsonDecode(note.stringifiedEvent);
    final tags = (event as Map)['tags'];
    if (tags is! List) {
      return false;
    }
    return !tags.any((tag) =>
        tag is List && tag.isNotEmpty && tag.first == 'content-warning');
  } catch (_) {
    return false;
  }
}

/// A small discovery digest, independent of Home's source and feed state.
class DesktopWorkspaceDiscovery extends HookWidget {
  const DesktopWorkspaceDiscovery({
    super.key,
    required this.account,
    required this.onSearch,
  });

  final String account;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final revision = useState(0);
    final signedIn =
        account.isNotEmpty && currentSigner?.getPublicKey() == account;
    final task = useMemoized(
      () => signedIn
          ? loadDesktopTrending(desktopCanShowTrendingNote)
          : Future<List<DetailedNoteModel>>.value(const []),
      [account, signedIn, revision.value],
    );
    final snapshot = useFuture(task, preserveState: false);
    if (!signedIn) {
      return Center(
        child: TextButton.icon(
          onPressed: onSearch,
          icon: const Icon(LucideIcons.search),
          label: Text(context.t.searchInNostr),
        ),
      );
    }

    final interests = nostrRepository.interests;
    final topics = (interests.isNotEmpty
            ? interests
            : nostrRepository.topics.map((topic) => topic.topic).toList())
        .where((topic) => topic.trim().isNotEmpty)
        .take(8)
        .toList();
    final notes = (snapshot.data ?? const <DetailedNoteModel>[])
        .where(desktopCanShowTrendingNote)
        .take(12)
        .toList();
    final theme = Theme.of(context);
    final density = DesktopDensityScope.of(context);
    final loading = snapshot.connectionState != ConnectionState.done;
    return DesktopWorkspaceFeed(
      storageKey: const PageStorageKey('desktop-discovery'),
      padding: EdgeInsets.fromLTRB(kDefaultPadding, fluidFeedTopInset(context),
          kDefaultPadding, kDefaultPadding),
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (topics.isNotEmpty) ...[
          Text(context.t.interests.capitalizeFirst(),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: kDefaultPadding / 2),
          Wrap(
            spacing: kDefaultPadding / 4,
            runSpacing: kDefaultPadding / 4,
            children: [
              for (final topic in topics)
                Semantics(
                  button: true,
                  child: TagContainer(
                    title: '#$topic',
                    isActive: true,
                    textColor: theme.primaryColorDark,
                    borderColor: theme.dividerColor,
                    onClick: () => YNavigator.pushPage(
                      context,
                      (_) => SearchView(search: topic, index: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: kDefaultPadding * 1.5),
        ],
        Row(children: [
          Expanded(
            child: Text(context.t.trending.capitalizeFirst(),
                style: theme.textTheme.titleMedium),
          ),
          IconButton(
            tooltip: context.t.refresh.capitalizeFirst(),
            onPressed: snapshot.connectionState == ConnectionState.waiting
                ? null
                : () => revision.value++,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ]),
        if (!loading && (snapshot.hasError || notes.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
            child: Column(children: [
              Text(snapshot.hasError
                  ? context.t.somethingWentWrongDesc
                  : context.t.noResults),
              TextButton(
                onPressed: () => revision.value++,
                child: Text(context.t.retry),
              ),
            ]),
          )
      ]),
      itemCount: loading ? 6 : (snapshot.hasError ? 0 : notes.length),
      loading: loading,
      itemBuilder: (context, index) {
        if (loading) {
          return DesktopWorkspaceSkeleton(
            label: index == 0 ? context.t.loading : null,
          );
        }
        final note = notes[index];
        return FluidContentCard(
          key: ValueKey(note.id),
          desktopContainer: true,
          padding: EdgeInsets.all(density.contentCardPadding),
          child: DetailedNoteContainer(
            note: note,
            isMain: false,
            isExtended: true,
            addLine: false,
            enableReply: true,
            shouldConsiderHiddenReply: true,
          ),
        );
      },
    );
  }
}
