import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/extensions.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../models/packs_model.dart';
import '../../repositories/nostr_functions_repository.dart';
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
  }

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

    if (isClosed) {
      return;
    }

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
}
