import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../../views/subscription_view/pricing/pricing_screen.dart';

class AiUpsellSheet extends StatelessWidget {
  const AiUpsellSheet({
    super.key,
    required this.parentContext,
    required this.title,
    required this.features,
  });

  final BuildContext parentContext;
  final String title;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(kDefaultPadding)),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding, kDefaultPadding, kDefaultPadding * 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 4),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(kDefaultPadding),
            ),
            child: Text(
              context.t.ai_upsell_badge.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.brightness == Brightness.dark ? Colors.white : theme.primaryColorDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.ai_upsell_description,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kDefaultPadding),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: Column(
              children: features.map((f) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, color: Colors.white, size: 13),
                      ),
                      const SizedBox(width: kDefaultPadding / 2 + 4),
                      Expanded(
                        child: Text(
                          f,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.brightness == Brightness.dark ? Colors.white : theme.primaryColorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                YNavigator.pushPage(parentContext, (_) => const PricingScreen());
              },
              style: TextButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              ),
              child: Text(
                context.t.ai_upsell_upgrade,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
