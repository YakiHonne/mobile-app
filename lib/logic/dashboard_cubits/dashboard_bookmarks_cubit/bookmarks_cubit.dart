// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/bookmark_list_model.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'bookmarks_state.dart';

class DashboardBookmarksCubit extends Cubit<DashboardBookmarksState> {
  DashboardBookmarksCubit()
      : super(
          DashboardBookmarksState(
            refresh: false,
            bookmarksLists: nostrRepository.bookmarksLists.values.toList(),
          ),
        ) {
    bookmarksListsSubcription = nostrRepository.bookmarksStream.listen(
      (bookmarksLists) {
        if (!isClosed) {
          emit(
            state.copyWith(
              bookmarksLists: nostrRepository.bookmarksLists.values.toList(),
            ),
          );
        }
      },
    );

    userSubcription = nostrRepository.currentSignerStream.listen(
      (user) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription userSubcription;
  late StreamSubscription bookmarksListsSubcription;
  String title = '';
  String description = '';

  void setText({required String text, required bool isTitle}) {
    if (isTitle) {
      title = text;
    } else {
      description = text;
    }
  }

  Future<void> deleteBookmarksList({
    required String bookmarkListEventId,
    required String bookmarkListIdentifier,
    required Function() onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: bookmarkListEventId,
    );

    if (isSuccessful) {
      nostrRepository.deleteBookmarkList(bookmarkListIdentifier);
      BotToastUtils.showSuccess('Bookmarks list has been deleted.');
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }

    cancel.call();
  }

  Future<void> addBookmarkList({
    required BuildContext context,
    required Function() onSuccess,
    required String image,
    BookmarkListModel? bookmarkListModel,
  }) async {
    if (title.trim().isEmpty) {
      BotToastUtils.showError(context.t.useValidTitle.capitalizeFirst());
      return;
    }

    title.trim().capitalize();
    final cancel = BotToast.showLoading();

    final createdBookmark = BookmarkListModel(
      title: title,
      description: description,
      image: image,
      identifier:
          bookmarkListModel?.identifier ?? StringUtil.getRandomString(16),
      bookmarkedReplaceableEvents:
          bookmarkListModel?.bookmarkedReplaceableEvents ?? [],
      bookmarkedEvents: bookmarkListModel?.bookmarkedEvents ?? [],
      bookmarkedTags: bookmarkListModel?.bookmarkedTags ?? [],
      bookmarkedUrls: bookmarkListModel?.bookmarkedUrls ?? [],
      id: '',
      stringifiedEvent: '',
      pubkey: currentSigner!.getPublicKey(),
      createdAt: DateTime.now(),
    );

    final event = await createdBookmark.bookmarkListModelToEvent();

    if (event == null) {
      BotToastUtils.showError(
        context.t.errorAddingBookmark.capitalizeFirst(),
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
      BotToastUtils.showSuccess(
        context.t.bookmarkAdded.capitalizeFirst(),
      );
      onSuccess.call();
    }

    cancel.call();
  }

  @override
  Future<void> close() {
    userSubcription.cancel();
    bookmarksListsSubcription.cancel();
    return super.close();
  }
}
