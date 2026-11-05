import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/contact_list.dart';

import '../../../models/article_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../article_view/article_view.dart';
import '../../widgets/article_container.dart';
import '../../widgets/fluid_content_card.dart';
import '../../widgets/fluid_source_filter_row.dart';
import '../../widgets/media_components/horizontal_video_view.dart';
import '../../widgets/media_components/vertical_video_view.dart';
import '../../widgets/video_common_container.dart';
import 'desktop_density.dart';
import 'workspace_content_source.dart';
import 'workspace_feed.dart';

class DesktopWorkspaceContent extends HookWidget {
  const DesktopWorkspaceContent({
    super.key,
    required this.account,
    required this.source,
  });

  final String account;
  final DesktopContentSource source;

  @override
  Widget build(BuildContext context) {
    final revision = useState(0);
    final density = DesktopDensityScope.of(context);
    final signedIn =
        account.isNotEmpty && currentSigner?.getPublicKey() == account;
    final future = useMemoized(() async {
      if (!signedIn) {
        return (items: <BaseEventModel>[], following: <String>{});
      }
      final results = await Future.wait([
        loadDesktopContent(account, source),
        contactListCubit.getContactList(account),
      ]);
      final contacts = results[1] as ContactList?;
      return (
        items: results[0]! as List<BaseEventModel>,
        following: contacts?.contacts.toSet() ?? <String>{},
      );
    }, [account, source, signedIn, revision.value]);
    final snapshot = useFuture(future, preserveState: false);
    if (!signedIn) {
      return Center(child: Text(context.t.signIn));
    }
    final items = snapshot.data?.items ?? const <BaseEventModel>[];
    final following = snapshot.data?.following ?? const <String>{};
    final bookmarks = getBookmarkIds(Map.fromEntries(nostrRepository
        .bookmarksLists.entries
        .where((entry) => entry.value.pubkey == account)));
    final title = source == DesktopContentSource.articles
        ? context.t.articles.capitalizeFirst()
        : context.t.videos.capitalizeFirst();
    final loading = snapshot.connectionState != ConnectionState.done;
    return DesktopWorkspaceFeed(
      storageKey: PageStorageKey('desktop-content-${source.name}'),
      padding: EdgeInsets.fromLTRB(kDefaultPadding / 2,
          fluidFeedTopInset(context), kDefaultPadding / 2, kDefaultPadding),
      header: Column(children: [
        Row(children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            tooltip: context.t.refresh.capitalizeFirst(),
            onPressed: snapshot.connectionState == ConnectionState.waiting
                ? null
                : () => revision.value++,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ]),
        if (!loading && (snapshot.hasError || items.isEmpty))
          Column(children: [
            Text(snapshot.hasError
                ? context.t.somethingWentWrongDesc
                : context.t.noResults),
            TextButton(
              onPressed: () => revision.value++,
              child: Text(context.t.retry),
            ),
          ]),
      ]),
      itemCount: loading ? 6 : items.length,
      loading: loading,
      itemBuilder: (context, index) {
        if (loading) {
          return DesktopWorkspaceSkeleton(
            label: index == 0 ? context.t.loading : null,
          );
        }
        final item = items[index];
        if (item is Article) {
          return FluidContentCard(
            key: ValueKey(item.id),
            desktopContainer: true,
            padding: EdgeInsets.all(density.contentCardPadding),
            child: ArticleContainer(
              article: item,
              highlightedTag: '',
              isFollowing: following.contains(item.pubkey),
              isBookmarked: bookmarks.contains(item.identifier),
              onClicked: () => YNavigator.pushNamed(
                  context, ArticleView.routeName,
                  arguments: item),
            ),
          );
        }
        final video = item as VideoModel;
        return FluidContentCard(
          key: ValueKey(video.id),
          desktopContainer: true,
          padding: EdgeInsets.all(density.contentCardPadding),
          child: VideoCommonContainer(
            video: video,
            isFollowing: following.contains(video.pubkey),
            isBookmarked: bookmarks.contains(video.id),
            onTap: () => YNavigator.pushNamed(
              context,
              video.isHorizontal
                  ? HorizontalVideoView.routeName
                  : VerticalVideoView.routeName,
              arguments: [video],
            ),
          ),
        );
      },
    );
  }
}
