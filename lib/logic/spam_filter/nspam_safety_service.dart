import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../globals.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/detailed_note_model.dart';
import '../../repositories/localdatabase_repository.dart' show prefs;
import 'nspam_feature_extractor.dart';
import 'nspam_model_worker.dart';

/// A reversible partition of a thread's replies by the local nspam score.
class NSpamReplyPartition {
  const NSpamReplyPartition({
    required this.visibleReplies,
    required this.potentialSpamReplies,
  });

  final List<DetailedNoteModel> visibleReplies;
  final List<DetailedNoteModel> potentialSpamReplies;
}

/// Applies account-local spam settings and scores cached author histories.
///
/// The model runs in a background isolate. Its only inputs are kind-1 events
/// already present in the local Nostr database; no content is sent elsewhere.
class NSpamSafetyService extends ChangeNotifier {
  NSpamSafetyService._();

  static final NSpamSafetyService instance = NSpamSafetyService._();

  static const double spamThreshold = 0.7;
  static const int _maxCachedAuthors = 2000;
  static const Duration _authorScoreCacheDuration = Duration(minutes: 30);
  static const String _enabledKeyPrefix = 'nspam_filter_enabled_';
  static const String _safeAuthorsKeyPrefix = 'nspam_safe_authors_';

  final LinkedHashMap<String, _NSpamAuthorScore> _scores =
      LinkedHashMap<String, _NSpamAuthorScore>();
  Set<String> _safeAuthors = <String>{};
  String? _loadedAccountPubkey;
  bool _hasLoadedAccount = false;
  bool _enabled = true;
  int _revision = 0;

  bool get isEnabled => _enabled;

  int get revision => _revision;

  /// Loads the current account's local setting and not-spam safelist.
  void initializeForCurrentAccount() {
    _ensureAccountLoaded();
  }

  /// Enables or disables the reply filter for the signed-in account.
  Future<void> setEnabled(bool enabled) async {
    _ensureAccountLoaded();
    if (_enabled == enabled) {
      return;
    }
    _enabled = enabled;
    _notifyChanged();
    final pubkey = _loadedAccountPubkey;
    if (pubkey != null) {
      await prefs.setBool('$_enabledKeyPrefix$pubkey', enabled);
    }
  }

  /// Safelists an author after the user marks one of their replies as not spam.
  Future<void> markAuthorNotSpam(String pubkey) async {
    _ensureAccountLoaded();
    if (pubkey.isEmpty || !_safeAuthors.add(pubkey)) {
      return;
    }
    _scores.remove(pubkey);
    _notifyChanged();
    final accountPubkey = _loadedAccountPubkey;
    if (accountPubkey != null) {
      await prefs.setStringList(
        '$_safeAuthorsKeyPrefix$accountPubkey',
        _safeAuthors.toList(),
      );
    }
  }

  /// Removes an author from the local not-spam safelist so they can be filtered
  /// again by the on-device model.
  Future<void> markAuthorSpam(String pubkey) async {
    _ensureAccountLoaded();
    if (pubkey.isEmpty || !_safeAuthors.remove(pubkey)) {
      return;
    }
    _scores.remove(pubkey);
    _notifyChanged();
    final accountPubkey = _loadedAccountPubkey;
    if (accountPubkey != null) {
      await prefs.setStringList(
        '$_safeAuthorsKeyPrefix$accountPubkey',
        _safeAuthors.toList(),
      );
    }
  }

  /// Whether the signed-in account has locally marked this author as not spam.
  bool isAuthorSafelisted(String pubkey) {
    _ensureAccountLoaded(notify: false);
    return _safeAuthors.contains(pubkey);
  }

  /// Returns the ordinary replies and likely-spam replies separately.
  ///
  /// A high score is only used for display grouping. It never deletes events
  /// or changes their Nostr representation.
  Future<NSpamReplyPartition> partitionReplies(
    List<DetailedNoteModel> replies,
  ) async {
    _ensureAccountLoaded(notify: false);
    if (replies.isEmpty || !_enabled || !canSign()) {
      return NSpamReplyPartition(
        visibleReplies: replies,
        potentialSpamReplies: const <DetailedNoteModel>[],
      );
    }

    final accountPubkey = currentSigner!.getPublicKey();
    final followedPubkeys = contactListCubit.contacts.toSet();
    if (currentSigner?.getPublicKey() != accountPubkey) {
      return NSpamReplyPartition(
        visibleReplies: replies,
        potentialSpamReplies: const <DetailedNoteModel>[],
      );
    }

    final eligibleAuthors = replies
        .map((reply) => reply.pubkey)
        .where(
          (pubkey) =>
              pubkey != accountPubkey &&
              !followedPubkeys.contains(pubkey) &&
              !_safeAuthors.contains(pubkey),
        )
        .toSet();
    if (eligibleAuthors.isEmpty) {
      return NSpamReplyPartition(
        visibleReplies: replies,
        potentialSpamReplies: const <DetailedNoteModel>[],
      );
    }

    final authorsToScore = <String>{};
    for (final author in eligibleAuthors) {
      final cached = _scores.remove(author);
      if (cached == null ||
          DateTime.now().difference(cached.scoredAt) >=
              _authorScoreCacheDuration) {
        authorsToScore.add(author);
      } else {
        _scores[author] = cached;
      }
    }

    if (authorsToScore.isNotEmpty) {
      final histories = <String, List<NSpamNoteInput>>{};
      await Future.wait(
        authorsToScore.map((author) async {
          try {
            final events = await nc.db.loadEvents(
              f: Filter(
                authors: <String>[author],
                kinds: <int>[EventKind.TEXT_NOTE],
                limit: 10,
              ),
            );
            final recentEvents = events
              ..sort(
                  (left, right) => right.createdAt.compareTo(left.createdAt));
            if (recentEvents.isNotEmpty) {
              histories[author] = recentEvents
                  .take(10)
                  .map(
                    (event) => NSpamNoteInput(
                      content: event.content,
                      tags: event.tags,
                      createdAt: event.createdAt,
                    ),
                  )
                  .toList();
            }
          } catch (_) {
            // A local cache miss should leave the reply visible.
          }
        }),
      );

      if (histories.isNotEmpty) {
        try {
          final scores =
              await NSpamModelWorker.instance.scoreAuthors(histories);
          for (final entry in scores.entries) {
            _rememberScore(
              entry.key,
              _NSpamAuthorScore(entry.value, DateTime.now()),
            );
          }
        } catch (_) {
          // If model loading or inference fails, fail open and show the replies.
        }
      }
    }

    final potentialSpamAuthors = eligibleAuthors.where((author) {
      return (_scores[author]?.score ?? 0) >= spamThreshold;
    }).toSet();
    if (potentialSpamAuthors.isEmpty) {
      return NSpamReplyPartition(
        visibleReplies: replies,
        potentialSpamReplies: const <DetailedNoteModel>[],
      );
    }

    return NSpamReplyPartition(
      visibleReplies: replies
          .where((reply) => !potentialSpamAuthors.contains(reply.pubkey))
          .toList(),
      potentialSpamReplies: replies
          .where((reply) => potentialSpamAuthors.contains(reply.pubkey))
          .toList(),
    );
  }

  void _ensureAccountLoaded({bool notify = true}) {
    final accountPubkey = canSign() ? currentSigner!.getPublicKey() : null;
    if (_hasLoadedAccount && _loadedAccountPubkey == accountPubkey) {
      return;
    }
    _hasLoadedAccount = true;
    _loadedAccountPubkey = accountPubkey;
    _scores.clear();
    _enabled = accountPubkey == null ||
        (prefs.getBool('$_enabledKeyPrefix$accountPubkey') ?? true);
    _safeAuthors = accountPubkey == null
        ? <String>{}
        : (prefs.getStringList('$_safeAuthorsKeyPrefix$accountPubkey') ??
                <String>[])
            .toSet();
    if (notify) {
      _notifyChanged();
    }
  }

  void _rememberScore(String pubkey, _NSpamAuthorScore score) {
    _scores
      ..remove(pubkey)
      ..[pubkey] = score;
    while (_scores.length > _maxCachedAuthors) {
      _scores.remove(_scores.keys.first);
    }
  }

  void _notifyChanged() {
    _revision++;
    notifyListeners();
  }
}

class _NSpamAuthorScore {
  const _NSpamAuthorScore(this.score, this.scoredAt);

  final double score;
  final DateTime scoredAt;
}
