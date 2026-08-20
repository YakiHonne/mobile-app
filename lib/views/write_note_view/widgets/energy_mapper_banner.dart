import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/subscription_cubit/usage_limit.dart';
import '../../../utils/utils.dart';
import '../../widgets/usage_gate.dart';

class NoteEnergyMapperBanner extends StatelessWidget {
  const NoteEnergyMapperBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      UsageGate(builder: (ctx) => _build(ctx));

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    // The screen analyzes in initState, so it must not open at all when the
    // quota is spent — a toast inside would fire after the sheet is up.
    final blocked = isUsageBlocked(kUsageKeyEnergyMapper);
    return GestureDetector(
      onTap: blocked ? null : onTap,
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
              blocked ? LucideIcons.triangleAlert : LucideIcons.sparkles,
              size: 20,
              color: blocked ? theme.hintColor : theme.primaryColor,
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Text(
              blocked
                  ? t.usage_limit_reached_short
                  : t.energy_mapper_title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: blocked ? theme.hintColor : theme.primaryColorDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
