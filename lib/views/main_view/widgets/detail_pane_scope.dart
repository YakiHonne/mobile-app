import 'package:flutter/widgets.dart';

/// Identifies routes rendered inside the desktop detail pane.
class DetailPaneScope extends InheritedWidget {
  const DetailPaneScope({super.key, required super.child});

  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DetailPaneScope>() != null;

  @override
  bool updateShouldNotify(DetailPaneScope oldWidget) => false;
}
