import 'package:flutter/material.dart';

import '../../../../utils/utils.dart';
import '../../../widgets/fluid_switch.dart';

class PublishSectionLabel extends StatelessWidget {
  const PublishSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class PublishSection extends StatelessWidget {
  const PublishSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PublishSectionLabel(label),
          const SizedBox(height: kDefaultPadding / 2),
          child,
        ],
      ),
    );
  }
}

InputDecoration publishInputDecoration(
  BuildContext context,
  String hintText, {
  bool isDense = false,
}) {
  return InputDecoration(
    hintText: hintText,
    isDense: isDense,
    contentPadding: const EdgeInsets.all(kDefaultPadding / 2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      borderSide: BorderSide(color: Theme.of(context).dividerColor),
    ),
  );
}

class PublishOptionsCard extends StatelessWidget {
  const PublishOptionsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) Divider(height: 1, color: theme.dividerColor),
            child,
          ],
        ],
      ),
    );
  }
}

class PublishToggleRow extends StatelessWidget {
  const PublishToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.highlightColor,
              ),
            ),
      contentPadding: EdgeInsets.zero,
      onTap: onChanged,
      trailing: FluidSwitch(
        value: value,
        onChanged: (_) => onChanged(),
        activeTrackColor: theme.primaryColor,
      ),
    );
  }
}
