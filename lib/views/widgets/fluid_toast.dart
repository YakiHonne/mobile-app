import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../utils/global_keys.dart';
import '../../utils/utils.dart';
import 'fluid_blur_container.dart';

enum FluidToastType { success, error, info, warning }

/// Glass-styled toast used instead of BotToast when fluid theme is active.
/// ponytail: single active entry, no queue — matches BotToast's replace-on-new behavior.
class FluidToast {
  FluidToast._();

  static OverlayEntry? _entry;

  static void show({
    required String message,
    required FluidToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = GlobalKeys.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      return;
    }

    _entry?.remove();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FluidToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) {
            _entry = null;
          }
          entry.remove();
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }
}

class _FluidToastWidget extends StatefulWidget {
  const _FluidToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final FluidToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_FluidToastWidget> createState() => _FluidToastWidgetState();
}

class _FluidToastWidgetState extends State<_FluidToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) {
      return;
    }
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color, IconData) get _accent => switch (widget.type) {
        FluidToastType.success => (kGreen, LucideIcons.check),
        FluidToastType.error => (kRed, LucideIcons.x),
        FluidToastType.warning => (kMainColor, LucideIcons.triangleAlert),
        FluidToastType.info => (kBlue, LucideIcons.info),
      };

  @override
  Widget build(BuildContext context) {
    final (accentColor, icon) = _accent;

    return Positioned(
      top: MediaQuery.of(context).padding.top + kDefaultPadding / 2,
      left: kDefaultPadding,
      right: kDefaultPadding,
      child: SafeArea(
        bottom: false,
        child: Dismissible(
          key: ValueKey(this),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismissed(),
          child: GestureDetector(
            onTap: _dismiss,
            child: FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                      parent: _controller, curve: Curves.easeOutCubic),
                ),
                child: FluidBlurContainer(
                  borderRadius: kDefaultPadding,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 1.5,
                    vertical: kDefaultPadding / 1.5,
                  ),
                  borderColor: accentColor.withValues(alpha: 0.4),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: accentColor),
                      const SizedBox(width: kDefaultPadding / 2),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: Theme.of(context).textTheme.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
