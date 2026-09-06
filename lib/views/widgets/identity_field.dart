import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/identity_models.dart';
import '../../utils/utils.dart';
import 'app_icon.dart';

export '../../models/identity_models.dart';

/// A bordered card field: label above the value, everything inline. Used for
/// every row of the edit-profile form and for identity onboarding, so a plain
/// text row and a claimable name row read as the same control.
///
/// [status] is what makes it a claim field — left at `unchecked` it is simply a
/// styled text input with no chip and no tint.
class IdentityField extends StatelessWidget {
  const IdentityField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.status = AddressStatus.unchecked,
    this.prefix,
    this.suffix,
    this.trailing,
    this.labelIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.capitalize = false,
  });

  final String label;
  final TextEditingController controller;
  final AddressStatus status;
  final String hint;
  final String? prefix;
  final String? suffix;

  /// Sits next to the label — marks the row as something other than a plain
  /// input, the way the crown marks a claimed Yaki username.
  final IconData? labelIcon;

  /// Sits inside the field, right of the input — where the row's own action
  /// belongs rather than as a separate button below the card.
  final Widget? trailing;

  final IconData? prefixIcon;
  final int maxLines;
  final bool capitalize;

  Color? _tint() => switch (status) {
        AddressStatus.taken => Colors.red,
        AddressStatus.available || AddressStatus.alreadySet => kGreen,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(kDefaultPadding / 2 + 2);
    final tint = _tint();
    final affix = theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor);
    final readOnly = status == AddressStatus.alreadySet;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding / 2 + 2,
        kDefaultPadding / 2,
        kDefaultPadding / 2 + 2,
        kDefaultPadding / 4,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        border: Border.all(color: tint ?? theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (labelIcon != null) ...[
                      const SizedBox(width: kDefaultPadding / 4),
                      AppIcon(labelIcon!, size: 13, color: theme.hintColor),
                    ],
                  ],
                ),
              ),
              IdentityStatusChip(status: status),
            ],
          ),
          Row(
            // A multiline field grows downward, so the affixes and the action
            // stay pinned to the first line rather than floating to the middle.
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (prefixIcon != null) ...[
                AppIcon(prefixIcon!, size: 18, color: theme.hintColor),
                const SizedBox(width: kDefaultPadding / 4),
              ],
              if (prefix != null) Text(prefix!, style: affix),
              Expanded(
                child: TextField(
                  controller: controller,
                  // A name field must not be "corrected"; prose fields want it.
                  autocorrect: capitalize,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  textCapitalization: capitalize
                      ? TextCapitalization.sentences
                      : TextCapitalization.none,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (suffix != null) Text(suffix!, style: affix),
              if (trailing != null) ...[
                const SizedBox(width: kDefaultPadding / 4),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class IdentityStatusChip extends StatelessWidget {
  const IdentityStatusChip({super.key, required this.status});

  final AddressStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == AddressStatus.unchecked || status == AddressStatus.skipped) {
      return const SizedBox.shrink();
    }
    if (status == AddressStatus.checking) {
      return SpinKitCircle(color: theme.hintColor, size: 12);
    }

    final (color, icon, label) = switch (status) {
      AddressStatus.available => (
          kGreen,
          LucideIcons.check,
          context.t.onboarding_status_available,
        ),
      AddressStatus.taken => (
          Colors.red,
          LucideIcons.x,
          context.t.onboarding_status_taken,
        ),
      _ => (
          kGreen,
          LucideIcons.circleCheck,
          context.t.onboarding_status_already_set,
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
