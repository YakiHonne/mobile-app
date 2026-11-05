import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/article_model.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/video_model.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/utils.dart';

enum DesktopContentSource { articles, videos }

/// Each request owns its relay connections; only the local cache is shared.
Future<List<BaseEventModel>> loadDesktopContent(
    String account, DesktopContentSource source) async {
  final signer = currentSigner;
  if (account.isEmpty || signer?.getPublicKey() != account) {
    return const [];
  }
  if (currentUserRelayList.pubkey != account) {
    throw StateError('Relay list is not ready for this account');
  }
  final relays = currentUserRelayList.relays.keys.toList();
  if (relays.isEmpty) {
    relays.addAll(DEFAULT_BOOTSTRAP_RELAYS);
  }
  final kinds = source == DesktopContentSource.articles
      ? [EventKind.LONG_FORM]
      : [
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
          EventKind.LEGACY_VIDEO_HORIZONTAL,
          EventKind.LEGACY_VIDEO_VERTICAL,
        ];
  final core = NostrCore(db: nc.db, loadRemoteCache: false)
    ..currentSigner = signer;
  final events = <String, Event>{};
  try {
    await NostrFunctionsRepository.queryEvents(
      [Filter(kinds: kinds, limit: 30)],
      relays,
      core: core,
      timeOut: 2,
      connectTimeout: const Duration(seconds: 3),
      includeExpired: false,
      source: EventsSource.all,
      eventCallBack: (event, _) {
        if (kinds.contains(event.kind)) {
          events[event.id] = event;
        }
      },
    );
    if (currentSigner?.getPublicKey() != account) {
      return const [];
    }
    final items = <String, BaseEventModel>{};
    for (final event in events.values) {
      if (isUserMuted(event.pubkey) || isThreadMutedByEvent(event)) {
        continue;
      }
      try {
        if (source == DesktopContentSource.articles) {
          final article = Article.fromEvent(event);
          if (article.identifier.isEmpty || article.title.isEmpty) {
            continue;
          }
          final key = '${article.pubkey}:${article.identifier}';
          final previous = items[key];
          if (previous == null ||
              previous.createdAt.isBefore(article.createdAt)) {
            items[key] = article;
          }
        } else {
          final video = VideoModel.fromEvent(event);
          // VideoCommonContainer does not mask content warnings.
          if (video.title.isNotEmpty &&
              video.url.isNotEmpty &&
              !video.contentWarning) {
            items[video.id] = video;
          }
        }
      } catch (error) {
        lg.i(error);
      }
    }
    return items.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  } finally {
    await core.dispose();
  }
}
