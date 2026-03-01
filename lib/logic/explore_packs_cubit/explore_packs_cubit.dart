import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/extensions.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../models/packs_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'explore_packs_state.dart';

class ExplorePacksCubit extends Cubit<ExplorePacksState> {
  ExplorePacksCubit()
      : super(ExplorePacksState(
          isLoading: false,
          updatingState: UpdatingState.success,
          packs: const [],
          pendings: const {},
          currentUserPubKey: currentSigner?.getPublicKey() ?? '',
          ownFollowings: contactListCubit.contacts,
        )) {
    getPacks(isStarterPack: true);

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

  Future<void> getPacks({
    required bool isStarterPack,
    bool isAdding = false,
  }) async {
    if (isAdding) {
      emit(state.copyWith(updatingState: UpdatingState.progress));
    } else {
      emit(
        state.copyWith(
          isLoading: true,
          updatingState: UpdatingState.success,
          packs: [],
        ),
      );
    }

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [
        if (isStarterPack) EventKind.STARTER_PACKS,
        if (!isStarterPack) EventKind.MEDIA_PACKS,
      ],
      limit: 30,
      until: isAdding ? state.packs.last.createdAt.toSecondsSinceEpoch() : null,
    );

    final packs = events.map((event) => PacksModel.fromEvent(event)).toList();
    final usedPacks = packs.where((pack) => pack.pubkeys.isNotEmpty).toList();

    emit(
      state.copyWith(
        isLoading: false,
        updatingState:
            packs.isEmpty ? UpdatingState.idle : UpdatingState.success,
        packs: isAdding ? [...state.packs, ...usedPacks] : usedPacks,
      ),
    );
  }

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
