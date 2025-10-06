// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'mute_list_state.dart';

class MuteListCubit extends Cubit<MuteListState> {
  MuteListCubit()
      : super(
          MuteListState(
            mutes: nostrRepository.mutes.toList(),
            isUsingPrivKey: canSign(),
          ),
        ) {
    mutesListSubscription = nostrRepository.mutesStream.listen(
      (mutes) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mutes.toList(),
            ),
          );
        }

        getAuthors();
      },
    );
  }

  late StreamSubscription mutesListSubscription;

  void getAuthors() {
    metadataCubit.fetchMetadata(state.mutes);
  }

  Future<void> setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(pubkey);

    cancel();

    if (result) {
      final hasBeenMuted = nostrRepository.mutes.contains(pubkey);

      BotToastUtils.showSuccess(
        hasBeenMuted
            ? t.userHasBeenMuted.capitalizeFirst()
            : t.userHasBeenUnmuted.capitalizeFirst(),
      );
      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  @override
  Future<void> close() {
    mutesListSubscription.cancel();
    return super.close();
  }
}
