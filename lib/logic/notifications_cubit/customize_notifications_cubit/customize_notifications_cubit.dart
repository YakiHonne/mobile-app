import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/notifications/notification_helper.dart';
import '../../../common/notifications/push_core.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

part 'customize_notifications_state.dart';

class CustomizeNotificationsCubit extends Cubit<CustomizeNotificationsState> {
  CustomizeNotificationsCubit()
      : super(
          const CustomizeNotificationsState(
            notifFollowings: true,
            notifMentionsReplies: true,
            notifReactions: true,
            notifReposts: true,
            notifZaps: true,
            refresh: true,
            enablePushNotification: true,
            notifPrivateMessage: true,
            notifMaxMentions: true,
          ),
        ) {
    init();
  }

  bool isUpdated = false;

  void init() {
    final c = nostrRepository.currentAppCustomization!;
    if (!isClosed) {
      emit(
        state.copyWith(
          notifFollowings: c.notifFollowings,
          notifMentionsReplies: c.notifMentionsReplies,
          notifReactions: c.notifReactions,
          notifReposts: c.notifReposts,
          notifZaps: c.notifZaps,
          enablePushNotification: c.enablePushNotification,
          notifPrivateMessage: c.notifPrivateMessage,
          notifMaxMentions: c.notifMaxMentions,
        ),
      );
    }
  }

  void setFollowings() {
    if (state.notifFollowings && abort()) {
      BotToastUtils.showError(t.oneNotifOptionAvailable.capitalizeFirst());
      return;
    }

    isUpdated = true;

    if (!isClosed) {
      emit(
        state.copyWith(
          notifFollowings: !state.notifFollowings,
        ),
      );
    }
  }

  void setPushNotification() {
    isUpdated = true;

    if (!isClosed) {
      emit(
        state.copyWith(
          enablePushNotification: !state.enablePushNotification,
        ),
      );
    }
  }

  void setMaxMentions() {
    isUpdated = true;

    if (!isClosed) {
      emit(
        state.copyWith(
          notifMaxMentions: !state.notifMaxMentions,
        ),
      );
    }
  }

  void setPrivateMessages() {
    isUpdated = true;

    if (!isClosed) {
      emit(
        state.copyWith(
          notifPrivateMessage: !state.notifPrivateMessage,
        ),
      );
    }
  }

  void setMentionsReplies() {
    if (state.notifMentionsReplies && abort()) {
      BotToastUtils.showError(t.oneNotifOptionAvailable.capitalizeFirst());
      return;
    }

    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          notifMentionsReplies: !state.notifMentionsReplies,
        ),
      );
    }
  }

  void setZaps() {
    if (state.notifZaps && abort()) {
      BotToastUtils.showError(t.oneNotifOptionAvailable.capitalizeFirst());
      return;
    }

    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          notifZaps: !state.notifZaps,
        ),
      );
    }
  }

  void setReactions() {
    if (state.notifReactions && abort()) {
      BotToastUtils.showError(t.oneNotifOptionAvailable.capitalizeFirst());
      return;
    }

    isUpdated = true;
    if (!isClosed) {
      emit(
        state.copyWith(
          notifReactions: !state.notifReactions,
        ),
      );
    }
  }

  void setReposts() {
    if (state.notifReposts && abort()) {
      BotToastUtils.showError(t.oneNotifOptionAvailable.capitalizeFirst());
      return;
    }

    isUpdated = true;

    emit(
      state.copyWith(
        notifReposts: !state.notifReposts,
      ),
    );
  }

  bool abort() {
    int count = 0;

    if (state.notifFollowings) {
      count++;
    }

    if (state.notifMentionsReplies) {
      count++;
    }

    if (state.notifReactions) {
      count++;
    }

    if (state.notifReposts) {
      count++;
    }

    if (state.notifZaps) {
      count++;
    }

    return count == 1;
  }

  @override
  Future<void> close() async {
    if (isUpdated) {
      final c = nostrRepository.currentAppCustomization;

      c!.notifFollowings = state.notifFollowings;
      c.notifMentionsReplies = state.notifMentionsReplies;
      c.notifReactions = state.notifReactions;
      c.notifReposts = state.notifReposts;
      c.notifZaps = state.notifZaps;
      c.enablePushNotification = state.enablePushNotification;
      c.notifPrivateMessage = state.notifPrivateMessage;
      c.notifMaxMentions = state.notifMaxMentions;

      nostrRepository.appCustomizations[c.pubkey] = c;

      if (state.enablePushNotification) {
        PushCore.sharedInstance.setup();
      } else {
        NotificationHelper.sharedInstance.logout();
      }

      nostrRepository.broadcastCurrentAppCustomization();
      nostrRepository.saveAppCustomization();
      notificationsCubit.cleanAndSubscribe();
    }

    return super.close();
  }
}
