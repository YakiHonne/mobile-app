import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/common_regex.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'write_zap_poll_state.dart';

class WriteZapPollCubit extends Cubit<WriteZapPollState> {
  WriteZapPollCubit()
      : super(
          const WriteZapPollState(
            images: [],
            options: [
              'A',
              'B',
            ],
          ),
        );

  void addImage(List<String> links) {
    if (!isClosed) {
      emit(
        state.copyWith(
          images: List.from(state.images)..addAll(links),
        ),
      );
    }
  }

  void removeImage(int index) {
    if (!isClosed) {
      emit(
        state.copyWith(
          images: List.from(state.images)..removeAt(index),
        ),
      );
    }
  }

  void addPollOption() {
    if (!isClosed) {
      emit(
        state.copyWith(
          options: List.from(state.options)..add(''),
        ),
      );
    }
  }

  void updatePollOption(String pollOption, int index) {
    final newList = List<String>.from(state.options);
    newList[index] = pollOption;
    if (!isClosed) {
      emit(
        state.copyWith(
          options: newList,
        ),
      );
    }
  }

  void removePollOption(int index) {
    if (!isClosed) {
      emit(
        state.copyWith(
          options: List.from(state.options)..removeAt(index),
        ),
      );
    }
  }

  Future<void> postZapPoll({
    required String content,
    required List<String> mentions,
    required List<String> tags,
    required String minimumSatoshis,
    required String maximumSatoshis,
    required DateTime? closedAt,
    required Function(Event) onSuccess,
  }) async {
    String updatedContent = content;
    final List<String> pTags = mentions;
    final minSat = minimumSatoshis.trim();
    final maxSat = maximumSatoshis.trim();

    if (minSat.isNotEmpty && maxSat.isNotEmpty) {
      final int min = int.parse(minimumSatoshis);
      final int max = int.parse(maximumSatoshis);

      if (max < min) {
        BotToastUtils.showError(
          t.submitMinMaxSats.capitalizeFirst(),
        );

        return;
      }
    }

    if (closedAt != null && closedAt.compareTo(DateTime.now()) <= 0) {
      BotToastUtils.showError(
        t.submitValidCloseDate.capitalizeFirst(),
      );
      return;
    }

    final List<List<String>> polls = [];

    bool hasEmptyOption = false;
    for (int i = 0; i < state.options.length; i++) {
      final e = state.options[i].trim();

      polls.add(['poll_option', '$i', e]);

      if (e.isEmpty) {
        hasEmptyOption = true;
      }
    }

    if (hasEmptyOption) {
      BotToastUtils.showError(
        t.submitValidOptions.capitalizeFirst(),
      );
      return;
    }

    final Iterable<Match> matches = hashtagsRegExp.allMatches(content);
    final List<String> hashtags =
        matches.map((match) => match.group(0)!).toList();
    if (state.images.isNotEmpty) {
      for (final image in state.images) {
        updatedContent = '$updatedContent $image';
      }
    }

    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.POLL,
      tags: [
        if (pTags.isNotEmpty) ...pTags.map((p) => ['p', p]),
        if (hashtags.isNotEmpty) ...hashtags.map((t) => ['t', t.split('#')[1]]),
        ['p', currentSigner!.getPublicKey(), mandatoryRelays.first],
        ...polls,
        [
          'closed_at',
          if (closedAt != null)
            (closedAt.millisecondsSinceEpoch ~/ 1000).toString()
          else
            'null'
        ],
        if (minSat.isNotEmpty) ['value_minimum', minSat],
        if (maxSat.isNotEmpty) ['value_maximum', maxSat]
      ],
      content: updatedContent,
      signer: currentSigner,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        BotToastUtils.showSuccess(
          t.pollZapPublished.capitalizeFirst(),
        );
        onSuccess.call(event);
      } else {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );
      }
    } else {
      BotToastUtils.showError(
        t.errorGeneratingEvent.capitalizeFirst(),
      );
      return;
    }

    cancel.call();
  }
}
