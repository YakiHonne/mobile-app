// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import 'smart_widget_component_customization.dart';

class SmartWidgetButtonPulldownButton extends StatelessWidget {
  const SmartWidgetButtonPulldownButton({
    super.key,
    required this.smartWidgetButton,
  });

  final SmartWidgetButton smartWidgetButton;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shape: const CircleBorder(),
      shadowColor: Theme.of(context).primaryColorLight.withValues(
            alpha: 1,
          ),
      child: PullDownButton(
        animationBuilder: (context, state, child) {
          return child;
        },
        routeTheme: PullDownMenuRouteTheme(
          backgroundColor: Theme.of(context).cardColor,
        ),
        itemBuilder: (context) {
          final textStyle = Theme.of(context).textTheme.labelMedium;

          return [
            PullDownMenuItem(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider.value(
                      value: context.read<WriteSmartWidgetCubit>(),
                      child: FrameComponentCustomization(
                        boxComponent: smartWidgetButton,
                        id: smartWidgetButton.id,
                      ),
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              title: context.t.edit.capitalizeFirst(),
              iconWidget: SvgPicture.asset(
                FeatureIcons.article,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
            PullDownMenuItem(
              onTap: () {
                context.read<WriteSmartWidgetCubit>().moveButton(
                      moveRight: false,
                      id: smartWidgetButton.id,
                    );
              },
              title: context.t.moveLeft.capitalizeFirst(),
              iconWidget: RotatedBox(
                quarterTurns: 3,
                child: SvgPicture.asset(
                  FeatureIcons.arrowUp,
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
            PullDownMenuItem(
              onTap: () {
                context.read<WriteSmartWidgetCubit>().moveButton(
                      id: smartWidgetButton.id,
                      moveRight: true,
                    );
              },
              title: context.t.moveRight.capitalizeFirst(),
              iconWidget: RotatedBox(
                quarterTurns: 3,
                child: SvgPicture.asset(
                  FeatureIcons.arrowDown,
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
            PullDownMenuItem(
              onTap: () {
                final canBeDeleted = context
                        .read<WriteSmartWidgetCubit>()
                        .state
                        .smartWidgetBox
                        .buttons
                        .length >
                    1;

                if (canBeDeleted) {
                  context
                      .read<WriteSmartWidgetCubit>()
                      .deleteButton(smartWidgetButton.id);
                } else {
                  BotToastUtils.showError(context.t.buttonRequired);
                }
              },
              title: context.t.delete.capitalizeFirst(),
              isDestructive: true,
              iconWidget: SvgPicture.asset(
                FeatureIcons.trash,
                height: 20,
                width: 20,
                colorFilter: const ColorFilter.mode(
                  kRed,
                  BlendMode.srcIn,
                ),
              ),
              itemTheme: PullDownMenuItemTheme(
                textStyle: textStyle,
              ),
            ),
          ];
        },
        buttonBuilder: (context, showMenu) => SmallRectangularButton(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.8),
          onClick: showMenu,
          icon: FeatureIcons.more,
        ),
      ),
    );
  }
}

class SmallRectangularButton extends StatelessWidget {
  const SmallRectangularButton({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.onClick,
    this.turns,
  });

  final Color? backgroundColor;
  final String icon;
  final int? turns;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 8,
          horizontal: kDefaultPadding / 3,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
        ),
        child: RotatedBox(
          quarterTurns: turns ?? 1,
          child: SvgPicture.asset(
            icon,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
