import 'package:flutter/material.dart';

import '../../common/functions/functions_set.dart';

/// Forwarder kept only so `showAppModalSheet(...)` call sites merged from `main`
/// bind to something desktop-correct on arrival. New code calls
/// [showAdaptiveModal] directly.
@Deprecated('Use showAdaptiveModal — bottom sheet on mobile, dialog on desktop.')
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isDismissible = true,
}) {
  return showAdaptiveModal<T>(
    context,
    builder: builder,
    backgroundColor: backgroundColor,
    isDismissible: isDismissible,
  );
}
