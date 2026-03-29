import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../globals.dart';
import '../../models/packs_model.dart';
import '../../utils/bot_toast_util.dart';

part 'explore_pack_details_state.dart';

class ExplorePackDetailsCubit extends Cubit<ExplorePackDetailsState> {
  ExplorePackDetailsCubit()
      : super(ExplorePackDetailsState(
          ownFollowings: contactListCubit.contacts,
          currentUserPubKey: currentSigner?.getPublicKey() ?? '',
        )) {
    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              ownFollowings: followings,
            ),
          );
        }
      },
    );
  }

  Timer? addFollowingOnStop;
  late StreamSubscription followingsSubscription;

  Future<void> followPack(PacksModel pack) async {
    final cancel = BotToastUtils.showLoading();
    final hasAllFollowed =
        state.ownFollowings.toSet().containsAll(pack.pubkeys);

    final contactList = await contactListCubit.setContacts(hasAllFollowed
        ? pack.pubkeys.toList()
        : pack.pubkeys
            .where(
              (element) => !state.ownFollowings.contains(element),
            )
            .toList());

    cancel.call();

    if (contactList != null) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pendings: {},
            ownFollowings: contactList.contacts,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(pendings: {}),
        );
      }
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  void setFollowingOnStop(String desiredAuthor) {
    addFollowingOnStop?.cancel();
    if (!isClosed) {
      emit(
        state.copyWith(
          pendings: Set.from(state.pendings)..add(desiredAuthor),
        ),
      );
    }

    addFollowingOnStop = Timer(
      const Duration(milliseconds: 800),
      () {
        setFollowingState();
      },
    );
  }

  Future<void> setFollowingState() async {
    final cancel = BotToastUtils.showLoading();

    final contactList =
        await contactListCubit.setContacts(state.pendings.toList());
    if (!isClosed) {
      emit(
        state.copyWith(
          pendings: {},
        ),
      );
    }

    cancel.call();

    if (contactList != null) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pendings: {},
            ownFollowings: contactList.contacts,
          ),
        );
      }
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(pendings: {}),
        );
      }
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  @override
  Future<void> close() {
    addFollowingOnStop?.cancel();
    followingsSubscription.cancel();
    return super.close();
  }
}
