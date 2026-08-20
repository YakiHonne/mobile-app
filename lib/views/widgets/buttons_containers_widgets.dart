// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../utils/bot_toast_util.dart';
import '../../utils/theme/custom/buttons_theme.dart';
import '../../utils/theme/glass_settings.dart';
import '../../utils/utils.dart';
import 'app_icon.dart';
import 'fluid_blur_container.dart';

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
  final IconData primaryIcon;
  final IconData secondaryIcon;
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
        icon: AppIcon(
          firstSelection ? primaryIcon : secondaryIcon,
          color: isDisabled != null
              ? kWhite
              : iconColor ?? Theme.of(context).primaryColorDark,
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

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.buttonStatus = ButtonStatus.active,
    this.onClicked,
    this.iconSize = 25,
    this.size = 45,
    this.iconColor,
    this.buttonRadius,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth,
    this.enableFluid = true,
  });

  final IconData icon;

  final ButtonStatus? buttonStatus;
  final Function()? onClicked;
  final double? iconSize;
  final Color? iconColor;
  final double? size;
  final double? buttonRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? borderWidth;
  final bool? enableFluid;

  @override
  Widget build(BuildContext context) {
    final fluid = isFluid() && (enableFluid ?? true);

    final ic = iconColor ?? Theme.of(context).primaryColorDark;
    final buttonSize = size ?? 45;
    final icnSize = iconSize ?? 25;

    final iconWidget = AppIcon(icon, size: icnSize, color: ic);

    if (fluid) {
      if (ModalRoute.of(context) is ModalBottomSheetRoute) {
        final button = SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: TextButton(
            onPressed: buttonStatus == ButtonStatus.disabled ? null : onClicked,
            style: backgroundColor != null
                ? TbuttonsTheme.solidTextButtonStyle(
                    backgroundColor!,
                    foregroundColor: ic,
                    borderColor: borderColor,
                  ).copyWith(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    minimumSize: const WidgetStatePropertyAll(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(buttonRadius ?? 300),
                      ),
                    ),
                    side: borderColor != null || borderWidth != null
                        ? WidgetStatePropertyAll(
                            BorderSide(
                              color:
                                  borderColor ?? Theme.of(context).dividerColor,
                              width: borderWidth ?? 0.5,
                            ),
                          )
                        : null,
                  )
                : TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonRadius ?? 12),
                    ),
                    side: borderColor != null || borderWidth != null
                        ? BorderSide(
                            color:
                                borderColor ?? Theme.of(context).dividerColor,
                            width: borderWidth ?? 0.5,
                          )
                        : null,
                  ),
            child: iconWidget,
          ),
        );

        return Opacity(
          opacity: buttonStatus == ButtonStatus.disabled ? 0.4 : 1.0,
          child: backgroundColor != null
              ? button
              : FluidCardContainer(
                  borderRadius: buttonRadius ?? 300,
                  padding: EdgeInsets.zero,
                  child: button,
                ),
        );
      }

      return GlassIconButton(
        icon: iconWidget,
        iconSize: iconSize,
        useOwnLayer: true,
        // Standalone icon buttons use the shared icon-button recipe; buttons
        // inside a GlassAppBar keep inheriting its `buttonSettings` plate.
        settings: DefaultButtonSettings.of(context) == null
            ? GlassSettings.iconButton(context)
            : null,
        onPressed: buttonStatus == ButtonStatus.disabled ? null : onClicked,
      );
    }

    final localStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundBuilder: (context, states, child) => child!,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius ?? 12),
      ),
      backgroundColor: backgroundColor ?? Colors.transparent,
      side: borderColor != null || borderWidth != null
          ? BorderSide(
              color: borderColor ?? Theme.of(context).dividerColor,
              width: borderWidth ?? 0.5,
            )
          : null,
    );

    final button = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: TextButton(
        onPressed: buttonStatus == ButtonStatus.disabled ? null : onClicked,
        style: localStyle,
        child: iconWidget,
      ),
    );

    return Opacity(
      opacity: buttonStatus == ButtonStatus.disabled ? 0.4 : 1.0,
      child: button,
    );
  }
}

class CustomizedIconButton extends StatelessWidget {
  const CustomizedIconButton({
    super.key,
    required this.buttonStatus,
    required this.icon,
    required this.onClicked,
    this.iconSize = 22,
    this.size,
    this.visualDensity,
  });

  final ButtonStatus buttonStatus;
  final IconData icon;
  final Function() onClicked;
  final double? iconSize;
  final double? size;
  final double? visualDensity;

  @override
  Widget build(BuildContext context) {
    final isActive = buttonStatus == ButtonStatus.active;
    final fluid = isFluid() && !isActive;

    final iconWidget = AppIcon(
      icon,
      size: iconSize,
      color: isActive ? kWhite : Theme.of(context).primaryColorDark,
    );

    final button = SizedBox(
      height: size ?? 42,
      width: size ?? 42,
      child: IconButton(
        onPressed: buttonStatus == ButtonStatus.disabled ? null : onClicked,
        icon: iconWidget,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity(
            horizontal: visualDensity ?? -4,
            vertical: visualDensity ?? -1,
          ),
          backgroundColor: isActive
              ? Theme.of(context).primaryColor
              : fluid
                  ? Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.35)
                  : Theme.of(context).scaffoldBackgroundColor,
          side: BorderSide(
            color: buttonStatus == ButtonStatus.loading || isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withValues(
                      alpha: fluid ? 0.5 : 1,
                    ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: buttonStatus == ButtonStatus.disabled ? 0.4 : 1,
      child: fluid
          ? FluidBlurContainer(
              showDecoration: false,
              borderRadius: 21,
              child: button,
            )
          : button,
    );
  }
}

class StatusButton extends StatelessWidget {
  const StatusButton({
    super.key,
    required this.isDisabled,
    required this.onClicked,
    required this.text,
    this.color,
  });

  final bool isDisabled;
  final String text;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: !isDisabled ? onClicked : null,
        style: TextButton.styleFrom(
          backgroundBuilder: (_, __, child) => child!,
          backgroundColor:
              isDisabled ? kDimGrey : (color ?? Theme.of(context).primaryColor),
          visualDensity: VisualDensity.comfortable,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: kWhite,
          ),
        ),
      ),
    );
  }

  final Color? color;
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
            const AppIcon(
              FeatureIcons.copy,
              size: 10,
              color: kWhite,
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
          icon: AppIcon(
            LucideIcons.chevronUp,
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
            icon: AppIcon(
              LucideIcons.chevronDown,
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
