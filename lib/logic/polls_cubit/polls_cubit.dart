import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/poll_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'polls_state.dart';

class PollsCubit extends Cubit<PollsState> {
  PollsCubit()
      : super(
          PollsState(
            isLoading: true,
            loadingState: UpdatingState.success,
            mutes: nostrRepository.mutes.toList(),
            polls: const [],
          ),
        ) {
    getPolls(isAdd: false, isSelf: false);

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
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

  late StreamSubscription muteListSubscription;
  bool isSelfVal = false;

  void getPolls({required bool isAdd, required bool isSelf}) {
    final oldPolls = List<PollModel>.from(state.polls);

    if (isAdd) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loadingState: UpdatingState.progress,
          ),
        );
      }
    } else {
      isSelfVal = isSelf;
      if (!isClosed) {
        emit(
          state.copyWith(
            polls: [],
            isLoading: true,
          ),
        );
      }
    }

    List<PollModel> addedPolls = [];

    NostrFunctionsRepository.getZapPolls(
      limit: 30,
      pubkeys: isSelfVal ? [currentSigner!.getPublicKey()] : null,
      until:
          isAdd ? state.polls.last.createdAt.toSecondsSinceEpoch() - 1 : null,
      onPollsFunc: (polls) {
        if (isAdd) {
          addedPolls = polls;
          if (!isClosed) {
            emit(
              state.copyWith(
                polls: [...oldPolls, ...polls],
                loadingState: UpdatingState.success,
              ),
            );
          }
        } else {
          if (!isClosed) {
            emit(
              state.copyWith(
                polls: polls,
                isLoading: false,
              ),
            );
          }
        }
      },
      onDone: () {
        if (!isClosed) {
          emit(
            state.copyWith(
              isLoading: false,
              loadingState:
                  isAdd && addedPolls.isEmpty ? UpdatingState.idle : null,
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    muteListSubscription.cancel();
    return super.close();
  }
}
