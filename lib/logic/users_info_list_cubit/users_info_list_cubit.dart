import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../globals.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_data_repository.dart';
import '../../utils/bot_toast_util.dart';

part 'users_info_list_state.dart';

class UsersInfoListCubit extends Cubit<UsersInfoListState> {
  UsersInfoListCubit({required this.nostrRepository})
      : super(
          UsersInfoListState(
            isLoading: false,
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            isValidUser: canSign(),
            currentUserPubKey: nostrRepository.currentMetadata.pubkey,
            followings: contactListCubit.contacts,
            pendings: const {},
          ),
        ) {
    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              followings: followings,
            ),
          );
        }
      },
    );

    muteListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mm.usersMutes.toList(),
            ),
          );
        }
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription muteListSubscription;
  final NostrDataRepository nostrRepository;
  Set<String> requests = {};
  Set<String> pubkeys = {};
  Timer? addFollowingOnStop;

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
    if (canSign()) {
      final cancel = BotToastUtils.showLoading();

      final contactList =
          await contactListCubit.setContacts(state.pendings.toList());

      if (contactList != null) {
        if (!isClosed) {
          emit(
            state.copyWith(
              pendings: {},
              followings: contactList.contacts,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(state.copyWith(pendings: {}));
        }
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    }
  }

  @override
  Future<void> close() {
    nc.closeRequests(requests.toList());
    followingsSubscription.cancel();
    muteListSubscription.cancel();
    return super.close();
  }
}
