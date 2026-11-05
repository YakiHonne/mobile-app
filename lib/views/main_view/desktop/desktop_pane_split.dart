import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _splitKey = 'desktop_pane_split';
const _dividerWidth = 1.0;
// Leave useful drag travel at the native minimum window size. Content inside
// either pane must adapt to this width rather than locking the divider in place.
const _minimumPaneWidth = 400.0;

/// Keeps the requested fraction separate from the clamped layout, so a narrow
/// window does not overwrite the user's preference for a wider display.
class DesktopPaneSplit extends StatefulWidget {
  const DesktopPaneSplit({
    super.key,
    required this.preferences,
    required this.label,
    required this.mainBuilder,
    required this.sideBuilder,
  });

  final SharedPreferences preferences;
  final String label;

  final Widget Function(double width) mainBuilder;
  final Widget Function(double width) sideBuilder;

  @override
  State<DesktopPaneSplit> createState() => _DesktopPaneSplitState();
}

class _DesktopPaneSplitState extends State<DesktopPaneSplit> {
  double? _fraction;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final saved = widget.preferences.get(_splitKey);
    if (saved is double && saved.isFinite && saved > 0 && saved < 1) {
      _fraction = saved;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final available = (constraints.maxWidth - _dividerWidth)
              .clamp(0.0, double.infinity);
          final minimum = (available / 2).clamp(0.0, _minimumPaneWidth);
          final side = (_fraction == null ? 520.0 : available * _fraction!)
              .clamp(minimum, available - minimum);
          final main = available - side;

          void adjust(double delta) {
            if (available <= 0) {
              return;
            }
            final next = (side - delta).clamp(minimum, available - minimum);
            if (next == side) {
              return;
            }
            setState(() => _fraction = next / available);
            widget.preferences.setDouble(_splitKey, _fraction!);
          }

          void reset() {
            setState(() => _fraction = null);
            widget.preferences.remove(_splitKey);
          }

          return Stack(children: [
            Row(textDirection: TextDirection.ltr, children: [
              SizedBox(width: main, child: widget.mainBuilder(main)),
              const VerticalDivider(
                  width: _dividerWidth, thickness: _dividerWidth),
              SizedBox(width: side, child: widget.sideBuilder(side)),
            ]),
            Positioned(
                  left: main - 10,
                  top: 0,
                  bottom: 0,
                  width: 21,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: FocusableActionDetector(
                      focusNode: _focusNode,
                      shortcuts: const {
                        SingleActivator(LogicalKeyboardKey.arrowLeft):
                            _ResizeIntent(-20),
                        SingleActivator(LogicalKeyboardKey.arrowRight):
                            _ResizeIntent(20),
                        SingleActivator(LogicalKeyboardKey.home):
                            _ResetIntent(),
                      },
                      actions: {
                        _ResizeIntent:
                            CallbackAction<_ResizeIntent>(onInvoke: (intent) {
                          adjust(intent.delta);
                          return null;
                        }),
                        _ResetIntent:
                            CallbackAction<_ResetIntent>(onInvoke: (_) {
                          reset();
                          return null;
                        }),
                      },
                      child: Semantics(
                        label: widget.label,
                        value:
                            '${(side / (available == 0 ? 1 : available) * 100).round()}%',
                        increasedValue:
                            '${((side + 20).clamp(minimum, available - minimum) / (available == 0 ? 1 : available) * 100).round()}%',
                        decreasedValue:
                            '${((side - 20).clamp(minimum, available - minimum) / (available == 0 ? 1 : available) * 100).round()}%',
                        onIncrease: () => adjust(-20),
                        onDecrease: () => adjust(20),
                        child: Listener(
                          onPointerDown: (_) => _focusNode.requestFocus(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragUpdate: (details) =>
                                adjust(details.delta.dx),
                            onDoubleTap: reset,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ]);
        },
      );
}

class _ResizeIntent extends Intent {
  const _ResizeIntent(this.delta);
  final double delta;
}

class _ResetIntent extends Intent {
  const _ResetIntent();
}
