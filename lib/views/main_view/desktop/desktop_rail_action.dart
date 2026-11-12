import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

/// Keyboard and semantic activation for a desktop rail control.
class DesktopRailAction extends StatefulWidget {
  const DesktopRailAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.selected,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final bool? selected;
  final Widget child;

  @override
  State<DesktopRailAction> createState() => _DesktopRailActionState();
}

class _DesktopRailActionState extends State<DesktopRailAction> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          widget.onPressed();
          return null;
        }),
        ButtonActivateIntent:
            CallbackAction<ButtonActivateIntent>(onInvoke: (_) {
          widget.onPressed();
          return null;
        }),
      },
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              border: _focused
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
