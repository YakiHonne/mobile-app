import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/utils.dart';

/// A neutral preview that does not load or play a hidden video.
class DesktopHiddenVideo extends StatelessWidget {
  const DesktopHiddenVideo({super.key, this.onOpen, this.compact = false});

  final VoidCallback? onOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: Theme.of(context).cardColor,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.eyeOff,
                  color: Theme.of(context).primaryColorDark),
              if (!compact) ...[
                const SizedBox(height: kDefaultPadding / 2),
                Text(context.t.sensitiveContent, textAlign: TextAlign.center),
                const SizedBox(height: kDefaultPadding / 4),
                Text(context.t.clickToView, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
    if (onOpen == null) {
      return content;
    }
    return Semantics(
      button: true,
      label: context.t.clickToView,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: content,
        ),
      ),
    );
  }
}

/// An explicit action for opening a desktop media preview in the gallery.
class DesktopOpenMediaButton extends StatelessWidget {
  const DesktopOpenMediaButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.t.clickToView,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          overlayColor: Colors.transparent,
        ),
        icon: const Icon(LucideIcons.expand, size: 20),
      );
}
