// ignore_for_file: use_build_context_synchronously

// =============================================================================
// IMPORTS
// =============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/nostr/remote_cache_event.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:uuid/v4.dart';

import '../models/app_models/app_customization.dart';
import '../models/app_models/diverse_functions.dart';
import '../models/app_models/extended_model.dart';
import '../models/article_model.dart';
import '../models/bookmark_list_model.dart';
import '../models/curation_model.dart';
import '../models/detailed_note_model.dart';
import '../models/flash_news_model.dart';
import '../models/picture_model.dart';
import '../models/points_system_models.dart';
import '../models/poll_model.dart';
import '../models/smart_widgets_components.dart';
import '../models/video_model.dart';
import '../models/vote_model.dart';
import '../models/zap_event_subscription.dart';
import '../utils/bot_toast_util.dart';
import '../utils/utils.dart';
import 'http_functions_repository.dart';

// =============================================================================
// NOSTR FUNCTIONS REPOSITORY: Core Nostr protocol operations and data fetching
// =============================================================================
class NostrFunctionsRepository {
  // =============================================================================
  // CONSTANTS
  // =============================================================================
  static const uuid = UuidV4();

  // =============================================================================
  // CACHE MANAGEMENT
  // =============================================================================

  /// Clear all cached data including gift wraps and cache manager.
  /// Returns true on success, shows error toast on failure.
  static Future<bool> clearCache() async {
    try {
      if (canSign()) {
        localDatabaseRepository.deleteNewestGiftWrap(
          currentSigner!.getPublicKey(),
        );
      }
      await nc.db.clearCache();
      return true;
    } catch (e) {
      BotToastUtils.showError('Error occurred while emptying the cache');
      return false;
    }
  }

  // =============================================================================
  // REMOTE CACHE FEED OPERATIONS
  // =============================================================================

  /// Build leading feed from remote cache based on feed type.
  /// Supports highlights and explore feeds with filtering and scoring.

  static Future<List<Metadata>> getUserSearch({
    required String search,
    int? limit,
  }) async {
    final Map<String, Event> users = {};

    try {
      await nc.remoteCacheService.doQuery(
        filter: RemoteCacheFilter(
          type: RemoteCacheEventsType.userSearch,
          limit: limit,
          query: search,
        ),
        eventCallBack: (event) {
          if (event is Event && event.kind == EventKind.METADATA) {
            users[event.id] = event;
          }
        },
      );
    } catch (e) {
      lg.i('Error building RC leading feed: $e');
    }

    return users.values
        .map(
          (e) => Metadata.fromEvent(e)!,
        )
        .toList();
  }

  static Future<List<Event>> buildRcLeadingFeed({
    required CommonFeedTypes type,
    int? limit,
    int? until,
    Function(int)? setScore,
  }) async {
    final Map<String, Event> notesToBeEmitted = {};
    final createdAfter = type == CommonFeedTypes.highlights
        ? null
        : DateTime.now().toSecondsSinceEpoch() - 86400;
    final isHighlight = type == CommonFeedTypes.highlights;
    try {
      await nc.remoteCacheService.doQuery(
        filter: RemoteCacheFilter(
          type: isHighlight
              ? RemoteCacheEventsType.feed
              : RemoteCacheEventsType.explore,
          limit: limit,
          pubkey: isHighlight ? nostrHighlights : null,
          until: until,
          scope: isHighlight ? null : 'global',
          timeFrame: isHighlight ? null : 'trending',
          createdAfter: createdAfter,
        ),
        eventCallBack: (event) {
          if (event is Event &&
              !isUserMuted(event.pubkey) &&
              (event.kind == EventKind.TEXT_NOTE ||
                  event.kind == EventKind.REPOST)) {
            notesToBeEmitted[event.id] = event;
          } else if (event is RemoteCacheEvent &&
              event.kind == RemoteCacheEventKind.feedLastUntil) {
            final data = jsonDecode(event.data['content']);
            setScore?.call(data['since']);
          }
        },
      );
    } catch (e) {
      lg.i('Error building RC leading feed: $e');
    }
    return notesToBeEmitted.values.toList();
  }

  // =============================================================================
  // USER STATISTICS AND PROFILE DATA
  // =============================================================================

  /// Get comprehensive user statistics from remote cache.
  /// Returns follower counts, note counts, and zap statistics.
  static Future<Map<String, num>> getRcUserStats(String pubkey) async {
    final stats = <String, num>{};
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.userProfile,
        pubkey: pubkey,
      ),
      eventCallBack: (e) {
        if (e is RemoteCacheEvent &&
            e.kind == RemoteCacheEventKind.userInfoKind) {
          try {
            final d = jsonDecode(e.data['content']);
            stats.addAll({
              'followings': d['follows_count'] ?? 0,
              'followers': d['followers_count'] ?? 0,
              'notes': d['note_count'] ?? 0,
              'replies': d['reply_count'] ?? 0,
              'zaps_received': d['total_satszapped'] ?? 0,
              'zaps_received_count': d['total_zap_count'] ?? 0,
            });
          } catch (e) {
            lg.w('Error parsing user stats: $e');
          }
        }
      },
    );
    return stats;
  }

  /// Get popular notes for a specific user from remote cache.
  /// Limited to 5 notes, filtered for banned/muted users.
  static Future<List<DetailedNoteModel>> getRcPopularNotes(
      String pubkey) async {
    final notes = <DetailedNoteModel>[];
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.popularNotes,
        pubkey: pubkey,
        limit: 5,
      ),
      eventCallBack: (e) {
        if (e is Event &&
            !isUserMuted(e.pubkey) &&
            e.kind == EventKind.TEXT_NOTE) {
          notes.add(DetailedNoteModel.fromEvent(e));
        }
      },
    );
    return notes;
  }

  /// Get mutual connections between current user and target user.
  /// Saves metadata to cubit and returns set of mutual pubkeys.
  static Future<Set<String>> getRcUserMutuals(String pubkey) async {
    final metadata = <Metadata>[];
    final pubkeys = <String>{};
    if (!canSign()) {
      return pubkeys;
    }
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.userMutuals,
        pubkey: currentSigner!.getPublicKey(),
        userPubkey: pubkey,
      ),
      eventCallBack: (e) {
        if (e is Event && e.kind == EventKind.METADATA) {
          final m = Metadata.fromEvent(e);
          if (m != null) {
            metadata.add(m);
            pubkeys.add(e.pubkey);
          }
        }
      },
    );
    if (metadata.isNotEmpty) {
      metadataCubit.saveMetadatas(metadata);
    }
    return pubkeys;
  }

  // =============================================================================
  // TRENDING AND DISCOVERY DATA
  // =============================================================================

  /// Get trending users from the last 24 hours.
  /// Filters out banned and muted users.
  static Future<List<Metadata>> getRcTrendingUsers24() async {
    final metadatas = <Metadata>[];
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.trendingUsers24,
      ),
      eventCallBack: (e) {
        if (e is Event &&
            e.kind == EventKind.METADATA &&
            !isUserMuted(e.pubkey)) {
          final m = Metadata.fromEvent(e);
          if (m != null) {
            metadatas.add(m);
          }
        }
      },
    );
    return metadatas;
  }

  /// Get trending notes from the last hour.
  /// Uses scored events with trending1H selector.
  static Future<List<DetailedNoteModel>> getRcTrendingNotes1H() async {
    final notes = <DetailedNoteModel>[];
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.scored,
        selector: RemoteCacheEventsSelector.trending1H,
      ),
      eventCallBack: (e) {
        if (e is Event &&
            e.kind == EventKind.TEXT_NOTE &&
            !isUserMuted(e.pubkey)) {
          notes.add(DetailedNoteModel.fromEvent(e));
        }
      },
    );
    return notes;
  }

  /// Search for notes by tag using remote cache.
  /// Limited to 10 results, filters banned/muted users.
  static Future<List<DetailedNoteModel>> getRcNotesFromTags(String tag) async {
    final notes = <DetailedNoteModel>[];
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.search,
        query: tag,
        limit: 10,
      ),
      eventCallBack: (e) {
        if (e is Event &&
            e.kind == EventKind.TEXT_NOTE &&
            !isUserMuted(e.pubkey)) {
          notes.add(DetailedNoteModel.fromEvent(e));
        }
      },
    );
    return notes;
  }

  /// Get basic user information (follower/following counts).
  /// Simplified version of getRcUserStats for basic counts only.
  static Future<Map<String, dynamic>> getRcUserInfos(String pubkey) async {
    final counts = <String, int>{
      'followings': 0,
      'followers': 0,
    };
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.userProfile,
        pubkey: pubkey,
      ),
      eventCallBack: (e) {
        if (e is RemoteCacheEvent &&
            e.kind == RemoteCacheEventKind.userInfoKind) {
          try {
            final d = jsonDecode(e.data['content']);
            counts['followings'] = d['follows_count'] ?? 0;
            counts['followers'] = d['followers_count'] ?? 0;
          } catch (e) {
            lg.w('Error parsing user info: $e');
          }
        }
      },
    );
    return counts;
  }

  /// Get user followers asynchronously from remote cache.
  /// Saves metadata and returns set of follower pubkeys.
  static Future<Set<String>> getRcUserAsyncFollowers(String pubkey) async {
    final metadata = <Metadata>[];
    final pubkeys = <String>{};
    await nc.remoteCacheService.doQuery(
      filter: RemoteCacheFilter(
        type: RemoteCacheEventsType.userFollowers,
        pubkey: pubkey,
      ),
      eventCallBack: (e) {
        if (e is Event && e.kind == EventKind.METADATA) {
          final m = Metadata.fromEvent(e);
          if (m != null) {
            metadata.add(m);
            pubkeys.add(e.pubkey);
          }
        }
      },
    );
    if (metadata.isNotEmpty) {
      metadataCubit.saveMetadatas(metadata);
    }
    return pubkeys;
  }

  // =============================================================================
  // CONTENT DISCOVERY AND TAG-BASED QUERIES
  // =============================================================================

  /// Fetch content by tag including articles, videos, and notes.
  /// Uses multiple filters to get comprehensive tag-based content.
  static Future<void> getTagData({
    required Function(List<Article>) onArticles,
    required Function(List<VideoModel>) onVideos,
    required Function(List<DetailedNoteModel>) onNotes,
    required Function() onDone,
    required String tag,
  }) async {
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, VideoModel> videosToBeEmitted = {};
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, DetailedNoteModel> notesToBeEmitted = {};

    // Filter for videos and long-form content
    final f1 = Filter(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
        EventKind.VIDEO_VERTICAL,
        EventKind.LONG_FORM,
      ],
      t: [tag],
    );

    // Filter for search-tagged notes
    final f2 = Filter(
      kinds: [EventKind.TEXT_NOTE],
      l: [FN_SEARCH_VALUE],
      t: [tag],
    );

    // Filter for regular tagged notes
    final f3 = Filter(
      kinds: [EventKind.TEXT_NOTE],
      t: [tag],
      limit: 40,
    );

    final id = nc.addSubscription(
      [f1, f2, f3],
      [],
      eventCallBack: (ev, relay) {
        final event = ExtendedEvent.fromEv(ev);
        _processTaggedEvent(
            event, videosToBeEmitted, articlesToBeEmitted, notesToBeEmitted);
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        _emitTaggedContent(videosToBeEmitted, articlesToBeEmitted,
            notesToBeEmitted, onVideos, onArticles, onNotes);
      },
    );

    _startSubscriptionTimer(currentUncompletedRelays, onDone, id);
  }

  /// Process individual tagged events and categorize them.
  static void _processTaggedEvent(
    ExtendedEvent event,
    Map<String, VideoModel> videosToBeEmitted,
    Map<String, Article> articlesToBeEmitted,
    Map<String, DetailedNoteModel> notesToBeEmitted,
  ) {
    if (event.kind == EventKind.VIDEO_HORIZONTAL ||
        event.kind == EventKind.VIDEO_VERTICAL) {
      final video = VideoModel.fromEvent(event);
      if (video.url.isNotEmpty) {
        final old = videosToBeEmitted[video.id];
        if (old == null || old.createdAt.compareTo(video.createdAt) < 1) {
          videosToBeEmitted[video.id] = video;
        }
      }
    } else if (event.kind == EventKind.LONG_FORM) {
      final article = Article.fromEvent(event);
      final old = articlesToBeEmitted[article.identifier];
      if (old == null || old.createdAt.compareTo(article.createdAt) < 1) {
        articlesToBeEmitted[article.identifier] = article;
      }
    } else if (event.kind == EventKind.TEXT_NOTE) {
      final note = DetailedNoteModel.fromEvent(event);
      final old = notesToBeEmitted[note.id];
      if (old == null || old.createdAt.compareTo(note.createdAt) < 1) {
        notesToBeEmitted[note.id] = note;
      }
    }
  }

  /// Emit collected tagged content through callbacks.
  static void _emitTaggedContent(
    Map<String, VideoModel> videosToBeEmitted,
    Map<String, Article> articlesToBeEmitted,
    Map<String, DetailedNoteModel> notesToBeEmitted,
    Function(List<VideoModel>) onVideos,
    Function(List<Article>) onArticles,
    Function(List<DetailedNoteModel>) onNotes,
  ) {
    if (videosToBeEmitted.isNotEmpty) {
      onVideos.call(videosToBeEmitted.values.toList());
    }
    if (articlesToBeEmitted.isNotEmpty) {
      onArticles.call(articlesToBeEmitted.values.toList());
    }
    if (notesToBeEmitted.isNotEmpty) {
      onNotes.call(notesToBeEmitted.values.toList());
    }
  }

  // =============================================================================
  // POLLING AND VOTING OPERATIONS
  // =============================================================================

  /// Fetch zap polls with filtering and sorting capabilities.
  /// Supports filtering by authors, tags, IDs, and time ranges.
  static void getZapPolls({
    required Function(List<PollModel>) onPollsFunc,
    required Function() onDone,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? ids,
    int? since,
    int? until,
    int? limit,
  }) {
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, PollModel> pollsToBeEmitted = {};

    final f1 = Filter(
      kinds: [EventKind.POLL],
      authors: pubkeys,
      t: tags,
      ids: ids,
      until: until,
      limit: limit,
    );

    final id = nc.addSubscription(
      [f1],
      [],
      eventCallBack: (event, relay) {
        final poll = PollModel.fromEvent(event);
        final oldPoll = pollsToBeEmitted[poll.id];
        if (oldPoll == null || poll.createdAt.isAfter(oldPoll.createdAt)) {
          pollsToBeEmitted[poll.id] = poll;
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && pollsToBeEmitted.isNotEmpty) {
          final updatedPolls = pollsToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          onPollsFunc.call(updatedPolls);
        }
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    _startSubscriptionTimer(currentUncompletedRelays, onDone, id);
  }

  static void _startSubscriptionTimer(
    List<String> currentUncompletedRelays,
    Function() onDone,
    String id,
  ) {
    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          nc.closeRequests([id]);
        }
      },
    );
  }
  // =============================================================================
  // SMART WIDGETS OPERATIONS
  // =============================================================================

  /// Publish a cloned smart widget to the network.
  /// Handles widget creation, tagging, and relay publishing.
  static Future<void> publishClonedSmartWidget({
    required SmartWidget sm,
    required Function(SmartWidget) onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();
    try {
      final event = await Event.genEvent(
        content: sm.title,
        kind: EventKind.SMART_WIDGET_ENH,
        signer: currentSigner,
        tags: [
          getClientTag(),
          ['d', sm.identifier],
          ['image', sm.smartWidgetBox.image.url],
          if (sm.smartWidgetBox.inputField != null)
            ['input', sm.smartWidgetBox.inputField!.placeholder],
          ...sm.smartWidgetBox.buttons.map(
            (e) => ['button', e.text, e.type.name.toLowerCase(), e.url],
          ),
        ],
      );

      if (event == null) {
        cancel.call();
        return;
      }

      final isSuccessful = await sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call(SmartWidget.fromEvent(event));
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }
    } catch (e) {
      lg.e('Error publishing smart widget: $e');
      BotToastUtils.showError(t.errorAddingWidget.capitalizeFirst());
    } finally {
      cancel.call();
    }
  }

  // =============================================================================
  // UNSENT EVENTS
  // =============================================================================

  // =============================================================================
  // NOTES FUNCTIONS
  // =============================================================================

  static Future<void> getDetailedNotes({
    required Function(List<Event>) onNotesFunc,
    required Function() onDone,
    required List<int> kinds,
    required bool isReplies,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? lTags,
    List<String>? ids,
    int? since,
    int? until,
    int? limit,
    bool? isFeed,
  }) async {
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, Event> notesToBeEmitted = {};

    final f1 = Filter(
      kinds: kinds,
      authors: pubkeys,
      t: tags,
      l: lTags,
      ids: ids,
      until: until,
      limit: limit,
    );

    final id = await nc.doSubscribe(
      [f1],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.TEXT_NOTE) {
          final ev = ExtendedEvent.fromEv(event);

          if (isReplies && ev.root != null) {
            if (ev.isSimpleNote()) {
              final note = DetailedNoteModel.fromEvent(event);
              final oldNote = notesToBeEmitted[note.id];

              if (!isUserMuted(note.pubkey)) {
                if (oldNote == null || event.createdAt > oldNote.createdAt) {
                  notesToBeEmitted[note.id] = event;
                }
              }
            }
          } else if (!isReplies && event.root == null) {
            if (ev.isSimpleNote()) {
              final note = DetailedNoteModel.fromEvent(event);
              final oldNote = notesToBeEmitted[note.id];

              if (!isUserMuted(note.pubkey)) {
                if (oldNote == null || event.createdAt > oldNote.createdAt) {
                  notesToBeEmitted[note.id] = event;
                }
              }
            }
          }
        } else if (event.kind == EventKind.REPOST) {
          if (!isUserMuted(event.pubkey)) {
            final oldRepost = notesToBeEmitted[event.id];
            if (oldRepost == null || event.createdAt > oldRepost.createdAt) {
              notesToBeEmitted[event.id] = event;
            }
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && notesToBeEmitted.isNotEmpty) {
          final Set<String> authors = {};

          for (final element in notesToBeEmitted.values) {
            authors.add(element.pubkey);
          }

          final updatedNotes = notesToBeEmitted.values.toList();

          updatedNotes.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          onNotesFunc.call(updatedNotes);
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          nc.closeRequests([id]);
        }
      },
    );
  }

  // =============================================================================
  // VIDEOS FUNCTIONS
  // =============================================================================

  static Future<void> getVideos({
    required bool loadHorizontal,
    required bool loadVertical,
    required Function(List<VideoModel>) onHorizontalVideos,
    required Function(List<VideoModel>) onVerticalVideos,
    Function(List<VideoModel>)? onAllVideos,
    required Function() onDone,
    int? since,
    int? until,
    int? limit,
    String? relay,
    List<String>? pubkeys,
    List<String>? videosIds,
  }) async {
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, VideoModel> horizontalEvents = {};
    final Map<String, VideoModel> verticalEvents = {};
    final Map<String, VideoModel> allEvents = {};

    final f1 = Filter(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
      ],
      since: since,
      until: until,
      d: videosIds,
      limit: limit,
      authors: pubkeys,
    );

    final f2 = Filter(
      kinds: [
        EventKind.VIDEO_VERTICAL,
      ],
      since: since,
      until: until,
      d: videosIds,
      limit: limit,
      authors: pubkeys,
    );

    final id = nc.addSubscription(
      [if (loadHorizontal) f1, if (loadVertical) f2],
      StringUtil.isBlank(relay) ? [] : [relay!],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final isHorizontal = event.kind == EventKind.VIDEO_HORIZONTAL;
          final video = VideoModel.fromEvent(event, relay: relay);

          if (video.url.isNotEmpty) {
            final old = isHorizontal
                ? horizontalEvents[video.id]
                : verticalEvents[video.id];

            final chosen = filterVideoModel(
              oldVideoModel: old,
              newVideoModel: video,
            );

            allEvents[chosen.id] = chosen;

            if (isHorizontal) {
              horizontalEvents[chosen.id] = chosen;
            } else {
              verticalEvents[chosen.id] = chosen;
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (allEvents.isNotEmpty) {
          onAllVideos?.call(allEvents.values.toList());
        }
        if (horizontalEvents.isNotEmpty) {
          onHorizontalVideos.call(horizontalEvents.values.toList());
        }
        if (verticalEvents.isNotEmpty) {
          onVerticalVideos.call(verticalEvents.values.toList());
        }
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call();
          nc.closeRequests([id]);
        }
      },
    );
  }

  static VideoModel filterVideoModel({
    required VideoModel? oldVideoModel,
    required VideoModel newVideoModel,
  }) {
    return _filterModel<VideoModel>(
      oldModel: oldVideoModel,
      newModel: newVideoModel,
      isNewer: (old, fresh) => old.createdAt.isBefore(fresh.createdAt),
      mergeRelays: (target, source) => target.relays.addAll(source.relays),
    );
  }

  // =============================================================================
  // DMS FUNCTIONS
  // =============================================================================

  static Future<Map<String, List<Event>>> getUserDmsAsync({
    int? since,
    int? until,
  }) async {
    final directMessages = <String, Event>{};
    final giftWraps = <String, Event>{};
    final pubkey = currentSigner!.getPublicKey();

    final f1 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      p: [pubkey],
      since: since,
      until: until,
    );

    final f3 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      authors: [pubkey],
      since: since,
      until: until,
    );

    final f2 = Filter(
      kinds: [
        EventKind.GIFT_WRAP,
      ],
      p: [pubkey],
      since: since,
      until: until,
    );

    await nc.doQuery(
      [f1, f2, f3],
      [],
      source: EventsSource.relays,
      timeOut: 2,
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.GIFT_WRAP) {
          if (giftWraps[event.id] == null) {
            giftWraps[event.id] = event;
          }
        } else if (event.kind == EventKind.DIRECT_MESSAGE) {
          if (directMessages[event.id] == null) {
            directMessages[event.id] = event;
          }
        }
      },
    );

    return {
      'directMessages': directMessages.values.toList(),
      'giftWraps': giftWraps.values.toList(),
    };
  }

  static String getUserDms({
    int? since,
    int? since1059,
    required Function(Event) kind1059Events,
    required Function(Event) kind4Events,
  }) {
    final Set<String> dms = {};
    final pubkey = currentSigner!.getPublicKey();

    final f1 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      p: [pubkey],
      since: since,
    );

    final f3 = Filter(
      kinds: [
        EventKind.DIRECT_MESSAGE,
      ],
      authors: [pubkey],
      since: since,
    );

    final f2 = Filter(
      kinds: [
        EventKind.GIFT_WRAP,
      ],
      since: since1059 != null ? since1059 - 172800 : null,
      p: [pubkey],
    );

    return nc.addSubscription(
      [f1, f2, f3],
      [],
      eventCallBack: (event, relay) async {
        if (!dms.contains(event.id)) {
          dms.add(event.id);
          if (event.kind == EventKind.GIFT_WRAP) {
            kind1059Events.call(event);
          } else if (event.kind == EventKind.DIRECT_MESSAGE) {
            kind4Events.call(event);
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {},
    );
  }

  // =============================================================================
  // NOTIFICATIONS FUNCTIONS
  // =============================================================================

  static Future<String> subscribeToNotifications({
    required String pubkey,
    required Function(Event) onEvents,
    int? limit,
    int? since,
    int? until,
  }) async {
    final Map<String, Event> eventsToBeEmitted = {};
    final c = nostrRepository.currentAppCustomization;

    final filters = getNotificationsFilter(
      pubkey: pubkey,
      limit: limit,
      since: since,
      until: until,
      c: c,
    );

    return nc.doSubscribe(
      [
        if (filters[0] != null) filters[0]!,
        if (filters[1] != null) filters[1]!,
        if (filters[2] != null) filters[2]!,
        if (filters[3] != null) filters[3]!,
        if (filters[4] != null) filters[4]!,
        if (filters[5] != null) filters[5]!,
      ],
      currentUserRelayList.relays.keys.toList(),
      source: EventsSource.all,
      eventCallBack: (event, relay) {
        if (canNotificationBeAdded(event, eventsToBeEmitted, pubkey, c)) {
          onEvents.call(event);
          eventsToBeEmitted[event.id] = event;
        }
      },
    );
  }

  static Future<List<Event>> queryNotifications({
    required String pubkey,
    int? limit,
    int? since,
    int? until,
  }) async {
    try {
      final Map<String, Event> eventsToBeEmitted = {};
      final c = nostrRepository.currentAppCustomization;

      final filters = getNotificationsFilter(
        pubkey: pubkey,
        limit: limit,
        since: since,
        until: until,
        c: c,
      );

      await nc.doQuery(
        [
          if (filters[0] != null) filters[0]!,
          if (filters[1] != null) filters[1]!,
          if (filters[2] != null) filters[2]!,
          if (filters[3] != null) filters[3]!,
          if (filters[4] != null) filters[4]!,
          if (filters[5] != null) filters[5]!,
        ],
        currentUserRelayList.relays.keys.toList(),
        timeOut: 2,
        startingTimeout: 3,
        source: EventsSource.all,
        eventCallBack: (event, relay) {
          if (canNotificationBeAdded(event, eventsToBeEmitted, pubkey, c)) {
            eventsToBeEmitted[event.id] = event;
          }
        },
      );

      return eventsToBeEmitted.values.toList();
    } catch (e) {
      lg.e('Error querying notifications: $e');
      return [];
    }
  }

  static bool canNotificationBeAdded(
    Event event,
    Map<String, Event> eventsToBeEmitted,
    String pubkey,
    AppCustomization? c,
  ) {
    final hideEvent = (c?.notifMaxMentions ?? true) && event.pTags.length > 10;

    if (hideEvent) {
      return false;
    }

    final allowed = (event.kind == EventKind.ZAP &&
            !isUserMuted(getZapPubkey(event.tags).first)) ||
        (event.kind != EventKind.ZAP &&
            !isUserMuted(event.pubkey) &&
            !isThreadMutedByEvent(event) &&
            !eventsToBeEmitted.keys.contains(event.id) &&
            event.pubkey != pubkey);

    final notOusideEvent = event.pTags.contains(pubkey) ||
        ((c?.notifFollowings ?? false) &&
            contactListCubit.contacts.contains(event.pubkey));

    final checkKind = (event.kind == EventKind.TEXT_NOTE &&
            !event.isUncensoredNote()) ||
        (event.kind == EventKind.REACTION && !event.isUnRate()) ||
        (event.kind != EventKind.TEXT_NOTE && event.kind != EventKind.REACTION);

    return allowed && checkKind && notOusideEvent;
  }

  static List<Filter?> getNotificationsFilter({
    required String pubkey,
    int? limit,
    int? since,
    int? until,
    AppCustomization? c,
  }) {
    Filter? filter;
    Filter? filter1;
    Filter? filter2;
    Filter? filter3;
    Filter? filter4;
    Filter? filter5;

    if (c?.notifMentionsReplies ?? false) {
      filter = Filter(
        kinds: [
          EventKind.TEXT_NOTE,
          EventKind.LONG_FORM,
          EventKind.SMART_WIDGET_ENH,
        ],
        p: [pubkey],
        since: since,
        until: until,
        limit: 100,
      );
    }

    if (c?.notifFollowings ?? false) {
      final contacts = contactListCubit.contacts;

      if (contacts.isNotEmpty) {
        filter1 = Filter(
          kinds: [
            EventKind.TEXT_NOTE,
          ],
          authors: contacts,
          l: [FN_SEARCH_VALUE],
          since: since,
          until: until,
          limit: limit,
        );

        filter2 = Filter(
          kinds: [
            EventKind.CURATION_ARTICLES,
            EventKind.CURATION_VIDEOS,
            EventKind.LONG_FORM,
            EventKind.VIDEO_HORIZONTAL,
            EventKind.VIDEO_VERTICAL,
            EventKind.SMART_WIDGET_ENH,
          ],
          authors: contacts,
          since: since,
          until: until,
          limit: limit,
        );
      }
    }

    if (c?.notifReactions ?? false) {
      filter3 = Filter(
        kinds: [
          EventKind.REACTION,
        ],
        p: [pubkey],
        since: since,
        until: until,
        limit: limit,
      );
    }

    if (c?.notifZaps ?? false) {
      filter4 = Filter(
        kinds: [
          EventKind.ZAP,
          EventKind.CASHU_NUTZAP,
        ],
        p: [pubkey],
        since: since,
        until: until,
        limit: limit,
      );
    }

    if (c?.notifReposts ?? false) {
      filter5 = Filter(
        kinds: [
          EventKind.REPOST,
        ],
        p: [pubkey],
        since: since,
        until: until,
        limit: limit,
      );
    }

    return [
      filter,
      filter1,
      filter2,
      filter3,
      filter4,
      filter5,
    ];
  }

  // * app curations /
  // =============================================================================
  // CURATIONS FUNCTIONS
  // =============================================================================

  static Stream<List<Curation>> getCurationsByPubkeys({
    required List<String> pubkeys,
  }) {
    final controller = StreamController<List<Curation>>();
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, Curation> curationsToBeEmitted = {};

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
          authors: pubkeys,
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          final curation = Curation.fromEvent(event, relay);

          final oldCuration = curationsToBeEmitted[curation.identifier];

          curationsToBeEmitted[curation.identifier] = filterCuration(
            oldCuration: oldCuration,
            newCuration: curation,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (curationsToBeEmitted.isNotEmpty) {
          final values = curationsToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) {
            controller.add(values);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static void getCurations({
    required Function(List<Curation>) onCurations,
    required Function() onDone,
  }) {
    final Map<String, Curation> curationsToBeEmitted = {};
    List<String> currentUncompletedRelays = nc.activeRelays();

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          try {
            final curation = Curation.fromEvent(event, relay);
            if (curation.eventsIds.isNotEmpty) {
              final oldCuration = curationsToBeEmitted[curation.identifier];

              curationsToBeEmitted[curation.identifier] = filterCuration(
                oldCuration: oldCuration,
                newCuration: curation,
              );
            }
          } catch (_) {}
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (curationsToBeEmitted.isNotEmpty) {
          final updatedCurations = curationsToBeEmitted.values.toList();

          updatedCurations.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          onCurations.call(updatedCurations);
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          onDone.call();
          timer.cancel();
        }
      },
    );
  }

  static Curation filterCuration({
    required Curation? oldCuration,
    required Curation newCuration,
  }) {
    return _filterModel<Curation>(
      oldModel: oldCuration,
      newModel: newCuration,
      isNewer: (old, fresh) => old.createdAt.compareTo(fresh.createdAt) < 1,
      mergeRelays: (target, source) => target.relays.addAll(source.relays),
    );
  }

  // * get events * /
  static Stream<Event> getEvents({
    List<String>? ids,
    List<String>? dTags,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? aTags,
    List<String>? eTags,
    List<String>? pTags,
    List<int>? kinds,
    int? limit,
    String? relay,
    int? until,
  }) {
    final controller = StreamController<Event>();
    List<String> currentUncompletedRelays = nc.activeRelays();
    final List<String> selectedRelays = relay != null
        ? [relay]
        : pubkeys?.isNotEmpty ?? false
            ? []
            : [];

    nc.addSubscription(
      [
        if (dTags != null && dTags.isNotEmpty)
          Filter(
            d: dTags,
            authors: pubkeys,
            t: tags,
            p: pTags,
            limit: limit,
            until: until,
          ),
        Filter(
          ids: ids,
          authors: pubkeys,
          e: eTags,
          t: tags,
          p: pTags,
          limit: limit,
          kinds: kinds,
          until: until,
        ),
      ],
      selectedRelays,
      eventCallBack: (event, relay) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Future<List<Event>> getEventsAsync({
    List<String>? ids,
    List<String>? dTags,
    List<String>? pubkeys,
    List<String>? tags,
    List<String>? aTags,
    List<String>? eTags,
    List<String>? pTags,
    List<String>? kTags,
    List<String>? lTags,
    List<int>? kinds,
    int? limit,
    List<String>? relays,
    int? until,
    int? since,
    bool compareById = true,
    bool relyOnLongestTags = false,
    bool includeIds = true,
    NostrCore? core,
    EventsSource? source,
    int? timeout,
  }) async {
    final events = <String, Event>{};
    final selectedRelays = relays ??
        (core != null
            ? core.relays()
            : settingsCubit.gossip ?? false
                ? <String>[]
                : currentUserRelayList.urls.toList());

    Filter? f1;
    Filter? f2;

    if (dTags != null) {
      f1 = Filter(
        d: dTags,
        authors: pubkeys,
        t: tags,
        p: pTags,
        limit: limit,
        until: until,
        k: kTags,
        kinds: kinds,
        since: since,
        l: lTags,
      );
    }

    f2 = Filter(
      ids: ids,
      authors: pubkeys,
      p: pTags,
      e: eTags,
      t: tags,
      limit: limit,
      kinds: kinds,
      k: kTags,
      l: lTags,
      until: until,
      since: since,
    );

    await (core ?? nc).doQuery(
      [
        if (f1 != null) f1,
        if (includeIds) f2,
      ],
      selectedRelays,
      timeOut: timeout ?? 1,
      source: source ?? EventsSource.cacheFirst,
      eventCallBack: (event, relay) {
        if (compareById) {
          if (events[event.id] == null) {
            events[event.id] = event;
          }
        } else {
          if (event.dTag != null) {
            final e = events[event.dTag];
            if (e == null) {
              events[event.dTag!] = event;
            } else {
              if (relyOnLongestTags) {
                if (e.tags.length < event.tags.length) {
                  events[event.dTag!] = event;
                }
              } else {
                if (e.createdAt < event.createdAt) {
                  events[event.dTag!] = event;
                }
              }
            }
          }
        }
      },
    );

    final evs = events.values.toList();

    evs.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return evs;
  }

  static Stream<Event> getCurrentUserRelatedData() {
    final controller = StreamController<Event>();
    List<String> currentUncompletedRelays = nc.activeRelays();

    final pubkey = currentSigner!.getPublicKey();

    nc.doQuery(
      [
        Filter(
          kinds: [
            if (canSign()) ...[
              EventKind.MUTE_LIST,
              EventKind.PINNED_NOTES,
            ],
            EventKind.CATEGORIZED_BOOKMARK,
          ],
          authors: [pubkey],
        ),
        Filter(
          kinds: [EventKind.DM_RELAYS, EventKind.SEARCH_RELAYS],
          authors: [pubkey],
        ),
        Filter(
          kinds: [EventKind.INTEREST_SET],
          authors: [pubkey],
        ),
      ],
      currentUserRelayList.urls.toList(),
      source: EventsSource.relays,
      eventCallBack: (event, relay) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<Event> getContentStats({
    required List<String> noteIds,
    required List<String> aTags,
    List<String>? pubkeys,
    int? since,
    int? until,
  }) {
    final controller = StreamController<Event>();
    List<String> currentUncompletedRelays = nc.activeRelays();

    final filters = <Filter>[];
    final nds = List<String>.from(noteIds);
    final atgs = List<String>.from(aTags);

    if (nds.isNotEmpty) {
      final f1 = Filter(
        e: nds,
        authors: pubkeys,
        kinds: [EventKind.TEXT_NOTE, EventKind.REACTION, EventKind.REPOST],
        since: since,
        until: until,
      );

      final f2 = Filter(
        q: nds,
        authors: pubkeys,
        kinds: [EventKind.TEXT_NOTE],
        since: since,
        until: until,
      );

      final f3 = Filter(
        e: nds,
        since: since,
        until: until,
        kinds: [
          EventKind.ZAP,
        ],
      );

      filters.addAll([f1, f2, f3]);
    }

    if (atgs.isNotEmpty) {
      final f1 = Filter(
        a: atgs,
        authors: pubkeys,
        kinds: [EventKind.TEXT_NOTE, EventKind.REACTION, EventKind.REPOST],
        since: since,
        until: until,
      );

      final f2 = Filter(
        q: aTags,
        authors: pubkeys,
        kinds: [EventKind.TEXT_NOTE],
        since: since,
        until: until,
      );

      final f3 = Filter(
        a: atgs,
        since: since,
        until: until,
        kinds: [
          EventKind.ZAP,
        ],
      );

      filters.addAll([f1, f2, f3]);
    }

    nc.addSubscription(
      filters,
      [],
      eventCallBack: (event, relay) {
        if (!controller.isClosed) {
          if (cleanEvent(event: event, noteIds: nds, aTags: atgs)) {
            if ((event.kind == EventKind.TEXT_NOTE &&
                    !event.isUncensoredNote()) ||
                event.kind != EventKind.TEXT_NOTE) {
              controller.add(event);
            }
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static bool cleanEvent({
    required Event event,
    required List<String> noteIds,
    required List<String> aTags,
  }) {
    final hasEtag = event.eTags.any(
      (element) => noteIds.contains(element),
    );

    if (hasEtag) {
      return true;
    }

    final hasAtag = event.aTags.any(
      (element) => aTags.contains(element),
    );

    if (hasAtag) {
      return true;
    }

    final q = event.getQtag(getDTag: false);

    return q != null && (noteIds.contains(q.key) || aTags.contains(q.key));
  }

  static Stream<Event> getForwardingEvents({
    List<String>? ids,
    List<String>? dTags,
    List<String>? pubkeys,
    List<int>? kinds,
    List<String>? relays,
  }) {
    final controller = StreamController<Event>();
    List<String> currentUncompletedRelays = nc.relays();

    final filter = Filter(d: dTags, authors: pubkeys, ids: ids, kinds: kinds);

    nc.addSubscription(
      [
        filter,
      ],
      relays ?? [],
      eventCallBack: (event, relay) {
        if (!controller.isClosed) {
          controller.add(event);
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  // * User bookmarks /
  static Future<void> setBookmarks({
    required bool isReplaceableEvent,
    required String bookmarkIdentifier,
    required String identifier,
    required String pubkey,
    required BaseEventModel model,
    required int kind,
  }) async {
    final bookmarkList = nostrRepository.bookmarksLists[bookmarkIdentifier];

    if (bookmarkList == null) {
      BotToastUtils.showError('Insure that bookmarks list exist!');
      return;
    }

    bool isBookmarkAvailable = false;

    if (model is BookmarkOtherType) {
      isBookmarkAvailable = model.isTag
          ? bookmarkList.bookmarkedTags
              .any((b) => b.val == model.val && b.isTag == model.isTag)
          : bookmarkList.bookmarkedUrls
              .any((b) => b.val == model.val && b.isTag == model.isTag);
    } else if (isReplaceableEvent) {
      isBookmarkAvailable = bookmarkList.isReplaceableEventAvailable(
        identifier: identifier,
        isReplaceableEvent: isReplaceableEvent,
      );
    } else {
      isBookmarkAvailable = bookmarkList.bookmarkedEvents.contains(identifier);
    }

    late EventCoordinates bookmarkEvent;
    late BookmarkOtherType bookmarkOtherType;

    if (!isBookmarkAvailable) {
      if (model is BookmarkOtherType) {
        bookmarkOtherType = model;
      } else if (isReplaceableEvent) {
        bookmarkEvent = EventCoordinates(
          kind,
          pubkey,
          identifier,
          null,
        );
      }
    }

    final bookmarksLoadingIdentifiers =
        nostrRepository.loadingBookmarks[bookmarkIdentifier];

    if (bookmarksLoadingIdentifiers != null) {
      bookmarksLoadingIdentifiers.add(identifier);
    } else {
      nostrRepository.loadingBookmarks[bookmarkIdentifier] = {identifier};
    }

    nostrRepository.loadingBookmarksController
        .add(nostrRepository.loadingBookmarks);

    late BookmarkListModel newBookmarkListModel;

    if (model is BookmarkOtherType) {
      // Handle tags and URLs
      final updatedList = model.isTag
          ? List<BookmarkOtherType>.from(bookmarkList.bookmarkedTags)
          : List<BookmarkOtherType>.from(bookmarkList.bookmarkedUrls);

      if (isBookmarkAvailable) {
        updatedList
            .removeWhere((b) => b.val == model.val && b.isTag == model.isTag);
      } else {
        updatedList.add(bookmarkOtherType);
      }

      newBookmarkListModel = bookmarkList.copyWith(
        bookmarkedTags: model.isTag ? updatedList : bookmarkList.bookmarkedTags,
        bookmarkedUrls:
            !model.isTag ? updatedList : bookmarkList.bookmarkedUrls,
      );
    } else if (isReplaceableEvent) {
      final updatedReplaceableEvents =
          List<EventCoordinates>.from(bookmarkList.bookmarkedReplaceableEvents);

      if (isBookmarkAvailable) {
        updatedReplaceableEvents
            .removeWhere((event) => event.identifier == identifier);
      } else {
        updatedReplaceableEvents.add(bookmarkEvent);
      }

      newBookmarkListModel = bookmarkList.copyWith(
        bookmarkedReplaceableEvents: updatedReplaceableEvents,
      );
    } else {
      final updatedEvents = List<String>.from(bookmarkList.bookmarkedEvents);

      if (isBookmarkAvailable) {
        updatedEvents.remove(identifier);
      } else {
        updatedEvents.add(identifier);
      }

      newBookmarkListModel = bookmarkList.copyWith(
        bookmarkedEvents: updatedEvents,
      );
    }

    final bookmarksEvent =
        await newBookmarkListModel.bookmarkListModelToEvent();

    if (bookmarksEvent == null) {
      BotToastUtils.showError('Error occured while adding the bookmark!');
      return;
    }

    lg.i(bookmarksEvent.toJson());
    final isSuccessful = await sendEvent(
      event: bookmarksEvent,
      relays: currentUserRelayList.urls.toList(),
      setProgress: false,
    );

    if (isSuccessful) {
      nostrRepository.bookmarksLists[bookmarkIdentifier] = newBookmarkListModel;
      nostrRepository.loadingBookmarks[bookmarkIdentifier]?.remove(identifier);
      nostrRepository.loadingBookmarksController
          .add(nostrRepository.loadingBookmarks);
      nostrRepository.bookmarksController.add(nostrRepository.bookmarksLists);

      if (!isBookmarkAvailable) {
        HttpFunctionsRepository.sendActionThroughEvent(bookmarksEvent);
      }
    }
  }

  static String getBookmarks({
    required BookmarkListModel bookmarksModel,
    required Function(List<dynamic>) contentFunc,
  }) {
    final filteredCurations = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) =>
              event.kind == EventKind.CURATION_ARTICLES ||
              event.kind == EventKind.CURATION_VIDEOS,
        )
        .toList();

    final filteredArticles = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) => event.kind == EventKind.LONG_FORM,
        )
        .toList();

    if (filteredArticles.isEmpty &&
        filteredCurations.isEmpty &&
        bookmarksModel.bookmarkedEvents.isEmpty) {
      return '';
    }

    final searchFilters = <Filter>[
      if (bookmarksModel.bookmarkedEvents.isNotEmpty)
        Filter(
          kinds: [
            EventKind.TEXT_NOTE,
            EventKind.VIDEO_HORIZONTAL,
            EventKind.VIDEO_VERTICAL
          ],
          ids: bookmarksModel.bookmarkedEvents,
        ),
      Filter(
        kinds: [EventKind.CURATION_ARTICLES, EventKind.CURATION_VIDEOS],
        d: filteredCurations.map((e) => e.identifier).toList(),
      ),
      Filter(
        kinds: [EventKind.LONG_FORM],
        d: filteredArticles.map((e) => e.identifier).toList(),
      ),
    ];

    final Map<String, DetailedNoteModel> notes = {};
    final Map<String, Curation> curations = {};
    final Map<String, Article> articles = {};
    final Map<String, VideoModel> videos = {};

    return nc.addSubscription(
      searchFilters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.TEXT_NOTE) {
          final note = DetailedNoteModel.fromEvent(event);

          if (notes[event.id] == null ||
              notes[event.id]!.createdAt.compareTo(note.createdAt) < 1) {
            notes[event.id] = note;
          }
        } else if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          final curation = Curation.fromEvent(
            event,
            relay,
          );

          if (curations[curation.identifier] == null ||
              curations[curation.identifier]!
                      .createdAt
                      .compareTo(curation.createdAt) <
                  1) {
            curations[curation.identifier] = curation;
          }
        } else if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(
            event,
          );

          if (articles[article.identifier] == null ||
              articles[article.identifier]!
                      .createdAt
                      .compareTo(article.createdAt) <
                  1) {
            articles[article.identifier] = article;
          }
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final video = VideoModel.fromEvent(
            event,
          );

          if (videos[video.id] == null ||
              videos[video.id]!.createdAt.compareTo(video.createdAt) < 1) {
            videos[video.id] = video;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        if (ok.status &&
            (notes.isNotEmpty ||
                curations.isNotEmpty ||
                articles.isNotEmpty ||
                videos.isNotEmpty)) {
          final List<dynamic> content = [
            ...notes.values,
            ...curations.values,
            ...articles.values,
            ...videos.values,
          ];

          content.sort(
            (a, b) {
              final aDate = a is DetailedNoteModel
                  ? a.createdAt
                  : a is Curation
                      ? a.createdAt
                      : a is VideoModel
                          ? a.createdAt
                          : (a as Article).createdAt;

              final bDate = b is DetailedNoteModel
                  ? b.createdAt
                  : b is Curation
                      ? b.createdAt
                      : b is VideoModel
                          ? b.createdAt
                          : (b as Article).createdAt;

              return aDate.compareTo(bDate);
            },
          );

          contentFunc.call(content);
        }

        nc.closeSubscription(requestId, relay);
      },
    );
  }

  // =============================================================================
  // BOOKMARKS FUNCTIONS
  // =============================================================================

  static Future<void> setSmartWidgetBookmark({
    required String identifier,
    required String pubkey,
  }) async {
    BookmarkListModel? bookmarkList =
        nostrRepository.bookmarksLists[smartWidgetSavedTools];

    bookmarkList ??= BookmarkListModel(
      id: '',
      title: 'Smart widget saved tools',
      description: '',
      image: '',
      identifier: smartWidgetSavedTools,
      bookmarkedReplaceableEvents: [],
      bookmarkedEvents: [],
      pubkey: pubkey,
      stringifiedEvent: '',
      createdAt: DateTime.now(),
      bookmarkedUrls: [],
      bookmarkedTags: [],
    );

    late EventCoordinates bookmarkEvent;

    final isBookmarkAvailable = bookmarkList.isReplaceableEventAvailable(
      identifier: identifier,
      isReplaceableEvent: true,
    );

    if (!isBookmarkAvailable) {
      bookmarkEvent = EventCoordinates(
        EventKind.SMART_WIDGET_ENH,
        pubkey,
        identifier,
        null,
      );
    }

    final bookmarksLoadingIdentifiers =
        nostrRepository.loadingBookmarks[smartWidgetSavedTools];

    if (bookmarksLoadingIdentifiers != null) {
      bookmarksLoadingIdentifiers.add(identifier);
    } else {
      nostrRepository.loadingBookmarks[smartWidgetSavedTools] = {identifier};
    }

    nostrRepository.loadingBookmarksController
        .add(nostrRepository.loadingBookmarks);

    late BookmarkListModel newBookmarkListModel;

    List<EventCoordinates> updatedReplaceableEvents = [];

    if (isBookmarkAvailable) {
      updatedReplaceableEvents = bookmarkList.bookmarkedReplaceableEvents
        ..removeWhere((event) => event.identifier == identifier);
    } else {
      updatedReplaceableEvents = bookmarkList.bookmarkedReplaceableEvents
        ..add(bookmarkEvent);
    }

    newBookmarkListModel = bookmarkList.copyWith(
      bookmarkedReplaceableEvents: updatedReplaceableEvents,
      image: bookmarkList.image,
    );

    final bookmarksEvent =
        await newBookmarkListModel.bookmarkListModelToEvent();

    if (bookmarksEvent == null) {
      BotToastUtils.showError(gc.t.errorAddingBookmark);
      return;
    }

    final isSuccessful = await sendEvent(
      event: bookmarksEvent,
      setProgress: true,
      relays: currentUserRelayList.urls.toList(),
    );

    if (isSuccessful) {
      nostrRepository.bookmarksLists[smartWidgetSavedTools] =
          newBookmarkListModel;
      nostrRepository.loadingBookmarks[smartWidgetSavedTools]
          ?.remove(identifier);
      nostrRepository.loadingBookmarksController
          .add(nostrRepository.loadingBookmarks);
      nostrRepository.bookmarksController.add(nostrRepository.bookmarksLists);

      if (!isBookmarkAvailable) {
        HttpFunctionsRepository.sendActionThroughEvent(bookmarksEvent);
      }
    } else {
      BotToastUtils.showError(gc.t.errorSendingEvent);
    }
  }

  static Future<List<SmartWidget>> getSmartWidgetBookmark({
    required BookmarkListModel bookmarksModel,
  }) async {
    final filteredSmartWidget = bookmarksModel.bookmarkedReplaceableEvents
        .where(
          (event) => event.kind == EventKind.SMART_WIDGET_ENH,
        )
        .toList();

    if (filteredSmartWidget.isEmpty) {
      return [];
    }

    final searchFilters = <Filter>[
      Filter(
        kinds: [EventKind.SMART_WIDGET_ENH],
        d: filteredSmartWidget.map((e) => e.identifier).toList(),
      ),
    ];

    final Map<String, SmartWidget> smartWidgets = {};

    await nc.doQuery(
      searchFilters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.SMART_WIDGET_ENH) {
          final sw = SmartWidget.fromEvent(
            event,
          );

          if (smartWidgets[sw.identifier] == null ||
              smartWidgets[sw.identifier]!.createdAt.compareTo(sw.createdAt) <
                  1) {
            smartWidgets[sw.identifier] = sw;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        nc.closeSubscription(requestId, relay);
      },
    );

    final content = smartWidgets.values.toList();

    content.sort(
      (a, b) {
        return a.createdAt.compareTo(b.createdAt);
      },
    );

    return content;
  }

  // * get user stats /
  static void getUserFollowers({
    required String pubkey,
    required Function(Set<String>) onFollowers,
    required Function(Set<String>) onDone,
  }) {
    final Set<String> followers = {};
    List<String> currentUncompletedRelays = nc.activeRelays();

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.CONTACT_LIST],
          p: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) async {
        if (event.kind == EventKind.CONTACT_LIST && event.pubkey != pubkey) {
          if (!followers.contains(event.pubkey)) {
            followers.add(event.pubkey);
          }
        }
      },
      eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(authorRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          timer.cancel();
          onDone.call(followers);
        } else {
          onFollowers.call(followers);
        }
      },
    );
  }

  // static Future<String> getUserProfile({
  //   required String authorPubkey,
  //   required Function(Set<String>) relaysFunc,
  //   required Function(List<Article>) articleFunc,
  //   required Function(List<VideoModel>) videosFunc,
  //   required Function(List<Event>) notesFunc,
  //   required Function(List<Event>) repliesFunc,
  //   required Function(List<Curation>) curationsFunc,
  //   required Function(List<SmartWidget>) smartWidgetFunc,
  //   required Function(List<DetailedNoteModel>) mentionsFunc,
  //   required Function(List<PictureModel>) picturesFunc,
  //   required Function() onDone,
  //   required ProfileData profileData,
  //   int? until,
  // }) async {
  //   List<String> currentUncompletedRelays = nc.activeRelays();

  //   Set<String> relays = {};
  //   final DateTime kind10002Date = DateTime(2000);
  //   final Map<String, Article> articlesToBeEmitted = {};
  //   final Map<String, VideoModel> videosToBeEmitted = {};
  //   final Map<String, Event> notesToBeEmitted = {};
  //   final Map<String, Event> repliesToBeEmitted = {};
  //   final Map<String, Curation> curationsToBeEmitted = {};
  //   final Map<String, SmartWidget> smartWidgetsToBeEmitted = {};
  //   final Map<String, DetailedNoteModel> mentionsToBeEmitted = {};
  //   final Map<String, PictureModel> picturesToBeEmitted = {};

  //   Timer.periodic(
  //     const Duration(milliseconds: 500),
  //     (timer) {
  //       if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
  //         onDone.call();
  //         timer.cancel();
  //       }
  //     },
  //   );

  //   return nc.doSubscribe(
  //     [
  //       if (profileData == ProfileData.all || profileData == ProfileData.other)
  //         Filter(
  //           kinds: [EventKind.CONTACT_LIST, EventKind.RELAY_LIST_METADATA],
  //           authors: [authorPubkey],
  //         ),
  //       if (profileData == ProfileData.all ||
  //           profileData == ProfileData.articles)
  //         Filter(
  //           kinds: [EventKind.LONG_FORM],
  //           authors: [authorPubkey],
  //           until: until,
  //           limit: 30,
  //         ),
  //       if (profileData == ProfileData.all ||
  //           profileData == ProfileData.curations)
  //         Filter(
  //           kinds: [
  //             EventKind.CURATION_ARTICLES,
  //             EventKind.CURATION_VIDEOS,
  //           ],
  //           authors: [authorPubkey],
  //           until: until,
  //           limit: 30,
  //         ),
  //       if (profileData == ProfileData.all ||
  //           profileData == ProfileData.smartWidgets)
  //         Filter(
  //           kinds: [EventKind.SMART_WIDGET_ENH],
  //           authors: [authorPubkey],
  //           until: until,
  //           limit: 30,
  //         ),
  //       if (profileData == ProfileData.all || profileData == ProfileData.videos)
  //         Filter(
  //           kinds: [
  //             EventKind.VIDEO_HORIZONTAL,
  //             EventKind.VIDEO_VERTICAL,
  //             EventKind.LEGACY_VIDEO_HORIZONTAL,
  //             EventKind.LEGACY_VIDEO_VERTICAL,
  //           ],
  //           authors: [authorPubkey],
  //           until: until,
  //           limit: 30,
  //         ),
  //       if (profileData == ProfileData.all ||
  //           profileData == ProfileData.pictures)
  //         Filter(
  //           kinds: [EventKind.PICTURE],
  //           authors: [authorPubkey],
  //           until: until,
  //           limit: 30,
  //         ),
  //       if (profileData == ProfileData.all || profileData == ProfileData.notes)
  //         Filter(
  //           kinds: [EventKind.TEXT_NOTE, EventKind.REPOST],
  //           authors: [authorPubkey],
  //           limit: 20,
  //           until: until,
  //         ),
  //       if (profileData == ProfileData.all ||
  //           profileData == ProfileData.mentions)
  //         Filter(
  //           kinds: [EventKind.TEXT_NOTE],
  //           p: [authorPubkey],
  //           limit: 20,
  //           until: until,
  //         ),
  //     ],
  //     [],
  //     source: EventsSource.all,
  //     eventCallBack: (event, relay) async {
  //       if ((VideoModel.isVideo(event.kind)) && event.pubkey == authorPubkey) {
  //         final video = VideoModel.fromEvent(event);

  //         if (video.url.isNotEmpty) {
  //           final old = videosToBeEmitted[video.id];

  //           if (old == null || old.createdAt.compareTo(video.createdAt) < 1) {
  //             videosToBeEmitted[video.id] = video;
  //             videosFunc.call(videosToBeEmitted.values.toList());
  //           }
  //         }
  //       } else if (Curation.isCuration(event.kind) &&
  //           event.pubkey == authorPubkey) {
  //         final curation = Curation.fromEvent(event, relay);

  //         final oldCuration = curationsToBeEmitted[curation.identifier];

  //         curationsToBeEmitted[curation.identifier] = filterCuration(
  //           oldCuration: oldCuration,
  //           newCuration: curation,
  //         );

  //         curationsFunc.call(curationsToBeEmitted.values.toList());
  //       } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
  //         final eventDate =
  //             DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

  //         if (kind10002Date.compareTo(eventDate) < 1) {
  //           final set = UserRelayList.fromNip65(Nip65.fromEvent(event));
  //           nc.db.saveUserRelayList(set);
  //           relays = set.urls.toSet();
  //           relaysFunc.call(relays);
  //         }
  //       } else if (event.kind == EventKind.LONG_FORM) {
  //         final article = Article.fromEvent(event);
  //         final oldArticle = articlesToBeEmitted[article.identifier];

  //         if (oldArticle == null ||
  //             article.createdAt.isAfter(oldArticle.createdAt)) {
  //           articlesToBeEmitted[article.identifier] = article;
  //           final sortedArticles = articlesToBeEmitted.values.toList()
  //             ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //           articleFunc.call(sortedArticles);
  //         }
  //       } else if (event.kind == EventKind.SMART_WIDGET_ENH) {
  //         final widget = SmartWidget.fromEvent(event);
  //         final oldWidget = smartWidgetsToBeEmitted[widget.identifier];

  //         if (oldWidget == null ||
  //             widget.createdAt.isAfter(oldWidget.createdAt)) {
  //           smartWidgetsToBeEmitted[widget.identifier] = widget;
  //           final sortedWidgets = smartWidgetsToBeEmitted.values.toList()
  //             ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //           smartWidgetFunc.call(sortedWidgets);
  //         }
  //       } else if (event.kind == EventKind.TEXT_NOTE) {
  //         if (event.pubkey == authorPubkey) {
  //           if (event.root == null) {
  //             if (notesToBeEmitted[event.id] == null ||
  //                 event.createdAt > notesToBeEmitted[event.id]!.createdAt) {
  //               notesToBeEmitted[event.id] = event;
  //               final sortedNotes = notesToBeEmitted.values.toList()
  //                 ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //               notesFunc.call(sortedNotes);
  //             }
  //           } else {
  //             if (repliesToBeEmitted[event.id] == null ||
  //                 event.createdAt > repliesToBeEmitted[event.id]!.createdAt) {
  //               repliesToBeEmitted[event.id] = event;
  //               final sortedNotes = repliesToBeEmitted.values.toList()
  //                 ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //               repliesFunc.call(sortedNotes);
  //             }
  //           }
  //         } else {
  //           final hasMentionVal =
  //               hasMention(content: event.content, pubkey: authorPubkey);

  //           if (hasMentionVal &&
  //               (mentionsToBeEmitted[event.id] == null ||
  //                   event.createdAt >
  //                       mentionsToBeEmitted[event.id]!
  //                           .createdAt
  //                           .toSecondsSinceEpoch())) {
  //             mentionsToBeEmitted[event.id] =
  //                 DetailedNoteModel.fromEvent(event);
  //             final sortedMentions = mentionsToBeEmitted.values.toList()
  //               ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //             mentionsFunc.call(sortedMentions);
  //           }
  //         }
  //       } else if (event.kind == EventKind.PICTURE) {
  //         if (picturesToBeEmitted[event.id] == null) {
  //           picturesToBeEmitted[event.id] = PictureModel.fromEvent(event);
  //           final sortedPictures = picturesToBeEmitted.values.toList()
  //             ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //           picturesFunc.call(sortedPictures);
  //         }
  //       } else if (event.kind == EventKind.REPOST) {
  //         if (notesToBeEmitted[event.id] == null) {
  //           notesToBeEmitted[event.id] = event;
  //           final sortedNotes = notesToBeEmitted.values.toList()
  //             ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  //           notesFunc.call(sortedNotes);
  //         }
  //       }
  //     },
  //     eoseCallBack: (authorRequestId, ok, relay, unCompletedRelays) {
  //       currentUncompletedRelays = unCompletedRelays;
  //       nc.closeSubscription(authorRequestId, relay);
  //     },
  //   );
  // }

  // =============================================================================
  // ZAPS FUNCTIONS
  // =============================================================================

  static void sendZapsToPoints({
    required List<ZapsToPoints> zapsToPointsList,
    String? id,
  }) {
    if (id != null) {
      nc.closeRequests([id]);
    }

    final List<String> receivedZaps = [];

    final filters = zapsToPointsList.map((e) {
      return Filter(
        p: [e.pubkey],
        since: e.actionTimeStamp,
        e: e.eventId != null ? [e.eventId!] : null,
        kinds: [EventKind.ZAP],
      );
    }).toList();

    id = nc.addSubscription(
      filters,
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.ZAP) {
          if (!receivedZaps.contains(event.id)) {
            receivedZaps.add(event.id);

            String pTag = '';
            String eventId = '';

            for (final tag in event.tags) {
              if (tag.first == 'p' && tag.length > 1 && pTag.isEmpty) {
                pTag = tag[1];
              }

              if (tag.first == 'e' && tag.length > 1) {
                eventId = tag[1];
              }
            }

            final index = zapsToPointsList.indexWhere(
              (element) =>
                  element.pubkey == pTag &&
                  (eventId.isEmpty || element.eventId == eventId),
            );

            if (index != -1) {
              final sats = getZapValue(event);

              if (sats != 0) {
                zapsToPointsList.removeAt(index);
                pointsManagementCubit.sendZapsPoints(sats);
              } else {
                zapsToPointsList.removeAt(index);
              }
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {},
    );
  }

// * connect to relay /
  static Future<bool> connectToRelay(String relay) async {
    try {
      final r = {
        ...currentUserRelayList.relays,
      };

      r[relay] = ReadWriteMarker.readWrite;

      final userRelaySet = await nc.setNip65Relays(
        r,
        currentUserRelayList.urls.toList(),
        currentSigner!,
        (ok, relay, unCompletedRelays) {},
      );

      if (userRelaySet != null) {
        currentUserRelayList = userRelaySet;
        nc.connectNonConnectedRelays(userRelaySet.urls.toSet());
        return true;
      } else {
        BotToastUtils.showError("Couldn't update relays' list.");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // * get events stats /

  static Stream<dynamic> getStats({
    required bool isEtag,
    required int eventKind,
    String? eventPubkey,
    List<int>? selectedKinds,
    List<String>? eventIds,
    String? identifier,
    bool? getViews,
  }) {
    final controller = StreamController<dynamic>();
    final Map<String, DetailedNoteModel> replies = {};
    final Map<String, double> zaps = {};
    final List<String> zapsEventIds = [];
    final Map<String, Map<String, VoteModel>> votes = {};
    final Set<String> reports = {};
    final List<String> views = [];
    EventCoordinates? identifierTag;
    List<String> currentUncompletedRelays = nc.activeRelays();

    if (!isEtag) {
      identifierTag = EventCoordinates(
        eventKind,
        eventPubkey!,
        identifier!,
        null,
      );
    }

    final aTag = !isEtag ? [identifierTag.toString()] : null;

    final filters = [
      if (selectedKinds == null || selectedKinds.contains(EventKind.TEXT_NOTE))
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          e: !isEtag ? null : eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.REACTION))
        Filter(
          kinds: [EventKind.REACTION],
          e: eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.REPORTING))
        Filter(
          kinds: [EventKind.REPORTING],
          e: eventIds,
          a: aTag,
        ),
      if (selectedKinds == null || selectedKinds.contains(EventKind.ZAP))
        Filter(
          kinds: [EventKind.ZAP],
          p: eventPubkey == null ? null : [eventPubkey],
          e: eventIds,
          a: aTag,
        ),
      if (getViews != null)
        Filter(
          a: aTag,
          d: aTag,
          kinds: [
            EventKind.VIDEO_VIEW,
          ],
        )
    ];

    nc.addSubscription(
      filters,
      [],
      eventCallBack: (ev, relay) {
        bool canBeAdded = false;

        if (isEtag) {
          for (final t in ev.tags) {
            if (t[0] == 'e' && t[1] == identifier) {
              canBeAdded = true;
            }
          }
        } else {
          for (final t in ev.tags) {
            if (t[0] == 'a' && t[1] == aTag!.first) {
              canBeAdded = true;
            }
          }
        }

        if (canBeAdded) {
          final event = ExtendedEvent.fromEv(ev);

          if (event.kind == EventKind.TEXT_NOTE) {
            if ((isEtag && !event.isUncensoredNote()) || !isEtag) {
              final reply = DetailedNoteModel.fromEvent(event);

              replies[reply.id] = reply;
              controller.add(replies);
            }
          } else if (event.kind == EventKind.ZAP) {
            filterZaps(
              zapsEventIds: zapsEventIds,
              zaps: zaps,
              event: event,
              isEtag: isEtag,
              identifier: identifierTag?.identifier,
              controller: controller,
            );
          } else if (event.kind == EventKind.REACTION) {
            filterVotes(
              votes: votes,
              event: event,
              isEtag: isEtag,
              identifier: identifierTag.toString(),
              controller: controller,
            );
          } else if (event.kind == EventKind.REPORTING) {
            filterReports(
              report: event.pubkey,
              reports: reports,
              controller: controller,
            );
          } else if (event.kind == EventKind.VIDEO_VIEW) {
            if (!views.contains(event.pubkey)) {
              views.add(event.pubkey);
              controller.add(views);
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<Metadata> getUserMetaData({
    required String pubkey,
  }) {
    final controller = StreamController<Metadata>();
    List<String> currentUncompletedRelays = nc.activeRelays();

    int authorCreatedAt = 0;

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.METADATA],
          authors: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.METADATA) {
          final author = Metadata.fromMap(
            jsonDecode(event.content),
            pubkey: event.pubkey,
            createdAt: event.createdAt,
            tags: event.tags,
          );

          if (authorCreatedAt.compareTo(author.createdAt) < 1) {
            authorCreatedAt = author.createdAt;
            controller.add(author);
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Future<void> setCustomTopics(String topic) async {
    final cancel = BotToastUtils.showLoading();

    final List<String> currentTopics =
        List<String>.from(nostrRepository.userTopics);

    if (currentTopics.contains(topic.trim())) {
      currentTopics.remove(topic.trim());
    } else {
      currentTopics.add(topic);
    }

    final event = await Event.genEvent(
      kind: EventKind.APP_CUSTOM,
      tags: [
        ['d', yakihonneTopicTag],
        ...currentTopics.map((e) => ['t', e]),
      ],
      content: '',
      signer: currentSigner,
    );

    if (event == null) {
      cancel.call();
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: currentUserRelayList.writes,
      setProgress: true,
    );

    if (isSuccessful) {
      nostrRepository.setTopics(currentTopics);
      BotToastUtils.showSuccess('Your topics have been updated');
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    cancel.call();
  }

  // * get home page data /

  static Future<List<BaseEventModel>> buildSingleRelayFeed({
    required RelayContentType type,
    required String relay,
    int? limit,
    int? until,
  }) async {
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, VideoModel> videosToBeEmitted = {};
    final Map<String, Curation> curationsToBeEmitted = {};
    final Map<String, DetailedNoteModel> notesToBeEmitted = {};

    final filters = <Filter>[];

    if (type == RelayContentType.notes) {
      final f1 = Filter(
        kinds: [
          EventKind.TEXT_NOTE,
        ],
        until: until,
        limit: limit,
      );
      filters.add(f1);
    }

    if (type == RelayContentType.articles) {
      final f2 = Filter(
        kinds: [
          EventKind.LONG_FORM,
        ],
        until: until,
        limit: limit,
      );
      filters.add(f2);
    }

    if (type == RelayContentType.media) {
      final f3 = Filter(
        kinds: [
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
          EventKind.LEGACY_VIDEO_HORIZONTAL,
          EventKind.LEGACY_VIDEO_VERTICAL,
          EventKind.PICTURE,
        ],
        until: until,
        limit: limit,
      );
      filters.add(f3);
    }

    if (type == RelayContentType.curations) {
      final f4 = Filter(
        kinds: [
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
        until: until,
        limit: limit,
      );
      filters.add(f4);
    }

    try {
      await nc.doQuery(
        filters,
        [relay],
        timeOut: 1,
        eventCallBack: (event, relay) {
          if (!isUserMuted(event.pubkey)) {
            if (event.kind == EventKind.LONG_FORM) {
              final article = Article.fromEvent(
                event,
                relay: relay,
              );

              if (article.title.isNotEmpty) {
                final oldArticle = articlesToBeEmitted[article.identifier];

                articlesToBeEmitted[article.identifier] = filterArticle(
                  oldArticle: oldArticle,
                  newArticle: article,
                );
              }
            } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
                event.kind == EventKind.VIDEO_VERTICAL) {
              final video = VideoModel.fromEvent(
                event,
                relay: relay,
              );

              if (video.title.isNotEmpty) {
                final oldVideo = videosToBeEmitted[video.id];
                if (oldVideo == null ||
                    oldVideo.createdAt.isBefore(video.createdAt)) {
                  videosToBeEmitted[video.id] = video;
                }
              }
            } else if (event.kind == EventKind.CURATION_ARTICLES ||
                event.kind == EventKind.CURATION_VIDEOS) {
              final curation = Curation.fromEvent(
                event,
                relay,
              );

              final oldCuration = curationsToBeEmitted[curation.identifier];
              if (oldCuration == null ||
                  oldCuration.createdAt.isBefore(curation.createdAt)) {
                curationsToBeEmitted[curation.identifier] = curation;
              }
            } else if (event.kind == EventKind.TEXT_NOTE) {
              final note = DetailedNoteModel.fromEvent(event);

              final oldCuration = curationsToBeEmitted[note.id];
              if (oldCuration == null) {
                notesToBeEmitted[note.id] = note;
              }
            }
          }
        },
      );
    } catch (e) {
      lg.i(e);
    }

    final media = <BaseEventModel>[
      ...articlesToBeEmitted.values,
      ...videosToBeEmitted.values,
      ...curationsToBeEmitted.values,
      ...notesToBeEmitted.values,
    ];

    media.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return media;
  }

  static Future<List<Event>> buildLeadingRelaysFeed({
    required CommonFeedTypes? type,
    NostrCore? core,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    int? since,
  }) async {
    final eventsToBeEmitted = <String, Event>{};
    final fallBackEventToBeEmitted = <String, Event>{};
    final removeReplies = type == CommonFeedTypes.recent;

    final l = type != null
        ? type == CommonFeedTypes.paid
            ? [FN_SEARCH_VALUE]
            : type == CommonFeedTypes.widgets
                ? ['smart-widget']
                : null
        : null;

    final f1 = Filter(
      kinds: [
        EventKind.TEXT_NOTE,
        if (type == CommonFeedTypes.recent ||
            type == CommonFeedTypes.recentWithReplies)
          EventKind.REPOST
      ],
      authors: pubkeys,
      t: tags,
      l: l,
      until: until,
      since: since,
      limit: limit,
    );

    void setEvents(Map<String, Event> events, Event event) {
      bool isMuted = isUserMuted(event.pubkey);

      if (isMuted) {
        return;
      }

      if (event.kind == EventKind.REPOST) {
        try {
          final ev = Event.fromJson(jsonDecode(event.content));
          isMuted = isUserMuted(ev.pubkey);
        } catch (_) {}
      }

      if (isMuted) {
        return;
      }

      if (event.kind == EventKind.TEXT_NOTE && events[event.id] == null) {
        if (removeReplies) {
          if (event.root == null) {
            events[event.id] = event;
          }
        } else {
          if (l != null && l.isNotEmpty) {
            bool canBeAdded = false;

            for (final t in event.tags) {
              if (t.length >= 2 && t[0] == 'l' && t[1] == l.first) {
                canBeAdded = true;
              }
            }

            if (canBeAdded) {
              events[event.id] = event;
            }
          } else {
            events[event.id] = event;
          }
        }
      } else if (event.kind == EventKind.REPOST && events[event.id] == null) {
        events[event.id] = event;
      }
    }

    final f = feedRelaySet?.urls.toList();
    final relays = core != null
        ? core.relays()
        : f != null && f.isNotEmpty
            ? f
            : DEFAULT_BOOTSTRAP_RELAYS;

    try {
      await (core ?? nc).doQuery(
        [f1],
        relays,
        timeOut: 1,
        source: EventsSource.all,
        eventCallBack: (ev, relay) {
          setEvents(fallBackEventToBeEmitted, ev);
        },
      );
    } catch (e, stack) {
      lg.i(stack);
    }

    List<Event> events = [];
    if (eventsToBeEmitted.isNotEmpty) {
      events = eventsToBeEmitted.values.toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      events = fallBackEventToBeEmitted.values.toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return events;
  }

  static Future<List<Event>> buildMediaFeed({
    NostrCore? core,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    int? since,
  }) async {
    final eventsToBeEmitted = <String, Event>{};
    final fallBackEventToBeEmitted = <String, Event>{};

    final f1 = Filter(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
        EventKind.VIDEO_VERTICAL,
        EventKind.LEGACY_VIDEO_HORIZONTAL,
        EventKind.LEGACY_VIDEO_VERTICAL,
        EventKind.PICTURE,
      ],
      authors: pubkeys,
      t: tags,
      until: until,
      since: since,
      limit: limit,
    );

    void setEvents(Map<String, Event> events, Event event) {
      final isMuted = isUserMuted(event.pubkey);

      if (isMuted) {
        return;
      }

      events[event.id] = event;
    }

    final f = feedRelaySet?.urls.toList();
    final relays = core != null
        ? core.relays()
        : f != null && f.isNotEmpty
            ? f
            : DEFAULT_BOOTSTRAP_RELAYS;

    try {
      await (core ?? nc).doQuery(
        [f1],
        relays,
        timeOut: 1,
        source: EventsSource.all,
        eventCallBack: (ev, relay) {
          setEvents(fallBackEventToBeEmitted, ev);
        },
      );
    } catch (e, stack) {
      lg.i(stack);
    }

    List<Event> events = [];
    if (eventsToBeEmitted.isNotEmpty) {
      events = eventsToBeEmitted.values.toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      events = fallBackEventToBeEmitted.values.toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return events;
  }

  static Future<List<BaseEventModel>> buildLeadingMedia({
    required bool includeVideos,
    List<String>? tags,
    int? limit,
    int? until,
  }) async {
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, VideoModel> videosToBeEmitted = {};
    nostrRepository.getTopics();

    try {
      await nc.doQuery(
        [
          Filter(
            kinds: [EventKind.LONG_FORM],
            limit: limit,
            t: tags,
          ),
          if (includeVideos) ...[
            Filter(
              kinds: [
                EventKind.VIDEO_HORIZONTAL,
                EventKind.VIDEO_VERTICAL,
              ],
              limit: limit,
              t: tags,
            ),
          ],
        ],
        [],
        timeOut: 1,
        eventCallBack: (event, relay) {
          if (!isUserMuted(event.pubkey)) {
            if (event.kind == EventKind.LONG_FORM) {
              final article = Article.fromEvent(
                event,
                relay: relay,
              );

              if (article.title.isNotEmpty) {
                final oldArticle = articlesToBeEmitted[article.identifier];

                articlesToBeEmitted[article.identifier] = filterArticle(
                  oldArticle: oldArticle,
                  newArticle: article,
                );
              }
            } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
                event.kind == EventKind.VIDEO_VERTICAL) {
              final video = VideoModel.fromEvent(
                event,
                relay: relay,
              );

              if (video.title.isNotEmpty) {
                final oldVideo = videosToBeEmitted[video.id];
                if (oldVideo == null ||
                    oldVideo.createdAt.isBefore(video.createdAt)) {
                  videosToBeEmitted[video.id] = video;
                }
              }
            }
          }
        },
      );
    } catch (e) {
      lg.i(e);
    }

    final media = <BaseEventModel>[
      ...articlesToBeEmitted.values,
      if (includeVideos) ...videosToBeEmitted.values,
    ];

    media.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return media;
  }

  static Future<List<BaseEventModel>> buildExploreFeed({
    required ExploreType exploreType,
    NostrCore? core,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    int? since,
  }) async {
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, VideoModel> videosToBeEmitted = {};
    final Map<String, Curation> curationsToBeEmitted = {};

    Filter? f1;
    Filter? f2;
    Filter? f3;

    final filteredTags = tags?.toSet();

    if (exploreType == ExploreType.all || exploreType == ExploreType.articles) {
      f1 = Filter(
        kinds: [
          EventKind.LONG_FORM,
        ],
        authors: pubkeys != null && pubkeys.isNotEmpty ? pubkeys : null,
        until: until,
        since: since,
        limit: limit,
        t: filteredTags?.toList(),
      );
    }

    if (exploreType == ExploreType.all || exploreType == ExploreType.videos) {
      f2 = Filter(
        kinds: [
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
        ],
        authors: pubkeys != null && pubkeys.isNotEmpty ? pubkeys : null,
        until: until,
        since: since,
        limit: limit,
        t: filteredTags?.toList(),
      );
    }

    if (exploreType == ExploreType.all ||
        exploreType == ExploreType.curations) {
      f3 = Filter(
        kinds: [
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
        authors: pubkeys != null && pubkeys.isNotEmpty ? pubkeys : null,
        until: until,
        since: since,
        limit: limit,
        t: filteredTags?.toList(),
      );
    }

    try {
      final f = feedRelaySet?.urls.toList();

      await (core ?? nc).doQuery(
        [
          if (f1 != null) f1,
          if (f2 != null) f2,
          if (f3 != null) f3,
        ],
        core != null
            ? core.relays()
            : f != null && f.isNotEmpty
                ? f
                : DEFAULT_BOOTSTRAP_RELAYS,
        eventCallBack: (ev, relay) {
          if (!isUserMuted(ev.pubkey)) {
            if (ev.kind == EventKind.LONG_FORM) {
              final article = Article.fromEvent(
                ev,
                relay: relay,
              );

              if (article.title.isNotEmpty) {
                final oldArticle = articlesToBeEmitted[article.identifier];

                articlesToBeEmitted[article.identifier] = filterArticle(
                  oldArticle: oldArticle,
                  newArticle: article,
                );
              }
            } else if (ev.kind == EventKind.CURATION_ARTICLES ||
                ev.kind == EventKind.CURATION_VIDEOS) {
              final newCuration = Curation.fromEvent(
                ev,
                relay,
              );

              if (newCuration.title.isNotEmpty &&
                  newCuration.eventsIds.isNotEmpty) {
                final oldArticle = curationsToBeEmitted[newCuration.identifier];

                curationsToBeEmitted[newCuration.identifier] = filterCuration(
                  oldCuration: oldArticle,
                  newCuration: newCuration,
                );
              }
            } else if (ev.kind == EventKind.VIDEO_HORIZONTAL ||
                ev.kind == EventKind.VIDEO_VERTICAL) {
              final video = VideoModel.fromEvent(
                ev,
                relay: relay,
              );

              if (video.title.isNotEmpty) {
                final oldVideo = videosToBeEmitted[video.id];
                if (oldVideo == null ||
                    oldVideo.createdAt.isBefore(video.createdAt)) {
                  videosToBeEmitted[video.id] = video;
                }
              }
            }
          }
        },
      );
    } catch (e) {
      lg.i(e);
    }

    final articles = orderedList(articlesToBeEmitted.values.toList());
    final videos = orderedList(videosToBeEmitted.values.toList());
    final curations = orderedList(curationsToBeEmitted.values.toList());

    List<BaseEventModel> selectedArticles = List<BaseEventModel>.from(articles);
    List<BaseEventModel> selectedCurations =
        List<BaseEventModel>.from(curations);
    List<BaseEventModel> selectedVideos = List<BaseEventModel>.from(videos);

    if (articles.isNotEmpty || videos.isNotEmpty || curations.isNotEmpty) {
      selectedArticles = articles;
      selectedCurations = curations;
      selectedVideos = videos;
    }

    final length = [
      selectedArticles.length,
      selectedVideos.length,
      selectedCurations.length,
    ].reduce(max);

    final List<BaseEventModel> list = [];

    for (int i = 0; i < length; i++) {
      if (selectedArticles.isNotEmpty) {
        list.add(selectedArticles.removeAt(0));
      }

      if (selectedVideos.isNotEmpty) {
        list.add(selectedVideos.removeAt(0));
      }

      if (selectedCurations.isNotEmpty) {
        list.add(selectedCurations.removeAt(0));
      }
    }

    return list;
  }

  static Future<List<BaseEventModel>> buildExploreFeedFromGeneric({
    required ExploreType exploreType,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    int? since,
  }) async {
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, VideoModel> videosToBeEmitted = {};
    final Map<String, Curation> curationsToBeEmitted = {};
    final Map<String, Event> eventsToBeEmitted = {};

    Filter? f1;
    Filter? f2;
    Filter? f3;

    if (exploreType == ExploreType.all || exploreType == ExploreType.articles) {
      f1 = Filter(
        k: [
          EventKind.LONG_FORM.toString(),
        ],
        kinds: [
          EventKind.GENERIC_REPOST,
        ],
        authors: pubkeys,
        until: until,
        since: since,
        limit: limit,
      );
    }

    if (exploreType == ExploreType.all || exploreType == ExploreType.videos) {
      f2 = Filter(
        k: [
          EventKind.VIDEO_HORIZONTAL.toString(),
          EventKind.VIDEO_VERTICAL.toString(),
        ],
        kinds: [
          EventKind.GENERIC_REPOST,
        ],
        authors: pubkeys,
        until: until,
        since: since,
        limit: limit,
      );
    }

    if (exploreType == ExploreType.all ||
        exploreType == ExploreType.curations) {
      f3 = Filter(
        k: [
          EventKind.CURATION_ARTICLES.toString(),
          EventKind.CURATION_VIDEOS.toString(),
        ],
        kinds: [
          EventKind.GENERIC_REPOST,
        ],
        authors: pubkeys,
        until: until,
        since: since,
        limit: limit,
      );
    }

    void setEvent(Event event, String? relay) {
      if (!isUserMuted(event.pubkey)) {
        eventsToBeEmitted[event.id] = event;

        if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(
            event,
            relay: relay,
          );

          if (article.title.isNotEmpty) {
            final oldArticle = articlesToBeEmitted[article.identifier];

            articlesToBeEmitted[article.identifier] = filterArticle(
              oldArticle: oldArticle,
              newArticle: article,
            );
          }
        } else if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          final newCuration = Curation.fromEvent(
            event,
            relay ?? '',
          );

          if (newCuration.title.isNotEmpty &&
              newCuration.eventsIds.isNotEmpty) {
            final oldArticle = curationsToBeEmitted[newCuration.identifier];

            curationsToBeEmitted[newCuration.identifier] = filterCuration(
              oldCuration: oldArticle,
              newCuration: newCuration,
            );
          }
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          final video = VideoModel.fromEvent(
            event,
            relay: relay,
          );

          if (video.title.isNotEmpty) {
            final oldVideo = videosToBeEmitted[video.id];
            if (oldVideo == null ||
                oldVideo.createdAt.isBefore(video.createdAt)) {
              videosToBeEmitted[video.id] = video;
            }
          }
        }
      }
    }

    final toBeSearched = <String>{};

    try {
      final f = feedRelaySet?.urls.toList();

      await nc.doQuery(
        [
          if (f1 != null) f1,
          if (f2 != null) f2,
          if (f3 != null) f3,
        ],
        f != null && f.isNotEmpty ? f : DEFAULT_BOOTSTRAP_RELAYS,
        timeOut: 1,
        eventCallBack: (ev, relay) {
          try {
            if (ev.content.isNotEmpty && ev.kind == EventKind.GENERIC_REPOST) {
              if (ev.content.isNotEmpty) {
                final event = Event.fromJson(jsonDecode(ev.content));
                setEvent(event, relay);
              } else {
                for (final tag in ev.aTags) {
                  if (tag.startsWith('${EventKind.LONG_FORM}') ||
                      tag.startsWith('${EventKind.CURATION_ARTICLES}') ||
                      tag.startsWith('${EventKind.CURATION_VIDEOS}') ||
                      tag.startsWith('${EventKind.VIDEO_HORIZONTAL}') ||
                      tag.startsWith('${EventKind.VIDEO_VERTICAL}')) {
                    toBeSearched.add(tag);
                  }
                }
              }
            }
          } catch (e) {
            return;
          }
        },
      );
    } catch (e) {
      lg.i(e);
    }

    if (toBeSearched.isNotEmpty) {
      final kinds = <int>[
        if (exploreType == ExploreType.all ||
            exploreType == ExploreType.articles)
          EventKind.LONG_FORM,
        if (exploreType == ExploreType.all ||
            exploreType == ExploreType.curations)
          EventKind.CURATION_ARTICLES,
        if (exploreType == ExploreType.all ||
            exploreType == ExploreType.curations)
          EventKind.CURATION_VIDEOS,
        if (exploreType == ExploreType.all || exploreType == ExploreType.videos)
          EventKind.VIDEO_HORIZONTAL,
        if (exploreType == ExploreType.all || exploreType == ExploreType.videos)
          EventKind.VIDEO_VERTICAL,
      ];

      final events = await getEventsAsync(
        dTags: [
          ...toBeSearched.map((e) => e.split(':')[2]),
        ],
        kinds: kinds,
      );

      for (final event in events) {
        setEvent(event, null);
      }
    }

    if (eventsToBeEmitted.isNotEmpty) {
      nc.db.saveEvents(eventsToBeEmitted.values.toList());
    }

    final articles = orderedList(articlesToBeEmitted.values.toList());
    final videos = orderedList(videosToBeEmitted.values.toList());
    final curations = orderedList(curationsToBeEmitted.values.toList());

    List<BaseEventModel> selectedArticles = List<BaseEventModel>.from(articles);
    List<BaseEventModel> selectedCurations =
        List<BaseEventModel>.from(curations);
    List<BaseEventModel> selectedVideos = List<BaseEventModel>.from(videos);

    if (articles.isNotEmpty || videos.isNotEmpty || curations.isNotEmpty) {
      selectedArticles = articles;
      selectedCurations = curations;
      selectedVideos = videos;
    }

    final length = [
      selectedArticles.length,
      selectedVideos.length,
      selectedCurations.length,
    ].reduce(max);

    final List<BaseEventModel> list = [];

    for (int i = 0; i < length; i++) {
      if (selectedArticles.isNotEmpty) {
        list.add(selectedArticles.removeAt(0));
      }

      if (selectedVideos.isNotEmpty) {
        list.add(selectedVideos.removeAt(0));
      }

      if (selectedCurations.isNotEmpty) {
        list.add(selectedCurations.removeAt(0));
      }
    }

    return list;
  }

  static Future<List<BaseEventModel>> getDiscoverDvmData({
    required String pubkey,
  }) async {
    final list = <BaseEventModel>[];
    final completer = Completer<List<BaseEventModel>>();

    final event = await Event.genEvent(
      kind: EventKind.DVM_CONTENT_FEED,
      tags: [
        ['p', pubkey],
      ],
      content: '',
      signer: actionsSigner,
    );

    if (event == null) {
      return list;
    }

    final f1 = Filter(
      kinds: [EventKind.DVM_CONTENT_FEED_RESPONSE],
      authors: [pubkey],
      p: [actionsSigner.getPublicKey()],
    );

    sendEvent(event: event, setProgress: false);

    final l = await getDvmResponse(f1);

    if (l.isNotEmpty) {
      final events = await getEventsAsync(
        ids: l,
      );

      for (final e in events) {
        if (e.kind == EventKind.LONG_FORM) {
          list.add(Article.fromEvent(e));
        }

        if (e.kind == EventKind.CURATION_ARTICLES ||
            e.kind == EventKind.CURATION_VIDEOS) {
          list.add(Curation.fromEvent(e, ''));
        }

        if (e.kind == EventKind.VIDEO_HORIZONTAL ||
            e.kind == EventKind.VIDEO_VERTICAL) {
          list.add(VideoModel.fromEvent(e));
        }
      }
    } else {
      completer.complete(list);
    }

    return list;
  }

  static Future<List<Event>> getLeadingDvmData({
    required String pubkey,
  }) async {
    final list = <Event>[];
    final completer = Completer<List<Event>>();

    final event = await Event.genEvent(
      kind: EventKind.DVM_CONTENT_FEED,
      tags: [
        ['p', pubkey],
      ],
      content: '',
      signer: actionsSigner,
    );

    if (event == null) {
      return list;
    }

    final f1 = Filter(
      kinds: [EventKind.DVM_CONTENT_FEED_RESPONSE],
      authors: [pubkey],
      p: [actionsSigner.getPublicKey()],
    );

    sendEvent(event: event, setProgress: false);

    final l = await getDvmResponse(f1);

    if (l.isNotEmpty) {
      final events = await getEventsAsync(
        ids: l,
      );

      for (final e in events) {
        if (e.kind == EventKind.TEXT_NOTE) {
          list.add(e);
        }
      }
    } else {
      completer.complete(list);
    }

    return list;
  }

  static Future<List<String>> getDvmResponse(Filter f) async {
    final list = <String>[];
    final completer = Completer<List<String>>();
    late String id;
    try {
      id = await nc.doSubscribe(
        [f],
        [],
        eventCallBack: (event, relay) {
          if (event.kind == EventKind.DVM_CONTENT_FEED_RESPONSE) {
            final content = event.content;
            final response = jsonDecode(content);

            if (response is List) {
              for (final item in response) {
                if (item is List) {
                  list.add(item[1]);
                }
              }
            }
          }
        },
        eoseCallBack: (p0, p1, p2, p3) {},
      );
    } catch (e) {
      completer.complete(list);
    }

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (list.isNotEmpty || timer.tick > timerTicks) {
          completer.complete(list);
          timer.cancel();
          nc.closeSubscriptions(id);
        }
      },
    );

    return completer.future;
  }

  static Future<List<BaseEventModel>> getDiscoverAlgoData({
    required List<String> relays,
    int? until,
    int? since,
    int? limit,
    List<int>? kinds,
  }) async {
    final list = <BaseEventModel>[];

    final events = await getEventsAsync(
      kinds: kinds,
      until: until,
      since: since,
      limit: limit,
      relays: relays,
      core: nc,
    );

    for (final e in events) {
      if (e.kind == EventKind.LONG_FORM) {
        list.add(Article.fromEvent(e));
      }

      if (e.kind == EventKind.CURATION_ARTICLES ||
          e.kind == EventKind.CURATION_VIDEOS) {
        list.add(Curation.fromEvent(e, ''));
      }

      if (e.kind == EventKind.VIDEO_HORIZONTAL ||
          e.kind == EventKind.VIDEO_VERTICAL) {
        list.add(VideoModel.fromEvent(e));
      }
    }

    return list;
  }

  static Future<List<Event>> getLeadingRelayData({
    required List<String> relays,
    int? until,
    int? since,
    int? limit,
  }) async {
    return getEventsAsync(
      kinds: [EventKind.TEXT_NOTE],
      until: until,
      since: since,
      limit: limit,
      relays: relays,
      core: nc,
      source: EventsSource.all,
    );
  }

  static Future<List<Event>> getMediaRelayData({
    required List<String> relays,
    int? until,
    int? since,
    int? limit,
  }) async {
    return getEventsAsync(
      kinds: [
        EventKind.VIDEO_HORIZONTAL,
        EventKind.VIDEO_VERTICAL,
        EventKind.LEGACY_VIDEO_HORIZONTAL,
        EventKind.LEGACY_VIDEO_VERTICAL,
        EventKind.PICTURE,
      ],
      until: until,
      since: since,
      limit: limit,
      relays: relays,
      core: nc,
      source: EventsSource.all,
    );
  }

  // * get home page data /
  static Future<List<BaseEventModel>> getHomePageData({
    required List<String> tags,
    required String search,
  }) async {
    final Map<String, Article> articlesToBeEmitted = {};
    final Map<String, VideoModel> videosToBeEmitted = {};
    final Map<String, PictureModel> picturesToBeEmitted = {};
    final Map<String, DetailedNoteModel> notesToBeEmitted = {};
    final list = <BaseEventModel>[];

    void processEvent(Event ev, String relay) {
      final event = ExtendedEvent.fromEv(ev);

      if (!isUserMuted(ev.pubkey)) {
        if (event.kind == EventKind.LONG_FORM) {
          final article = Article.fromEvent(
            event,
            relay: relay,
          );

          final oldArticle = articlesToBeEmitted[article.identifier];

          articlesToBeEmitted[article.identifier] = filterArticle(
            oldArticle: oldArticle,
            newArticle: article,
          );
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL ||
            event.kind == EventKind.LEGACY_VIDEO_HORIZONTAL ||
            event.kind == EventKind.LEGACY_VIDEO_VERTICAL) {
          final video = VideoModel.fromEvent(
            event,
            relay: relay,
          );

          final oldVideo = videosToBeEmitted[video.id];
          if (oldVideo == null ||
              oldVideo.createdAt.isBefore(video.createdAt)) {
            videosToBeEmitted[video.id] = video;
          }
        }
        if (event.kind == EventKind.PICTURE) {
          final picture = PictureModel.fromEvent(
            event,
            relay: relay,
          );

          final oldPicture = picturesToBeEmitted[picture.id];
          if (oldPicture == null ||
              oldPicture.createdAt.isBefore(picture.createdAt)) {
            picturesToBeEmitted[picture.id] = picture;
          }
        } else if (event.kind == EventKind.TEXT_NOTE) {
          notesToBeEmitted[event.id] = DetailedNoteModel.fromEvent(event);
        }
      }
    }

    try {
      await Future.wait(
        [
          nc.doQuery(
            [
              Filter(
                kinds: [
                  EventKind.TEXT_NOTE,
                  EventKind.LONG_FORM,
                  EventKind.VIDEO_HORIZONTAL,
                  EventKind.VIDEO_VERTICAL,
                  EventKind.LEGACY_VIDEO_HORIZONTAL,
                  EventKind.LEGACY_VIDEO_VERTICAL,
                  EventKind.PICTURE,
                ],
                t: tags,
              ),
            ],
            [
              ...nc
                  .activeRelays()
                  .toSet()
                  .difference(nostrRepository.getSearchRelays().toSet())
            ],
            source: EventsSource.all,
            eventCallBack: (ev, relay) {
              processEvent(ev, relay);
            },
            timeOut: 2,
            eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
              nc.closeSubscription(curationRequestId, relay);
            },
          ),
          nc.doQuery(
            [
              Filter(
                kinds: [
                  EventKind.TEXT_NOTE,
                  EventKind.LONG_FORM,
                  EventKind.VIDEO_HORIZONTAL,
                  EventKind.VIDEO_VERTICAL,
                  EventKind.LEGACY_VIDEO_HORIZONTAL,
                  EventKind.LEGACY_VIDEO_VERTICAL,
                  EventKind.PICTURE,
                ],
                search: search,
              ),
            ],
            nostrRepository.getSearchRelays(),
            source: EventsSource.all,
            eventCallBack: (ev, relay) {
              processEvent(ev, relay);
            },
            timeOut: 2,
            eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
              nc.closeSubscription(curationRequestId, relay);
            },
          ),
        ],
      );
    } catch (e) {
      lg.i(e);
    }

    final articles = orderedList(articlesToBeEmitted.values.toList());
    final videos = orderedList(videosToBeEmitted.values.toList());
    final notes = orderedList(notesToBeEmitted.values.toList());
    final pictures = orderedList(picturesToBeEmitted.values.toList());

    final length = [
      articles.length,
      videos.length,
      notes.length,
      pictures.length,
    ].reduce(max);

    for (int i = 0; i < length; i++) {
      if (videos.isNotEmpty) {
        list.add(videos.removeAt(0));
      }

      if (articles.isNotEmpty) {
        list.add(articles.removeAt(0));
      }

      if (notes.isNotEmpty) {
        list.add(notes.removeAt(0));
      }

      if (pictures.isNotEmpty) {
        list.add(pictures.removeAt(0));
      }
    }

    return list;
  }

  static List<BaseEventModel> orderedList(List<BaseEventModel> list) {
    final values = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return values;
  }

  // * get smart widgets /
  static Stream<List<SmartWidget>> getSmartWidgets({
    List<String>? smartWidgetsIds,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    String? relay,
  }) {
    final controller = StreamController<List<SmartWidget>>();

    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, SmartWidget> smartWidgetsToBeEmitted = {};

    final id = nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.SMART_WIDGET_ENH],
          d: smartWidgetsIds?.toList(),
          authors: pubkeys,
          t: tags,
          until: until,
          limit: limit,
        ),
      ],
      relay != null ? [relay] : [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.SMART_WIDGET_ENH &&
            !isUserMuted(event.pubkey)) {
          final smartWidget = SmartWidget.fromEvent(
            event,
          );

          final oldSmartWidget =
              smartWidgetsToBeEmitted[smartWidget.identifier];
          if (oldSmartWidget == null ||
              oldSmartWidget.createdAt.compareTo(smartWidget.createdAt) <= 0) {
            smartWidgetsToBeEmitted[smartWidget.identifier] = smartWidget;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (ok.status && smartWidgetsToBeEmitted.isNotEmpty) {
          final values = smartWidgetsToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) {
            controller.add(values);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          nc.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // * get articles /
  static Stream<List<Article>> getArticles({
    List<String>? articlesIds,
    List<String>? pubkeys,
    List<String>? tags,
    int? limit,
    int? until,
    ArticleFilter? articleFilter,
  }) {
    final controller = StreamController<List<Article>>();
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, Article> articlesToBeEmitted = {};

    final id = nc.addSubscription(
      [
        Filter(
          kinds: articleFilter == null
              ? [EventKind.LONG_FORM]
              : articleFilter == ArticleFilter.All
                  ? [EventKind.LONG_FORM, EventKind.LONG_FORM_DRAFT]
                  : articleFilter == ArticleFilter.Published
                      ? [EventKind.LONG_FORM]
                      : [EventKind.LONG_FORM_DRAFT],
          d: articlesIds?.toList(),
          authors: pubkeys,
          t: tags,
          until: until,
          limit: limit,
        ),
      ],
      (pubkeys != null &&
              pubkeys.isNotEmpty &&
              pubkeys.first == currentSigner?.getPublicKey())
          ? currentUserRelayList.urls.toList()
          : feedRelaySet?.urls.toList() ?? currentUserRelayList.urls.toList(),
      eventCallBack: (event, relay) {
        if ((event.kind == EventKind.LONG_FORM ||
                event.kind == EventKind.LONG_FORM_DRAFT) &&
            !isUserMuted(event.pubkey)) {
          final article = Article.fromEvent(
            event,
            relay: relay,
            isDraft: event.kind == EventKind.LONG_FORM_DRAFT,
          );

          final oldArticle = articlesToBeEmitted[article.identifier];

          articlesToBeEmitted[article.identifier] = filterArticle(
            oldArticle: oldArticle,
            newArticle: article,
          );
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;

        if (ok.status && articlesToBeEmitted.isNotEmpty) {
          final values = articlesToBeEmitted.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (!controller.isClosed) {
            controller.add(values);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          nc.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // * get flash news events /
  static Stream<List<FlashNews>> getUserFlashNews({
    required String pubkey,
  }) {
    final controller = StreamController<List<FlashNews>>();
    final List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, FlashNews> flashNewsToBeEmitted = {};

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          authors: [pubkey],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);

        if (flashNews.isAuthentic) {
          if (flashNewsToBeEmitted[flashNews.id] == null ||
              flashNews.createdAt
                  .isAfter(flashNewsToBeEmitted[flashNews.id]!.createdAt)) {
            flashNewsToBeEmitted[flashNews.id] = flashNews;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          final updatedFlashnews = flashNewsToBeEmitted.values.toList();
          updatedFlashnews.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          if (!controller.isClosed) {
            controller.add(updatedFlashnews);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  // =============================================================================
  // FLASH NEWS FUNCTIONS
  // =============================================================================

  static Stream<Map<String, List<FlashNews>>> getFlashNewsWithTime({
    required DateTime since,
    required DateTime until,
  }) {
    final controller = StreamController<Map<String, List<FlashNews>>>();
    List<String> currentUncompletedRelays = nc.activeRelays();

    final Map<String, Map<String, FlashNews>> flashNewsToBeEmitted = {
      dateFormat2.format(until): {},
      dateFormat2.format(since): {},
    };

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          since: since.toSecondsSinceEpoch(),
          until: until.toSecondsSinceEpoch(),
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);

        if (flashNews.isAuthentic) {
          if (flashNewsToBeEmitted[flashNews.formattedDate] == null) {
            flashNewsToBeEmitted[flashNews.formattedDate] = {
              flashNews.id: flashNews,
            };
          } else {
            final flashNewsList =
                flashNewsToBeEmitted[flashNews.formattedDate]!;
            final canBeAdded = flashNewsList[flashNews.id] == null ||
                flashNewsList[flashNews.id]!
                        .createdAt
                        .compareTo(flashNews.createdAt) <
                    1;

            if (canBeAdded) {
              flashNewsList.addAll(
                {
                  flashNews.id: flashNews,
                },
              );
            }
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          final Map<String, List<FlashNews>> updatedFlashNews = {};
          final Set<String> authors = {};

          flashNewsToBeEmitted.forEach(
            (key, value) {
              updatedFlashNews[key] = value.values.toList()
                ..sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );

              authors.addAll(value.values.map((e) => e.pubkey).toList());
            },
          );
          if (!controller.isClosed) {
            controller.add(updatedFlashNews);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
        }
      },
    );

    return controller.stream;
  }

  static Stream<List<FlashNews>> getFlashNews({
    List<String>? tags,
    List<String>? pubkeys,
    List<String>? ids,
    int? limit,
  }) {
    final controller = StreamController<List<FlashNews>>();
    List<String> currentUncompletedRelays = nc.activeRelays();
    final Map<String, FlashNews> flashNewsToBeEmitted = {};

    final id = nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.TEXT_NOTE],
          l: [FN_SEARCH_VALUE],
          authors: pubkeys,
          t: tags,
          ids: ids,
          limit: limit,
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        final flashNews = FlashNews.fromEvent(event);
        final oldFlashNews = flashNewsToBeEmitted[flashNews.id];

        if (flashNews.isAuthentic && !isUserMuted(flashNews.pubkey)) {
          if (oldFlashNews == null ||
              flashNews.createdAt.isAfter(oldFlashNews.createdAt)) {
            flashNewsToBeEmitted[flashNews.id] = flashNews;
          }
        }
      },
      eoseCallBack: (curationRequestId, ok, relay, unCompletedRelays) {
        currentUncompletedRelays = unCompletedRelays;
        if (ok.status && flashNewsToBeEmitted.isNotEmpty) {
          final Set<String> authors = {};

          for (final element in flashNewsToBeEmitted.values) {
            authors.add(element.pubkey);
          }

          final updatedFlashNews = flashNewsToBeEmitted.values.toList();

          updatedFlashNews.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          );

          if (!controller.isClosed) {
            controller.add(updatedFlashNews);
          }
        }

        nc.closeSubscription(curationRequestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (currentUncompletedRelays.isEmpty || timer.tick > timerTicks) {
          controller.close();
          timer.cancel();
          nc.closeRequests([id]);
        }
      },
    );

    return controller.stream;
  }

  // =============================================================================
  // VOTES FUNCTIONS
  // =============================================================================

  // * add voting event /
  static Future<String?> addVote({
    required String eventId,
    required bool upvote,
    required bool isEtag,
    required String eventPubkey,
    String? identifier,
    int? kind,
  }) async {
    final event = await Event.genEvent(
      kind: 7,
      content: upvote ? '+' : '-',
      signer: currentSigner,
      verify: true,
      tags: [
        if (isEtag)
          ['e', eventId]
        else
          Nip33.coordinatesToTag(
            EventCoordinates(
              kind!,
              eventPubkey,
              identifier!,
              '',
            ),
          ),
        ['p', eventPubkey],
      ],
    );

    if (event == null) {
      return null;
    } else {
      final relays = await broadcastRelays(eventPubkey);

      final isSuccessful = await sendEvent(
        event: event,
        relays: relays,
        setProgress: true,
      );

      return isSuccessful ? event.id : null;
    }
  }

  static Future<Event?> getEventById({
    required bool isIdentifier,
    String? eventId,
    String? author,
    List<int>? kinds,
    List<String>? relays,
    EventsSource? source,
  }) async {
    Event? event;

    final f1 = Filter(
      authors: author != null ? [author] : null,
      ids: isIdentifier || eventId == null ? null : [eventId],
      d: isIdentifier && eventId != null ? [eventId] : null,
      kinds: kinds,
    );

    await nc.doQuery(
      [f1],
      relays ?? [],
      eventCallBack: (newEvent, relay) {
        if (event == null || event!.createdAt < newEvent.createdAt) {
          event = newEvent;
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        nc.closeSubscription(requestId, relay);
      },
      timeOut: 2,
      source: source ?? EventsSource.cacheFirst,
    );

    return event;
  }

  static Future<Event?> getZapEvent({
    required String eventId,
    required String pTag,
    required bool isIdentifier,
    int? since,
  }) async {
    Event? event;
    final completer = Completer<Event?>();
    List<String> uncompletedRelays = nc.relays();

    final f1 = Filter(
      e: isIdentifier ? null : [eventId],
      a: !isIdentifier ? null : [eventId],
      p: [pTag],
      kinds: [EventKind.ZAP],
    );

    nc.addSubscription(
      [f1],
      [],
      eventCallBack: (newEvent, relay) {
        if (newEvent.kind == EventKind.ZAP) {
          if (event == null ||
              (event != null &&
                  event!.createdAt.compareTo(newEvent.createdAt) == -1)) {
            event = newEvent;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        uncompletedRelays = unCompletedRelays;
        nc.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (uncompletedRelays.isEmpty ||
            event != null ||
            timer.tick > timerTicks * 2) {
          completer.complete(event);
          timer.cancel();
        }
      },
    );

    return completer.future;
  }

  static ZapEventSubscription getZapEventStream({
    required String invoice,
  }) {
    Event? event;
    final completer = Completer<Event?>();

    final f1 = Filter(
      bolt11: [invoice],
      since: currentUnixTimestampSeconds(),
    );

    final id = nc.addSubscription(
      [f1],
      [],
      eventCallBack: (newEvent, relay) {
        if (newEvent.kind == EventKind.ZAP) {
          if (event == null ||
              event!.createdAt.compareTo(newEvent.createdAt) == -1) {
            event = newEvent;
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {},
    );

    final timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (t) {
        if (event != null && !completer.isCompleted) {
          completer.complete(event);
          t.cancel();
          nc.closeSubscriptions(id);
        }
      },
    );

    // return both future + cancel handle
    return ZapEventSubscription(
      future: completer.future,
      cancel: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        timer.cancel();
        nc.closeSubscriptions(id);
      },
    );
  }

  // * flash news invoice
  static Future<bool> checkPayment(String eventId) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final completer = Completer<bool>();

    bool isChecked = false;

    nc.addSubscription(
      [
        Filter(
          kinds: [EventKind.ZAP],
          p: [yakihonneHex],
          e: [eventId],
        ),
      ],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.ZAP) {
          for (final t in event.tags) {
            if (t[0] == 'e' && t.length >= 2 && t[1] == eventId) {
              isChecked = true;
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        nc.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (isChecked) {
          timer.cancel();
          completer.complete(true);
        } else if (timer.tick > 20) {
          timer.cancel();
          completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  static Future<Event?> checkInvoicePayment({
    required String id,
    required bool isIdentifier,
    String? p,
  }) async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    final completer = Completer<Event?>();
    Event? ev;

    final f = Filter(
      kinds: [EventKind.ZAP],
      p: p != null ? [p] : null,
      e: !isIdentifier && id.isNotEmpty ? [id] : null,
      a: isIdentifier && id.isNotEmpty ? [id] : null,
    );

    nc.addSubscription(
      [f],
      [],
      eventCallBack: (event, relay) {
        if (event.kind == EventKind.ZAP) {
          for (final t in event.tags) {
            if (isIdentifier && t.length >= 2 && t[0] == 'a' && t[1] == id) {
              ev = event;
            } else if (!isIdentifier &&
                t.length >= 2 &&
                t[0] == 'e' &&
                t[1] == id) {
              ev = event;
            }
          }
        }
      },
      eoseCallBack: (requestId, ok, relay, unCompletedRelays) {
        nc.closeSubscription(requestId, relay);
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (ev != null) {
          timer.cancel();
          completer.complete(ev);
        } else if (timer.tick > 20) {
          timer.cancel();
          completer.complete(null);
        }
      },
    );

    return completer.future;
  }

  // * mute user /

  static Future<bool> setMuteList({
    required String muteKey,
    bool isPubkey = true,
  }) async {
    if (!canSign()) {
      if (isPubkey) {
        final mm = nostrRepository.muteModel.copyWith();

        if (mm.usersMutes.contains(muteKey)) {
          mm.usersMutes.remove(muteKey);
        } else {
          mm.usersMutes.add(muteKey);
        }

        nostrRepository.setMuteList(mm);
        localDatabaseRepository.setLocalMutes(mm.usersMutes.toList());

        return true;
      }

      return false;
    } else {
      final mm = nostrRepository.muteModel.copyWith();

      if (isPubkey) {
        if (mm.usersMutes.contains(muteKey)) {
          mm.usersMutes.remove(muteKey);
        } else {
          mm.usersMutes.add(muteKey);
        }
      } else {
        if (mm.eventsMutes.contains(muteKey)) {
          mm.eventsMutes.remove(muteKey);
        } else {
          mm.eventsMutes.add(muteKey);
        }
      }

      final tags = [
        ...mm.usersMutes.map((user) => ['p', user]),
        ...mm.eventsMutes.map((e) => ['e', e]),
      ];

      final event = await Event.genEvent(
        kind: EventKind.MUTE_LIST,
        tags: tags,
        content: '',
        signer: currentSigner,
      );

      if (event == null) {
        return false;
      }

      final isSuccessful = await sendEvent(event: event, setProgress: false);

      if (isSuccessful) {
        nostrRepository.setMuteList(mm);

        nc.db.saveEvent(event);
      }

      return isSuccessful;
    }
  }

  // * report event /
  static Future<bool> report({
    required String reason,
    required String comment,
    required bool isEtag,
    required String eventPubkey,
    String? identifier,
    String? eventId,
    int? kind,
  }) async {
    final completer = Completer<bool>();

    final event = await Event.genEvent(
      kind: 1984,
      tags: [
        if (isEtag) ['e', eventId!, reason],
        if (!isEtag)
          Nip33.coordinatesToTag(
            EventCoordinates(
              kind!,
              eventPubkey,
              identifier!,
              reason,
            ),
          ),
        ['p', eventPubkey],
      ],
      content: comment,
      signer: currentSigner,
    );

    if (event == null) {
      completer.complete(false);
    } else {
      bool isSuccessful = false;

      nc.sendEvent(
        event,
        [],
        sendCallBack: (ok, relay, unCompletedRelays) {
          if (ok.status && !isSuccessful) {
            isSuccessful = true;
          }
        },
      );

      Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) {
          if (isSuccessful || timer.tick > timerTicks) {
            completer.complete(isSuccessful);
            timer.cancel();
          }
        },
      );
    }

    return completer.future;
  }

  static Future<bool> setFollowingEvent({
    required bool isFollowingAuthor,
    required String targetPubkey,
  }) async {
    if (isFollowingAuthor) {
      await contactListCubit.removeContact(targetPubkey);
    } else {
      await contactListCubit.addContact(targetPubkey);
    }

    nostrRepository.contactListController.sink.add(contactListCubit.contacts);

    if (canSign()) {
      final list = await contactListCubit.loadContactList(
        currentSigner!.getPublicKey(),
      );

      if (list != null) {
        HttpFunctionsRepository.sendActionThroughEvent(list.toEvent());
      }
    }

    return true;
  }

  // =============================================================================
  // EVENT MANAGEMENT
  // =============================================================================

  /// Helper method to handle event operations with timer-based completion
  ///
  /// This reduces code duplication between sendEvent and deleteEvent functions
  static Future<bool> _handleEventOperation({
    required Event event,
    required List<String> relays,
    required int timeout,
    required Function(bool success) onComplete,
    bool relyOnUnsentEvents = true,
    String? destinationPubkey,
  }) async {
    final completer = Completer<bool>();
    bool isSuccessful = false;

    final missingRelays = nc.missingRelays(relays);

    if (missingRelays.isNotEmpty) {
      await nc.connectRelays(missingRelays);
    }

    nc.sendEvent(
      event,
      relays,
      sendCallBack: (ok, relay, unCompletedRelays) {
        if (ok.status && !isSuccessful) {
          isSuccessful = true;
        }
      },
    );

    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        // Handle offline case (like setProgress does)
        if (!connectivityService.isConnected && relyOnUnsentEvents) {
          if (missingRelays.isNotEmpty) {
            nc.closeConnect(missingRelays);
          }

          timer.cancel();
          unsentEventsCubit.addUnsentEvent(
            event,
            pubkey: destinationPubkey,
          );
          nc.db.saveEvent(event);
          completer.complete(true);
          return;
        }

        // Handle success or timeout
        if (isSuccessful || timer.tick > timeout) {
          timer.cancel();

          if (missingRelays.isNotEmpty) {
            nc.closeConnect(missingRelays);
          }

          if (isSuccessful) {
            // Remove from unsent events if successful (like setProgress does)
            if (relyOnUnsentEvents) {
              unsentEventsCubit.removeUnsentEvent(event.id);
            }

            nc.db.saveEvent(event);
            onComplete(true);
          } else if (relyOnUnsentEvents) {
            unsentEventsCubit.addUnsentEvent(event);
            nc.db.saveEvent(event);
          }

          completer.complete(relyOnUnsentEvents || isSuccessful);
        }
      },
    );

    return completer.future;
  }

  /// Sends an event to the specified relays and tracks its progress
  ///
  /// Returns a Future<bool> that completes when the event is successfully sent
  /// or when the timeout is reached
  static Future<bool> sendEvent({
    required Event event,
    required bool setProgress,
    List<String>? relays,
    int? timeout,
    bool relyOnUnsentEvents = true,
    String? destinationPubkey,
  }) async {
    final id = uuid.generate();
    final ur = currentUserRelayList.urls.toList();

    final targetRelays =
        relays ?? (ur.isNotEmpty ? ur : DEFAULT_BOOTSTRAP_RELAYS);
    final actualTimeout = timeout ?? timerTicks;

    if (setProgress) {
      return _sendEventWithProgress(
        event: event,
        requestId: id,
        relays: targetRelays,
        timeout: actualTimeout,
        relyOnUnsentEvents: relyOnUnsentEvents,
        destinationPubkey: destinationPubkey,
      );
    } else {
      return _handleEventOperation(
        event: event,
        relays: targetRelays,
        timeout: actualTimeout,
        onComplete: (success) {
          if (success) {
            HttpFunctionsRepository.sendActionThroughEvent(event);
          }
        },
        relyOnUnsentEvents: relyOnUnsentEvents,
        destinationPubkey: destinationPubkey,
      );
    }
  }

  /// Sends event with progress tracking
  static Future<bool> _sendEventWithProgress({
    required Event event,
    required String requestId,
    required List<String> relays,
    required int timeout,
    required bool relyOnUnsentEvents,
    String? destinationPubkey,
  }) async {
    final completer = Completer<bool>();
    bool isSuccessful = false;

    final missingRelays = nc.missingRelays(relays);

    if (missingRelays.isNotEmpty) {
      await nc.connectRelays(missingRelays);
    }

    nc.sendEvent(
      event,
      relays,
      sendCallBack: (ok, relay, unCompletedRelays) {
        if (ok.status) {
          relaysProgressCubit.setRelays(
            requestId: requestId,
            incompleteRelays: unCompletedRelays,
            chosenTotalRelays: relays,
          );

          isSuccessful = true;
        }
      },
    );

    // Check for completion periodically
    Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        // Handle offline case
        if (!connectivityService.isConnected && relyOnUnsentEvents) {
          if (missingRelays.isNotEmpty) {
            nc.closeConnect(missingRelays);
          }

          timer.cancel();
          unsentEventsCubit.addUnsentEvent(
            event,
            pubkey: destinationPubkey,
          );

          nc.db.saveEvent(event);
          completer.complete(true);
          return;
        }

        // Handle success or timeout
        if (isSuccessful || timer.tick > timeout) {
          timer.cancel();

          if (missingRelays.isNotEmpty) {
            nc.closeConnect(missingRelays);
          }

          if (isSuccessful) {
            if (relyOnUnsentEvents) {
              unsentEventsCubit.removeUnsentEvent(event.id);
            }

            nc.db.saveEvent(event);
            HttpFunctionsRepository.sendActionThroughEvent(event);
          }

          completer.complete(isSuccessful);
        }
      },
    );

    return completer.future;
  }

  // =============================================================================
  // EVENT MANAGEMENT
  // =============================================================================

  /// Deletes an event by publishing a deletion event (kind 5)
  ///
  /// Parameters:
  /// - eventId: The ID of the event to delete
  /// - label: Optional label for the deletion
  /// - type: Optional type for the deletion
  /// - relays: Optional list of relays to send the deletion to
  static Future<bool> deleteEvent({
    required String eventId,
    String? aTag,
    String? lable,
    String? type,
    List<String>? relays,
    bool relyOnUnsentEvents = true,
  }) async {
    final event = await Event.genEvent(
      kind: EventKind.EVENT_DELETION,
      tags: [
        if (eventId.isNotEmpty) ['e', eventId],
        if (aTag != null && aTag.isNotEmpty) ['a', aTag],
        if (lable != null && lable.isNotEmpty) ['l', lable, type!],
      ],
      content: 'this event is to be deleted',
      signer: currentSigner,
    );

    if (event == null) {
      return false;
    }

    return _handleEventOperation(
      event: event,
      relays: relays ?? [],
      timeout: timerTicks,
      onComplete: (_) {
        nc.db.removeEvent(eventId);
      },
      relyOnUnsentEvents: relyOnUnsentEvents,
    );
  }

  static Future<bool> deleteEvents({
    required List<String> eventIds,
    List<String>? relays,
    bool relyOnUnsentEvents = true,
  }) async {
    final event = await Event.genEvent(
      kind: EventKind.EVENT_DELETION,
      tags: eventIds.map((e) => ['e', e]).toList(),
      content: 'these events are to be deleted',
      signer: currentSigner,
    );

    lg.i(event?.toJson());
    if (event == null) {
      return false;
    }

    return _handleEventOperation(
      event: event,
      relays: relays ?? [],
      timeout: timerTicks,
      onComplete: (_) {
        nc.db.removeEvents(eventIds);
      },
      relyOnUnsentEvents: relyOnUnsentEvents,
    );
  }

  // =============================================================================
  // FILTERS
  // =============================================================================
  static void filterComments({
    required Comment comment,
    required Map<String, Comment> comments,
    StreamController? controller,
  }) {
    final canBeAdded = comments[comment.id] == null ||
        comments[comment.id]!.createdAt.compareTo(comment.createdAt) < 1;

    if (canBeAdded) {
      comments[comment.id] = comment;
      if (controller != null && !controller.isClosed) {
        controller.add(comments);
      }
    }
  }

  static void filterReports({
    required String report,
    required Set<String> reports,
    StreamController? controller,
  }) {
    reports.add(report);
    if (controller != null && !controller.isClosed) {
      controller.add(reports);
    }
  }

  static void filterZaps({
    required List<String> zapsEventIds,
    required Map<String, double> zaps,
    required Event event,
    required bool isEtag,
    String? identifier,
    StreamController? controller,
  }) {
    final isATagAvailable = event.tags.where(
      (element) {
        if (isEtag) {
          return element.first == 'e';
        } else {
          if (element.first == 'a') {
            final c = Nip33.getEventCoordinates(element);
            return c != null && c.identifier == identifier;
          } else {
            return false;
          }
        }
      },
    );

    if (isATagAvailable.isEmpty) {
      return;
    }

    if (!zapsEventIds.contains(event.id)) {
      final receipt = Nip57.getZapReceipt(event);
      final req = Bolt11PaymentRequest(receipt.bolt11);

      zapsEventIds.add(event.id);
      final zapPubkey = getZapPubkey(event.tags).first;
      final usedPubkey = zapPubkey.isNotEmpty ? zapPubkey : event.pubkey;

      if (zaps[usedPubkey] == null) {
        zaps[usedPubkey] =
            (req.amount.toDouble() * 100000000).round().toDouble();
      } else {
        zaps[usedPubkey] =
            ((zaps[usedPubkey] ?? 0) + (req.amount.toDouble() * 100000000))
                .round()
                .toDouble();
      }

      if (controller != null && !controller.isClosed) {
        controller.add(zaps);
      }
    }
  }

  static void filterVotes({
    required Map<String, Map<String, VoteModel>> votes,
    required Event event,
    required bool isEtag,
    String? identifier,
    StreamController? controller,
  }) {
    if (event.content == '+' || event.content == '-') {
      final isATagAvailable = event.tags.lastWhere(
        (element) => isEtag
            ? element.first == 'e'
            : element.first == 'a' && element[1] == identifier.toString(),
        orElse: () => [],
      );

      if (isATagAvailable.isEmpty) {
        return;
      }

      EventCoordinates? eventCoordinates;

      if (!isEtag) {
        eventCoordinates = Nip33.getEventCoordinates(isATagAvailable);
      }

      final selectedKey =
          isEtag ? isATagAvailable[1] : eventCoordinates!.identifier;

      if (votes[selectedKey] == null) {
        votes[selectedKey] = {
          event.pubkey: VoteModel.fromEvent(event),
        };
      } else {
        votes[selectedKey]!.addAll({
          event.pubkey: VoteModel.fromEvent(event),
        });
      }

      if (controller != null && !controller.isClosed) {
        controller.add(votes);
      }
    }
  }

  // =============================================================================
  // ARTICLES FUNCTIONS
  // =============================================================================

  /// Generic filter method for models with relays and createdAt properties
  /// This helps reduce code duplication across multiple filter methods
  static T _filterModel<T>({
    required T? oldModel,
    required T newModel,
    required bool Function(T oldModel, T newModel) isNewer,
    required void Function(T target, T source) mergeRelays,
  }) {
    if (oldModel != null) {
      final shouldUseNew = isNewer(oldModel, newModel);

      if (shouldUseNew) {
        mergeRelays(newModel, oldModel);
        return newModel;
      } else {
        mergeRelays(oldModel, newModel);
        return oldModel;
      }
    } else {
      return newModel;
    }
  }

  static Article filterArticle({
    required Article? oldArticle,
    required Article newArticle,
  }) {
    return _filterModel<Article>(
      oldModel: oldArticle,
      newModel: newArticle,
      isNewer: (old, fresh) => old.createdAt.isBefore(fresh.createdAt),
      mergeRelays: (target, source) => target.relays.addAll(source.relays),
    );
  }
}
