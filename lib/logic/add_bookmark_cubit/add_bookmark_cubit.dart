// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/bookmark_list_model.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'add_bookmark_state.dart';

class AddBookmarkCubit extends Cubit<AddBookmarkState> {
  AddBookmarkCubit({
    required int kind,
    required String identifier,
    required String eventPubkey,
    required String image,
    required this.nostrRepository,
  }) : super(
          AddBookmarkState(
            bookmarks: nostrRepository.bookmarksLists.values.toList(),
            loadingBookmarksList: const <String>[],
            kind: kind,
            isBookmarksLists: true,
            eventId: identifier,
            eventPubkey: eventPubkey,
            image: image,
          ),
        ) {
    initView();

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (Map<String, BookmarkListModel> bookmarks) {
        if (!isClosed) {
          initView();
        }
      },
    );

    loadingBookmarksSubscription =
        nostrRepository.loadingBookmarksStream.listen(
      (Map<String, Set<String>> loadingBookmarks) {
        if (!isClosed) {
          emit(
            state.copyWith(
              loadingBookmarksList: getLoadingBookmarkIds(loadingBookmarks),
            ),
          );
        }
      },
    );
  }

  late StreamSubscription<Map<String, BookmarkListModel>> bookmarksSubscription;
  late StreamSubscription<Map<String, Set<String>>>
      loadingBookmarksSubscription;
  final NostrDataRepository nostrRepository;
  String title = '';
  String description = '';

  void initView() {
    if (!isClosed) {
      emit(
        state.copyWith(
          bookmarks: nostrRepository.bookmarksLists.values.toList(),
        ),
      );
    }
  }

  void setBookmark({
    required String bookmarkListIdentifier,
  }) {
    NostrFunctionsRepository.setBookmarks(
      isReplaceableEvent: state.kind != EventKind.TEXT_NOTE &&
          state.kind != EventKind.VIDEO_HORIZONTAL &&
          state.kind != EventKind.VIDEO_VERTICAL,
      identifier: state.eventId,
      pubkey: state.eventPubkey,
      bookmarkIdentifier: bookmarkListIdentifier,
      image: state.image,
      kind: state.kind,
    );
  }

  Future<void> addBookmarkList() async {
    if (title.trim().isEmpty) {
      BotToastUtils.showError(t.useValidTitle.capitalizeFirst());
      return;
    }

    title.trim().capitalize();
    final cancel = BotToast.showLoading();

    final createdBookmark = BookmarkListModel(
      title: title,
      description: description,
      image: state.image,
      placeholder: '',
      id: '',
      stringifiedEvent: '',
      identifier: StringUtil.getRandomString(16),
      bookmarkedReplaceableEvents: <EventCoordinates>[
        if (state.kind != EventKind.TEXT_NOTE)
          EventCoordinates(
            state.kind,
            state.eventPubkey,
            state.eventId,
            '',
          ),
      ],
      bookmarkedEvents: <String>[
        if (state.kind == EventKind.TEXT_NOTE) state.eventId
      ],
      pubkey: currentSigner!.getPublicKey(),
      createdAt: DateTime.now(),
    );

    final Event? event = await createdBookmark.bookmarkListModelToEvent();

    if (event == null) {
      BotToastUtils.showError(
        t.errorAddingBookmark.capitalizeFirst(),
      );
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: currentUserRelayList.writes,
      setProgress: true,
    );

    if (isSuccessful) {
      nostrRepository.addBookmarkList(
        BookmarkListModel.fromEvent(event),
      );

      title = '';
      description = '';
      setView(true);
      BotToastUtils.showSuccess(
        t.bookmarkAdded.capitalizeFirst(),
      );
    }

    cancel.call();
  }

  void setView(bool status) {
    if (!isClosed) {
      emit(
        state.copyWith(
          isBookmarksLists: status,
        ),
      );
    }
  }

  void setText({required String text, required bool isTitle}) {
    if (isTitle) {
      title = text;
    } else {
      description = text;
    }
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    loadingBookmarksSubscription.cancel();
    return super.close();
  }
}
