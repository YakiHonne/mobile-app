import 'package:flutter/material.dart';

import '../../../../utils/utils.dart';
import '../../../widgets/dotted_container.dart';

class SecondReaderSheetHeader extends StatelessWidget {
  const SecondReaderSheetHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag target: the sheet body is filled by scrollables that swallow the
        // drag, so the handle is the only place the sheet can be pulled down.
        const Center(child: ModalBottomSheetHandle()),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding,
            kDefaultPadding / 2,
            kDefaultPadding / 2,
            kDefaultPadding / 2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.t.second_reader_choose,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
