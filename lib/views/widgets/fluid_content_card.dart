import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/theme_cubit/theme_cubit.dart';
import '../../utils/utils.dart';

BoxDecoration contentCardDecoration(ThemeData theme, {required bool solid}) =>
    BoxDecoration(
      color: solid ? theme.cardColor : null,
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      border: Border(
        top: BorderSide(color: theme.dividerColor),
        left: BorderSide(width: 0.5, color: theme.dividerColor),
        right: BorderSide(width: 0.5, color: theme.dividerColor),
        bottom: BorderSide(width: 0.5, color: theme.dividerColor),
      ),
    );

/// Bordered card wrapper for feed/list content in fluid mode. The top border is
/// thicker than the other three, giving each item a subtle lit edge.
///
/// Normally respects the fluid-card setting. Feed callers can also request a
/// desktop container in both solid and fluid themes.
class FluidContentCard extends StatelessWidget {
  const FluidContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(kDefaultPadding / 1.5),
    this.desktopContainer = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool desktopContainer;

  @override
  Widget build(BuildContext context) {
    // Subscribed rather than a plain `useFluidCards()` read: the toggle lives in
    // a pushed settings route, so already-built feeds need the notification.
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final showDesktopContainer = desktopContainer && isDesktopPlatform;
        if (!showDesktopContainer && (!state.isFluid || !state.fluidCards)) {
          return child;
        }

        return Container(
          padding: padding,
          decoration: contentCardDecoration(Theme.of(context),
              solid: showDesktopContainer && !state.isFluid),
          child: child,
        );
      },
    );
  }
}
