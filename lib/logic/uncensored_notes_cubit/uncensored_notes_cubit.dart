// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../models/flash_news_model.dart';
import '../../models/uncensored_notes_models.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'uncensored_notes_state.dart';

const FETCH_NEW = 'new';
const FETCH_NEEDS_MORE_HELP = 'needs-more-help';
const FETCH_HELPFUL = 'sealed';

class UncensoredNotesCubit extends Cubit<UncensoredNotesState> {
  UncensoredNotesCubit()
      : super(
          UncensoredNotesState(
            unNewFlashNews: const [],
            loading: true,
            balance: 0,
            index: 0,
            page: 0,
            refresh: false,
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            addingFlashNewsStatus: UpdatingState.success,
          ),
        ) {
    getBalance();
    getUnFlashnews(FETCH_NEW, 0);

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed) {
          emit(
            state.copyWith(
              bookmarks: getBookmarkIds(bookmarks).toSet(),
            ),
          );
        }
      },
    );
  }

  late StreamSubscription bookmarksSubscription;

  void setIndex(int index) {
    if (index == 0) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: true,
            index: 0,
            page: 0,
            addingFlashNewsStatus: UpdatingState.success,
            unNewFlashNews: [],
          ),
        );
      }

      getUnFlashnews(FETCH_NEW, 0);
    } else if (index == 1) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: true,
            index: 1,
            page: 0,
            addingFlashNewsStatus: UpdatingState.success,
            unNewFlashNews: [],
          ),
        );
      }

      getUnFlashnews(FETCH_NEEDS_MORE_HELP, 0);
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: true,
            index: 2,
            page: 0,
            addingFlashNewsStatus: UpdatingState.success,
            unNewFlashNews: [],
          ),
        );
      }

      getUnFlashnews(FETCH_HELPFUL, 0);
    }
  }

  Future<void> getBalance() async {
    final balance = await HttpFunctionsRepository.getBalance();
    if (!isClosed) {
      emit(
        state.copyWith(
          balance: balance,
        ),
      );
    }
  }

  Future<void> getUnFlashnews(String extension, int page) async {
    try {
      final unFlashNews =
          await HttpFunctionsRepository.getNewFlashnews(extension, page);
      if (!isClosed) {
        emit(
          state.copyWith(
            unNewFlashNews: unFlashNews,
            loading: false,
          ),
        );
      }
    } catch (e) {
      Logger().i(e);
    }
  }

  Future<void> addMoreUnFlashnews() async {
    try {
      final extension = state.index == 0
          ? FETCH_NEW
          : state.index == 1
              ? FETCH_NEEDS_MORE_HELP
              : FETCH_HELPFUL;
      if (!isClosed) {
        emit(
          state.copyWith(
            addingFlashNewsStatus: UpdatingState.progress,
          ),
        );
      }

      final flashnews = await HttpFunctionsRepository.getNewFlashnews(
        extension,
        state.page + 1,
      );

      if (flashnews.isEmpty) {
        if (!isClosed) {
          emit(
            state.copyWith(
              addingFlashNewsStatus: UpdatingState.idle,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(
            state.copyWith(
              addingFlashNewsStatus: UpdatingState.success,
              unNewFlashNews: [...state.unNewFlashNews, ...flashnews],
              page: state.page + 1,
            ),
          );
        }
      }
    } catch (e) {
      Logger().i(e);
      if (!isClosed) {
        emit(
          state.copyWith(
            addingFlashNewsStatus: UpdatingState.idle,
          ),
        );
      }
    }
  }

  Future<void> deleteRating({
    required String uncensoredNoteId,
    required String ratingId,
    required Function() onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: ratingId,
      lable: FN_SEARCH_VALUE,
      type: 'r',
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        t.ratingDeleted.capitalizeFirst(),
      );
      onSuccess.call();
    } else {
      BotToastUtils.showError(
        t.errorDeletingRating.capitalizeFirst(),
      );
    }

    cancel.call();
  }

  @override
  Future<void> close() {
    bookmarksSubscription.cancel();
    return super.close();
  }
}
