// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/bookmark_list_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required this.context,
  }) : super(
          SearchState(
            content: const <dynamic>[],
            authors: const <Metadata>[],
            contentSearchResult: SearchResultsType.noSearch,
            profileSearchResult: SearchResultsType.noSearch,
            search: '',
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            refresh: false,
            interests: nostrRepository.interests,
            relayConnectivity: RelayConnectivity.idle,
            isSearching: false,
          ),
        ) {
    _initializeSubscriptions();
  }

  // Properties
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubscription;
  final BuildContext context;
  Timer? searchOnStoppedTyping;
  String requestId = '';
  Set<String> requests = <String>{};

  // Initialization
  void _initializeSubscriptions() {
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (Map<String, BookmarkListModel> bookmarks) {
        _emit(bookmarks: getBookmarkIds(bookmarks).toSet());
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        _emit(
          content: state.content
              .where((t) => t is Article && !mm.usersMutes.contains(t.pubkey))
              .toList(),
          authors: state.authors
              .where(
                  (Metadata author) => !mm.usersMutes.contains(author.pubkey))
              .toList(),
        );
      },
    );
  }

  // Main Search Entry Point
  void getItemsBySearch(String? search) {
    if (search == null) {
      return;
    }

    _cancelPreviousSearch();

    searchOnStoppedTyping = Timer(
      const Duration(seconds: 1),
      () async {
        if (search.isNotEmpty) {
          await _handleSearch(search);
        } else {
          _resetSearch();
        }
      },
    );
  }

  void _cancelPreviousSearch() {
    if (requestId.isNotEmpty) {
      nc.closeRequests(<String>[requestId]);
      requestId = '';
    }

    searchOnStoppedTyping?.cancel();
  }

  Future<void> _handleSearch(String search) async {
    checkForRelay(search);

    if (nostrSchemeRegex.hasMatch(search)) {
      nostrRepository.mainCubit.handleNostrEntity(search, '');
    } else {
      await _performGeneralSearch(search);
    }
  }

  Future<void> _performGeneralSearch(String search) async {
    _emit(
      profileSearchResult: SearchResultsType.loading,
      contentSearchResult: SearchResultsType.loading,
      content: <dynamic>[],
      authors: <Metadata>[],
    );

    getUsers(search);
    getContent(search);
  }

  void _resetSearch() {
    _emit(
      content: <dynamic>[],
      authors: <Metadata>[],
      contentSearchResult: SearchResultsType.noSearch,
      profileSearchResult: SearchResultsType.noSearch,
      search: '',
      relayConnectivity: RelayConnectivity.idle,
    );
  }

  // Relay Connectivity Check
  Future<void> checkForRelay(String search) async {
    _emit(relayConnectivity: RelayConnectivity.idle);

    if (search.contains('.')) {
      _emit(relayConnectivity: RelayConnectivity.searching);
      final relay = relayRegExp.hasMatch(search) ? search : 'wss://$search';

      final res = await nc.checkRelayConnectivity(relay);

      _emit(
        relayConnectivity:
            res ? RelayConnectivity.found : RelayConnectivity.notFound,
        search: res ? relay : '',
      );
    }
  }

  // Content Search
  Future<void> getContent(String search) async {
    _emit(isSearching: true);

    final List<dynamic> currentContent = List<dynamic>.from(state.content);

    final searchTag =
        search.startsWith('#') ? search.removeFirstCharacter() : search;

    final content = await NostrFunctionsRepository.getHomePageData(
      tags: <String>[
        searchTag,
        '#$searchTag',
        searchTag.toLowerCase(),
        '#${searchTag.toLowerCase()}',
        searchTag.capitalizeFirst(),
        '#${searchTag.capitalizeFirst()}',
      ],
      search: search,
    );

    final List<dynamic> updatedContent = List<dynamic>.from(currentContent);
    updatedContent.addAll(content);

    _emit(
      content: updatedContent,
      contentSearchResult: SearchResultsType.content,
      isSearching: false,
    );
  }

  // User Search
  Future<void> getUsers(String search) async {
    _emit(isSearching: true);

    try {
      List<Metadata> searchedUsers = (await metadataCubit
          .searchCacheMetadatasFromContactList(search))
        ..where((element) => !isUserMuted(element.pubkey)).toList();

      final local = await metadataCubit.searchCacheMetadatas(search);
      final filteredLocal = <Metadata>[];

      for (final user in local) {
        final notAvailable = searchedUsers
            .where((Metadata element) => element.pubkey == user.pubkey)
            .isEmpty;

        if (notAvailable) {
          filteredLocal.add(user);
        }
      }

      searchedUsers = [
        ...searchedUsers,
        ...orderMetadataByScore(metadatas: filteredLocal, match: search)
      ];

      final cached = orderMetadataByScore(
        metadatas: searchedUsers
            .where((Metadata author) => !isUserMuted(author.pubkey))
            .toList(),
        match: search,
      );

      if (cached.isNotEmpty) {
        _emit(
          authors: cached,
          profileSearchResult: SearchResultsType.content,
        );
      }

      final users = await NostrFunctionsRepository.getUserSearch(
        search: search,
        limit: 20,
      );

      final newList = <Metadata>[...state.authors];

      for (final user in users) {
        final userExists = newList
            .where((Metadata element) => element.pubkey == user.pubkey)
            .isNotEmpty;

        if (!userExists && !isUserMuted(user.pubkey)) {
          newList.add(user);
          metadataCubit.saveMetadata(user);
        }
      }

      final total = orderMetadataByScore(match: search, metadatas: newList);

      _emit(
        authors: total,
        profileSearchResult: SearchResultsType.content,
      );
    } catch (e) {
      Logger().i(e);
    }

    _emit(isSearching: false);
  }

  // Interest Management
  Future<void> updateInterest(String interest) async {
    final isAdded = await nostrRepository.setInterest(interest.toLowerCase());

    if (isAdded) {
      _emit(
        refresh: !state.refresh,
        interests: nostrRepository.interests,
      );
    }
  }

  // State Management
  void _emit({
    List<dynamic>? content,
    List<Metadata>? authors,
    String? search,
    bool? isSearching,
    SearchResultsType? contentSearchResult,
    SearchResultsType? profileSearchResult,
    Set<String>? bookmarks,
    List<String>? interests,
    List<String>? mutes,
    RelayConnectivity? relayConnectivity,
    bool? refresh,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        content: content,
        authors: authors,
        search: search,
        isSearching: isSearching,
        contentSearchResult: contentSearchResult,
        profileSearchResult: profileSearchResult,
        bookmarks: bookmarks,
        interests: interests,
        mutes: mutes,
        relayConnectivity: relayConnectivity,
        refresh: refresh,
      ));
    }
  }

  // Cleanup
  @override
  Future<void> close() {
    muteListSubscription.cancel();
    bookmarksSubscription.cancel();
    return super.close();
  }
}
