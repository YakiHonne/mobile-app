import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../main.dart' show AppConstants;
import '../../../utils/utils.dart';
import '../../dm_view/widgets/dm_details.dart';

/// Keep both inner columns usable; below this width show the list alone.
const double kDesktopDmSplitMinWidth = 600;

class DesktopDmScope extends InheritedWidget {
  const DesktopDmScope({super.key, required this.select, required super.child});

  final ValueChanged<String> select;

  static ValueChanged<String>? maybeSelect(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopDmScope>()?.select;

  @override
  bool updateShouldNotify(DesktopDmScope oldWidget) =>
      select != oldWidget.select;
}

/// A conversation list and an independently scoped active conversation inside
/// the main panel; the outer workspace pane remains mounted beside them.
class DesktopDmWorkspace extends HookWidget {
  const DesktopDmWorkspace(
      {super.key,
      required this.list,
      required this.selected,
      this.conversationBuilder});

  final Widget list;
  final ValueNotifier<String?> selected;
  final Widget Function(BuildContext, String, VoidCallback)?
      conversationBuilder;

  @override
  Widget build(BuildContext context) {
    useListenable(selected);
    return DesktopDmScope(
      select: (pubkey) {
        if (context.mounted) {
          selected.value = pubkey;
        }
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final available =
            (constraints.maxWidth - 1).clamp(0.0, double.infinity);
        final narrow = constraints.maxWidth < kDesktopDmSplitMinWidth;
        final listWidth = narrow ? constraints.maxWidth : available * 0.4;
        final conversationWidth = narrow ? 360.0 : available - listWidth;
        Widget scoped(double width, Widget child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(width, MediaQuery.sizeOf(context).height),
              ),
              child: ResponsiveBreakpoints.builder(
                breakpoints: AppConstants.responsiveBreakpoints,
                child: child,
              ),
            );
        return Row(children: [
          SizedBox(width: listWidth, child: scoped(listWidth, list)),
          if (!narrow) const VerticalDivider(width: 1, thickness: 1),
          Offstage(
            offstage: narrow,
            child: ExcludeFocus(
              excluding: narrow,
              child: SizedBox(
                width: conversationWidth,
                child: scoped(
                  conversationWidth,
                  selected.value == null
                      ? Center(child: Text(context.t.selectContentToView))
                      : conversationBuilder?.call(context, selected.value!,
                              () => selected.value = null) ??
                          Padding(
                            padding:
                                const EdgeInsets.only(top: kDefaultPadding),
                            child: DmDetails(
                              key: ValueKey(selected.value),
                              pubkey: selected.value!,
                              onClose: () => selected.value = null,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
