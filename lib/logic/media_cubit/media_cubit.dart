import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../models/packs_model.dart';
import '../../models/picture_model.dart';
import '../../models/relays_feed.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';
import '../feed_extra_refresh_controller.dart';

part 'media_state.dart';

class MediaCubit extends Cubit<MediaState> {
  MediaCubit()
      : super(
          MediaState(
            content: const [],
            extraContent: const [],
            onLoading: true,
            onAddingData: UpdatingState.idle,
            refresh: false,
            selectedSource:
                appSettingsManagerCubit.getMediaSelectedSource().key,
          ),
        );

  late StreamSubscription feedStream;
  late StreamSubscription mutesStream;
  late final FeedExtraRefreshController _extraRefreshController =
      FeedExtraRefreshController(onRefresh: _fetchExtraContent);
  int _extraRefreshGeneration = 0;
  bool _streamsInitialized = false;
  Future<void>? _initialization;
  bool _isFeedActive = false;
  bool _isAppResumed = true;
  bool _isRestoringSnapshot = false;
  bool _hasInitialized = false;
  bool _pendingCustomizationRefresh = false;
  Future<void> _feedSnapshotPersistence = Future<void>.value();
  // =============================================================================
  // STREAMS & LISTENERS
  // =============================================================================
  void _initializeStreams() {
    if (_streamsInitialized) {
      return;
    }
    _streamsInitialized = true;

    // Listen for app customization changes
    feedStream = nostrRepository.appCustomizationStream.listen(
      (appCustom) async {
        if (!_canRefreshForCustomization) {
          _pendingCustomizationRefresh = true;
          return;
        }

        await Future.delayed(const Duration(seconds: 1));

        if (!_canRefreshForCustomization) {
          _pendingCustomizationRefresh = true;
          return;
        }

        _refreshAfterCustomization();
      },
    );

    // Listen for mutes changes
    mutesStream = nostrRepository.mutesStream.listen(
      (mm) {
        final newContent = List<BaseEventModel>.from(state.content)
          ..removeWhere((e) => isUserMuted(e.pubkey));

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
  // PUBLIC METHODS
  // =============================================================================
  /// Start the Media feed the first time its tab is selected.
  Future<void> ensureInitialized({bool restoreSnapshot = false}) =>
      _initialization ??= _initialize(restoreSnapshot: restoreSnapshot);

  void setFeedActive(bool active) {
    _isFeedActive = active;
    if (!active) {
      _extraRefreshGeneration++;
    } else {
      _refreshAfterPendingCustomization();
    }
    _extraRefreshController.setFeedActive(active);
  }

  void setAppResumed(bool resumed) {
    _isAppResumed = resumed;
    if (!resumed) {
      _extraRefreshGeneration++;
    } else {
      _refreshAfterPendingCustomization();
    }
    _extraRefreshController.setAppResumed(resumed);
  }

  Future<void> _initialize({required bool restoreSnapshot}) async {
    if (isClosed) {
      return;
    }

    _initializeStreams();
    final restored = restoreSnapshot && await _restoreCachedFeed();
    if (!restored) {
      await buildMediaFeed(isAdding: false);
    }
    _hasInitialized = true;
    _pendingCustomizationRefresh = false;
  }

  bool get _canRefreshForCustomization =>
      _hasInitialized && _isFeedActive && _isAppResumed && !isClosed;

  void _refreshAfterPendingCustomization() {
    if (!_pendingCustomizationRefresh || !_canRefreshForCustomization) {
      return;
    }

    _refreshAfterCustomization();
  }

  void _refreshAfterCustomization() {
    _pendingCustomizationRefresh = false;
    emit(state.copyWith(refresh: !state.refresh));
    unawaited(buildMediaFeed(isAdding: false));
  }

  Future<bool> _restoreCachedFeed() async {
    final owner = currentSigner?.getPublicKey() ?? '';
    final savedIds = localDatabaseRepository.getMainViewFeedSnapshot(
      owner,
      'media',
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
      final content = applyMediaFilter(orderedEvents, removeMuted: true);
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
      lg.i('Unable to restore the cached media feed: $error');
      return false;
    }
  }

  @override
  void onChange(Change<MediaState> change) {
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
        'media',
        nextIds,
      );
    });
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
        appSettingsManagerCubit.getMediaSelectedSource();
    final f = appSettingsManagerCubit.getSelectedMediaFilter();
    final since = first.createdAt.toSecondsSinceEpoch() + 1;

    List<BaseEventModel> content = [];
    if (currentSelectedSource.key == AppContentSource.community) {
      content = await getMediaFeedCommunityEvents(
        since: since,
        limit: 20,
        f: f,
      );

      if (isClosed || generation != _extraRefreshGeneration) {
        return;
      }

      final source = appSettingsManagerCubit.state.selectedDiscoverSource;
      if (source.value == SOURCE_RECENT) {
        final globalIds = state.content.map((event) => event.id).toSet();
        content.removeWhere((event) => globalIds.contains(event.id));
      }
    } else if (currentSelectedSource.key == AppContentSource.packs) {
      content = await getMediaFeedPacksEvents(
        since: since,
        limit: 20,
      );
    } else if (currentSelectedSource.key == AppContentSource.relay) {
      content = await getMediaFeedRelayEvents(
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

  Future<void> buildMediaFeed({
    required bool isAdding,
  }) async {
    final currentSelectedSource =
        appSettingsManagerCubit.getMediaSelectedSource();

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
      await buildMediaFeedFromCommunity(
        isAdding: isAdding,
      );
    } else if (currentSelectedSource.key == AppContentSource.packs) {
      await buildMediaFeedFromPacks(
        isAdding: isAdding,
      );
    } else {
      await buildMediaFeedFromRelays(
        isAdding: isAdding,
      );
    }

    getExtra();
  }

  Future<void> buildMediaFeedFromRelays({
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedMediaFilter();

    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getMediaFeedRelayEvents(
      f: f,
      until: until,
      limit: 50,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<BaseEventModel>> getMediaFeedRelayEvents({
    required MediaFilter f,
    int? until,
    int? since,
    int? limit,
  }) async {
    final val = appSettingsManagerCubit.state.selectedMediaSource.value;

    final content = await NostrFunctionsRepository.getMediaRelayData(
      relays: val != null
          ? val is String
              ? [val]
              : (val as UserRelaySet).relays
          : [],
      until: until,
      limit: 50,
      since: since,
    );

    return applyMediaFilter(content, removeMuted: true);
  }

  Future<List<BaseEventModel>> getMediaFeedPacksEvents({
    int? until,
    int? since,
    int? limit,
  }) async {
    final val = appSettingsManagerCubit.state.selectedMediaSource.value;

    final content = await NostrFunctionsRepository.getMediaPacksData(
      pubkeys: val is PacksModel ? val.pubkeys.toList() : [],
      until: until,
      limit: 50,
      since: since,
    );

    return applyMediaFilter(content, removeMuted: true);
  }

  Future<void> buildMediaFeedFromCommunity({
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedMediaFilter();
    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getMediaFeedCommunityEvents(
      f: f,
      until: until,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<void> buildMediaFeedFromPacks({
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedMediaFilter();
    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
            : null;

    final filtered = await getMediaFeedPacksEvents(
      until: until,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered].capFeed(),
          onLoading: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<BaseEventModel>> getMediaFeedCommunityEvents({
    required MediaFilter f,
    int? until,
    int? since,
    int? limit,
  }) async {
    final source = appSettingsManagerCubit.state.selectedMediaSource;
    List<Event> content = [];
    List<String>? pubkeys;

    final usePubkeys = source.value == SOURCE_RECENT || f.postedBy.isNotEmpty;

    if (usePubkeys) {
      Set<String> contacts = {};

      if (f.postedBy.isNotEmpty) {
        contacts = f.postedBy.toSet();
      } else {
        contacts = canSign()
            ? (await contactListCubit.contactsAsync()).toSet()
            : <String>{};

        if (contacts.length <= 5) {
          final yakiContacts =
              (await contactListCubit.loadContactList(yakihonneHex))
                      ?.contacts
                      .toSet() ??
                  {};

          contacts.addAll(yakiContacts);
        }
      }

      pubkeys = [
        ...contacts,
        if (canSign() && f.postedBy.isEmpty) currentSigner!.getPublicKey(),
      ];
    }

    content = await NostrFunctionsRepository.buildMediaFeed(
      until: until,
      limit: limit ?? 50,
      pubkeys: pubkeys,
      since: since ?? f.from,
    );

    return applyMediaFilter(content);
  }

  List<BaseEventModel> applyMediaFilter(
    List<Event> content, {
    bool removeMuted = false,
  }) {
    if (canSign() && removeMuted) {
      content.removeWhere(
        (element) => isUserMuted(element.pubkey),
      );
    }

    final s = appSettingsManagerCubit.state;

    if (s.selectedMediaFilter.isEmpty) {
      return content
          .map(
            (e) => VideoModel.isVideo(e.kind)
                ? VideoModel.fromEvent(e)
                : PictureModel.fromEvent(e),
          )
          .toList();
    }

    final filter = s.mediaFilters[s.selectedMediaFilter];

    if (filter == null) {
      return content
          .map(
            (e) => VideoModel.isVideo(e.kind)
                ? VideoModel.fromEvent(e)
                : PictureModel.fromEvent(e),
          )
          .toList();
    }

    return content
        .where((ev) => _canBeAdded(ev, filter))
        .map(
          (e) => VideoModel.isVideo(e.kind)
              ? VideoModel.fromEvent(e)
              : PictureModel.fromEvent(e),
        )
        .toList();
  }

  /// Determines if an [Event] passes all filter criteria.
  /// Returns true if it passes included/excluded words, postedBy, and onlyMedia checks.
  bool _canBeAdded(Event ev, MediaFilter filter) {
    final content = _concatenateEventContent(ev);
    return _checkIncludedWords(content, filter.includedKeywords) &&
        _checkExcludedWords(content, filter.excludedKeywords) &&
        _checkPostedBy(ev.pubkey, filter.postedBy) &&
        checkSensitive(
            isSensitive: VideoModel.isVideo(ev.kind)
                ? VideoModel.fromEvent(ev).contentWarning
                : PictureModel.fromEvent(ev).hasContentWarning,
            hideSensitive: filter.hideSensitive);
  }

  /// Concatenates event content and tags for keyword filtering.
  String _concatenateEventContent(Event ev) {
    return '${ev.content} - ${ev.tags.map((e) => e.length > 1 ? e[1] : '').join(' - ')}'
        .toLowerCase();
  }

  /// Returns true if all [words] are found in [content]. If [words] is empty, returns true.
  bool _checkIncludedWords(String content, List<String> words) {
    if (words.isEmpty) {
      return true;
    }
    return words.any((word) => content.contains(word.toLowerCase()));
  }

  /// Returns true if none of [words] are found in [content]. If [words] is empty, returns true.
  bool _checkExcludedWords(String content, List<String> words) {
    if (words.isEmpty) {
      return true;
    }
    return words.every((word) => !content.contains(word.toLowerCase()));
  }

  /// Returns true if [pubkeys] is empty or [pubkey] is in [pubkeys].
  bool _checkPostedBy(String pubkey, List<String> pubkeys) {
    if (pubkeys.isEmpty) {
      return true;
    }
    return pubkeys.contains(pubkey);
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

  void resetExtra() {
    _extraRefreshController.reset();
  }

  @override
  Future<void> close() async {
    _extraRefreshGeneration++;
    _extraRefreshController.dispose();
    if (_streamsInitialized) {
      await feedStream.cancel();
      await mutesStream.cancel();
    }
    return super.close();
  }
}
