import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

class ShowPotentialSpamRepliesButton extends StatelessWidget {
  const ShowPotentialSpamRepliesButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.hintColor;

    return Center(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 22,
          color: foregroundColor,
        ),
        label: Text(
          context.t.seePotentialSpams(count: count),
          style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor,
          side: BorderSide(color: theme.dividerColor, width: 0.8),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 3,
          ),
          minimumSize: const Size(0, kDefaultPadding * 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
