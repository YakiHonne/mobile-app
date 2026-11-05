import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../logic/main_cubit/main_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/detailed_note_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../profile_view/profile_view.dart';
import '../../search_view/search_view.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/fluid_content_card.dart';
import '../../widgets/fluid_source_filter_row.dart';
import 'desktop_density.dart';
import 'workspace_discovery.dart';
import 'workspace_feed.dart';
import 'workspace_sources.dart';
import 'workspace_trending_source.dart';

/// The workspace and its source selection are rebuilt when the account changes.
class DesktopWorkspace extends StatelessWidget {
  const DesktopWorkspace({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: contactListCubit,
      child: BlocBuilder<MainCubit, MainState>(
        buildWhen: (previous, current) => previous.pubKey != current.pubKey,
        builder: (context, state) => DesktopWorkspaceSources(
          key: ValueKey(state.pubKey),
          account: state.pubKey,
          onSearch: onSearch,
          following: _PeopleBase(
            account: state.pubKey,
            onSearch: onSearch,
          ),
        ),
      ),
    );
  }
}

class _PeopleBase extends HookWidget {
  const _PeopleBase({required this.account, required this.onSearch});

  final String account;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final revision = useState(0);
    final signedIn =
        account.isNotEmpty && currentSigner?.getPublicKey() == account;
    final future = useMemoized(
      () => signedIn
          ? loadDesktopTrending(desktopCanShowTrendingNote)
          : Future.value(<DetailedNoteModel>[]),
      [account, signedIn, revision.value],
    );
    final snapshot = useFuture(future, preserveState: false);
    final people = signedIn
        ? desktopTrendingAuthors(snapshot.data ?? const [], account)
            .where((pubkey) => !isUserMuted(pubkey))
            .toList()
        : <String>[];
    return DesktopWorkspaceBase(
      onSearch: onSearch,
      contacts: people,
      showTitle: false,
      floatingSource: true,
      loading: signedIn && snapshot.connectionState != ConnectionState.done,
      onRefresh: signedIn ? () => revision.value++ : null,
      status: !signedIn
          ? context.t.signIn
          : snapshot.hasError
              ? context.t.somethingWentWrongDesc
              : context.t.noResults,
    );
  }
}

class DesktopWorkspaceBase extends StatelessWidget {
  const DesktopWorkspaceBase({
    super.key,
    required this.onSearch,
    this.contacts = const [],
    this.status,
    this.showTitle = true,
    this.floatingSource = false,
    this.loading = false,
    this.onRefresh,
  });

  final VoidCallback onSearch;
  final List<String> contacts;
  final String? status;
  final bool showTitle;
  final bool floatingSource;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = DesktopDensityScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Text(
              context.t.desktopKnowPeople,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (showTitle) const Divider(height: 1),
        Expanded(
          child: DesktopWorkspaceFeed(
            storageKey: const PageStorageKey('desktop-people'),
            padding: EdgeInsets.fromLTRB(
              kDefaultPadding / 1.5,
              floatingSource ? fluidFeedTopInset(context) : kDefaultPadding,
              kDefaultPadding / 1.5,
              kDefaultPadding,
            ),
            header: Column(children: [
              DecoratedBox(
                decoration: contentCardDecoration(theme, solid: !isFluid()),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    overlayColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                    onTap: onSearch,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: density.contentCardPadding,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, color: theme.primaryColor),
                          const SizedBox(width: kDefaultPadding / 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.t.searchInNostr,
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: kDefaultPadding / 8),
                                Text(context.t.findPeopleContent,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.hintColor)),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight,
                              color: theme.hintColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: density.headerGap),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          loading
                              ? context.t.loading
                              : contacts.isEmpty
                                  ? (status ?? context.t.startSearchPeople)
                                  : '${context.t.people.capitalizeFirst()} (${contacts.length})',
                          style: contacts.isEmpty
                              ? theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.hintColor)
                              : theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700))),
                  if (onRefresh != null)
                    IconButton(
                      tooltip: context.t.refresh.capitalizeFirst(),
                      onPressed: loading ? null : onRefresh,
                      icon: const Icon(LucideIcons.refreshCw),
                    ),
                ]),
              ),
            ]),
            itemCount: loading ? 4 : contacts.length,
            loading: loading,
            itemBuilder: (context, index) => loading
                ? DesktopWorkspaceSkeleton(
                    people: true,
                    label: index == 0 ? context.t.loading : null,
                  )
                : _FollowingPerson(pubkey: contacts[index]),
          ),
        ),
      ],
    );
  }
}

class _FollowingPerson extends StatelessWidget {
  const _FollowingPerson({required this.pubkey});
  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      loadNip05: false,
      child: (metadata, _) {
        void open() => YNavigator.pushNamed(context, ProfileView.routeName,
            arguments: [pubkey]);
        return DesktopFollowingPersonCard(metadata: metadata, onOpen: open);
      },
    );
  }
}

class DesktopFollowingPersonCard extends StatelessWidget {
  const DesktopFollowingPersonCard({
    super.key,
    required this.metadata,
    required this.onOpen,
  });

  final Metadata metadata;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = DesktopDensityScope.of(context);
    return FluidContentCard(
      desktopContainer: true,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          child: Padding(
            padding: EdgeInsets.all(density.contentCardPadding),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: SearchAuthorContainer(
                    metadata: metadata,
                    youFollow:
                        contactListCubit.contacts.contains(metadata.pubkey),
                    onClick: onOpen,
                  ),
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Icon(LucideIcons.arrowUpRight,
                    size: 18, color: theme.hintColor),
              ]),
              if (metadata.about.trim().isNotEmpty) ...[
                const SizedBox(height: kDefaultPadding / 2),
                Text(metadata.about.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
              if (metadata.website.trim().isNotEmpty) ...[
                const SizedBox(height: kDefaultPadding / 2),
                Row(children: [
                  Icon(LucideIcons.globe, size: 16, color: theme.hintColor),
                  const SizedBox(width: kDefaultPadding / 4),
                  Expanded(
                    child: Text(metadata.website.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
