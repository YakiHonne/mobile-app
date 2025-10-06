import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'interests_management_state.dart';

class InterestsManagementCubit extends Cubit<InterestsManagementState> {
  InterestsManagementCubit()
      : super(
          InterestsManagementState(
            interests: nostrRepository.interests.toSet(),
            refresh: false,
          ),
        );

  void setInterest(String interest) {
    final newSet = Set<String>.from(state.interests);

    if (newSet.contains(interest)) {
      newSet.remove(interest);
      if (!isClosed) {
        emit(
          state.copyWith(
            interests: newSet,
          ),
        );
      }
    } else {
      newSet.add(interest);
      if (!isClosed) {
        emit(
          state.copyWith(
            interests: newSet,
          ),
        );
      }
    }
  }

  void setFeedTypesNewOrder(int oldIndex, int newIndex) {
    final interestsList = List<String>.from(state.interests);

    final interest = interestsList.removeAt(oldIndex);
    interestsList.insert(newIndex, interest);

    if (!isClosed) {
      emit(
        state.copyWith(
          interests: interestsList.toSet(),
          refresh: !state.refresh,
        ),
      );
    }
  }

  Future<void> updateInterest(Function() onSuccess) async {
    final event = await Event.genEvent(
      kind: EventKind.INTEREST_SET,
      tags: [
        ...state.interests.map(
          (e) => ['t', e.toLowerCase()],
        ),
      ],
      content: '',
      signer: currentSigner,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: true,
        relays: currentUserRelayList.writes,
      );

      if (isSuccessful) {
        nostrRepository.setInterestSet(state.interests);

        BotToastUtils.showSuccess(
          t.interestsUpdateMessage.capitalizeFirst(),
        );
        onSuccess.call();
      } else {
        BotToastUtils.showError(
          t.errorSendingEvent.capitalizeFirst(),
        );
      }
    } else {
      BotToastUtils.showError(
        t.errorGeneratingEvent.capitalizeFirst(),
      );
    }
  }
}
