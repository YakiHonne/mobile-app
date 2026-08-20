import 'package:flutter/material.dart';

Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isDismissible = true,
}) {
  final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

  return showModalBottomSheet(
    context: context,
    builder: builder,
    backgroundColor: bg,
    elevation: 0,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
  );
}
