import 'package:flutter/material.dart';

import '../../../../logic/ask_ai_cubit/ask_ai_cubit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../subscription_view/pricing/subscription_gate.dart';
import '../../../widgets/response_snackbar.dart';
import 'article_ai_panel.dart';

/// Helpers shared by both article editor sections — the Quill one in
/// article_quill_editor.dart and the legacy AppFlowy one in article_content.dart.
/// They live here so neither file has to import the other.

void confirmDeleteDraft(BuildContext context, VoidCallback onConfirmed) {
  showCupertinoDeletionDialogue(
    context: context,
    title: context.t.deleteDraft.capitalizeFirst(),
    description: context.t.confirmDeleteDraftChats.capitalizeFirst(),
    buttonText: context.t.delete.capitalizeFirst(),
    onDelete: () {
      YNavigator.pop(context);
      onConfirmed();
    },
  );
}

/// Gates Ask AI behind the premium check.
void openAskAi(BuildContext context, AskAiCubit askAiCubit) {
  final allowed = requireSubscription(
    context,
    upsellTitle: context.t.aiPanel_upgrade_title,
    upsellFeatures: [
      context.t.aiPanel_feature1,
      context.t.aiPanel_feature2,
      context.t.aiPanel_feature3,
    ],
  );

  if (!allowed) {
    return;
  }
  showArticleAskAi(context, askAiCubit);
}

class AiButtonRow extends StatelessWidget {
  const AiButtonRow({
    super.key,
    required this.onSecondReader,
    required this.onAskAi,
  });

  final VoidCallback onSecondReader;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: _AiButton(
            label: '✦ ${context.t.second_reader_title}',
            onTap: onSecondReader,
          ),
        ),
        Expanded(
          child: _AiButton(
            label: '✦ ${context.t.ask_ai_title}',
            onTap: onAskAi,
          ),
        ),
      ],
    );
  }
}

class _AiButton extends StatelessWidget {
  const _AiButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}
