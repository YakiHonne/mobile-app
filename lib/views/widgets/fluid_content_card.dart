import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/theme_cubit/theme_cubit.dart';
import '../../utils/utils.dart';

/// Bordered card wrapper for feed/list content in fluid mode. The top border is
/// thicker than the other three, giving each item a subtle lit edge.
///
/// Returns [child] untouched when fluid mode is off or the user disabled
/// content cards in Settings → Customization, so call sites need no condition.
class FluidContentCard extends StatelessWidget {
  const FluidContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(kDefaultPadding / 1.5),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Subscribed rather than a plain `useFluidCards()` read: the toggle lives in
    // a pushed settings route, so already-built feeds need the notification.
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        if (!state.isFluid || !state.fluidCards) {
          return child;
        }

        final borderColor = Theme.of(context).dividerColor;

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
            border: Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(width: 0.5, color: borderColor),
              right: BorderSide(width: 0.5, color: borderColor),
              bottom: BorderSide(width: 0.5, color: borderColor),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
