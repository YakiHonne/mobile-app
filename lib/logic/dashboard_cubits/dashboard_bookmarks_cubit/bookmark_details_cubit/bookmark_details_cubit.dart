import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../../models/article_model.dart';
import '../../../../models/bookmark_list_model.dart';
import '../../../../models/curation_model.dart';
import '../../../../models/detailed_note_model.dart';
import '../../../../models/flash_news_model.dart';
import '../../../../models/video_model.dart';
import '../../../../repositories/nostr_data_repository.dart';
import '../../../../repositories/nostr_functions_repository.dart';
import '../../../../utils/utils.dart';

part 'bookmark_details_state.dart';

class BookmarkDetailsCubit extends Cubit<BookmarkDetailsState> {
  BookmarkDetailsCubit({
    required this.nostrRepository,
    required BookmarkListModel bookmarkListModel,
  }) : super(
          BookmarkDetailsState(
            content: const <dynamic>[],
            metadatas: const <String, Metadata>{},
            mutes: nostrRepository.mutes.toList(),
            bookmarkListModel: bookmarkListModel,
            followings: contactListCubit.contacts,
            isLoading: true,
            refresh: false,
          ),
        ) {
    getBookmarks();

    bookmarksListsSubcription = nostrRepository.bookmarksStream.listen(
      (Map<String, BookmarkListModel> bookmarksLists) {
        final BookmarkListModel? newBookmarkList =
            bookmarksLists[bookmarkListModel.identifier];

        if (newBookmarkList != null) {
          if (!isClosed) {
            emit(
              state.copyWith(
                bookmarkListModel: newBookmarkList,
              ),
            );
          }

          getBookmarks();
        }
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (Set<String> mutes) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
        }
      },
    );
  }

  final NostrDataRepository nostrRepository;
  late StreamSubscription bookmarksListsSubcription;
  late StreamSubscription muteListSubscription;
  List<dynamic> globalContent = <dynamic>[];

  void getBookmarks() {
    final String requestId = NostrFunctionsRepository.getBookmarks(
      bookmarksModel: state.bookmarkListModel,
      contentFunc: (List<dynamic> content) {
        globalContent = content;

        if (!isClosed) {
          emit(
            state.copyWith(
              content: content,
              isLoading: false,
            ),
          );
        }
      },
    );

    if (requestId.isEmpty) {
      if (!isClosed) {
        emit(
          state.copyWith(
            content: <dynamic>[],
          ),
        );
      }
    }
  }

  void filterBookmarksByType(String bookmarkType) {
    if (bookmarkType == bookmarksTypes[0]) {
      if (!isClosed) {
        emit(
          state.copyWith(
            content: globalContent,
          ),
        );
      }
    } else if (bookmarkType == bookmarksTypes[1]) {
      final List<Article> newContent =
          globalContent.whereType<Article>().toList();
      if (!isClosed) {
        emit(
          state.copyWith(
            content: newContent,
          ),
        );
      }
    } else if (bookmarkType == bookmarksTypes[2]) {
      final List<Curation> newContent =
          globalContent.whereType<Curation>().toList();
      if (!isClosed) {
        emit(
          state.copyWith(
            content: newContent,
          ),
        );
      }
    } else if (bookmarkType == bookmarksTypes[3]) {
      final List<FlashNews> newContent =
          globalContent.whereType<FlashNews>().toList();
      if (!isClosed) {
        emit(
          state.copyWith(
            content: newContent,
          ),
        );
      }
    } else if (bookmarkType == bookmarksTypes[4]) {
      final List<DetailedNoteModel> newContent =
          globalContent.whereType<DetailedNoteModel>().toList();
      if (!isClosed) {
        emit(
          state.copyWith(
            content: newContent,
          ),
        );
      }
    } else if (bookmarkType == bookmarksTypes[5]) {
      final List<VideoModel> newContent =
          globalContent.whereType<VideoModel>().toList();
      if (!isClosed) {
        emit(
          state.copyWith(
            content: newContent,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    bookmarksListsSubcription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
