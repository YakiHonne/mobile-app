import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/bookmark_list_model.dart';
import '../../models/video_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'horizontal_video_state.dart';

class HorizontalVideoCubit extends Cubit<HorizontalVideoState> {
  HorizontalVideoCubit({required VideoModel video})
      : super(
          HorizontalVideoState(
            author: Metadata.empty().copyWith(pubkey: video.pubkey),
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            currentUserPubkey: nostrRepository.currentMetadata.pubkey,
            canBeZapped: false,
            refresh: false,
            isSameArticleAuthor:
                video.pubkey == nostrRepository.currentMetadata.pubkey,
            isFollowingAuthor: false,
            isBookmarked: getBookmarkIds(nostrRepository.bookmarksLists)
                .contains(video.id),
            isLoading: true,
            video: video,
            viewsCount: const <String>[],
          ),
        ) {
    userSubscription =
        nostrRepository.currentSignerStream.listen((EventSigner? signer) {
      if (signer == null || signer.isGuest()) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isSameArticleAuthor: false,
            ),
          );
        }
      } else {
        if (!isClosed) {
          emit(
            state.copyWith(
              isSameArticleAuthor: video.pubkey == signer.getPublicKey(),
            ),
          );
        }
      }
    });

    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (Map<String, BookmarkListModel> bookmarks) {
        final bool isBookmarked =
            getBookmarkIds(nostrRepository.bookmarksLists).contains(video.id);

        if (!isClosed) {
          emit(
            state.copyWith(
              isBookmarked: isBookmarked,
            ),
          );
        }
      },
    );

    followingsSubscription = nostrRepository.contactListStream.listen(
      (List<String> followings) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isFollowingAuthor: followings.contains(video.pubkey),
            ),
          );
        }
      },
    );

    mutesSubscription = nostrRepository.mutesStream.listen(
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
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesSubscription;
  late StreamSubscription userSubscription;

  void initView() {
    setAuthor();
    setVideoView();
  }

  Future<void> setAuthor() async {
    bool isFollowing = false;
    final metadata = await metadataCubit.getCachedMetadata(state.video.pubkey);

    if (metadata != null) {
      if (canSign() && state.video.pubkey != state.currentUserPubkey) {
        isFollowing = contactListCubit.contacts.contains(metadata.pubkey);
      }

      if (!isClosed) {
        emit(
          state.copyWith(
            author: metadata,
            isFollowingAuthor: isFollowing,
            canBeZapped: metadata.lud16.isNotEmpty &&
                canSign() &&
                state.video.pubkey != currentSigner!.getPublicKey(),
          ),
        );
      }

      return;
    }

    NostrFunctionsRepository.getUserMetaData(
      pubkey: state.video.pubkey,
    ).listen(
      (Metadata metadata) {
        if (canSign() && state.video.pubkey != state.currentUserPubkey) {
          isFollowing = contactListCubit.contacts.contains(metadata.pubkey);
        }
        if (!isClosed) {
          emit(
            state.copyWith(
              author: metadata,
              isFollowingAuthor: isFollowing,
              canBeZapped: metadata.lud16.isNotEmpty &&
                  canSign() &&
                  state.video.pubkey != currentSigner!.getPublicKey(),
            ),
          );
        }
      },
    );
  }

  Future<void> setVideoView() async {
    await Future<dynamic>.delayed(
      const Duration(seconds: 2),
    );

    if (canSign()) {
      final event = await Event.genEvent(
        kind: EventKind.VIDEO_VIEW,
        tags: <List<String>>[
          <String>['e', state.video.id],
        ],
        content: '',
        signer: currentSigner,
      );

      if (event == null) {
        return;
      }

      final bool isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: false,
      );

      if (isSuccessful &&
          !state.viewsCount.contains(currentSigner!.getPublicKey())) {
        final List<String> views = List<String>.from(state.viewsCount)
          ..add(currentSigner!.getPublicKey());
        if (!isClosed) {
          emit(
            state.copyWith(
              viewsCount: views,
            ),
          );
        }
      }
    }
  }

  Future<void> setFollowingState() async {
    final CancelFunc cancel = BotToastUtils.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.video.pubkey,
    );

    cancel.call();
  }

  Future<void> shareLink(RenderBox? renderBox) async {
    final res = await externalShearableLink(
      kind: state.video.kind,
      pubkey: state.video.pubkey,
      id: state.video.id,
    );

    Share.share(
      res,
      subject: 'Check out www.yakihonne.com for more videos.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    mutesSubscription.cancel();
    userSubscription.cancel();
    return super.close();
  }
}
