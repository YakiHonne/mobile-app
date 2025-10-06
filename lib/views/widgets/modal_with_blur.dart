import 'package:flutter/material.dart';

import '../../utils/utils.dart';

void showBlurredModal(
    {required BuildContext context,
    required Widget view,
    bool? isDismissable}) {
  final isDark = themeCubit.isDark;

  showGeneralDialog(
    barrierDismissible: isDismissable ?? true,
    barrierLabel: '',
    barrierColor: isDark
        ? Colors.black45.withValues(alpha: 0.8)
        : kDimGrey.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim1, anim2) => Center(
      child: view,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(
      opacity: anim1,
      child: child,
    ),
    context: context,
  );
}
