import 'dart:async';
import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.pubkey,
  }) : super(
          ProfileState(
            profileStatus: ProfileStatus.loading,
            notesLoading: UpdatingState.success,
            repliesLoading: UpdatingState.success,
            isFollowedByUser: false,
            isRelaysLoading: true,
            isVideoLoading: true,
            isNotesLoading: true,
            isRepliesLoading: true,
            isSmartWidgetsLoading: true,
            isArticlesLoading: true,
            mutes: nostrRepository.muteModel.usersMutes.toList(),
            userRelays: const [],
            videos: const [],
            notes: const [],
            replies: const [],
            articles: const [],
            curations: const [],
            smartWidgets: const [],
            canBeZapped: false,
            isFollowingUser: false,
            isNip05: false,
            isSameUser: canSign() && pubkey == currentSigner!.getPublicKey(),
            followers: 0,
            followings: 0,
            bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            activeRelays: nc.activeRelays(),
            ownRelays: nc.relays(),
            user: Metadata.empty().copyWith(
              pubkey: pubkey,
            ),
            ratingImpact: 0,
            writingImpact: 0,
            negativeWritingImpact: 0,
            ongoingWritingImpact: 0,
            positiveRatingImpactH: 0,
            positiveRatingImpactNh: 0,
            positiveWritingImpact: 0,
            negativeRatingImpactH: 0,
            negativeRatingImpactNh: 0,
            ongoingRatingImpact: 0,
            refresh: false,
          ),
        ) {
    bookmarksSubscription = nostrRepository.bookmarksStream.listen(
      (bookmarks) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
            ),
          );
        }
      },
    );

    mutesListSubscription = nostrRepository.mutesStream.listen(
      (mm) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              mutes: mm.usersMutes.toList(),
              refresh: !state.refresh,
            ),
          );
        }
      },
    );

    followingsSubscription = nostrRepository.contactListStream.listen(
      (followings) {
        final Set<String>? followingsList =
            canSign() && pubkey == currentSigner!.getPublicKey()
                ? followings.toSet()
                : null;

        if (!isClosed) {
          _emit(
            state.copyWith(
              isFollowingUser: followings.contains(pubkey),
              followings: followingsList?.length,
            ),
          );
        }
      },
    );

    setIsFollowedByUser();
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesListSubscription;

  final String pubkey;
  Set<String> requests = {};

  Future<void> setIsFollowedByUser() async {
    final contactList = await contactListCubit.getContactList(pubkey);

    final isFollowedByUser = !isDisconnected() &&
        (contactList?.contacts.contains(currentSigner!.getPublicKey()) ??
            false);

    _emit(
      state.copyWith(
        isFollowedByUser: isFollowedByUser,
        refresh: !state.refresh,
      ),
    );
  }

  void emitEmptyState() {
    if (!isClosed) {
      _emit(
        ProfileState(
          profileStatus: ProfileStatus.loading,
          isFollowedByUser: false,
          notesLoading: UpdatingState.idle,
          repliesLoading: UpdatingState.idle,
          isVideoLoading: true,
          isRelaysLoading: true,
          isNotesLoading: true,
          isRepliesLoading: true,
          isSmartWidgetsLoading: true,
          userRelays: const [],
          videos: const [],
          notes: const [],
          replies: const [],
          articles: const [],
          curations: const [],
          smartWidgets: const [],
          mutes: nostrRepository.muteModel.usersMutes.toList(),
          isArticlesLoading: true,
          canBeZapped: false,
          isFollowingUser: false,
          isNip05: false,
          isSameUser: canSign() && pubkey == currentSigner!.getPublicKey(),
          followers: 0,
          followings: 0,
          bookmarks: getBookmarkIds(nostrRepository.bookmarksLists).toSet(),
          activeRelays: nc.activeRelays(),
          ownRelays: nc.relays(),
          user: Metadata.empty()..copyWith(pubkey: pubkey),
          ratingImpact: 0,
          writingImpact: 0,
          negativeWritingImpact: 0,
          ongoingWritingImpact: 0,
          positiveRatingImpactH: 0,
          positiveRatingImpactNh: 0,
          positiveWritingImpact: 0,
          negativeRatingImpactH: 0,
          negativeRatingImpactNh: 0,
          ongoingRatingImpact: 0,
          refresh: !state.refresh,
        ),
      );

      setIsFollowedByUser();
    }
  }

  void initView() {
    getUserInfos();
    getImpacts();
  }

  Future<void> getImpacts() async {
    try {
      final response = await HttpFunctionsRepository.getImpacts(pubkey);
      if (!isClosed) {
        _emit(
          state.copyWith(
            writingImpact: response['writing'],
            ratingImpact: response['rating'],
            negativeWritingImpact: response['negativeWriting'],
            ongoingWritingImpact: response['ongoingWriting'],
            positiveRatingImpactH: response['positiveRatingH'],
            positiveRatingImpactNh: response['positiveRatingNh'],
            positiveWritingImpact: response['positiveWriting'],
            negativeRatingImpactH: response['negativeRatingH'],
            negativeRatingImpactNh: response['negativeRatingNh'],
            ongoingRatingImpact: response['ongoingRating'],
          ),
        );
      }
    } catch (_) {}
  }

  void onRemoveMutedContent(
    String pubkey,
    bool isNotes,
  ) {
    if (!isClosed) {
      final newContent = List<Event>.from(isNotes ? state.notes : state.replies)
        ..removeWhere((e) {
          if (e.kind == EventKind.REPOST) {
            try {
              final repost = Event.fromJson(jsonDecode(e.content));

              return repost.pubkey == pubkey;
            } catch (_) {
              return false;
            }
          } else {
            return e.pubkey == pubkey;
          }
        });

      _emit(
        state.copyWith(
          notes: isNotes ? newContent : state.notes,
          replies: !isNotes ? newContent : state.replies,
          refresh: !state.refresh,
        ),
      );
    }
  }

  Future<void> setMuteStatus({
    required String pubkey,
    required Function() onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    final result = await NostrFunctionsRepository.setMuteList(muteKey: pubkey);
    cancel();

    if (result) {
      final hasBeenMuted = isUserMuted(state.user.pubkey);

      BotToastUtils.showSuccess(
        hasBeenMuted
            ? t.userHasBeenMuted.capitalizeFirst()
            : t.userHasBeenUnmuted.capitalizeFirst(),
      );

      onSuccess.call();
    } else {
      BotToastUtils.showUnreachableRelaysError();
    }
  }

  void getMoreNotes(bool isReplies) {
    if (state.notes.isNotEmpty) {
      final oldNotes = isReplies ? state.replies : state.notes;

      List<Event> newNotes = [];
      if (!isClosed) {
        _emit(
          state.copyWith(
            notesLoading: isReplies ? null : UpdatingState.progress,
            repliesLoading: isReplies ? UpdatingState.progress : null,
          ),
        );
      }

      NostrFunctionsRepository.getDetailedNotes(
        kinds: [EventKind.TEXT_NOTE, if (!isReplies) EventKind.REPOST],
        isReplies: isReplies,
        onNotesFunc: (notes) {
          newNotes = notes;
        },
        pubkeys: [pubkey],
        until: oldNotes.last.createdAt - 1,
        limit: 30,
        onDone: () {
          if (!isClosed) {
            _emit(
              state.copyWith(
                notes: isReplies ? null : [...oldNotes, ...newNotes],
                notesLoading: isReplies
                    ? null
                    : newNotes.isEmpty
                        ? UpdatingState.idle
                        : UpdatingState.success,
                replies: !isReplies ? null : [...oldNotes, ...newNotes],
                repliesLoading: !isReplies
                    ? null
                    : newNotes.isEmpty
                        ? UpdatingState.idle
                        : UpdatingState.success,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> shareLink(RenderBox? renderBox) async {
    final res = await externalShearableLink(
      kind: EventKind.METADATA,
      pubkey: '',
      id: state.user.pubkey,
    );

    Share.share(
      res,
      subject: 'Check out www.yakihonne.com for me more.',
      sharePositionOrigin: renderBox != null
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null,
    );
  }

  Future<void> establishRequiredData() async {
    establishMetadata();
    getFollowingsAndFollowersCount();
    loadContactList();
  }

  Future<void> establishMetadata() async {
    bool isFollowing = false;

    if (canSign()) {
      isFollowing = contactListCubit.contacts.contains(pubkey);
    }

    await getCachedMetadata(isFollowing);
    await getFreshMetadata(isFollowing);
  }

  Future<void> getCachedMetadata(bool isFollowing) async {
    final m = metadataCubit.getMemoryMetadata(pubkey) ??
        await metadataCubit.getAvailableMetadata(pubkey);

    setCurrentMetadata(m, isFollowing);
  }

  Future<void> getFreshMetadata(bool isFollowing) async {
    final metadata = await metadataCubit.getFutureMetadata(
      pubkey,
      forceSearch: true,
    );

    if (metadata != null) {
      setCurrentMetadata(metadata, isFollowing);
    }
  }

  Future<void> setCurrentMetadata(Metadata m, bool isFollowing) async {
    bool isNip05 = state.isNip05;

    if (!state.isNip05 && m.nip05.isNotEmpty) {
      isNip05 = await metadataCubit.isNip05Valid(m);
    }

    _emit(
      state.copyWith(
        isNip05: isNip05,
        user: m,
        refresh: !state.refresh,
        isFollowingUser: isFollowing,
        profileStatus: ProfileStatus.available,
        canBeZapped: (m.lud16.isNotEmpty || m.lud06.isNotEmpty) &&
            canSign() &&
            m.pubkey != currentSigner!.getPublicKey(),
      ),
    );
  }

  Future<void> getUserInfos() async {
    establishRequiredData();

    final requestId = await NostrFunctionsRepository.getUserProfile(
      authorPubkey: pubkey,
      curationsFunc: (curations) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              curations: curations,
            ),
          );
        }
      },
      smartWidgetFunc: (widgets) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              smartWidgets: widgets,
              isSmartWidgetsLoading: false,
            ),
          );
        }
      },
      videosFunc: (videos) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              videos: videos,
              isVideoLoading: false,
            ),
          );
        }
      },
      notesFunc: (notes) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              notes: notes,
              isNotesLoading: false,
            ),
          );
        }
      },
      repliesFunc: (replies) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              replies: replies,
              isRepliesLoading: false,
            ),
          );
        }
      },
      articleFunc: (articles) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              articles: articles,
              isArticlesLoading: false,
            ),
          );
        }
      },
      relaysFunc: (relays) {
        if (!isClosed) {
          _emit(
            state.copyWith(
              userRelays: relays.toList(),
              isRelaysLoading: false,
            ),
          );
        }
      },
      onDone: () {
        if (!isClosed) {
          _emit(
            state.copyWith(
              isArticlesLoading: false,
              isRelaysLoading: false,
              isVideoLoading: false,
              isNotesLoading: false,
              isSmartWidgetsLoading: false,
              isRepliesLoading: false,
            ),
          );
        }
      },
    );

    requests.add(requestId);
  }

  Future<void> getFollowingsAndFollowersCount() async {
    final counts = await NostrFunctionsRepository.getRcUserInfos(pubkey);

    int followers = counts['followers'] ?? 0;

    if (followers == 0) {
      followers = await HttpFunctionsRepository.getUserFollowers(pubkey);
    }

    if (!isClosed) {
      _emit(
        state.copyWith(
          followers: followers,
        ),
      );
    }
  }

  Future<void> loadContactList() async {
    final contactList = await nc.loadContactList(pubkey);

    if (contactList != null) {
      if (!isClosed) {
        _emit(
          state.copyWith(
            followings: contactList.contacts.length,
            isFollowedByUser: !isDisconnected() &&
                (contactList.contacts.contains(currentSigner!.getPublicKey())),
          ),
        );
      }
    }
  }

  Future<void> addRelay({required String newRelay}) async {
    final String relay = newRelay.removeLastBackSlashes();

    if (state.activeRelays.contains(relay)) {
      BotToastUtils.showError(
        t.relayInUse.capitalizeFirst(),
      );
      return;
    }

    final cancel = BotToast.showLoading();

    final isSuccessful = await NostrFunctionsRepository.connectToRelay(relay);

    if (isSuccessful) {
      await nc.connect(relay);
      setRelays();
    } else {
      BotToastUtils.showError(
        t.errorConnectingRelay.capitalizeFirst(),
      );
    }

    cancel.call();
  }

  void setRelays() {
    final allRelays = nc.relays();
    final activeRelays = nc.activeRelays();

    if (!isClosed) {
      emit(
        state.copyWith(
          ownRelays: allRelays,
          activeRelays: activeRelays,
        ),
      );
    }
  }

  Future<void> setFollowingState() async {
    final cancel = BotToast.showLoading();

    await NostrFunctionsRepository.setFollowingEvent(
      isFollowingAuthor: state.isFollowingUser,
      targetPubkey: pubkey,
    );

    cancel.call();
  }

  void _emit(ProfileState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  @override
  Future<void> close() {
    followingsSubscription.cancel();
    bookmarksSubscription.cancel();
    mutesListSubscription.cancel();
    nc.closeRequests(requests.toList());
    return super.close();
  }
}
