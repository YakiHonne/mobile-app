import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/packs_model.dart';
import '../../models/relays_feed.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';
import '../feed_extra_refresh_controller.dart';

part 'discover_state.dart';

// =============================================================================
// DISCOVER CUBIT: State management for Discover Feed and related features
// =============================================================================
class DiscoverCubit extends Cubit<DiscoverState> {
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  DiscoverCubit()
      : super(
          DiscoverState(
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            content: const [],
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            onAddingData: UpdatingState.success,
            onLoading: true,
            followings: contactListCubit.contacts,
            refresh: false,
            extraContent: const [],
            showFollowingListMessage: false,
            selectedSource:
                appSettingsManagerCubit.getDiscoverSelectedSource().key,
          ),
        );
  // =============================================================================
  // PROPERTIES
  // =============================================================================
  StreamSubscription? feedStream;
  StreamSubscription? mutesStream;
  late final FeedExtraRefreshController _extraRefreshController =
      FeedExtraRefreshController(onRefresh: _fetchExtraContent);
  ExploreType exploreType = ExploreType.articles;
  final extraIds = <String>{};
  int _extraRefreshGeneration = 0;
  Future<void>? _initialization;
  bool _isFeedActive = false;
  bool _isAppResumed = true;
  bool _isRestoringSnapshot = false;
  Future<void> _feedSnapshotPersistence = Future<void>.value();

  // =============================================================================
  // PUBLIC METHODS
  // =============================================================================
  /// Start the Discover feed the first time its tab is selected.
  Future<void> ensureInitialized({bool restoreSnapshot = false}) =>
      _initialization ??= _initialize(restoreSnapshot: restoreSnapshot);

  void setFeedActive(bool active) {
    _isFeedActive = active;
    if (!active) {
      _extraRefreshGeneration++;
    }
    _extraRefreshController.setFeedActive(active);
  }

  void setAppResumed(bool resumed) {
    _isAppResumed = resumed;
    if (!resumed) {
      _extraRefreshGeneration++;
    }
    _extraRefreshController.setAppResumed(resumed);
  }

  Future<void> _initialize({required bool restoreSnapshot}) async {
    if (isClosed) {
      return;
    }

    _setupStreams();
    suggestionsBoxCubit.initDiscover();
    final restored = restoreSnapshot && await _restoreCachedFeed();
    if (!restored) {
      await buildDiscoverFeed(
        exploreType: ExploreType.articles,
        isAdding: false,
      );
    }
  }

  Future<bool> _restoreCachedFeed() async {
    final owner = currentSigner?.getPublicKey() ?? '';
    final savedIds = localDatabaseRepository.getMainViewFeedSnapshot(
      owner,
      'articles',
    );
    if (savedIds.isEmpty) {
      return false;
    }

    try {
      final cachedEvents = await NostrFunctionsRepository.getCachedEventsByIds(
        savedIds,
      );
      if (cachedEvents.isEmpty || isClosed) {
        return false;
      }

      final eventsById = {for (final event in cachedEvents) event.id: event};
      final orderedEvents =
          savedIds.map((id) => eventsById[id]).whereType<Event>().toList();
      final models = <BaseEventModel>[];
      for (final event in orderedEvents) {
        if (event.kind == EventKind.LONG_FORM) {
          models.add(Article.fromEvent(event));
        } else if (event.kind == EventKind.CURATION_ARTICLES ||
            event.kind == EventKind.CURATION_VIDEOS) {
          models.add(Curation.fromEvent(event, ''));
        } else if (event.kind == EventKind.VIDEO_HORIZONTAL ||
            event.kind == EventKind.VIDEO_VERTICAL) {
          models.add(VideoModel.fromEvent(event));
        }
      }

      final content = applyDiscoverFilter(models);
      if (content.isEmpty) {
        return false;
      }

      _isRestoringSnapshot = true;
      emit(
        state.copyWith(
          content: content,
          onLoading: false,
          onAddingData: UpdatingState.success,
        ),
      );
      _isRestoringSnapshot = false;
      getExtra();
      if (_isFeedActive && _isAppResumed) {
        unawaited(_fetchExtraContent());
      }
      return true;
    } catch (error) {
      _isRestoringSnapshot = false;
      lg.i('Unable to restore the cached articles feed: $error');
      return false;
    }
  }

  @override
  void onChange(Change<DiscoverState> change) {
    super.onChange(change);
    if (_isRestoringSnapshot || change.nextState.content.isEmpty) {
      return;
    }

    final currentIds =
        change.currentState.content.map((event) => event.id).toList();
    final nextIds = change.nextState.content.map((event) => event.id).toList();
    if (currentIds.length == nextIds.length &&
        currentIds.asMap().entries.every(
              (entry) => nextIds[entry.key] == entry.value,
            )) {
      return;
    }

    final owner = currentSigner?.getPublicKey() ?? '';
    _feedSnapshotPersistence = _feedSnapshotPersistence.then((_) async {
      await localDatabaseRepository.setMainViewFeedSnapshot(
        owner,
        'articles',
        nextIds,
      );
    });
  }

  /// Set up streams for app customization and mutes
  // =============================================================================
  // STREAMS & LISTENERS
  // =============================================================================
  void _setupStreams() {
    // Listen for app customization changes
    feedStream = nostrRepository.appCustomizationStream.listen(
      (appCustom) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );

    // Listen for mutes changes
    mutesStream = nostrRepository.mutesStream.listen(
      (mm) {
        final newContent = List<BaseEventModel>.from(state.content)
          ..removeWhere(
            (e) => mm.usersMutes.contains(e.pubkey),
          );
        if (!isClosed) {
          emit(
            state.copyWith(
              content: newContent,
              refresh: true,
            ),
          );
        }
      },
    );
  }

  // =============================================================================
  // DATA MANAGEMENT METHODS
  // =============================================================================
  /// Append extra content to the main content list
  void appendExtra() {
    if (!isClosed) {
      emit(
        state.copyWith(
          content: [
            ...state.extraContent,
            ...state.content,
          ],
          extraContent: [],
        ),
      );
    }
  }

  /// Clear all content data and reset state for the given source
  void clearData(AppContentSource source) {
    _extraRefreshGeneration++;
    _extraRefreshController.setHasContent(false);
    if (!isClosed) {
      emit(
        state.copyWith(
          content: [],
          onAddingData: UpdatingState.success,
          onLoading: true,
          extraContent: [],
          selectedSource: source,
          showFollowingListMessage: false,
        ),
      );
    }
  }

  /// Manage extra content
  void getExtra() {
    _extraRefreshController.setHasContent(state.content.isNotEmpty);
  }

  Future<void> _fetchExtraContent() async {
    if (isClosed || state.content.isEmpty) {
      return;
    }
    final generation = _extraRefreshGeneration;

    final first = state.extraContent.isNotEmpty
        ? state.extraContent.first
        : state.content.first;
    final currentSelectedSource =
        appSettingsManagerCubit.getDiscoverSelectedSource();
    final f = appSettingsManagerCubit.getSelectedDiscoverFilter();
    final since = first.createdAt.toSecondsSinceEpoch() + 1;

    List<BaseEventModel> content = [];
    if (currentSelectedSource.key == AppContentSource.community) {
      content = await getExploreFeedCommunityEvents(
        since: since,
        limit: 20,
        f: f,
      );

      if (isClosed || generation != _extraRefreshGeneration) {
        return;
      }

      final source = appSettingsManagerCubit.state.selectedDiscoverSource;
      if (source.value == SOURCE_TOP) {
        final globalIds = state.content.map((event) => event.id).toSet();
        content.removeWhere((event) => globalIds.contains(event.id));
      }
    } else if (currentSelectedSource.key == AppContentSource.packs) {
      content = await getExploreFeedPacksEvents(
        since: since,
        limit: 20,
        f: f,
      );
    } else if (currentSelectedSource.key == AppContentSource.relay) {
      content = await getExploreFeedRelayEvents(
        since: since,
        limit: 20,
        f: f,
      );
    }

    if (isClosed || generation != _extraRefreshGeneration) {
      return;
    }

    if (content.isNotEmpty && !isClosed) {
      emit(
        state.copyWith(
          extraContent: [...content, ...state.extraContent],
          onLoading: false,
          onAddingData: UpdatingState.success,
        ),
      );
    }
  }

  void resetExtra() {
    _extraRefreshController.reset();
  }

  // =============================================================================
  // FEED BUILDING METHODS
  // =============================================================================
  /// Main method to build the explore feed based on the selected source and explore type
  ///
  /// If [isAdding] is true, appends to existing content, otherwise replaces it
  /// [exploreType] determines what kind of content to fetch (all, articles, videos, etc.)
  Future<void> buildDiscoverFeed({
    required ExploreType exploreType,
    required bool isAdding,
  }) async {
    final currentSelectedSource =
        appSettingsManagerCubit.getDiscoverSelectedSource();
    this.exploreType = exploreType;

    if (!isAdding) {
      clearData(currentSelectedSource.key);
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            onAddingData: UpdatingState.progress,
          ),
        );
      }
    }

    if (currentSelectedSource.key == AppContentSource.community) {
      await buildExploreFeedFromCommunity(
        exploreType: exploreType,
        isAdding: isAdding,
      );
    } else if (currentSelectedSource.key == AppContentSource.packs) {
      await buildExploreFeedFromPacks(
        exploreType: exploreType,
        isAdding: isAdding,
      );
    } else {
      await buildExploreFeedFromRelays(
        exploreType: exploreType,
        isAdding: isAdding,
      );
    }

    getExtra();
  }

  /// Build the explore feed from community sources
  ///
  /// If [isAdding] is true, appends to existing content, otherwise replaces it
  /// [exploreType] determines what kind of content to fetch (all, articles, videos, etc.)
  Future<void> buildExploreFeedFromCommunity({
    required ExploreType exploreType,
    required bool isAdding,
  }) async {
    bool? showFollowingsMessage;

    final f = appSettingsManagerCubit.getSelectedDiscoverFilter();
    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getExploreFeedCommunityEvents(
      f: f,
      until: until,
      showFollowingsMessage: (status) {
        showFollowingsMessage = status;
      },
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          showFollowingListMessage: showFollowingsMessage,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<BaseEventModel>> getExploreFeedCommunityEvents({
    required DiscoverFilter f,
    int? until,
    int? since,
    Function(bool)? showFollowingsMessage,
    int? limit,
  }) async {
    final source = appSettingsManagerCubit.state.selectedDiscoverSource;
    List<BaseEventModel> content = [];

    if (source.value == SOURCE_GLOBAL) {
      content = await NostrFunctionsRepository.buildExploreFeed(
        until: until,
        limit: limit ?? 50,
        since: since ?? f.from,
        exploreType: exploreType,
        pubkeys: f.postedBy.isNotEmpty ? f.postedBy : null,
      );

      showFollowingsMessage?.call(false);
    } else if (source.value == SOURCE_TOP) {
      content = await NostrFunctionsRepository.buildExploreFeedFromGeneric(
        until: until,
        limit: limit ?? 50,
        since: since ?? f.from,
        exploreType: exploreType,
      );

      showFollowingsMessage?.call(false);
    } else if (source.value == SOURCE_NETWORK) {
      List<String> wot = [];

      if (f.postedBy.isNotEmpty) {
        wot = f.postedBy;
      } else {
        if (canSign()) {
          wot = (await nc.calculateWot(
            pubkey: currentSigner!.getPublicKey(),
            mutes: nostrRepository.muteModel.usersMutes,
          ))
              .keys
              .toList();

          if (wot.isEmpty) {
            wot = (await nc.calculateWot(
              pubkey: yakihonneHex,
              mutes: nostrRepository.muteModel.usersMutes,
            ))
                .keys
                .toList();

            showFollowingsMessage?.call(true);
          }
        } else {
          wot = (await nc.calculateWot(
            pubkey: yakihonneHex,
            mutes: nostrRepository.muteModel.usersMutes,
          ))
              .keys
              .toList();

          showFollowingsMessage?.call(true);
        }
      }

      if (wot.isNotEmpty) {
        content = await NostrFunctionsRepository.buildExploreFeed(
          until: until,
          limit: limit ?? 50,
          since: since ?? f.from,
          exploreType: exploreType,
          pubkeys: wot,
        );
      }
    }

    return applyDiscoverFilter(content);
  }

  /// Build the explore feed from relay sources
  ///
  /// If [isAdding] is true, appends to existing content, otherwise replaces it
  /// [exploreType] determines what kind of content to fetch (all, articles, videos, etc.)
  Future<void> buildExploreFeedFromRelays({
    required ExploreType exploreType,
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedDiscoverFilter();

    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getExploreFeedRelayEvents(
      f: f,
      until: until,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          showFollowingListMessage: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<BaseEventModel>> getExploreFeedRelayEvents({
    required DiscoverFilter f,
    int? until,
    int? since,
    int? limit,
  }) async {
    final val = appSettingsManagerCubit.state.selectedDiscoverSource.value;

    final content = await NostrFunctionsRepository.getDiscoverAlgoData(
      relays: val is String ? [val] : (val as UserRelaySet).relays,
      until: until,
      limit: limit ?? 50,
      since: since ?? f.from,
      kinds: [EventKind.LONG_FORM],
    );

    return applyDiscoverFilter(content);
  }

  Future<void> buildExploreFeedFromPacks({
    required ExploreType exploreType,
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedDiscoverFilter();

    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getExploreFeedPacksEvents(
      f: f,
      until: until,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          showFollowingListMessage: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<BaseEventModel>> getExploreFeedPacksEvents({
    required DiscoverFilter f,
    int? until,
    int? since,
    int? limit,
  }) async {
    final val = appSettingsManagerCubit.state.selectedDiscoverSource.value;

    final content = await NostrFunctionsRepository.getDiscoverAlgoData(
      relays: val is String
          ? [val]
          : val is UserRelaySet
              ? val.relays
              : null,
      pubkeys: val is PacksModel ? val.pubkeys.toList() : null,
      until: until,
      limit: limit ?? 50,
      since: since ?? f.from,
      kinds: [EventKind.LONG_FORM],
    );

    return applyDiscoverFilter(content);
  }

  // =============================================================================
  // LIFECYCLE MANAGEMENT
  // =============================================================================
  /// Clean up resources when the cubit is closed
  @override
  Future<void> close() {
    _extraRefreshGeneration++;
    feedStream?.cancel();
    mutesStream?.cancel();
    _extraRefreshController.dispose();
    return super.close();
  }

  // =============================================================================
  // FILTERING & HELPER METHODS
  // =============================================================================
  /// Apply filter settings to the content list based on current app settings
  ///
  /// Returns a filtered list of BaseEventModel objects
  /// [defaultFilter] can be provided to override the app settings filter
  List<BaseEventModel> applyDiscoverFilter(List<BaseEventModel> content,
      {DiscoverFilter? defaultFilter}) {
    final s = appSettingsManagerCubit.state;

    final filteredEvents = <BaseEventModel>[];

    if (s.selectedDiscoverFilter.isNotEmpty) {
      final filter =
          defaultFilter ?? s.discoverFilters[s.selectedDiscoverFilter];

      if (filter != null) {
        for (final ev in content) {
          if (ev is Article &&
              applyArticleFilter(article: ev, filter: filter)) {
            filteredEvents.add(ev);
          } else if (ev is VideoModel &&
              applyVideoFilter(video: ev, filter: filter)) {
            filteredEvents.add(ev);
          } else if (ev is Curation &&
              applyCurationFilter(curation: ev, filter: filter)) {
            filteredEvents.add(ev);
          }
        }

        return filteredEvents;
      } else {
        return content;
      }
    }

    return content;
  }

  /// Apply filter settings to a Curation object
  ///
  /// Returns true if the curation passes the filter criteria
  bool applyCurationFilter({
    required Curation curation,
    required DiscoverFilter filter,
  }) {
    final postedBy = checkPostedBy(
      pubkey: curation.pubkey,
      pubkeys: filter.postedBy,
    );

    final shouldKeep = curation.title != 'ignore' && curation.title != 'test';

    final concatenatedContent =
        '${curation.title} - ${curation.description} - ${curation.tags.join(' - ')}';

    final includeWords = checkIncludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.includedKeywords,
    );

    final excludeWords = checkExcludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.excludedKeywords,
    );

    final hideSensitive = checkSensitive(
      isSensitive: false, // Assuming Curation doesn't have a sensitivity flag
      hideSensitive: filter.hideSensitive,
    );

    final thumbnail = checkThumbnail(
      thumbnail: curation.image,
      includeOnlyThumbnail: filter.inludeThumbnail,
    );

    return shouldKeep &&
        postedBy &&
        includeWords &&
        excludeWords &&
        hideSensitive &&
        thumbnail;
  }

  /// Apply filter settings to a VideoModel object
  ///
  /// Returns true if the video passes the filter criteria
  bool applyVideoFilter({
    required VideoModel video,
    required DiscoverFilter filter,
  }) {
    final postedBy = checkPostedBy(
      pubkey: video.pubkey,
      pubkeys: filter.postedBy,
    );

    final shouldKeep = video.title != 'ignore' && video.title != 'test';

    final concatenatedContent =
        '${video.title} - ${video.summary} - ${video.tags.join(' - ')}';

    final includeWords = checkIncludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.includedKeywords,
    );

    final excludeWords = checkExcludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.excludedKeywords,
    );

    final hideSensitive = checkSensitive(
      isSensitive: video.contentWarning,
      hideSensitive: filter.hideSensitive,
    );

    final thumbnail = checkThumbnail(
      thumbnail: video.thumbnail,
      includeOnlyThumbnail: filter.inludeThumbnail,
    );

    final videoSource = checkVideoSource(
      url: video.url,
      type: filter.videoFilter.source,
    );

    return shouldKeep &&
        videoSource &&
        postedBy &&
        includeWords &&
        excludeWords &&
        hideSensitive &&
        thumbnail;
  }

  /// Apply filter settings to an Article object
  ///
  /// Returns true if the article passes the filter criteria
  bool applyArticleFilter({
    required Article article,
    required DiscoverFilter filter,
  }) {
    final postedBy = checkPostedBy(
      pubkey: article.pubkey,
      pubkeys: filter.postedBy,
    );

    final shouldKeep = article.title != 'ignore' && article.title != 'test';

    final concatenatedContent =
        '${article.title} - ${article.summary} - ${article.content} - ${article.hashTags.join(' - ')}';

    final includeWords = checkIncludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.includedKeywords,
    );

    final excludeWords = checkExcludedWords(
      content: concatenatedContent.toLowerCase(),
      words: filter.excludedKeywords,
    );

    final hideSensitive = checkSensitive(
      isSensitive: article.isSensitive,
      hideSensitive: filter.hideSensitive,
    );

    final thumbnail = checkThumbnail(
      thumbnail: article.image,
      includeOnlyThumbnail: filter.inludeThumbnail,
    );

    final minimumWords =
        countWords(article.content) >= filter.articleFilter.minWords;

    final onlyMedia = checkOnlyMedia(
      content: article.content,
      onlyMedia: filter.articleFilter.onlyMedia,
    );

    return shouldKeep &&
        onlyMedia &&
        minimumWords &&
        postedBy &&
        includeWords &&
        excludeWords &&
        hideSensitive &&
        thumbnail;
  }

  /// Check if a video source matches the filter criteria
  bool checkVideoSource({
    required String url,
    required VideoSourceTypes type,
  }) {
    if (type != VideoSourceTypes.all) {
      if (type == VideoSourceTypes.youtube) {
        return url.contains('youtube.com') || url.contains('youtu.be');
      } else if (type == VideoSourceTypes.vimeo) {
        return url.contains('vimeo.com');
      } else if (type == VideoSourceTypes.others) {
        return !url.contains('youtube.com') &&
            !url.contains('youtu.be') &&
            !url.contains('vimeo.com');
      }
    }

    return true;
  }

  /// Check if content has a thumbnail that matches filter criteria
  bool checkThumbnail({
    required String thumbnail,
    required bool includeOnlyThumbnail,
  }) {
    if (includeOnlyThumbnail) {
      return thumbnail.isNotEmpty;
    }

    return true;
  }

  /// Check if content's sensitivity matches filter criteria
  bool checkSensitive({
    required bool isSensitive,
    required bool hideSensitive,
  }) {
    if (hideSensitive) {
      return !isSensitive;
    }

    return true;
  }

  /// Check if content contains media when required by filter
  bool checkOnlyMedia({
    required String content,
    required bool onlyMedia,
  }) {
    if (onlyMedia) {
      return hasMedia(content);
    }

    return true;
  }

  /// Check if content's author is in the allowed list
  bool checkPostedBy({
    required String pubkey,
    required List<String> pubkeys,
  }) {
    if (pubkeys.isNotEmpty) {
      return pubkeys.contains(pubkey);
    }

    return true;
  }

  /// Check if content contains any excluded words
  bool checkExcludedWords({
    required String content,
    required List<String> words,
  }) {
    if (words.isNotEmpty) {
      return words
          .where(
            (word) => content.contains(word.toLowerCase()),
          )
          .isEmpty;
    }

    return true;
  }

  /// Check if content contains any included words
  bool checkIncludedWords({
    required String content,
    required List<String> words,
  }) {
    if (words.isNotEmpty) {
      return words
          .where(
            (word) => content.contains(word.toLowerCase()),
          )
          .isNotEmpty;
    }

    return true;
  }
}

List<BaseEventModel> applyDiscoverFilter(List<BaseEventModel> content,
    {DiscoverFilter? defaultFilter}) {
  final s = appSettingsManagerCubit.state;

  final filteredEvents = <BaseEventModel>[];

  if (s.selectedDiscoverFilter.isNotEmpty) {
    final filter = defaultFilter ?? s.discoverFilters[s.selectedDiscoverFilter];

    if (filter != null) {
      for (final ev in content) {
        if (ev is Article && applyArticleFilter(article: ev, filter: filter)) {
          filteredEvents.add(ev);
        } else if (ev is VideoModel &&
            applyVideoFilter(video: ev, filter: filter)) {
          filteredEvents.add(ev);
        } else if (ev is Curation &&
            applyCurationFilter(curation: ev, filter: filter)) {
          filteredEvents.add(ev);
        }
      }

      return filteredEvents;
    } else {
      return content;
    }
  }

  return content;
}

bool applyCurationFilter({
  required Curation curation,
  required DiscoverFilter filter,
}) {
  final postedBy = checkPostedBy(
    pubkey: curation.pubkey,
    pubkeys: filter.postedBy,
  );

  final shouldKeep = curation.title != 'ignore' && curation.title != 'test';

  final concatenatedContent =
      '${curation.title} - ${curation.description} - ${curation.tags.join(' - ')}';

  final includeWords = checkIncludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.includedKeywords,
  );

  final excludeWords = checkExcludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.excludedKeywords,
  );

  final hideSensitive = checkSensitive(
    isSensitive: curation.isSensitive,
    hideSensitive: filter.hideSensitive,
  );

  final thumbnail = checkThumbnail(
    thumbnail: curation.image,
    includeOnlyThumbnail: filter.inludeThumbnail,
  );

  final itemCount = curation.eventsIds.length >= filter.curationFilter.minItems;

  return shouldKeep &&
      itemCount &&
      postedBy &&
      includeWords &&
      excludeWords &&
      hideSensitive &&
      thumbnail;
}

bool applyVideoFilter({
  required VideoModel video,
  required DiscoverFilter filter,
}) {
  final postedBy = checkPostedBy(
    pubkey: video.pubkey,
    pubkeys: filter.postedBy,
  );

  final shouldKeep = video.title != 'ignore' && video.title != 'test';

  final concatenatedContent =
      '${video.title} - ${video.summary} - ${video.tags.join(' - ')}';

  final includeWords = checkIncludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.includedKeywords,
  );

  final excludeWords = checkExcludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.excludedKeywords,
  );

  final hideSensitive = checkSensitive(
    isSensitive: video.contentWarning,
    hideSensitive: filter.hideSensitive,
  );

  final thumbnail = checkThumbnail(
    thumbnail: video.thumbnail,
    includeOnlyThumbnail: filter.inludeThumbnail,
  );

  final videoSource = checkVideoSource(
    url: video.url,
    type: filter.videoFilter.source,
  );

  return shouldKeep &&
      videoSource &&
      postedBy &&
      includeWords &&
      excludeWords &&
      hideSensitive &&
      thumbnail;
}

bool applyArticleFilter({
  required Article article,
  required DiscoverFilter filter,
}) {
  final postedBy = checkPostedBy(
    pubkey: article.pubkey,
    pubkeys: filter.postedBy,
  );

  final shouldKeep = article.title != 'ignore' && article.title != 'test';

  final concatenatedContent =
      '${article.title} - ${article.summary} - ${article.content} - ${article.hashTags.join(' - ')}';

  final includeWords = checkIncludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.includedKeywords,
  );

  final excludeWords = checkExcludedWords(
    content: concatenatedContent.toLowerCase(),
    words: filter.excludedKeywords,
  );

  final hideSensitive = checkSensitive(
    isSensitive: article.isSensitive,
    hideSensitive: filter.hideSensitive,
  );

  final thumbnail = checkThumbnail(
    thumbnail: article.image,
    includeOnlyThumbnail: filter.inludeThumbnail,
  );

  final minimumWords =
      countWords(article.content) >= filter.articleFilter.minWords;

  final onlyMedia = checkOnlyMedia(
    content: article.content,
    onlyMedia: filter.articleFilter.onlyMedia,
  );

  return shouldKeep &&
      onlyMedia &&
      minimumWords &&
      postedBy &&
      includeWords &&
      excludeWords &&
      hideSensitive &&
      thumbnail;
}

bool checkVideoSource({
  required String url,
  required VideoSourceTypes type,
}) {
  if (type != VideoSourceTypes.all) {
    if (type == VideoSourceTypes.youtube) {
      return url.contains('youtube.com') || url.contains('youtu.be');
    } else if (type == VideoSourceTypes.vimeo) {
      return url.contains('vimeo.com');
    } else if (type == VideoSourceTypes.others) {
      return !url.contains('youtube.com') &&
          !url.contains('youtu.be') &&
          !url.contains('vimeo.com');
    }
  }

  return true;
}

bool checkThumbnail({
  required String thumbnail,
  required bool includeOnlyThumbnail,
}) {
  if (includeOnlyThumbnail) {
    return thumbnail.isNotEmpty;
  }

  return true;
}

bool checkSensitive({
  required bool isSensitive,
  required bool hideSensitive,
}) {
  if (hideSensitive) {
    return !isSensitive;
  }

  return true;
}

bool checkOnlyMedia({
  required String content,
  required bool onlyMedia,
}) {
  if (onlyMedia) {
    return hasMedia(content);
  }

  return true;
}

bool checkPostedBy({
  required String pubkey,
  required List<String> pubkeys,
}) {
  if (pubkeys.isNotEmpty) {
    return pubkeys.contains(pubkey);
  }

  return true;
}

bool checkExcludedWords({
  required String content,
  required List<String> words,
}) {
  if (words.isNotEmpty) {
    return words
        .where(
          (word) => content.contains(word.toLowerCase()),
        )
        .isEmpty;
  }

  return true;
}

bool checkIncludedWords({
  required String content,
  required List<String> words,
}) {
  if (words.isNotEmpty) {
    return words
        .where(
          (word) => content.contains(word.toLowerCase()),
        )
        .isNotEmpty;
  }

  return true;
}
