// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../../logic/gpt_chat_cubit/gpt_chat_cubit.dart';
import '../../../../models/chat_message.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/empty_list.dart';
import '../../../widgets/profile_picture.dart';

class ChatGpt extends HookWidget {
  const ChatGpt({
    super.key,
    required this.insertText,
  });

  final Function(String) insertText;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();

    return BlocProvider(
      create: (context) => GptChatCubit(),
      child: Material(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: SizedBox(
          height: 80.h,
          child: SafeArea(
            child: Column(
              children: [
                const ModalBottomSheetHandle(),
                _clearChat(),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                const Divider(
                  height: 0,
                  thickness: 0.5,
                ),
                _chatMessages(),
                _send(textEditingController)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Padding _send(TextEditingController textEditingController) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: BlocBuilder<GptChatCubit, GptChatState>(
        builder: (context, state) {
          return TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: textEditingController,
            decoration: InputDecoration(
              hintText: context.t.askMeSomething.capitalize(),
              suffixIcon: IconButton(
                onPressed: () {
                  final text = textEditingController.text.trim();

                  if (text.isNotEmpty) {
                    context.read<GptChatCubit>().getChatResponse(text);
                    textEditingController.clear();
                  }
                },
                icon: SvgPicture.asset(
                  FeatureIcons.send,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            maxLines: 3,
            minLines: 1,
          );
        },
      ),
    );
  }

  Expanded _chatMessages() {
    return Expanded(
      child: BlocBuilder<GptChatCubit, GptChatState>(
        builder: (context, state) {
          if (state.chatMessage.isEmpty) {
            return Center(
              child: EmptyList(
                description: context.t.noDataFromGpt.capitalize(),
                icon: FeatureIcons.gpt,
              ),
            );
          }

          return ListView.custom(
            reverse: true,
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding,
              horizontal: kDefaultPadding / 2,
            ),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                final message =
                    state.chatMessage[state.chatMessage.length - 1 - index];

                return MessageContainer(
                  message: message,
                  insertText: insertText,
                );
              },
              childCount: state.chatMessage.length,
              findChildIndexCallback: (Key key) {
                final valueKey = key as ValueKey<String>;
                final val = state.chatMessage.indexWhere(
                  (message) => message.id == valueKey.value,
                );
                return state.chatMessage.length - 1 - val;
              },
            ),
          );
        },
      ),
    );
  }

  BlocBuilder<GptChatCubit, GptChatState> _clearChat() {
    return BlocBuilder<GptChatCubit, GptChatState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GPT Helper',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton(
                onPressed: () => context.read<GptChatCubit>().clearMessages(),
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColorDark,
                ),
                child: Text(
                  context.t.clearChat.capitalize(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).primaryColorLight,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MessageContainer extends StatelessWidget {
  const MessageContainer({
    super.key,
    required this.message,
    required this.insertText,
  });

  final ChatMessage message;
  final Function(String) insertText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isCurrentUser) ...[
            if (message.user.pubkey == 'GPT')
              CircleAvatar(
                radius: 18,
                backgroundColor: kGreen,
                child: SvgPicture.asset(
                  FeatureIcons.gpt,
                  colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
                ),
              )
            else
              ProfilePicture2(
                size: 36,
                image: message.user.picture,
                pubkey: message.user.pubkey,
                padding: 0,
                strokeWidth: 0,
                strokeColor: kTransparent,
                onClicked: () {},
              ),
          ],
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _createdAt(context),
          if (message.isCurrentUser) ...[
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            ProfilePicture2(
              size: 36,
              image: message.user.picture,
              pubkey: message.user.pubkey,
              padding: 1,
              strokeWidth: 1,
              strokeColor: Theme.of(context).primaryColorDark,
              onClicked: () {},
            ),
          ] else if (message.user.pubkey == 'GPT') ...[
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            _pulldownButton(context),
          ],
        ],
      ),
    );
  }

  Flexible _createdAt(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text.capitalize(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              dateFormat3.format(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  PullDownButton _pulldownButton(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) {
        return child;
      },
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).primaryColorLight,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelMedium;

        return [
          PullDownMenuItem(
            title: context.t.copy,
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text: message.text,
                ),
              );

              BotToastUtils.showSuccess(
                context.t.textSuccesfulyCopied,
              );
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.copy,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          PullDownMenuItem(
            title: context.t.insertText,
            onTap: () {
              insertText.call(message.text);
              Navigator.pop(context);
            },
            itemTheme: PullDownMenuItemTheme(
              textStyle: textStyle,
            ),
            iconWidget: SvgPicture.asset(
              FeatureIcons.insertText,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ];
      },
      buttonBuilder: (context, showMenu) => IconButton(
        onPressed: showMenu,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColorLight,
        ),
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).primaryColorDark,
        ),
      ),
    );
  }
}
