import 'dart:async';
import 'dart:convert';

import 'package:nostr_core_enhanced/cache/remote_cache_service.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr/remote_cache_event.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/detailed_note_model.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/utils.dart';

/// The cache client can deliver events without ever delivering EOSE. Keep its
/// partial results, and release this request when the deadline is reached.
Future<List<DetailedNoteModel>> loadDesktopTrending(
    bool Function(DetailedNoteModel) canPreview) async {
  final notes =
      await loadDesktopTrendingCache(nc.remoteCacheService, canPreview);
  if (notes.isNotEmpty) {
    return notes;
  }

  // This matches the app's existing trending source, but owns its own relay
  // sockets so a pane refresh cannot close a relay used by Home.
  final core = NostrCore(db: nc.db, loadRemoteCache: false);
  final events = <String, Event>{};
  try {
    await NostrFunctionsRepository.queryEvents(
      [
        Filter(kinds: [EventKind.TEXT_NOTE], limit: 25)
      ],
      DEFAULT_TRENDING_RELAYS,
      core: core,
      timeOut: 2,
      connectTimeout: const Duration(seconds: 3),
      includeExpired: false,
      source: EventsSource.all,
      eventCallBack: (event, _) {
        if (event.kind == EventKind.TEXT_NOTE && event.root == null) {
          events[event.id] = event;
        }
      },
    );
    final sorted = events.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.map(DetailedNoteModel.fromEvent).where(canPreview).toList();
  } finally {
    await core.dispose();
  }
}

Future<List<DetailedNoteModel>> loadDesktopTrendingCache(
  RemoteCacheService cache,
  bool Function(DetailedNoteModel) canPreview, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  final notes = <String, DetailedNoteModel>{};
  if (cache.connectionStatus == 1) {
    final complete = Completer<void>();
    final id = cache.addSubscription(
      RemoteCacheFilter(
        type: RemoteCacheEventsType.scored,
        selector: RemoteCacheEventsSelector.trending1H,
      ),
      eventCallBack: (event) {
        if (event is Event && event.kind == EventKind.TEXT_NOTE) {
          final note = DetailedNoteModel.fromEvent(event);
          if (canPreview(note)) {
            notes[event.id] = note;
          }
        }
      },
      eoseCallBack: (_, __) {
        if (!complete.isCompleted) {
          complete.complete();
        }
      },
    );
    try {
      await complete.future.timeout(timeout);
    } on TimeoutException {
      // A cache without EOSE can still have returned useful events.
    } finally {
      cache.requestsMap.remove(id);
      cache.send(jsonEncode(['CLOSE', id]));
    }
  }
  return notes.values.toList();
}

/// Preserve trending order while showing each author only once.
List<String> desktopTrendingAuthors(
        List<DetailedNoteModel> notes, String account) =>
    notes
        .map((note) => note.pubkey)
        .where((key) => key.isNotEmpty && key != account)
        .toSet()
        .toList();
