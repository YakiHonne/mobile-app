import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Scrolls [child] into view when it takes focus.
///
/// The sheet shrinks to make room for the keyboard, so a field low in the
/// scroll body would otherwise end up behind it. The delay lets the inset
/// animation settle first, else we scroll to the pre-keyboard offset.
class EnsureVisibleOnFocus extends HookWidget {
  const EnsureVisibleOnFocus({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final node = useFocusNode();

    return Focus(
      focusNode: node,
      onFocusChange: (hasFocus) async {
        if (!hasFocus) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (!context.mounted) {
          return;
        }
        await Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      },
      child: child,
    );
  }
}
