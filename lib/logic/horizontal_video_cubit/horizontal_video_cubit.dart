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
import '../../models/detailed_note_model.dart';
import '../../models/video_model.dart';
import '../../models/vote_model.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'horizontal_video_state.dart';

class HorizontalVideoCubit extends Cubit<HorizontalVideoState> {
  HorizontalVideoCubit({required VideoModel video})
      : super(
          HorizontalVideoState(
            author: Metadata.empty().copyWith(pubkey: video.pubkey),
            mutes: nostrRepository.mutes.toList(),
            currentUserPubkey: nostrRepository.currentMetadata.pubkey,
            canBeZapped: false,
            refresh: false,
            isSameArticleAuthor:
                video.pubkey == nostrRepository.currentMetadata.pubkey,
            votes: const <String, VoteModel>{},
            replies: const <DetailedNoteModel>[],
            zaps: const <String, double>{},
            reports: const <String>{},
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
      (Set<String> mutes) {
        if (!isClosed) {
          emit(
            state.copyWith(
              mutes: mutes.toList(),
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
    getStats();
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
        setProgress: true,
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

  void getStats() {
    NostrFunctionsRepository.getStats(
      identifier: state.video.id,
      eventKind: state.video.kind,
      eventPubkey: state.video.pubkey,
      isEtag: false,
      getViews: true,
    ).listen(
      (data) {
        if (data is Map<String, Map<String, VoteModel>>) {
          final Map<String, VoteModel> votes =
              Map<String, VoteModel>.from(state.votes)
                ..addAll(
                  data[state.video.id] ?? <String, VoteModel>{},
                );
          if (!isClosed) {
            emit(
              state.copyWith(
                votes: votes,
              ),
            );
          }
        } else if (data is Map<String, DetailedNoteModel>) {
          final replies = data.values
              .toList()
              .where(
                (e) =>
                    e.replyTo == getBaseEventModelId(state.video) ||
                    e.originId == getBaseEventModelId(state.video),
              )
              .toList();
          if (!isClosed) {
            emit(
              state.copyWith(
                replies: replies,
              ),
            );
          }
        } else if (data is Map<String, double>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                zaps: data,
              ),
            );
          }
        } else if (data is Set<String>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                reports: data,
              ),
            );
          }
        } else if (data is List<String>) {
          if (!isClosed) {
            emit(
              state.copyWith(
                viewsCount: data,
              ),
            );
          }
        }
      },
      onDone: () {},
    );
  }

  Future<void> setFollowingState() async {
    final CancelFunc cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingAuthor,
      targetPubkey: state.video.pubkey,
    );

    cancel.call();
  }

  void addReply({
    required Event event,
  }) {
    if (!isClosed) {
      emit(
        state.copyWith(
          replies: List.from(state.replies)
            ..add(
              DetailedNoteModel.fromEvent(event),
            ),
        ),
      );
    }
  }

  Future<void> setVote({
    required bool upvote,
    required String eventId,
    required String eventPubkey,
  }) async {
    final cancel = BotToast.showLoading();

    final currentVoteModel = state.votes[state.currentUserPubkey];

    if (currentVoteModel == null || upvote != currentVoteModel.vote) {
      final addingEventId = await NostrFunctionsRepository.addVote(
        eventId: eventId,
        upvote: upvote,
        identifier: state.video.id,
        kind: state.video.kind,
        eventPubkey: eventPubkey,
        isEtag: true,
      );

      if (addingEventId != null) {
        if (currentVoteModel != null) {
          await NostrFunctionsRepository.deleteEvent(
            eventId: currentVoteModel.eventId,
          );
        }

        final Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap[state.currentUserPubkey] = VoteModel(
          eventId: addingEventId,
          pubkey: state.currentUserPubkey,
          vote: upvote,
        );
        if (!isClosed) {
          emit(
            state.copyWith(votes: newMap),
          );
        }
      } else {
        BotToastUtils.showError(
          t.voteNotSubmitted.capitalizeFirst(),
        );
      }
    } else {
      final bool isSuccessful = await NostrFunctionsRepository.deleteEvent(
        eventId: currentVoteModel.eventId,
      );

      if (isSuccessful) {
        final Map<String, VoteModel> newMap = Map.from(state.votes);

        newMap.remove(currentVoteModel.pubkey);
        if (!isClosed) {
          emit(
            state.copyWith(
              votes: newMap,
            ),
          );
        }
      } else {
        BotToastUtils.showError(
          t.voteNotSubmitted.capitalizeFirst(),
        );
      }
    }

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
