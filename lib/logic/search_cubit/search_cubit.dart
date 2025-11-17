// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../../views/article_view/article_view.dart';
import '../../views/curation_view/curation_view.dart';
import '../../views/note_view/note_view.dart';
import '../../views/profile_view/profile_view.dart';
import '../../views/smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../views/widgets/video_components/horizontal_video_view.dart';
import '../../views/widgets/video_components/vertical_video_view.dart';

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
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (Map<String, BookmarkListModel> bookmarks) {
        _emit(
          bookmarks: getBookmarkIds(bookmarks).toSet(),
        );
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

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription muteListSubscription;

  BuildContext context;
  Timer? searchOnStoppedTyping;
  String requestId = '';
  Set<String> requests = <String>{};

  void getItemsBySearch(String search) {
    if (requestId.isNotEmpty) {
      nc.closeRequests(<String>[requestId]);
      requestId = '';
    }

    if (searchOnStoppedTyping != null) {
      searchOnStoppedTyping!.cancel();
    }

    searchOnStoppedTyping = Timer(
      const Duration(seconds: 1),
      () async {
        if (search.isNotEmpty) {
          checkForRelay(search);

          if (search.startsWith('naddr') || search.startsWith('nostr:naddr')) {
            forwardNaddrView(search);
          } else if (search.startsWith('nostr:npub') ||
              search.startsWith('nostr:nprofile') ||
              search.startsWith('npub') ||
              search.startsWith('nprofile') ||
              search.length == 64) {
            try {
              final newSearch = search.startsWith('nostr:')
                  ? search.split('nostr:').last
                  : search;

              final String hex = newSearch.startsWith('npub')
                  ? Nip19.decodePubkey(newSearch)
                  : newSearch.startsWith('nprofile')
                      ? Nip19.decodeShareableEntity(newSearch)['special']
                      : newSearch;

              Navigator.pushNamed(
                context,
                ProfileView.routeName,
                arguments: [hex],
              );
            } catch (_) {
              BotToastUtils.showError(
                context.t.errorDecodingData.capitalizeFirst(),
              );
            }
          } else if (search.startsWith('note1') ||
              search.startsWith('nostr:note1')) {
            final newSearch = search.startsWith('nostr:')
                ? search.split('nostr:').last
                : search;

            forwardNoteView(newSearch);
          } else if (search.startsWith('nevent1') ||
              search.startsWith('nostr:nevent1')) {
            final String newSearch = search.startsWith('nostr:')
                ? search.split('nostr:').last
                : search;
            forwardNeventView(newSearch);
          } else {
            _emit(
              profileSearchResult: SearchResultsType.loading,
              contentSearchResult: SearchResultsType.loading,
              content: <dynamic>[],
              authors: <Metadata>[],
            );

            getUsers(search);
            getContent(search);
          }
        } else {
          _emit(
            content: <dynamic>[],
            authors: <Metadata>[],
            contentSearchResult: SearchResultsType.noSearch,
            profileSearchResult: SearchResultsType.noSearch,
            search: '',
            relayConnectivity: RelayConnectivity.idle,
          );
        }
      },
    );
  }

  Future<void> checkForRelay(String search) async {
    _emit(
      relayConnectivity: RelayConnectivity.idle,
    );

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

  Future<void> forwardNeventView(String nostrUri) async {
    _emit(isSearching: true);

    try {
      final Map<String, dynamic> nostrDecode =
          Nip19.decodeShareableEntity(nostrUri);
      metadataCubit.requestMetadata(nostrDecode['author'] ?? '');

      final ev = await getForwardEvent(
        kinds: nostrDecode['kind'] != null ? <int>[nostrDecode['kind']] : null,
        identifier: nostrDecode['special'],
        author: nostrDecode['author'],
      );

      if (ev == null) {
        BotToastUtils.showError(
          context.t.eventNotFound.capitalizeFirst(),
        );
      } else if (ev.kind == EventKind.TEXT_NOTE) {
        final DetailedNoteModel note = DetailedNoteModel.fromEvent(ev);

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: [note],
          );
        }
      } else if (ev.kind == EventKind.VIDEO_HORIZONTAL ||
          ev.kind == EventKind.VIDEO_VERTICAL) {
        final video = VideoModel.fromEvent(ev);

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            ev.kind == EventKind.VIDEO_HORIZONTAL
                ? HorizontalVideoView.routeName
                : VerticalVideoView.routeName,
            arguments: [video],
          );
        }
      } else if (ev.kind == EventKind.LONG_FORM) {
        final article = Article.fromEvent(ev);

        if (context.mounted) {
          Navigator.pushNamed(
            context,
            ArticleView.routeName,
            arguments: article,
          );
        }
      } else {
        BotToastUtils.showError(context.t.unsupportedKind);
      }
    } catch (e) {
      lg.i(e);
      BotToastUtils.showError(
        context.t.errorDecodingData.capitalizeFirst(),
      );
    }

    _emit(isSearching: false);
  }

  Future<void> forwardNoteView(String note) async {
    _emit(isSearching: true);

    try {
      final String decodedNote = Nip19.decodeNote(note);

      final event = await getForwardEvent(
        kinds: <int>[EventKind.TEXT_NOTE],
        identifier: decodedNote,
      );

      if (event == null) {
        BotToastUtils.showError(
          context.t.noteNotFound.capitalizeFirst(),
        );
      } else {
        if (context.mounted) {
          final DetailedNoteModel note = DetailedNoteModel.fromEvent(event);
          Navigator.pushNamed(
            context,
            NoteView.routeName,
            arguments: [note],
          );
        }
      }
    } catch (_) {
      BotToastUtils.showError(
        context.t.errorDecodingData.capitalizeFirst(),
      );
    }

    _emit(isSearching: false);
  }

  Future<void> forwardNaddrView(String naddr) async {
    _emit(isSearching: true);

    try {
      final Map<String, dynamic> decodedNaddr =
          Nip19.decodeShareableEntity(naddr);
      final int? kind = decodedNaddr['kind'] as int?;
      final List<int> hexCode = hex.decode(decodedNaddr['special']);
      final String special = String.fromCharCodes(hexCode);

      if (kind == EventKind.LONG_FORM) {
        final Event? event = await getForwardEvent(
          kinds: <int>[EventKind.LONG_FORM],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError(
            context.t.articleNotFound.capitalizeFirst(),
          );
        } else {
          if (context.mounted) {
            final Article article = Article.fromEvent(event);
            Navigator.pushNamed(
              context,
              ArticleView.routeName,
              arguments: article,
            );
          }
        }
      } else if (kind == EventKind.CURATION_ARTICLES) {
        final Event? event = await getForwardEvent(
          kinds: <int>[EventKind.CURATION_ARTICLES],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError(
            context.t.curationNotFound.capitalizeFirst(),
          );
        } else {
          if (context.mounted) {
            final Curation curation = Curation.fromEvent(event, '');

            Navigator.pushNamed(
              context,
              CurationView.routeName,
              arguments: curation,
            );
          }
        }
      } else if (kind == EventKind.VIDEO_HORIZONTAL ||
          kind == EventKind.VIDEO_VERTICAL) {
        final Event? event = await getForwardEvent(
          kinds: <int>[EventKind.VIDEO_HORIZONTAL, EventKind.VIDEO_VERTICAL],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError(
            context.t.videoNotFound.capitalizeFirst(),
          );
        } else {
          if (context.mounted) {
            final VideoModel video = VideoModel.fromEvent(event);

            Navigator.pushNamed(
              context,
              video.kind == EventKind.VIDEO_HORIZONTAL
                  ? HorizontalVideoView.routeName
                  : VerticalVideoView.routeName,
              arguments: <VideoModel>[video],
            );
          }
        }
      } else if (kind == EventKind.SMART_WIDGET_ENH) {
        final Event? event = await getForwardEvent(
          kinds: <int>[EventKind.SMART_WIDGET_ENH],
          identifier: special,
        );

        if (event == null) {
          BotToastUtils.showError(
            context.t.smartWidgetNotFound.capitalizeFirst(),
          );
        } else {
          if (context.mounted) {
            final smartWidgetModel = SmartWidget.fromEvent(event);
            Navigator.pushNamed(
              context,
              SmartWidgetChecker.routeName,
              arguments: <Object>[
                smartWidgetModel.getNaddr(),
                smartWidgetModel
              ],
            );
          }
        }
      }
    } catch (_) {
      BotToastUtils.showError(
        context.t.errorDecodingData.capitalizeFirst(),
      );
    }

    _emit(isSearching: false);
  }

  Future<void> updateInterest(String interest) async {
    final isAdded = await nostrRepository.setInterest(interest.toLowerCase());

    if (isAdded) {
      _emit(
        refresh: !state.refresh,
        interests: nostrRepository.interests,
      );
    }
  }

  Future<Event?> getForwardEvent({
    List<int>? kinds,
    String? identifier,
    String? author,
  }) async {
    Event? event;

    final List<String>? dTags =
        identifier != null && kinds != null && isReplaceable(kinds.first)
            ? <String>[identifier]
            : null;

    final List<String>? ids = identifier != null &&
            (kinds != null && !isReplaceable(kinds.first) || kinds == null)
        ? <String>[identifier]
        : null;

    if (dTags?.isNotEmpty ?? false) {
      event = await nc.db.loadEventById(dTags!.first, true);
    } else if (ids?.isNotEmpty ?? false) {
      event = await nc.db.loadEventById(ids!.first, false);
    }

    if (event != null) {
      return Future.value(event);
    } else {
      final completer = Completer<Event?>();

      NostrFunctionsRepository.getForwardingEvents(
        kinds: kinds,
        dTags: dTags,
        ids: ids,
        pubkeys: author != null ? <String>[author] : null,
      ).listen((Event recentEvent) {
        if (event == null ||
            event!.createdAt.compareTo(recentEvent.createdAt) < 0) {
          event = recentEvent;
        }
      }).onDone(
        () {
          if (event != null) {
            nc.db.saveEvent(event!);
          }

          completer.complete(event);
        },
      );

      return completer.future;
    }
  }

  Future<void> getUsers(String search) async {
    _emit(isSearching: true);

    try {
      List<Metadata> searchedUsers =
          (await metadataCubit.searchCacheMetadatasFromContactList(
        search,
      ))
            ..where(
              (element) => !isUserMuted(element.pubkey),
            ).toList();

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

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    bookmarksSubscription.cancel();
    return super.close();
  }
}
