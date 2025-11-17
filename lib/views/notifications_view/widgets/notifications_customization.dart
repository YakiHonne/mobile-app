import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/notifications_cubit/customize_notifications_cubit/customize_notifications_cubit.dart';
import '../../../utils/utils.dart';
import '../../settings_view/widgets/settings_text.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsCustomization extends StatelessWidget {
  const NotificationsCustomization({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomizeNotificationsCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.notifications.capitalizeFirst(),
        ),
        body: BlocBuilder<CustomizeNotificationsCubit,
            CustomizeNotificationsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              children: [
                Text(
                  context.t.settingsNotificationsDesc,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
                const Divider(
                  height: kDefaultPadding * 1.5,
                  thickness: 0.5,
                ),
                SwitchRow(
                  title: context.t.pushNotifications.capitalizeFirst(),
                  desc: context.t.pushNotificationsDesc,
                  val: state.enablePushNotification,
                  onSwitched: (isToggled) {
                    context
                        .read<CustomizeNotificationsCubit>()
                        .setPushNotification();
                  },
                ),
                const Divider(
                  height: kDefaultPadding * 1.5,
                  thickness: 0.5,
                ),
                SwitchRow(
                  title: context.t.following.capitalizeFirst(),
                  desc: context.t.followingDesc,
                  val: state.notifFollowings,
                  onSwitched: (isToggled) {
                    context.read<CustomizeNotificationsCubit>().setFollowings();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SwitchRow(
                  title:
                      '${context.t.mentions.capitalizeFirst()} / ${context.t.replies.capitalizeFirst()}',
                  desc: context.t.mentionsDesc,
                  val: state.notifMentionsReplies,
                  onSwitched: (isToggled) {
                    context
                        .read<CustomizeNotificationsCubit>()
                        .setMentionsReplies();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SwitchRow(
                  title: context.t.reactions.capitalizeFirst(),
                  desc: context.t.reactionsDesc,
                  val: state.notifReactions,
                  onSwitched: (isToggled) {
                    context.read<CustomizeNotificationsCubit>().setReactions();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SwitchRow(
                  title: context.t.reposts.capitalizeFirst(),
                  desc: context.t.repostsDesc,
                  val: state.notifReposts,
                  onSwitched: (isToggled) {
                    context.read<CustomizeNotificationsCubit>().setReposts();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SwitchRow(
                  title: context.t.zaps.capitalizeFirst(),
                  desc: context.t.zapDesc,
                  val: state.notifZaps,
                  onSwitched: (isToggled) {
                    context.read<CustomizeNotificationsCubit>().setZaps();
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                SwitchRow(
                  title: context.t.privateMessages.capitalizeFirst(),
                  desc: context.t.privateMessagesDesc,
                  val: state.notifPrivateMessage,
                  onSwitched: (isToggled) {
                    context
                        .read<CustomizeNotificationsCubit>()
                        .setPrivateMessages();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.onSwitched,
    required this.val,
    this.desc = '',
  });

  final String title;
  final String desc;
  final Function(bool) onSwitched;
  final bool val;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: title,
            description: desc,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: val,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: onSwitched,
          ),
        ),
      ],
    );
  }
}
