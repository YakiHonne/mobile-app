import 'package:aescryptojs/aescryptojs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../models/flash_news_model.dart';
import '../../../models/uncensored_notes_models.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'set_un_rating_state.dart';

class SetUnRatingCubit extends Cubit<SetUnRatingState> {
  SetUnRatingCubit() : super(const SetUnRatingState());

  Future<void> addRating({
    required bool isUpvote,
    required String uncensoredNoteId,
    required List<String> reasons,
    required Function() onSuccess,
  }) async {
    final createdAt = currentUnixTimestampSeconds();
    final encryptedMessage = encryptAESCryptoJS(
      createdAt.toString(),
      dotenv.env['FN_KEY']!,
    );

    final event = await Event.genEvent(
      kind: EventKind.REACTION,
      content: isUpvote ? '+' : '-',
      createdAt: createdAt,
      signer: currentSigner,
      verify: true,
      tags: [
        ['l', NR_SEARCH_VALUE],
        [
          FN_ENCRYPTION,
          encryptedMessage,
        ],
        ...reasons.map(
          (e) => ['cause', e],
        ),
        ['e', uncensoredNoteId],
      ],
    );

    if (event == null) {
      return;
    }

    final cancel = BotToastUtils.showLoading();

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: currentUserRelayList.writes,
      setProgress: true,
    );

    if (isSuccessful) {
      BotToastUtils.showSuccess(
        t.ratingSubmittedCheckReward.capitalizeFirst(),
      );

      onSuccess.call();
    } else {
      BotToastUtils.showError(
        t.errorSubmittingRating.capitalizeFirst(),
      );
    }

    cancel.call();
  }
}
