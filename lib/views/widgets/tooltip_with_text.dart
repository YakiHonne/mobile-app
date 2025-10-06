// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class TooltipWithText extends StatelessWidget {
  const TooltipWithText({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).primaryColorDark,
          ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      triggerMode: TooltipTriggerMode.tap,
      child: child,
    );
  }
}
