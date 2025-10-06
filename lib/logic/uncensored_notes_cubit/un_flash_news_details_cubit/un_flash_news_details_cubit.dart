// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:aescryptojs/aescryptojs.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/flash_news_model.dart';
import '../../../models/uncensored_notes_models.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'un_flash_news_details_state.dart';

class UnFlashNewsDetailsCubit extends Cubit<UnFlashNewsDetailsState> {
  UnFlashNewsDetailsCubit({
    required this.unFlashNews,
  }) : super(
          UnFlashNewsDetailsState(
            refresh: false,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .toSet()
                .contains(unFlashNews.flashNews.id),
            loading: true,
            isSealed: unFlashNews.isSealed,
            uncensoredNotes: const [],
            notHelpFulNotes: const [],
            writingNoteStatus: WritingNoteStatus.disabled,
          ),
        ) {
    getUncensoredNotes();

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isBookmarked: getBookmarkIds(bookmarks)
                  .toSet()
                  .contains(unFlashNews.flashNews.id),
            ),
          );
        }
      },
    );

    userSubscription = nostrRepository.currentSignerStream.listen(
      (userStatusModel) {
        WritingNoteStatus writingNoteStatus = WritingNoteStatus.disabled;

        if (currentSigner!.getPublicKey() != unFlashNews.flashNews.pubkey &&
            !unFlashNews.isSealed) {
          final canBeWritten = state.uncensoredNotes
              .where(
                (element) =>
                    element.pubKey == nostrRepository.currentMetadata.pubkey,
              )
              .toList()
              .isEmpty;

          writingNoteStatus = canBeWritten
              ? WritingNoteStatus.canBeWritten
              : WritingNoteStatus.alreadyWritten;
        }

        if (!isClosed) {
          emit(
            state.copyWith(
              writingNoteStatus: writingNoteStatus,
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription bookmarksSubscription;
  late StreamSubscription userSubscription;
  final UnFlashNews unFlashNews;

  Future<void> getUncensoredNotes() async {
    try {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: true,
            uncensoredNotes: [],
            writingNoteStatus: WritingNoteStatus.disabled,
          ),
        );
      }

      final data = await HttpFunctionsRepository.getUncensoredNotes(
        flashNewsId: unFlashNews.flashNews.id,
      );

      List<UncensoredNote> notes = data['notes'] as List<UncensoredNote>;

      if (unFlashNews.isSealed) {
        notes = notes
            .where((element) =>
                element.id != unFlashNews.sealedNote!.uncensoredNote.id)
            .toList();
      }

      WritingNoteStatus writingNoteStatus = WritingNoteStatus.disabled;

      if (canSign() &&
          nostrRepository.currentMetadata.pubkey !=
              unFlashNews.flashNews.pubkey &&
          !unFlashNews.isSealed) {
        final canBeWritten = notes
            .where(
              (element) =>
                  element.pubKey == nostrRepository.currentMetadata.pubkey,
            )
            .toList()
            .isEmpty;

        writingNoteStatus = canBeWritten
            ? WritingNoteStatus.canBeWritten
            : WritingNoteStatus.alreadyWritten;
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            uncensoredNotes: notes,
            loading: false,
            notHelpFulNotes: data['notHelpful'],
            writingNoteStatus: writingNoteStatus,
          ),
        );
      }
    } catch (e, stack) {
      Logger().i(stack);
    }
  }

  Future<void> addUncensoredNotes({
    required String content,
    required String source,
    required bool isCorrect,
    required Function() onSuccess,
  }) async {
    final createdAt = currentUnixTimestampSeconds();
    final encryptedMessage = encryptAESCryptoJS(
      createdAt.toString(),
      dotenv.env['FN_KEY']!,
    );

    final event = await Event.genEvent(
      kind: EventKind.TEXT_NOTE,
      content: content,
      createdAt: createdAt,
      signer: currentSigner,
      verify: true,
      tags: [
        ['l', UN_SEARCH_VALUE],
        if (source.isNotEmpty) ['source', source],
        [
          FN_ENCRYPTION,
          encryptedMessage,
        ],
        ['e', unFlashNews.flashNews.id],
        ['p', unFlashNews.flashNews.pubkey],
        ['type', if (isCorrect) '+' else '-'],
      ],
    );

    if (event == null) {
      return;
    }

    final cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: currentUserRelayList.writes,
      setProgress: true,
    );

    if (isSuccessful) {
      getUncensoredNotes();

      BotToastUtils.showSuccess(
        t.verifiedNoteAdded.capitalizeFirst(),
      );

      onSuccess.call();
    } else {
      BotToastUtils.showError(
        t.errorAddingVerifiedNote.capitalizeFirst(),
      );
    }

    cancel.call();
  }

  Future<void> deleteRating({
    required String uncensoredNoteId,
    required String ratingId,
    required Function() onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

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
    userSubscription.cancel();
    return super.close();
  }
}
