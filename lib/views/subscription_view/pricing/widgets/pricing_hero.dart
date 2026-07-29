import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../utils/utils.dart';
import '../../../widgets/profile_picture.dart';

class PricingHeroHeader extends StatelessWidget {
  const PricingHeroHeader({
    super.key,
    required this.picture,
    required this.name,
    required this.pubkey,
    required this.isLn,
    required this.isPoints,
    required this.onToggleLn,
    required this.onTogglePoints,
    required this.onClose,
  });

  final String picture;
  final String name;
  final String pubkey;
  final bool isLn;
  final bool isPoints;
  final ValueChanged<bool>? onToggleLn;
  final ValueChanged<bool>? onTogglePoints;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pills = [
      context.t.pricing_pill_no_commission,
      context.t.pricing_pill_cancel,
      context.t.pricing_pill_pay,
      context.t.pricing_pill_sovereign,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding,
        kDefaultPadding / 2 - 2,
        kDefaultPadding,
        kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: kDefaultPadding),
            child: Row(
              children: [
                ProfilePicture2(
                  size: 48,
                  pubkey: pubkey,
                  image: picture,
                  padding: 2,
                  strokeWidth: 1.5,
                  strokeColor: theme.primaryColor.withValues(alpha: 0.4),
                  onClicked: () {},
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t.pricing_welcome_back,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: theme.hintColor),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.25,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: '${context.t.pricing_headline_1}\n'),
                TextSpan(
                  text: context.t.pricing_headline_2,
                  style: TextStyle(color: theme.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.pricing_body,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.55),
          ),
          const SizedBox(height: kDefaultPadding),
          Wrap(
            spacing: kDefaultPadding / 2 - 2,
            runSpacing: kDefaultPadding / 2 - 2,
            children: pills.map((label) => _Pill(label: label)).toList(),
          ),
          if (onToggleLn != null || onTogglePoints != null) ...[
            const SizedBox(height: kDefaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(kDefaultPadding / 4 - 2),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onToggleLn != null) ...[
                        PricingToggleBtn(
                          label: context.t.pricing_toggle_usd,
                          selected: !isLn && !isPoints,
                          onTap: () {
                            onToggleLn!(false);
                            onTogglePoints?.call(false);
                          },
                        ),
                        PricingToggleBtn(
                          label: context.t.pricing_toggle_sats,
                          selected: isLn,
                          onTap: () {
                            onToggleLn!(true);
                            onTogglePoints?.call(false);
                          },
                        ),
                      ] else
                        PricingToggleBtn(
                          label: context.t.pricing_toggle_store,
                          selected: !isPoints,
                          onTap: () => onTogglePoints?.call(false),
                        ),
                      if (onTogglePoints != null)
                        PricingToggleBtn(
                          label: context.t.pricing_toggle_points,
                          selected: isPoints,
                          onTap: () {
                            onToggleLn?.call(false);
                            onTogglePoints!(true);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLn) ...[
              const SizedBox(height: kDefaultPadding / 2),
              LnDiscountBanner(
                text: context.t.pricing_ln_discount_on,
              ),
            ] else if (!isPoints) ...[
              const SizedBox(height: kDefaultPadding / 2),
              LnDiscountBanner(
                text: context.t.pricing_ln_discount_off,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 4,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: kDefaultPadding / 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class LnDiscountBanner extends StatelessWidget {
  const LnDiscountBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2 + 4,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ),
        ],
      ),
    );
  }
}

class PricingToggleBtn extends StatelessWidget {
  const PricingToggleBtn({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.hintColor,
          ),
        ),
      ),
    );
  }
}
