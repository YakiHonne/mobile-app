import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/flash_news_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'leading_state.dart';

// =============================================================================
// LEADING CUBIT: State management for the Leading Feed and related features
// =============================================================================
class LeadingCubit extends Cubit<LeadingState> {
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  LeadingCubit()
      : super(
          LeadingState(
            content: const <Event>[],
            extraContent: const [],
            onContentLoading: true,
            onAddingData: UpdatingState.success,
            media: const <BaseEventModel>[],
            onMediaLoading: true,
            commonFeedTypes: nostrRepository.getLeadingFeedTypes(),
            showSuggestions: nostrRepository.getLeadingShowSuggestions(),
            refresh: false,
            showFollowingListMessage: false,
            selectedSource:
                appSettingsManagerCubit.getNotesSelectedSource().key,
          ),
        ) {
    _initializeStreams();
    initView();
  }

  // =============================================================================
  // PROPERTIES
  // =============================================================================
  late StreamSubscription feedStream;
  late StreamSubscription mutesStream;
  final extraIds = <String>{};
  int? score;
  Timer? currentExtraTimer;

  // =============================================================================
  // STREAMS & LISTENERS
  // =============================================================================
  void _initializeStreams() {
    // Listen for app customization changes
    feedStream = nostrRepository.appCustomizationStream.listen(
      (appCustom) {
        if (!isClosed) {
          emit(
            state.copyWith(
              commonFeedTypes: nostrRepository.getLeadingFeedTypes(),
              showSuggestions: nostrRepository.getLeadingShowSuggestions(),
              refresh: !state.refresh,
              onContentLoading: true,
            ),
          );
        }

        buildLeadingFeed(
          isAdding: false,
        );
      },
    );

    // Listen for mutes changes
    mutesStream = nostrRepository.mutesStream.listen(
      (mutes) {
        final newContent = List<Event>.from(state.content)
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
  // PUBLIC METHODS
  // =============================================================================
  /// Initialize the view with data and suggestions
  Future<void> initView() async {
    if (nostrRepository.delayLeading) {
      await Future.delayed(const Duration(seconds: 1));
      nostrRepository.delayLeading = false;
    }

    fetchMedia();

    buildLeadingFeed(
      isAdding: false,
    );

    suggestionsBoxCubit.initLeading();
  }

  void onRemoveMutedContent(String pubkey) {
    if (!isClosed) {
      final newContent = List<Event>.from(state.content)
        ..removeWhere((e) {
          if (e.kind == EventKind.REPOST) {
            try {
              final repost = Event.fromJson(jsonDecode(e.content));

              return repost.pubkey == pubkey;
            } catch (_) {
              return false;
            }
          } else {
            return e.pubkey == pubkey;
          }
        });

      emit(
        state.copyWith(
          content: newContent,
          refresh: !state.refresh,
        ),
      );
    }
  }

  /// Clear the current data and reset state for the given source
  /// Clear all content and reset state for a given source
  void clearData(AppContentSource source) {
    extraIds.clear();
    currentExtraTimer?.cancel();
    if (!isClosed) {
      emit(
        state.copyWith(
          content: [],
          onAddingData: UpdatingState.success,
          onContentLoading: true,
          selectedSource: source,
          showFollowingListMessage: false,
          extraContent: [],
        ),
      );
    }
  }

  /// Fetch media content for the leading view
  /// Fetch media content for the leading view
  Future<void> fetchMedia() async {
    final content = await NostrFunctionsRepository.buildExploreFeedFromGeneric(
      exploreType: ExploreType.articles,
      limit: 5,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          media: content,
          onMediaLoading: false,
        ),
      );
    }
  }

  /// Manage extra content
  Future<void> getExtra() async {
    currentExtraTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (state.content.isNotEmpty) {
          final first = state.extraContent.isNotEmpty
              ? state.extraContent.first
              : state.content.first;

          final currentSelectedSource =
              appSettingsManagerCubit.getNotesSelectedSource();

          final f = appSettingsManagerCubit.getSelectedNotesFilter();

          List<Event> content = [];

          final since = first.createdAt + 1;

          if (currentSelectedSource.key == AppContentSource.community) {
            content = await getLeadingFeedCommunityEvents(
              since: since,
              limit: 20,
              f: f,
              isExtra: true,
            );
          } else if (currentSelectedSource.key == AppContentSource.algo) {
            content = await getLeadingFeedRelayEvents(
              since: since,
              limit: 20,
              f: f,
            );
          }

          content.removeWhere((e) {
            final exists = extraIds.contains(e.id);

            if (!exists) {
              extraIds.add(e.id);
            }

            return exists;
          });

          if (content.isNotEmpty) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  extraContent: [...content, ...state.extraContent],
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

  Future<void> appendExtra(Function scrollToPosition) async {
    final allContent = [
      ...state.extraContent,
      ...state.content,
    ];

    if (!isClosed) {
      extraIds.clear();

      emit(
        state.copyWith(
          content: [],
          extraContent: [],
        ),
      );

      scrollToPosition.call();
      // await Future.delayed(const Duration(milliseconds: 300));
      emit(
        state.copyWith(
          content: allContent,
        ),
      );
    }
  }

  void resetExtra() {
    currentExtraTimer?.cancel();
    getExtra();
  }

  // =============================================================================
  // FEED BUILDING METHODS
  // =============================================================================
  /// Build the leading feed based on the selected source
  Future<void> buildLeadingFeed({
    required bool isAdding,
  }) async {
    final currentSelectedSource =
        appSettingsManagerCubit.getNotesSelectedSource();

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
      await buildLeadingFeedFromCommunity(
        isAdding: isAdding,
      );
    } else if (currentSelectedSource.key == AppContentSource.algo) {
      await buildLeadingFeedFromRelays(
        isAdding: isAdding,
      );
    } else if (currentSelectedSource.key == AppContentSource.dvm) {
      await buildLeadingFeedFromDvm();
    }

    getExtra();
  }

  /// Build the leading feed from community sources
  ///
  /// If [isAdding] is true, appends to existing content, otherwise replaces it
  /// Build the leading feed from community sources
  Future<void> buildLeadingFeedFromCommunity({
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedNotesFilter();
    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt - 1
            : null;

    final events = await getLeadingFeedCommunityEvents(
      f: f,
      until: until,
      limit: 50,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: events,
          onContentLoading: false,
          onAddingData:
              events.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<Event>> getLeadingFeedCommunityEvents({
    required NotesFilter f,
    int? until,
    int? since,
    int? limit,
    bool isExtra = false,
  }) async {
    List<Event> content = [];
    final source = appSettingsManagerCubit.state.selectedNotesSource;
    List<String>? pubkeys;

    final type = source.value == SOURCE_GLOBAL
        ? CommonFeedTypes.global
        : source.value == SOURCE_RECENT
            ? CommonFeedTypes.recent
            : source.value == SOURCE_RECENT_WITH_REPLIES
                ? CommonFeedTypes.recentWithReplies
                : source.value == SOURCE_PAID
                    ? CommonFeedTypes.paid
                    : CommonFeedTypes.widgets;

    final usePubkeys = type == CommonFeedTypes.recent ||
        type == CommonFeedTypes.recentWithReplies ||
        f.postedBy.isNotEmpty;

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

          emit(state.copyWith(showFollowingListMessage: true));

          contacts.addAll(yakiContacts);
        }
      }

      pubkeys = [
        ...contacts,
        if (canSign() && f.postedBy.isEmpty) currentSigner!.getPublicKey(),
      ];
    }

    content = await NostrFunctionsRepository.buildLeadingRelaysFeed(
      until: until,
      limit: limit ?? 51,
      type: type,
      pubkeys: pubkeys,
      since: since ?? f.from,
    );

    final filtered = applyNotesFilter(content);

    return isExtra ? filtered : processEvents(state.content, filtered);
  }

  /// Build the leading feed from relay sources
  ///
  /// If [isAdding] is true, appends to existing content, otherwise replaces it
  /// Build the leading feed from relay sources
  Future<void> buildLeadingFeedFromRelays({
    required bool isAdding,
  }) async {
    final f = appSettingsManagerCubit.getSelectedNotesFilter();

    final until = (!isAdding && f.to != null)
        ? f.to
        : state.content.isNotEmpty
            ? state.content.last.createdAt - 1
            : null;

    final filtered = await getLeadingFeedRelayEvents(
      f: f,
      until: until,
      limit: 50,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...filtered],
          onContentLoading: false,
          onAddingData:
              filtered.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  Future<List<Event>> getLeadingFeedRelayEvents({
    required NotesFilter f,
    int? until,
    int? since,
    int? limit,
  }) async {
    final content = await NostrFunctionsRepository.getLeadingAlgoData(
      url: appSettingsManagerCubit.state.selectedNotesSource.value,
      until: until,
      limit: 50,
      since: since,
    );

    return applyNotesFilter(content, removeMuted: true);
  }

  /// Build the leading feed from DVM (Decentralized Virtual Machine) data
  /// Build the leading feed from DVM (Decentralized Virtual Machine) data
  Future<void> buildLeadingFeedFromDvm() async {
    final content = await NostrFunctionsRepository.getLeadingDvmData(
      pubkey: appSettingsManagerCubit.state.selectedNotesSource.key,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: applyNotesFilter(content),
          onContentLoading: false,
          onAddingData: UpdatingState.idle,
        ),
      );
    }
  }

  // =============================================================================
  // EVENT PROCESSING
  // =============================================================================
  /// Process and merge older and newer events, handling deletions and replacements
  List<Event> processEvents(List<Event> olderEvents, List<Event> newEvents) {
    final Map<String, Event> olderEventsById = {
      for (final event in olderEvents) event.id: event
    };

    final Map<String, List<Event>> olderEventsByETag = {};

    for (final event in olderEvents) {
      for (final eTag in event.eTags) {
        olderEventsByETag.putIfAbsent(eTag, () => []).add(event);
      }
    }

    final List<Event> result = List.from(olderEvents);
    final Set<String> idsToRemove = {};
    final Map<String, Event> processedNewEventsById = {};
    final Map<String, List<Event>> processedNewEventsByETag = {};

    for (final newEvent in newEvents) {
      if (newEvent.kind == 6) {
        final eTag = newEvent.eTags.isNotEmpty ? newEvent.eTags.first : null;
        if (eTag != null) {
          if (olderEventsById.containsKey(eTag) &&
              olderEventsById[eTag]!.kind == 1) {
            idsToRemove.add(eTag);
          }

          if (processedNewEventsById.containsKey(eTag) &&
              processedNewEventsById[eTag]!.kind == 1) {
            idsToRemove.add(eTag);
          }

          if (olderEventsByETag.containsKey(eTag)) {
            for (final event in olderEventsByETag[eTag]!) {
              if (event.kind == 6) {
                idsToRemove.add(event.id);
              }
            }
          }

          if (processedNewEventsByETag.containsKey(eTag)) {
            for (final event in processedNewEventsByETag[eTag]!) {
              if (event.kind == 6) {
                idsToRemove.add(event.id);
              }
            }
          }
        }
      }

      result.add(newEvent);
      processedNewEventsById[newEvent.id] = newEvent;

      for (final eTag in newEvent.eTags) {
        processedNewEventsByETag.putIfAbsent(eTag, () => []).add(newEvent);
      }
    }

    result.retainWhere((event) => !idsToRemove.contains(event.id));

    return result;
  }

  // =============================================================================
  // LIFECYCLE MANAGEMENT
  // =============================================================================
  /// Clean up resources when the cubit is closed
  @override
  Future<void> close() {
    feedStream.cancel();
    mutesStream.cancel();
    // Note: score is an int, not a StreamSubscription
    return super.close();
  }

  // =============================================================================
  // FILTERING & NOTES HELPER METHODS
  // =============================================================================
  /// Filters a list of [Event]s using the current appSettingsManagerCubit filter.
  ///
  /// Returns only events that pass all filter criteria. If no filter is selected, returns [content] unchanged.
  List<Event> applyNotesFilter(
    List<Event> content, {
    bool removeMuted = false,
  }) {
    if (canSign() && removeMuted) {
      content.removeWhere(
        (element) => isUserMuted(element.pubkey),
      );
    }

    final s = appSettingsManagerCubit.state;
    if (s.selectedNotesFilter.isEmpty) {
      return content;
    }
    final filter = s.notesFilters[s.selectedNotesFilter];
    if (filter == null) {
      return content;
    }
    return content.where((ev) => _canBeAdded(ev, filter)).toList();
  }

  /// Determines if an [Event] passes all filter criteria.
  /// Returns true if it passes included/excluded words, postedBy, and onlyMedia checks.
  bool _canBeAdded(Event ev, NotesFilter filter) {
    final content = _concatenateEventContent(ev);
    return _checkIncludedWords(content, filter.includedKeywords) &&
        _checkExcludedWords(content, filter.excludedKeywords) &&
        _checkPostedBy(ev.pubkey, filter.postedBy) &&
        _checkOnlyMedia(ev.content, filter.onlyMedia);
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

  /// Returns true if [onlyMedia] is false, or if true, [content] contains media.
  bool _checkOnlyMedia(String content, bool onlyMedia) {
    if (!onlyMedia) {
      return true;
    }
    return hasMedia(content);
  }
}
