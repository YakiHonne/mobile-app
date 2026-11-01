import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../models/article_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/topic.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'suggestions_box_state.dart';

class SuggestionsBoxCubit extends Cubit<SuggestionsBoxState> {
  SuggestionsBoxCubit()
      : super(
          const SuggestionsBoxState(
            articles: [],
            notes: [],
            trendingUsers24: [],
            suggestions: [],
          ),
        ) {
    contactList = nostrRepository.contactListStream.listen(
      (contacts) {
        final trending = List<Metadata>.from(state.trendingUsers24);

        final filtered = trending
            .where(
              (e) => !contacts.contains(e.pubkey),
            )
            .toList();
        if (!isClosed) {
          emit(
            state.copyWith(
              trendingUsers24: filtered,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription contactList;
  final Map<String, Future<void>> _inFlightRequests = {};
  bool _leadingInitialized = false;
  bool _trendingUsers24Loaded = false;

  Future<void> _deduplicateRequest(
    String key,
    Future<void> Function() request,
  ) {
    final current = _inFlightRequests[key];
    if (current != null) {
      return current;
    }

    late final Future<void> pending;
    pending = request().whenComplete(() {
      if (identical(_inFlightRequests[key], pending)) {
        _inFlightRequests.remove(key);
      }
    });
    _inFlightRequests[key] = pending;
    return pending;
  }

  void initLeading({String? tag}) {
    if (_leadingInitialized) {
      return;
    }
    _leadingInitialized = true;

    getTrendingUser24();
    getSuggestions();
    getLatestArticles(tag: tag);
  }

  void initDiscover({String? tag}) {
    getTrendingUser24();
    getSuggestions();

    if (tag != null) {
      getNotesFromTags(tag);
    } else {
      getTrendingNotes1H();
    }
  }

  Future<void> getTrendingUser24() {
    if (_trendingUsers24Loaded) {
      return Future<void>.value();
    }
    return _deduplicateRequest('trendingUsers24', _loadTrendingUser24);
  }

  Future<void> _loadTrendingUser24() async {
    final users = await NostrFunctionsRepository.getRcTrendingUsers24();
    _trendingUsers24Loaded = true;
    final currentContacts = contactListCubit.contacts;
    if (!isClosed) {
      emit(
        state.copyWith(
          trendingUsers24: users
              .where(
                (u) => !currentContacts.contains(u.pubkey),
              )
              .toList(),
        ),
      );
    }
  }

  Future<void> getTrendingNotes1H() async {
    final notes = await NostrFunctionsRepository.getRcTrendingNotes1H();
    if (!isClosed) {
      emit(
        state.copyWith(
          notes: notes,
        ),
      );
    }
  }

  Future<void> getNotesFromTags(String tag) async {
    final notes = await NostrFunctionsRepository.getRcNotesFromTags(tag);
    if (!isClosed) {
      emit(
        state.copyWith(
          notes: notes,
        ),
      );
    }
  }

  void getSuggestions() {
    final selectedTopics = <String, Topic>{};

    final ts = nostrRepository.topics
        .where(
          (topic) =>
              !nostrRepository.interests.contains(topic.topic.toLowerCase()),
        )
        .toList();

    final random = Random();

    for (int i = 0; i < 5; i++) {
      if (ts.isNotEmpty) {
        final num = random.nextInt(ts.length);

        if (num >= 0 && num < ts.length) {
          final topic = ts[num];
          selectedTopics[topic.topic] = topic;
        }
      }
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          suggestions: selectedTopics.values.toList(),
        ),
      );
    }
  }

  Future<void> setInterest(String interest) async {
    final isSuccesful = await nostrRepository.setInterest(
      interest.toLowerCase(),
    );

    final interests = List<Topic>.from(state.suggestions)
      ..removeWhere(
        (element) {
          return element.topic.toLowerCase() == interest.toLowerCase();
        },
      );

    if (isSuccesful) {
      if (!isClosed) {
        emit(
          state.copyWith(suggestions: interests),
        );
      }
    }
  }

  Future<void> getLatestArticles({String? tag}) => _deduplicateRequest(
        tag == null ? 'latestArticles:default' : 'latestArticles:tag:$tag',
        () => _loadLatestArticles(tag: tag),
      );

  Future<void> _loadLatestArticles({String? tag}) async {
    final selectedTopics = <String>[];
    if (tag == null) {
      final t = nostrRepository.topics;
      final random = Random();

      for (int i = 0; i < 3; i++) {
        final topic = t[random.nextInt(t.length)];

        selectedTopics.addAll([topic.topic, ...topic.subTopics]);
      }
    } else {
      selectedTopics.add(tag);
    }

    final content = await NostrFunctionsRepository.buildLeadingMedia(
      includeVideos: false,
      limit: 10,
      tags: selectedTopics,
    );

    final filtered = content
        .where(
          (e) => e is Article && e.title.isNotEmpty && e.image.isNotEmpty,
        )
        .toList();
    if (!isClosed) {
      emit(
        state.copyWith(
          articles: filtered
              .map(
                (e) => e as Article,
              )
              .toList(),
        ),
      );
    }
  }

  Future<void> setFollowingState({
    required String pubkey,
  }) async {
    final cancel = BotToastUtils.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: false,
      targetPubkey: pubkey,
    );

    cancel.call();
  }

  @override
  Future<void> close() {
    contactList.cancel();
    return super.close();
  }
}
