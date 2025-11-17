// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

//** Bordered icon button */

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    required this.onClicked,
    required this.primaryIcon,
    required this.borderColor,
    required this.firstSelection,
    required this.secondaryIcon,
    this.size,
    this.backGroundColor,
    this.iconColor,
    this.isDisabled,
    this.border,
  });

  final bool firstSelection;
  final Function() onClicked;
  final String primaryIcon;
  final String secondaryIcon;
  final Color borderColor;
  final Color? backGroundColor;
  final Color? iconColor;
  final double? size;
  final bool? isDisabled;
  final double? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size ?? 42,
      width: size ?? 42,
      child: IconButton(
        onPressed: isDisabled != null ? () {} : onClicked,
        padding: const EdgeInsets.all(10),
        icon: SvgPicture.asset(
          firstSelection ? primaryIcon : secondaryIcon,
          fit: BoxFit.scaleDown,
          colorFilter: ColorFilter.mode(
            isDisabled != null
                ? kWhite
                : iconColor ?? Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        style: IconButton.styleFrom(
          backgroundColor: isDisabled != null
              ? kDimGrey
              : backGroundColor ?? Theme.of(context).primaryColorLight,
          side: BorderSide(
            width: border ?? 2,
            color: isDisabled != null ? kDimGrey : borderColor,
          ),
        ),
      ),
    );
  }
}

class NewBorderedIconButton extends StatelessWidget {
  const NewBorderedIconButton({
    super.key,
    required this.buttonStatus,
    required this.icon,
    required this.onClicked,
    this.iconData,
  });

  final ButtonStatus buttonStatus;
  final String icon;
  final Function() onClicked;
  final IconData? iconData;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: buttonStatus == ButtonStatus.disabled ? 0.4 : 1,
      child: SizedBox(
        height: 42,
        width: 42,
        child: IconButton(
          onPressed: buttonStatus == ButtonStatus.disabled ? null : onClicked,
          icon: iconData == null
              ? SvgPicture.asset(
                  icon,
                  width: 22,
                  height: 22,
                  fit: BoxFit.scaleDown,
                  colorFilter: ColorFilter.mode(
                    buttonStatus == ButtonStatus.active
                        ? kWhite
                        : Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  iconData,
                  size: 22,
                ),
          style: IconButton.styleFrom(
            backgroundColor: buttonStatus == ButtonStatus.active
                ? Theme.of(context).primaryColor
                : Theme.of(context).scaffoldBackgroundColor,
            side: BorderSide(
              color: buttonStatus == ButtonStatus.loading ||
                      buttonStatus == ButtonStatus.active
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}

class StatusButton extends StatelessWidget {
  const StatusButton({
    super.key,
    required this.isDisabled,
    required this.onClicked,
    required this.text,
  });

  final bool isDisabled;
  final String text;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: !isDisabled ? onClicked : null,
      style: TextButton.styleFrom(
        backgroundColor: isDisabled ? kDimGrey : Theme.of(context).primaryColor,
        visualDensity: VisualDensity.comfortable,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kWhite,
        ),
      ),
    );
  }
}

//** Information rounded container */
class InfoRoundedContainer extends StatelessWidget {
  const InfoRoundedContainer({
    super.key,
    required this.tag,
    required this.color,
    required this.textColor,
    required this.onClicked,
    this.useOpacity,
  });

  final String tag;
  final Color color;
  final Color textColor;
  final Function() onClicked;
  final bool? useOpacity;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: useOpacity != null ? color.withValues(alpha: 0.6) : color,
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        ),
        child: Text(
          tag,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: textColor,
              ),
        ),
      ),
    );
  }
}

//** dot container */

class DotContainer extends StatelessWidget {
  const DotContainer({
    super.key,
    required this.color,
    this.isNotMarging,
    this.size,
    this.width,
    this.height,
  });

  final Color color;
  final bool? isNotMarging;
  final double? size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width ?? size ?? 5,
      height: height ?? size ?? 5,
      margin: isNotMarging != null
          ? null
          : const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(300),
        color: color,
      ),
    );
  }
}

//** public key container */
class PubKeyContainer extends StatelessWidget {
  const PubKeyContainer({
    super.key,
    required this.pubKey,
  });

  final String pubKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Clipboard.setData(
          ClipboardData(
            text: Nip19.encodePubkey(
              pubKey,
            ),
          ),
        );

        HapticFeedback.mediumImpact();

        BotToastUtils.showSuccess(
          context.t.publicKeyCopied.capitalizeFirst(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: kPurple,
          borderRadius: BorderRadius.circular(kDefaultPadding),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Nip19.encodePubkey(
                pubKey,
              ).nineCharacters(),
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: kWhite,
                  ),
            ),
            const SizedBox(
              width: 5,
            ),
            SvgPicture.asset(
              FeatureIcons.copy,
              width: 10,
              height: 10,
              colorFilter: const ColorFilter.mode(
                kWhite,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetScrollButton extends HookWidget {
  const ResetScrollButton({
    super.key,
    required this.scrollController,
    this.isLeft,
    this.padding,
  });

  final ScrollController scrollController;
  final bool? isLeft;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    final showButton = useState(false);

    useEffect(() {
      void setShowButton() {
        showButton.value = scrollController.offset > 100;
      }

      scrollController.addListener(setShowButton);
      return () => scrollController.removeListener(setShowButton);
    }, [scrollController]);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      right: isLeft != null
          ? null
          : showButton.value
              ? kDefaultPadding / 2
              : -50,
      left: isLeft == null
          ? null
          : showButton.value
              ? kDefaultPadding / 2
              : -50,
      bottom: padding ?? kBottomNavigationBarHeight,
      child: Material(
        shape: const StadiumBorder(),
        elevation: 0.2,
        color: kTransparent,
        shadowColor: Theme.of(context).primaryColorDark,
        child: IconButton(
          onPressed: () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                0.0,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
              );
            }
          },
          icon: Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Theme.of(context).primaryColorLight,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColorDark,
          ),
        ),
      ),
    );
  }
}

class ChatResetScrollButton extends HookWidget {
  const ChatResetScrollButton({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final showButton = useState(false);

    useEffect(() {
      void setShowButton() {
        showButton.value = scrollController.offset > 200;
      }

      scrollController.addListener(setShowButton);
      return () => scrollController.removeListener(setShowButton);
    }, [scrollController]);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: showButton.value ? kDefaultPadding / 2 : -50,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          shape: const StadiumBorder(),
          elevation: 0.2,
          color: kTransparent,
          shadowColor: Theme.of(context).primaryColorDark,
          child: IconButton(
            onPressed: () {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  0.0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                );
              }
            },
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).primaryColorLight,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
      ),
    );
  }
}
