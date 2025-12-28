import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/picture_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'picture_state.dart';

class PictureCubit extends Cubit<PictureState> {
  PictureCubit({
    required this.pictureModel,
  }) : super(const PictureState()) {
    setAuthor();

    mutesSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription mutesSubscription;
  PictureModel pictureModel;

  Future<void> setAuthor() async {
    bool isFollowing = false;

    if (canSign() && pictureModel.pubkey != currentSigner!.getPublicKey()) {
      isFollowing = contactListCubit.contacts.contains(pictureModel.pubkey);
    }

    _emit(
      state.copyWith(
        isFollowingAuthor: isFollowing,
      ),
    );
  }

  Future<void> setFollowingState() async {
    final cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: pictureModel.pubkey,
    );

    _emit(
      state.copyWith(
        refresh: !state.refresh,
      ),
    );

    cancel.call();
  }

  void _emit(PictureState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  @override
  Future<void> close() async {
    mutesSubscription.cancel();
    return super.close();
  }
}
