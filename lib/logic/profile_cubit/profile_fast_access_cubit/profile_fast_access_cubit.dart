// ignore_for_file: prefer_foreach

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../repositories/http_functions_repository.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'profile_fast_access_state.dart';

class ProfileFastAccessCubit extends Cubit<ProfileFastAccessState> {
  ProfileFastAccessCubit({required this.pubkey})
      : super(
          ProfileFastAccessState(
            commonPubkeys: nostrRepository.mutuals[pubkey] ?? const {},
            isFollowing: contactListCubit.contacts.contains(pubkey),
            followersCount: 0,
            refresh: false,
          ),
        ) {
    getFollowers();

    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isFollowing: followings.contains(pubkey),
            ),
          );
        }
      },
    );

    muteSubscription = nostrRepository.mutesStream.listen(
      (followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              refresh: !state.refresh,
            ),
          );
        }
      },
    );
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription muteSubscription;
  late String pubkey;

  Future<void> getFollowers() async {
    final data = await Future.wait(
      [
        NostrFunctionsRepository.getRcUserMutuals(pubkey),
        NostrFunctionsRepository.getRcUserInfos(pubkey),
      ],
    );

    final pubkeys = data[0] as Set<String>;
    final info = data[1] as Map<String, dynamic>;

    if (pubkeys.isNotEmpty) {
      nostrRepository.mutuals[pubkey] = pubkeys;
    }

    int followers = info['followers'];

    if (followers == 0) {
      followers = await HttpFunctionsRepository.getUserFollowers(pubkey);
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          commonPubkeys: pubkeys,
          followersCount: followers,
        ),
      );
    }
  }

  Future<void> setFollowingState() async {
    final cancel = BotToastUtils.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowing,
      targetPubkey: pubkey,
    );

    cancel.call();
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    muteSubscription.cancel();
    return super.close();
  }
}
