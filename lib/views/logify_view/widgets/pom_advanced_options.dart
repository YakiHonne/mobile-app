import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/pomegranate/pomegranate_config.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import 'ensure_visible_on_focus.dart';
import 'pom_server_picker.dart';

/// Both bounds are protocol-level: a 1-of-n split gives any single operator the
/// whole key, and a threshold above the operator count can never be met.
const kPomMinOperators = 2;
const kPomMinThreshold = 2;

/// Collapsed by default — the defaults are good, and the cost of a bad operator
/// set here is an unrecoverable account.
class PomAdvancedOptions extends HookWidget {
  const PomAdvancedOptions({
    super.key,
    required this.operators,
    required this.threshold,
    required this.onOperatorsChanged,
    required this.onThresholdChanged,
    this.enabled = true,
  });

  final List<String> operators;
  final int threshold;
  final ValueChanged<List<String>> onOperatorsChanged;
  final ValueChanged<int> onThresholdChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = useState(false);
    final controller = useTextEditingController();
    final error = useState('');

    final recommended = kPomOperatorUrls
        .where((op) => !operators.contains(op))
        .toList();
    final canRemove = operators.length > kPomMinOperators;

    void addOperator(String raw) {
      final normalised = pomNormaliseCentral(raw);
      if (normalised == null) {
        error.value = context.t.pomOperatorInvalid;
        return;
      }
      if (operators.contains(normalised)) {
        error.value = context.t.pomOperatorDuplicate;
        return;
      }
      error.value = '';
      controller.clear();
      onOperatorsChanged([...operators, normalised]);
    }

    void removeOperator(String operator) {
      error.value = '';
      final next = operators.where((op) => op != operator).toList();
      onOperatorsChanged(next);
      // Threshold can never exceed the number of operators holding a shard.
      if (threshold > next.length) {
        onThresholdChanged(next.length);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: enabled ? () => expanded.value = !expanded.value : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
            child: Row(
              children: [
                AppIcon(
                  LucideIcons.settings2,
                  size: 18,
                  color: theme.hintColor,
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Expanded(
                  child: Text(
                    context.t.pomAdvancedOptions,
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded.value ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: AppIcon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (expanded.value)
          Container(
            margin: const EdgeInsets.only(bottom: kDefaultPadding / 2),
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(text: context.t.pomOperatorsTitle),
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  context.t.pomOperatorsDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),

                // At the minimum none of them can be removed, so the whole row
                // reads as locked rather than offering a button that refuses.
                ...operators.map(
                  (operator) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            Uri.parse(operator).host,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: canRemove ? null : theme.disabledColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: (enabled && canRemove)
                              ? () => removeOperator(operator)
                              : null,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AppIcon(
                              LucideIcons.circleX,
                              size: 18,
                              color: canRemove
                                  ? theme.hintColor
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: kDefaultPadding / 2),
                Row(
                  children: [
                    Expanded(
                      child: EnsureVisibleOnFocus(
                        child: TextField(
                          controller: controller,
                          enabled: enabled,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          onChanged: (_) => error.value = '',
                          onSubmitted: addOperator,
                          decoration: InputDecoration(
                            hintText: context.t.pomOperatorAddHint,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: kDefaultPadding / 2),
                    TextButton(
                      onPressed: enabled
                          ? () => addOperator(controller.text)
                          : null,
                      child: Text(context.t.pomOperatorAdd),
                    ),
                  ],
                ),

                if (error.value.isNotEmpty) ...[
                  const SizedBox(height: kDefaultPadding / 4),
                  Text(
                    error.value,
                    style: theme.textTheme.labelSmall!.copyWith(color: kRed),
                  ),
                ],

                if (recommended.isNotEmpty) ...[
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    context.t.pomOperatorRecommended,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding / 4),
                  Wrap(
                    spacing: kDefaultPadding / 2,
                    runSpacing: kDefaultPadding / 2,
                    children: recommended
                        .map(
                          (operator) => _RecommendedChip(
                            host: Uri.parse(operator).host,
                            enabled: enabled,
                            onTap: () => addOperator(operator),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: kDefaultPadding),
                _SectionLabel(text: context.t.pomThresholdTitle),
                const SizedBox(height: kDefaultPadding / 2),
                Row(
                  children: [
                    _StepperButton(
                      icon: LucideIcons.minus,
                      enabled: enabled && threshold > kPomMinThreshold,
                      onTap: () => onThresholdChanged(threshold - 1),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$threshold',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: LucideIcons.plus,
                      enabled: enabled && threshold < operators.length,
                      onTap: () => onThresholdChanged(threshold + 1),
                    ),
                    const SizedBox(width: kDefaultPadding / 2),
                    Expanded(
                      child: Text(
                        context.t.pomThresholdDesc(total: operators.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
        color: Theme.of(context).hintColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RecommendedChip extends StatelessWidget {
  const _RecommendedChip({
    required this.host,
    required this.enabled,
    required this.onTap,
  });

  final String host;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 2.5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(LucideIcons.plus, size: 14, color: theme.hintColor),
            const SizedBox(width: kDefaultPadding / 2),
            Text(host, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.cardColor,
          border: Border.all(
            color: enabled ? theme.dividerColor : theme.disabledColor,
            width: 0.5,
          ),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 16,
            color: enabled ? null : theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
