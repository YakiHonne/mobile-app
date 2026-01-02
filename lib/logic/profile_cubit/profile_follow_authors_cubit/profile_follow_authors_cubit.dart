import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'profile_follow_authors_state.dart';

class ProfileFollowAuthorsCubit extends Cubit<ProfileFollowAuthorsState> {
  ProfileFollowAuthorsCubit({
    required this.pubkey,
    required bool isFollowers,
  }) : super(
          ProfileFollowAuthorsState(
            followers: const [],
            followings: const [],
            isFollowersLoading: false,
            isFollowingLoading: false,
            isFollowers: isFollowers,
            isValidUser: canSign(),
            currentUserPubKey: nostrRepository.currentMetadata.pubkey,
            ownFollowings: contactListCubit.contacts,
            pendings: const {},
          ),
        ) {
    loadInfos();

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

  late StreamSubscription followingsSubscription;
  Set<String> requests = {};
  Timer? addFollowingOnStop;
  String pubkey;

  void loadInfos() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isFollowersLoading: true,
          isFollowingLoading: true,
        ),
      );
    }

    loadFollowers();
    loadFollowings();
  }

  Future<void> loadFollowers() async {
    Set<String> followers =
        await NostrFunctionsRepository.getRcUserAsyncFollowers(pubkey);

    if (followers.isEmpty) {
      final events = await NostrFunctionsRepository.getEventsAsync(
        kinds: [EventKind.CONTACT_LIST],
        pTags: [pubkey],
      );

      followers = events
          .map(
            (e) => e.pubkey,
          )
          .toSet();
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          followers: followers.toList(),
          isFollowersLoading: false,
        ),
      );
    }
  }

  Future<void> loadFollowings() async {
    final contactList = await nc.loadContactList(pubkey);
    if (!isClosed) {
      emit(
        state.copyWith(
          followings: contactList?.contacts,
          isFollowingLoading: false,
        ),
      );
    }
  }

  void toggleFollowers() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isFollowers: !state.isFollowers,
        ),
      );
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
    if (state.isValidUser) {
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
  }

  @override
  Future<void> close() {
    nc.closeRequests(requests.toList());
    followingsSubscription.cancel();
    return super.close();
  }
}
