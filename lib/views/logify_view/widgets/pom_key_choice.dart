import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../common/pomegranate/pomegranate_config.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import 'ensure_visible_on_focus.dart';
import 'pom_advanced_options.dart';

/// Step where a new user either generates a key or imports their own, before
/// it gets split across the operators.
class PomKeyChoice extends HookWidget {
  const PomKeyChoice({
    super.key,
    required this.operators,
    required this.threshold,
    required this.onOperatorsChanged,
    required this.onThresholdChanged,
    required this.onContinue,
    this.busy = false,
  });

  final List<String> operators;
  final int threshold;
  final ValueChanged<List<String>> onOperatorsChanged;
  final ValueChanged<int> onThresholdChanged;
  final void Function(String secretKeyHex) onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final useOwn = useState(false);
    final controller = useTextEditingController();
    final error = useState('');

    // Generated once per sheet so the shown nsec is the one registered.
    final generated = useMemoized(Keychain.generate);

    useListenable(controller);
    final parsedOwn = pomParsePrivateKey(controller.text);
    final canContinue = !useOwn.value || parsedOwn != null;

    void handleContinue() {
      if (useOwn.value) {
        final hex = pomParsePrivateKey(controller.text);
        if (hex == null) {
          error.value = context.t.pomKeyInvalid;
          return;
        }
        onContinue(hex);
      } else {
        onContinue(generated.private);
      }
    }

    // Advanced options can outgrow the sheet, so the body scrolls while
    // Continue stays pinned. Done here rather than via the sheet's shared
    // footer because the button depends on this widget's hook state.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: _body(context, useOwn, controller, error, parsedOwn),
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: (busy || !canContinue) ? null : handleContinue,
            child: Text(context.t.pomContinue),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    ValueNotifier<bool> useOwn,
    TextEditingController controller,
    ValueNotifier<String> error,
    String? parsedOwn,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.t.pomKeyChoiceTitle,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.pomKeyChoiceDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: kDefaultPadding),

        _KeyOption(
          icon: LucideIcons.sparkles,
          title: context.t.pomKeyGenerate,
          subtitle: context.t.pomKeyGenerateDesc,
          isSelected: !useOwn.value,
          enabled: !busy,
          onTap: () {
            useOwn.value = false;
            error.value = '';
          },
        ),
        const SizedBox(height: kDefaultPadding / 2),
        _KeyOption(
          icon: LucideIcons.keyRound,
          title: context.t.pomKeyOwn,
          subtitle: context.t.pomKeyOwnDesc,
          isSelected: useOwn.value,
          enabled: !busy,
          onTap: () {
            useOwn.value = true;
            error.value = '';
          },
        ),

        if (useOwn.value) ...[
          const SizedBox(height: kDefaultPadding / 2),
          EnsureVisibleOnFocus(
            child: TextField(
              controller: controller,
              enabled: !busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => error.value = '',
              decoration: InputDecoration(
                hintText: context.t.pomKeyOwnHint,
                errorText: error.value.isEmpty ? null : error.value,
              ),
            ),
          ),
          if (parsedOwn != null) ...[
            const SizedBox(height: kDefaultPadding / 2),
            Container(
              padding: const EdgeInsets.all(kDefaultPadding / 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                color: kMainColor.withValues(alpha: 0.1),
                border: Border.all(color: kMainColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(
                    LucideIcons.triangleAlert,
                    size: 16,
                    color: kMainColor,
                  ),
                  const SizedBox(width: kDefaultPadding / 2),
                  Expanded(
                    child: Text(
                      context.t.pomKeyExistingWarning(count: operators.length),
                      style: theme.textTheme.labelSmall!.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],

        const SizedBox(height: kDefaultPadding / 2),
        PomAdvancedOptions(
          operators: operators,
          threshold: threshold,
          enabled: !busy,
          onOperatorsChanged: onOperatorsChanged,
          onThresholdChanged: onThresholdChanged,
        ),
      ],
    );
  }
}

class _KeyOption extends StatelessWidget {
  const _KeyOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final bool isSelected, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(kDefaultPadding / 1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.08)
              : theme.cardColor,
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              icon,
              size: 20,
              color: isSelected ? theme.primaryColor : theme.hintColor,
            ),
            const SizedBox(width: kDefaultPadding / 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
              isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 18,
              color: isSelected ? theme.primaryColor : theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }
}
