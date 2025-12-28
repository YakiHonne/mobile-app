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
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this.pubkey,
  }) : super(
          ProfileState.intial(pubkey: pubkey),
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

    if (canSign() && pubkey == currentSigner!.getPublicKey()) {
      pinnedNotesSubscription = nostrRepository.pinnedNotesStream.listen(
        (pNotes) {
          pinnedNotes = pNotes;
          if (currentProfileData == ProfileData.pinned) {
            getUserInfos(profileData: ProfileData.pinned);
          }
        },
      );
    }

    setIsFollowedByUser();
  }

  late StreamSubscription followingsSubscription;
  late StreamSubscription bookmarksSubscription;
  late StreamSubscription mutesListSubscription;
  StreamSubscription? pinnedNotesSubscription;

  final String pubkey;
  String fetchId = '';
  Set<String> requests = {};
  Set<String> pinnedNotes = {};
  ProfileData currentProfileData = ProfileData.notes;

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
      _emit(ProfileState.intial(pubkey: pubkey));

      setIsFollowedByUser();
    }
  }

  void initView() {
    establishRequiredData();
    getUserInfos();
  }

  void onRemoveMutedContent(
    String pubkey,
    bool isNotes,
  ) {
    if (!isClosed) {
      final newContent = List<Event>.from(state.content)
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
          content: newContent,
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

  // void getMoreNotes(bool isReplies) {
  //   if (state.notes.isNotEmpty) {
  //     final oldNotes = isReplies ? state.replies : state.notes;

  //     List<Event> newNotes = [];
  //     if (!isClosed) {
  //       _emit(
  //         state.copyWith(
  //           notesLoading: isReplies ? null : UpdatingState.progress,
  //           repliesLoading: isReplies ? UpdatingState.progress : null,
  //         ),
  //       );
  //     }

  //     NostrFunctionsRepository.getDetailedNotes(
  //       kinds: [EventKind.TEXT_NOTE, if (!isReplies) EventKind.REPOST],
  //       isReplies: isReplies,
  //       onNotesFunc: (notes) {
  //         newNotes = notes;
  //       },
  //       pubkeys: [pubkey],
  //       until: oldNotes.last.createdAt - 1,
  //       limit: 30,
  //       onDone: () {
  //         if (!isClosed) {
  //           _emit(
  //             state.copyWith(
  //               notes: isReplies ? null : [...oldNotes, ...newNotes],
  //               notesLoading: isReplies
  //                   ? null
  //                   : newNotes.isEmpty
  //                       ? UpdatingState.idle
  //                       : UpdatingState.success,
  //               replies: !isReplies ? null : [...oldNotes, ...newNotes],
  //               repliesLoading: !isReplies
  //                   ? null
  //                   : newNotes.isEmpty
  //                       ? UpdatingState.idle
  //                       : UpdatingState.success,
  //             ),
  //           );
  //         }
  //       },
  //     );
  //   }
  // }

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
    loadPinnedNotes();
    establishMetadata();
    getFollowingsAndFollowersCount();
    loadContactList();
  }

  Future<void> loadPinnedNotes() async {
    if (pubkey != currentSigner?.getPublicKey()) {
      final events = await NostrFunctionsRepository.getEventsAsync(
        pubkeys: [pubkey],
        kinds: [EventKind.PINNED_NOTES],
      );

      if (events.isNotEmpty) {
        pinnedNotes = events.first.eTags.toSet();
      }
    } else {
      pinnedNotes = nostrRepository.pinnedNotes;
    }
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

  Future<void> getUserInfos({
    bool isAdding = false,
    ProfileData profileData = ProfileData.notes,
  }) async {
    final id = uuid.v4();
    fetchId = id;

    currentProfileData = profileData;
    int? until;

    if (!isAdding) {
      _emit(state.intialData());
    } else {
      _emit(
        state.copyWith(
          loadingState: UpdatingState.progress,
        ),
      );

      until = state.content.last.createdAt - 1;
    }

    if (profileData == ProfileData.pinned && pinnedNotes.isEmpty) {
      _emit(
        state.copyWith(
          loadingState: UpdatingState.idle,
          isLoading: false,
        ),
      );

      return;
    }

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [
        if (profileData == ProfileData.notes) ...[
          EventKind.TEXT_NOTE,
          EventKind.REPOST
        ],
        if (profileData == ProfileData.pinned ||
            profileData == ProfileData.replies ||
            profileData == ProfileData.mentions) ...[
          EventKind.TEXT_NOTE,
        ],
        if (profileData == ProfileData.curations) ...[
          EventKind.CURATION_ARTICLES,
          EventKind.CURATION_VIDEOS,
        ],
        if (profileData == ProfileData.videos ||
            profileData == ProfileData.allMedia) ...[
          EventKind.VIDEO_HORIZONTAL,
          EventKind.VIDEO_VERTICAL,
          EventKind.LEGACY_VIDEO_HORIZONTAL,
          EventKind.LEGACY_VIDEO_VERTICAL,
        ],
        if (profileData == ProfileData.pictures ||
            profileData == ProfileData.allMedia) ...[
          EventKind.PICTURE,
        ],
        if (profileData == ProfileData.smartWidgets) EventKind.SMART_WIDGET_ENH,
        if (profileData == ProfileData.articles) EventKind.LONG_FORM,
      ],
      pTags: profileData == ProfileData.mentions ? [pubkey] : null,
      pubkeys: profileData == ProfileData.mentions ||
              profileData == ProfileData.pinned
          ? null
          : [pubkey],
      ids: profileData == ProfileData.pinned ? pinnedNotes.toList() : null,
      until: until,
      limit: 100,
      source: EventsSource.all,
    );

    if (fetchId == id) {
      final handledEvents =
          handleEvents(events: events, profileData: profileData);

      _emit(
        state.copyWith(
          loadingState:
              handledEvents.isEmpty || profileData == ProfileData.pinned
                  ? UpdatingState.idle
                  : UpdatingState.success,
          content: [...state.content, ...handledEvents],
          isLoading: false,
        ),
      );
    }
  }

  List<Event> handleEvents({
    required List<Event> events,
    required ProfileData profileData,
  }) {
    List<Event> selectedEvents = <Event>[];

    switch (profileData) {
      case ProfileData.notes:
        for (final e in events) {
          if ((e.kind == EventKind.TEXT_NOTE && e.root == null) ||
              e.kind == EventKind.REPOST) {
            selectedEvents.add(e);
          }
        }

      case ProfileData.mentions:
        for (final e in events) {
          final hasMentionVal = hasMention(content: e.content, pubkey: pubkey);

          if (hasMentionVal) {
            selectedEvents.add(e);
          }
        }

      case ProfileData.replies:
        for (final e in events) {
          if (e.root != null) {
            selectedEvents.add(e);
          }
        }

      case ProfileData.pinned:
        selectedEvents = events;

      case ProfileData.articles:
        selectedEvents = events;
      case ProfileData.curations:
        selectedEvents = events;
      case ProfileData.smartWidgets:
        selectedEvents = events;
      case ProfileData.allMedia:
        selectedEvents = events;
      case ProfileData.videos:
        selectedEvents = events;
      case ProfileData.pictures:
        selectedEvents = events;
    }

    selectedEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return selectedEvents;
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
    pinnedNotesSubscription?.cancel();
    nc.closeRequests(requests.toList());
    return super.close();
  }
}
