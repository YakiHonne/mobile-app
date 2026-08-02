import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/event_signer/event_signer.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../common/markdown/format_markdown.dart';
import '../../../../common/markdown/markdown_text_input.dart';
import '../../../../common/widgets/ai_upsell_sheet.dart';
import '../../../../logic/ask_ai_cubit/ask_ai_cubit.dart';
import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/fluid_blur_container.dart';
import '../../../widgets/mark_down_widget.dart';
import '../../../widgets/response_snackbar.dart';
import '../../second_reader/second_reader_screen.dart';
import 'article_ai_panel.dart';

class ArticleContent extends HookWidget {
  const ArticleContent({
    super.key,
    required this.isMenuDismissed,
    this.useAdvanced = false,
    this.signer,
    required this.isSubscriber,
  });

  final bool isMenuDismissed;
  final bool useAdvanced;
  final ValueNotifier<EventSigner>? signer;
  final bool isSubscriber;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    final articleWritingState = useState(
      isTablet ? ArticleWritingState.editPreview : ArticleWritingState.edit,
    );

    final title = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.title,
    );

    final content = useTextEditingController(
      text: context.read<WriteArticleCubit>().state.content,
    );

    // Sync the classic editor text into the cubit when switching to advanced,
    // so AppFlowy builds its document from the latest typed content.
    useEffect(() {
      if (useAdvanced) {
        context.read<WriteArticleCubit>().setContentText(content.text);
      }
      return null;
    }, [useAdvanced]);

    return BlocConsumer<WriteArticleCubit, WriteArticleState>(
      listenWhen: (previous, current) =>
          previous.tryToLoad != current.tryToLoad,
      listener: (context, state) {
        title.text = state.title;
        content.text = state.content;
      },
      builder: (context, state) {
        void onDeleteDraft() => _confirmDeleteDraft(
              context,
              () => context.read<WriteArticleCubit>().deleteDraft(),
            );

        return Column(
          children: [
            Expanded(
              child: useAdvanced
                  ? _AppFlowyEditorSection(
                      cubit: context.read<WriteArticleCubit>(),
                      onDeleteDraft:
                          context.read<WriteArticleCubit>().deleteDraft,
                      titleController: title,
                      onTitleChanged:
                          context.read<WriteArticleCubit>().setTitleText,
                    )
                  : Padding(
                      padding:
                          EdgeInsets.all(isTablet ? kDefaultPadding / 2 : 0),
                      child: MarkdownTextInput(
                        (c) =>
                            context.read<WriteArticleCubit>().setContentText(c),
                        (t) =>
                            context.read<WriteArticleCubit>().setTitleText(t),
                        title,
                        removeBottomPadding: isSubscriber,
                        state.content,
                        isMenuDismissed,
                        onDeleteDraft: onDeleteDraft,
                        onMetadataInserted: (imeta) {
                          context.read<WriteArticleCubit>().addImeta(imeta);
                        },
                        label: context.t.whatsOnYourMind,
                        toggleArticleContent: articleWritingState,
                        previewWidget: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 1.5,
                          ),
                          child: CustomScrollView(
                            slivers: [
                              const SliverToBoxAdapter(
                                child: SizedBox(height: kDefaultPadding / 2),
                              ),
                              SliverToBoxAdapter(
                                child: Directionality(
                                  textDirection: getTextDirect(state.content),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BlocBuilder<WriteArticleCubit,
                                          WriteArticleState>(
                                        buildWhen: (p, c) => p.title != c.title,
                                        builder: (context, state) {
                                          return Text(
                                            state.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall!
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(
                                          height: kDefaultPadding / 2),
                                      MarkDownWidget(
                                        content: state.content,
                                        onLinkClicked: (link) =>
                                            openWebPage(url: link),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: kDefaultPadding / 2),
                              ),
                            ],
                          ),
                        ),
                        actions: MarkdownType.values,
                        controller: content,
                        maxLines: isTablet ? 15 : 10,
                      ),
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        );
      },
    );
  }
}

void _confirmDeleteDraft(BuildContext context, VoidCallback onConfirmed) {
  showCupertinoDeletionDialogue(
    context: context,
    title: context.t.deleteDraft.capitalizeFirst(),
    description: context.t.confirmDeleteDraft.capitalizeFirst(),
    buttonText: context.t.delete.capitalizeFirst(),
    onDelete: () {
      YNavigator.pop(context);
      onConfirmed();
    },
  );
}

// ── AppFlowy editor section ───────────────────────────────────────────────────

class _AppFlowyEditorSection extends StatefulWidget {
  const _AppFlowyEditorSection({
    required this.cubit,
    required this.onDeleteDraft,
    required this.titleController,
    required this.onTitleChanged,
  });
  final WriteArticleCubit cubit;
  final VoidCallback onDeleteDraft;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;

  @override
  State<_AppFlowyEditorSection> createState() => _AppFlowyEditorSectionState();
}

class _AppFlowyEditorSectionState extends State<_AppFlowyEditorSection> {
  late final EditorState _editorState;
  late final EditorScrollController _scrollController;
  late final AskAiCubit _askAiCubit;
  StreamSubscription<EditorTransactionValue>? _txSub;
  bool _aiRowExpanded = true;

  @override
  void initState() {
    super.initState();
    _editorState = widget.cubit.buildEditorState();
    _scrollController = EditorScrollController(editorState: _editorState);
    _askAiCubit = AskAiCubit(editorState: _editorState);
    _txSub = _editorState.transactionStream.listen((_) {
      widget.cubit.setContentText(
        widget.cubit.extractMarkdown(_editorState),
      );
    });
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _scrollController.dispose();
    _askAiCubit.close();
    super.dispose();
  }

  // The cubit reset alone doesn't touch the AppFlowy document, so wipe the
  // nodes here too and let the title controller be reset by the bloc listener.
  Future<void> _deleteDraft() async {
    final children = _editorState.document.root.children;
    final transaction = _editorState.transaction
      ..deleteNodesAtPath([0], children.length)
      ..insertNode([0], paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: [0]));

    await _editorState.apply(transaction);
    widget.onDeleteDraft();
  }

  void _openSecondReader(BuildContext context) {
    final content = widget.cubit.extractMarkdown(_editorState);
    showSecondReader(
      context,
      content,
      onFixWithAi: (prefill) =>
          showArticleAskAi(context, _askAiCubit, prefill: prefill),
    );
  }

  void _openAskAi(BuildContext context) {
    if (!subscriptionCubit.isPremium) {
      showAdaptiveModal<void>(
        context,
        useRootNavigator: false,
        backgroundColor: Colors.transparent,
        builder: (_) => AiUpsellSheet(
          parentContext: context,
          title: context.t.aiPanel_upgrade_title,
          features: [
            context.t.aiPanel_feature1,
            context.t.aiPanel_feature2,
            context.t.aiPanel_feature3,
          ],
        ),
      );
      return;
    }
    showArticleAskAi(context, _askAiCubit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final toolbar = MobileToolbar(
      editorState: _editorState,
      toolbarItems: [
        textDecorationMobileToolbarItem,
        headingMobileToolbarItem,
        listMobileToolbarItem,
        linkMobileToolbarItem,
        quoteMobileToolbarItem,
        codeMobileToolbarItem,
      ],
      trailingActions: [
        CustomIconButton(
          onClicked: () => _confirmDeleteDraft(context, _deleteDraft),
          icon: FeatureIcons.trash,
          size: 25,
          backgroundColor: kTransparent,
          iconColor: Colors.red,
          borderRadius: kDefaultPadding / 2,
          vd: 2.8,
        ),
      ],
      backgroundColor: kTransparent,
      foregroundColor: theme.hintColor,
      iconColor: theme.primaryColorDark,
      primaryColor: theme.primaryColor,
      outlineColor: theme.dividerColor,
      itemHighlightColor: theme.primaryColor,
      itemOutlineColor: kTransparent,
      tabbarSelectedBackgroundColor: theme.primaryColor.withValues(alpha: 0.12),
      tabbarSelectedForegroundColor: theme.primaryColorDark,
      clearDiagonalLineColor: Colors.red,
    );

    return Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: TextFormField(
                    controller: widget.titleController,
                    onChanged: widget.onTitleChanged,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: context.t.giveMeCatchyTitle,
                      hintStyle: theme.textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.highlightColor,
                      ),
                      fillColor: theme.scaffoldBackgroundColor,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 2,
                        horizontal: kDefaultPadding / 1.5,
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: AppFlowyEditor(
                    editorState: _editorState,
                    editorScrollController: _scrollController,
                    blockComponentBuilders: {
                      ...standardBlockComponentBuilderMap,
                      ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
                        configuration: BlockComponentConfiguration(
                          placeholderText: (_) => context.t.whatsOnYourMind,
                          placeholderTextStyle: (node, {textSpan}) =>
                              theme.textTheme.bodyLarge!.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        showPlaceholder: (editorState, node) {
                          final nodes = editorState.document.root.children;
                          return nodes.length == 1 &&
                              node == nodes.first &&
                              (node.delta?.isEmpty ?? true);
                        },
                      ),
                    },
                    commandShortcutEvents: standardCommandShortcutEvents,
                    editorStyle: EditorStyle.mobile(
                      padding: const EdgeInsets.fromLTRB(
                        kDefaultPadding,
                        kDefaultPadding / 2,
                        kDefaultPadding,
                        kDefaultPadding / 2,
                      ),
                      textStyleConfiguration: TextStyleConfiguration(
                        text: theme.textTheme.bodyLarge!,
                      ),
                    ),
                    footer: const SizedBox(height: kDefaultPadding * 4),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Toggle arrow
        GestureDetector(
          onTap: () => setState(() => _aiRowExpanded = !_aiRowExpanded),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: AnimatedRotation(
                turns: _aiRowExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronUp,
                  size: 20,
                  color: _aiRowExpanded ? theme.primaryColor : theme.hintColor,
                ),
              ),
            ),
          ),
        ),

        // Collapsible AI buttons row
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _aiRowExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding / 2,
                    kDefaultPadding / 4,
                    kDefaultPadding / 2,
                    kDefaultPadding / 2,
                  ),
                  child: _AiButtonRow(
                    onSecondReader: () => _openSecondReader(context),
                    onAskAi: () => _openAskAi(context),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Formatting toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding / 2,
            0,
            kDefaultPadding / 2,
            kDefaultPadding / 2,
          ),
          child: isFluid()
              ? FluidBlurContainer(
                  borderRadius: kDefaultPadding / 2,
                  child: toolbar,
                )
              : Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  ),
                  child: toolbar,
                ),
        ),
      ],
    );
  }
}

class _AiButtonRow extends StatelessWidget {
  const _AiButtonRow({
    required this.onSecondReader,
    required this.onAskAi,
  });

  final VoidCallback onSecondReader;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AiButton(
            label: '✦ ${context.t.second_reader_title}',
            onTap: onSecondReader,
          ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
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
