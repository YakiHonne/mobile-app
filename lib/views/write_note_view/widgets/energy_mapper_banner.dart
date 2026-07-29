import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../utils/utils.dart';

class NoteEnergyMapperBanner extends StatelessWidget {
  const NoteEnergyMapperBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          kDefaultPadding / 2,
          kDefaultPadding / 4,
          kDefaultPadding / 2,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 20,
              color: theme.primaryColor,
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Text(
              t.energy_mapper_title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.primaryColorDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
