import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/pomegranate/pomegranate_config.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import 'ensure_visible_on_focus.dart';

/// Normalised central URL, or null when [raw] is not a usable https address.
///
/// Thin alias over the shared validator, kept so this file reads in terms of
/// centrals; operators go through the same rules.
String? pomNormaliseCentral(String raw) => pomNormaliseUrl(raw);

/// Lets the user pick which central their identity lives on: ours, the
/// suggested alternative, or one they host themselves.
class PomServerPicker extends HookWidget {
  const PomServerPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom =
        selected != kPomCentralUrl && selected != kPomBackupCentralUrl;
    final showCustomField = useState(isCustom);
    final controller = useTextEditingController(text: isCustom ? selected : '');
    final error = useState('');
    final focusNode = useFocusNode();

    // Reported up as an empty central so the caller cannot start OAuth
    // against a half-typed or invalid host. The message itself waits for
    // submit/blur, else it fires on the first keystroke of a good URL.
    void submitCustom(String value, {bool showError = false}) {
      final trimmed = value.trim();
      final normalised = pomNormaliseCentral(value);

      // A wrong scheme cannot become valid by typing more, so say so now
      // rather than leaving the button greyed out with no reason given.
      final wrongScheme =
          trimmed.contains('://') && !trimmed.startsWith('https://');

      error.value =
          (normalised == null &&
              trimmed.isNotEmpty &&
              (showError || wrongScheme))
          ? context.t.pomServerInvalid
          : '';
      onChanged(normalised ?? '');
    }

    useEffect(() {
      void onFocusChange() {
        if (!focusNode.hasFocus) {
          submitCustom(controller.text, showError: true);
        }
      }

      focusNode.addListener(onFocusChange);
      return () => focusNode.removeListener(onFocusChange);
    }, [focusNode]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.pomServerTitle,
          style: theme.textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.pomServerDesc,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: kDefaultPadding / 1.5),

        _ServerOption(
          host: Uri.parse(kPomCentralUrl).host,
          badge: context.t.pomServerDefault,
          isSelected: selected == kPomCentralUrl && !showCustomField.value,
          enabled: enabled,
          onTap: () {
            showCustomField.value = false;
            onChanged(kPomCentralUrl);
          },
        ),
        const SizedBox(height: kDefaultPadding / 2),
        _ServerOption(
          host: Uri.parse(kPomBackupCentralUrl).host,
          badge: context.t.pomServerSuggested,
          isSelected:
              selected == kPomBackupCentralUrl && !showCustomField.value,
          enabled: enabled,
          onTap: () {
            showCustomField.value = false;
            onChanged(kPomBackupCentralUrl);
          },
        ),
        const SizedBox(height: kDefaultPadding / 2),
        _ServerOption(
          host: context.t.pomServerCustom,
          isSelected: showCustomField.value,
          enabled: enabled,
          onTap: () {
            showCustomField.value = true;
            submitCustom(controller.text);
          },
        ),

        if (showCustomField.value) ...[
          const SizedBox(height: kDefaultPadding / 2),
          EnsureVisibleOnFocus(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.url,
              autocorrect: false,
              onChanged: submitCustom,
              onSubmitted: (v) => submitCustom(v, showError: true),
              decoration: InputDecoration(
                hintText: context.t.pomServerCustomHint,
                errorText: error.value.isEmpty ? null : error.value,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServerOption extends StatelessWidget {
  const _ServerOption({
    required this.host,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  final String host;
  final String? badge;
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
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 1.5,
        ),
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
              isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
              size: 18,
              color: isSelected ? theme.primaryColor : theme.hintColor,
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Text(
                host,
                style: theme.textTheme.labelLarge!.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: theme.dividerColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  badge!,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
