import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/flash_news_model.dart';
import '../../models/relay_review.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'relay_feed_state.dart';

class RelayFeedCubit extends Cubit<RelayFeedState> {
  RelayFeedCubit({required this.relay})
      : super(
          const RelayFeedState(
            content: [],
            reviews: [],
            onAddingData: UpdatingState.success,
            onLoading: true,
            refresh: false,
            onLoadingReviews: true,
          ),
        );

  String relay;
  bool removeUponDisposal = false;

  Future<void> initView() async {
    if (!nc.activeRelays().contains(relay)) {
      await nc.connect(
        relay,
        waitForAuth: relay.contains('nostr.wine') ? true : null,
      );

      removeUponDisposal = true;
    }

    getRelayReviews(relay);
    buildRelayFeed(type: RelayContentType.notes, isAdding: false);
    _checkNip43Support();
  }

  Future<void> _checkNip43Support() async {
    final relayInfo = relayInfoCubit.state.relayInfos[relay];
    if (relayInfo != null) {
      final isSupported = relayInfo.nips.contains('43');
      if (!isClosed) {
        emit(state.copyWith(isNip43Supported: isSupported));
      }
      if (isSupported && currentSigner != null) {
        checkMembership();
      }
    } else {
      relayInfoCubit.getCurrentRelayInfo(relay);
      final updatedRelayInfo = relayInfoCubit.state.relayInfos[relay];
      if (updatedRelayInfo != null) {
        final isSupported = updatedRelayInfo.nips.contains('43');
        if (!isClosed) {
          emit(state.copyWith(isNip43Supported: isSupported));
        }
        if (isSupported && currentSigner != null) {
          checkMembership();
        }
      }
    }
  }

  Future<bool> checkMembership({bool refreshing = false}) async {
    if (!refreshing) {
      emit(state.copyWith(checkMembership: true));
    }

    final userPubkey = currentSigner?.getPublicKey() ?? '';

    if (userPubkey.isEmpty) {
      return false;
    }

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.RELAY_MEMBERSHIP_LIST],
      relays: [relay],
    );

    bool isMember = false;
    if (events.isNotEmpty) {
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestEvent = events.first;
      isMember = latestEvent.tags.any((tag) =>
          tag.length >= 2 && tag[0] == 'member' && tag[1] == userPubkey);
    }

    if (!isClosed) {
      emit(state.copyWith(isMember: isMember, checkMembership: false));
    }

    return isMember;
  }

  Future<String?> requestRelayInviteCode() async {
    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.RELAY_INVITE_REQUEST],
      relays: [relay],
    );

    if (events.isNotEmpty) {
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestEvent = events.first;
      for (final t in latestEvent.tags) {
        if (t.length >= 2 && t[0] == 'claim') {
          return t[1];
        }
      }
    }

    return null;
  }

  Future<void> joinRelay({
    required String inviteCode,
    required Function() onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.RELAY_JOIN_REQUEST,
      tags: [
        ['claim', inviteCode],
      ],
      content: '',
      signer: currentSigner,
    );

    if (event == null) {
      BotToastUtils.showError(t.errorSigningEvent);
      cancel();
      return;
    }

    final isSuccess = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: [relay],
      setProgress: true,
    );

    _handleJoinRelayResponse(isSuccess: isSuccess, onSuccess: onSuccess);

    cancel();
  }

  Future<void> _handleJoinRelayResponse({
    required bool isSuccess,
    required Function() onSuccess,
  }) async {
    if (isSuccess) {
      bool isMember = false;

      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 2));
        isMember = await checkMembership();

        if (isMember) {
          BotToastUtils.showSuccess(t.joinRequestSent);
          onSuccess.call();
          return;
        }
      }

      BotToastUtils.showError(t.errorJoiningRelay);
    } else {
      BotToastUtils.showError(t.errorJoiningRelay);
    }
  }

  Future<void> leaveRelay() async {
    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.RELAY_LEAVE_REQUEST,
      tags: [],
      content: '',
      signer: currentSigner,
    );

    if (event == null) {
      BotToastUtils.showError(t.errorSigningEvent);
      cancel();
      return;
    }

    final isSuccess = await NostrFunctionsRepository.sendEvent(
      event: event,
      relays: [relay],
      setProgress: true,
    );

    cancel();

    if (isSuccess) {
      checkMembership();
    } else {
      BotToastUtils.showError(t.errorLeavingRelay);
    }
  }

  void clearData() {
    if (!isClosed) {
      emit(
        state.copyWith(
          content: [],
          onAddingData: UpdatingState.success,
          onLoading: true,
        ),
      );
    }
  }

  Future<void> addRelayReview({
    required String review,
    required int rating,
    required Function() onSuccess,
  }) async {
    final cancel = BotToastUtils.showLoading();

    final event = await Event.genEvent(
      kind: EventKind.RELAY_REVIEW,
      tags: [
        ['d', Relay.clean(relay) ?? relay],
        ['rating', (rating / 5).toString()],
      ],
      content: review,
      signer: currentSigner,
    );

    if (event == null) {
      BotToastUtils.showError(t.errorSigningEvent);
      cancel();
      return;
    }

    final isSuccess = await NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: true,
    );

    cancel();

    if (isSuccess) {
      BotToastUtils.showSuccess(t.reviewSubmitted);
      onSuccess.call();
      final reviews = [RelayReview.fromEvent(event), ...state.reviews];
      if (!isClosed) {
        emit(
          state.copyWith(
            reviews: reviews,
          ),
        );
      }
    } else {
      BotToastUtils.showError(t.errorSubmittingReview);
    }
  }

  Future<void> getRelayReviews(String relayUrl) async {
    final url = Relay.clean(relayUrl) ?? relayUrl;

    final events = await NostrFunctionsRepository.getEventsAsync(
      dTags: [if (url.endsWith('/')) url else '$url/'],
      kinds: [EventKind.RELAY_REVIEW],
      includeIds: false,
    );

    final reviews = <RelayReview>[];

    for (final e in events) {
      final review = RelayReview.fromEvent(e);
      if (review.rating != -1) {
        reviews.add(review);
      }
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          reviews: reviews,
          onLoadingReviews: false,
        ),
      );
    }
  }

  Future<void> buildRelayFeed({
    required RelayContentType type,
    required bool isAdding,
  }) async {
    if (!isAdding) {
      clearData();
    } else {
      if (!isClosed) {
        emit(
          state.copyWith(
            onAddingData: UpdatingState.progress,
          ),
        );
      }
    }

    final until = state.content.isNotEmpty
        ? state.content.last.createdAt.toSecondsSinceEpoch() - 1
        : null;

    final content = await NostrFunctionsRepository.buildSingleRelayFeed(
      until: until,
      limit: 50,
      type: type,
      relay: relay,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          content: [...state.content, ...content],
          onLoading: false,
          onAddingData:
              content.isEmpty ? UpdatingState.idle : UpdatingState.success,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (removeUponDisposal) {
      nc.closeConnect([relay]);
    }

    return super.close();
  }
}
