// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'customize_notifications_cubit.dart';

class CustomizeNotificationsState extends Equatable {
  final bool enablePushNotification;
  final bool notifMentionsReplies;
  final bool notifReactions;
  final bool notifReposts;
  final bool notifZaps;
  final bool notifFollowings;
  final bool notifPrivateMessage;
  final bool notifMaxMentions;
  final bool refresh;

  const CustomizeNotificationsState({
    required this.enablePushNotification,
    required this.notifMentionsReplies,
    required this.notifReactions,
    required this.notifReposts,
    required this.notifZaps,
    required this.notifFollowings,
    required this.notifPrivateMessage,
    required this.notifMaxMentions,
    required this.refresh,
  });

  @override
  List<Object?> get props => [
        enablePushNotification,
        notifMentionsReplies,
        notifReactions,
        notifReposts,
        notifZaps,
        notifFollowings,
        notifPrivateMessage,
        notifMaxMentions,
        refresh,
      ];

  CustomizeNotificationsState copyWith({
    bool? enablePushNotification,
    bool? notifMentionsReplies,
    bool? notifReactions,
    bool? notifReposts,
    bool? notifZaps,
    bool? notifFollowings,
    bool? notifPrivateMessage,
    bool? notifMaxMentions,
    bool? refresh,
  }) {
    return CustomizeNotificationsState(
      enablePushNotification:
          enablePushNotification ?? this.enablePushNotification,
      notifMentionsReplies: notifMentionsReplies ?? this.notifMentionsReplies,
      notifReactions: notifReactions ?? this.notifReactions,
      notifReposts: notifReposts ?? this.notifReposts,
      notifZaps: notifZaps ?? this.notifZaps,
      notifFollowings: notifFollowings ?? this.notifFollowings,
      notifPrivateMessage: notifPrivateMessage ?? this.notifPrivateMessage,
      notifMaxMentions: notifMaxMentions ?? this.notifMaxMentions,
      refresh: refresh ?? this.refresh,
    );
  }
}
