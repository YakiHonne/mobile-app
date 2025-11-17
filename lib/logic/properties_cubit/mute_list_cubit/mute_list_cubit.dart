// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';

part 'mute_list_state.dart';

class MuteListCubit extends Cubit<MuteListState> {
  MuteListCubit()
      : super(
          MuteListState(
            usersMutes: nostrRepository.muteModel.usersMutes.toList(),
            eventsMutes: nostrRepository.muteModel.eventsMutes.toList(),
            isUsingPrivKey: canSign(),
          ),
        ) {
    mutesListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          emit(
            state.copyWith(
              usersMutes: mm.usersMutes.toList(),
              eventsMutes: mm.eventsMutes.toList(),
            ),
          );
        }

        getAuthors();
      },
    );
  }

  late StreamSubscription mutesListSubscription;

  void getAuthors() {
    metadataCubit.fetchMetadata(state.usersMutes);
  }

  Future<void> setMuteStatusFunc({
    required String muteKey,
    bool isPubkey = true,
    required Function() onSuccess,
  }) async {
    await setMuteStatus(
      muteKey: muteKey,
      isPubkey: isPubkey,
      onSuccess: onSuccess,
    );
  }

  @override
  Future<void> close() {
    mutesListSubscription.cancel();
    return super.close();
  }
}
