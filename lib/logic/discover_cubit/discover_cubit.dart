import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

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
            mutes: nostrRepository.mutes.toList(),
            onAddingData: UpdatingState.success,
            onLoading: true,
            followings: contactListCubit.contacts,
            refresh: false,
            extraContent: const [],
            showFollowingListMessage: false,
            selectedSource:
                appSettingsManagerCubit.getDiscoverSelectedSource().key,
          ),
        ) {
    init();
  }
  // =============================================================================
  // PROPERTIES
  // =============================================================================
  StreamSubscription? feedStream;
  StreamSubscription? mutesStream;
  Timer? currentExtraTimer;
  ExploreType exploreType = ExploreType.all;
  final extraIds = <String>{};

  // =============================================================================
  // PUBLIC METHODS
  // =============================================================================
  /// Initialize the cubit with data and set up streams
  Future<void> init() async {
    Future.delayed(const Duration(seconds: 1)).then(
      (_) {
        // Initialize suggestions
        suggestionsBoxCubit.initDiscover();

        // Build initial feed
        buildDiscoverFeed(
          exploreType: ExploreType.all,
          isAdding: false,
        );

        // Set up streams
        _setupStreams();
      },
    );
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
      (mutes) {
        final newContent = List<BaseEventModel>.from(state.content)
          ..removeWhere(
            (e) => mutes.contains(e.pubkey),
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
  Future<void> getExtra() async {
    if (currentExtraTimer != null) {
      currentExtraTimer?.cancel();
    }

    currentExtraTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (state.content.isNotEmpty) {
          final first = state.extraContent.isNotEmpty
              ? state.extraContent.first
              : state.content.first;

          final currentSelectedSource =
              appSettingsManagerCubit.getDiscoverSelectedSource();

          final f = appSettingsManagerCubit.getSelectedDiscoverFilter();

          List<BaseEventModel> content = [];

          if (currentSelectedSource.key == AppContentSource.community) {
            content = await getExploreFeedCommunityEvents(
              since: first.createdAt.toSecondsSinceEpoch() + 1,
              limit: 20,
              f: f,
            );

            final source = appSettingsManagerCubit.state.selectedDiscoverSource;

            if (source.value == SOURCE_TOP) {
              final globalIds = state.content.map((e) => e.id).toSet();
              content.removeWhere((e) => globalIds.contains(e.id));
            }
          } else if (currentSelectedSource.key == AppContentSource.algo) {
            content = await getExploreFeedRelayEvents(
              since: first.createdAt.toSecondsSinceEpoch() + 1,
              limit: 20,
              f: f,
            );
          }

          if (content.isNotEmpty) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  extraContent: [...content, ...state.extraContent],
                  onLoading: false,
                  onAddingData: content.isEmpty
                      ? UpdatingState.idle
                      : UpdatingState.success,
                ),
              );
            }
          }
        }
      },
    );
  }

  void resetExtra() {
    currentExtraTimer?.cancel();
    getExtra();
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
    } else if (currentSelectedSource.key == AppContentSource.algo) {
      await buildExploreFeedFromRelays(
        exploreType: exploreType,
        isAdding: isAdding,
      );
    } else if (currentSelectedSource.key == AppContentSource.dvm) {
      await buildExploreFeedFromDvm();
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
          content: [...state.content, ...filtered],
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
            mutes: nostrRepository.mutes,
          ))
              .keys
              .toList();

          if (wot.isEmpty) {
            wot = (await nc.calculateWot(
              pubkey: yakihonneHex,
              mutes: nostrRepository.mutes,
            ))
                .keys
                .toList();

            showFollowingsMessage?.call(true);
          }
        } else {
          wot = (await nc.calculateWot(
            pubkey: yakihonneHex,
            mutes: nostrRepository.mutes,
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
          content: [...state.content, ...filtered],
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
    final content = await NostrFunctionsRepository.getDiscoverAlgoData(
      url: appSettingsManagerCubit.state.selectedDiscoverSource.value,
      until: until,
      limit: limit ?? 50,
      since: since ?? f.from,
      kinds: [
        if (exploreType == ExploreType.articles ||
            exploreType == ExploreType.all)
          EventKind.LONG_FORM,
        if (exploreType == ExploreType.videos ||
            exploreType == ExploreType.all) ...[
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL
        ],
        if (exploreType == ExploreType.curations ||
            exploreType == ExploreType.all) ...[
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
      ],
    );

    return applyDiscoverFilter(content);
  }

  /// Build the explore feed from DVM (Decentralized Virtual Machine) data
  Future<void> buildExploreFeedFromDvm() async {
    final content = await NostrFunctionsRepository.getDiscoverDvmData(
      pubkey: appSettingsManagerCubit.state.selectedDiscoverSource.key,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: applyDiscoverFilter(content),
          onLoading: false,
          onAddingData: UpdatingState.idle,
        ),
      );
    }
  }

  // =============================================================================
  // LIFECYCLE MANAGEMENT
  // =============================================================================
  /// Clean up resources when the cubit is closed
  @override
  Future<void> close() {
    feedStream?.cancel();
    mutesStream?.cancel();
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
