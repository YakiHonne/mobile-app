import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../../logic/ask_ai_cubit/ask_ai_cubit.dart';
import '../../../../logic/subscription_cubit/usage_limit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../subscription_view/pricing/pricing_screen.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/fluid_sheet.dart';
import '../../../widgets/modal_sheet_container.dart';
import '../../../widgets/usage_gate.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

Future<void> showArticleAskAi(
  BuildContext context,
  AskAiCubit cubit, {
  String? prefill,
}) {
  return showAppModalSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _AskAiBody(prefill: prefill),
    ),
  );
}

// ── Body router ───────────────────────────────────────────────────────────────

class _AskAiBody extends StatefulWidget {
  const _AskAiBody({this.prefill});
  final String? prefill;

  @override
  State<_AskAiBody> createState() => _AskAiBodyState();
}

class _AskAiBodyState extends State<_AskAiBody> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prefill ?? '');
    if (widget.prefill != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.selection =
            TextSelection.collapsed(offset: _controller.text.length);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AskAiCubit, AskAiState>(
      buildWhen: (p, c) => p.view != c.view,
      builder: (_, state) => state.view == AskAiView.diff
          ? const _AiDiffSheet()
          : _AiChatSheet(controller: _controller, focusNode: _focusNode),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

Widget _aiShell({
  required BuildContext context,
  required List<Widget> children,
}) {
  // showModalBottomSheet doesn't resize for the keyboard, so lift the sheet by
  // the inset ourselves — otherwise the input bar sits behind the keyboard.
  final media = MediaQuery.of(context);
  final bottomInset = media.viewInsets.bottom;
  // Clamped: a tall keyboard on a short screen would otherwise send maxHeight
  // negative, which BoxConstraints rejects.
  final maxHeight = (media.size.height * 0.92 - bottomInset)
      .clamp(0.0, media.size.height);

  return Padding(
    padding: EdgeInsets.only(bottom: bottomInset),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ModalSheetContainer(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
}

// ── Chat sheet ────────────────────────────────────────────────────────────────

class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet({required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocConsumer<AskAiCubit, AskAiState>(
      listenWhen: (p, c) =>
          p.messages.length != c.messages.length || p.isLoading != c.isLoading,
      listener: (_, __) => _scrollToBottom(),
      builder: (ctx, state) {
        final cubit = ctx.read<AskAiCubit>();

        return _aiShell(
          context: context,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding / 2,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    context.t.ask_ai_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppIconButton(
                      icon: LucideIcons.x,
                      onClicked: () => Navigator.of(context).pop(),
                      iconSize: 16,
                      iconColor: theme.hintColor,
                      backgroundColor: theme.cardColor,
                      size: 32,
                      buttonRadius: 16,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: theme.dividerColor),

            // Message list
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding,
                ),
                itemCount: _itemCount(state),
                itemBuilder: (_, i) => _buildItem(ctx, i, state, theme, cubit),
              ),
            ),

            // Quota banner + input bar. UsageGate so a refresh mid-session
            // raises the banner without the sheet knowing about usage.
            UsageGate(
              builder: (ctx) {
                final limit = usageLimitFor(kUsageKeyAskAi);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (limit != null) _QuotaBanner(limit: limit),
                    _buildInputBar(
                      ctx,
                      theme,
                      state,
                      cubit,
                      bottomInset,
                      bottomPadding,
                      blocked: limit != null,
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    ThemeData theme,
    AskAiState state,
    AskAiCubit cubit,
    double bottomInset,
    double bottomPadding, {
    required bool blocked,
  }) {
    final sendDisabled = state.isLoading || blocked;
    return Container(
      padding: EdgeInsets.fromLTRB(
        kDefaultPadding / 2,
        kDefaultPadding / 2,
        kDefaultPadding / 2,
        bottomInset > 0
            ? kDefaultPadding / 2
            : bottomPadding + kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !blocked,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: blocked
                    ? context.t.usage_quota_exceeded
                    : context.t.ask_ai_placeholder,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2 + 2,
                  vertical: kDefaultPadding / 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 4),
          CustomIconButton(
            onClicked: sendDisabled
                ? () {}
                : () {
                    final msg = widget.controller.text.trim();
                    if (msg.isEmpty) {
                      return;
                    }
                    cubit.send(msg);
                    widget.controller.clear();
                  },
            icon: LucideIcons.arrowUp,
            widget: state.isLoading
                ? SpinKitThreeBounce(color: theme.hintColor, size: 12)
                : null,
            iconColor: Colors.white,
            size: 18,
            backgroundColor:
                sendDisabled ? theme.dividerColor : theme.primaryColor,
            borderRadius: kDefaultPadding / 2,
            vd: 1,
          ),
          const SizedBox(width: kDefaultPadding / 4),
          CustomIconButton(
            onClicked: state.messages.isEmpty
                ? () {}
                : () {
                    cubit.clear();
                    widget.controller.clear();
                  },
            icon: FeatureIcons.trash,
            iconColor: state.messages.isEmpty
                ? theme.dividerColor
                : theme.hintColor,
            size: 18,
            backgroundColor: theme.cardColor,
            borderRadius: kDefaultPadding / 2,
            vd: 1,
          ),
        ],
      ),
    );
  }

  int _itemCount(AskAiState state) =>
      state.messages.length +
      (state.isLoading ? 1 : 0) +
      (state.changedHunkCount > 0 && !state.applied ? 1 : 0) +
      (state.applied ? 1 : 0) +
      (state.error != null ? 1 : 0) +
      (state.messages.isEmpty && !state.isLoading ? 1 : 0);

  Widget _buildItem(
    BuildContext ctx,
    int i,
    AskAiState state,
    ThemeData theme,
    AskAiCubit cubit,
  ) {
    if (state.messages.isEmpty && !state.isLoading) {
      return i == 0
          ? Text(
              ctx.t.ask_ai_empty_hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.6,
              ),
            )
          : const SizedBox.shrink();
    }

    if (i < state.messages.length) {
      final msg = state.messages[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding),
        child: msg.role == ChatRole.user
            ? _AiUserBubble(text: msg.text, theme: theme)
            : _AiAssistantBubble(text: msg.text, theme: theme),
      );
    }

    int offset = state.messages.length;

    if (state.isLoading && i == offset) {
      return Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding),
        child: _AiLoadingBubble(theme: theme),
      );
    }
    if (state.isLoading) {
      offset++;
    }

    if (state.changedHunkCount > 0 && !state.applied && i == offset) {
      return Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
        child: _ReviewChangesButton(
          count: state.changedHunkCount,
          theme: theme,
          onTap: cubit.showDiff,
        ),
      );
    }
    if (state.changedHunkCount > 0 && !state.applied) {
      offset++;
    }

    if (state.applied && i == offset) {
      return Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
        child: Row(
          children: [
            Icon(
              LucideIcons.circleCheck,
              size: 15,
              color: Colors.green[600],
            ),
            const SizedBox(width: kDefaultPadding / 4),
            Text(
              ctx.t.ask_ai_changes_applied,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (state.applied) {
      offset++;
    }

    if (state.error != null && i == offset) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Text(
          ctx.t.ask_ai_error,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Diff sheet ────────────────────────────────────────────────────────────────

class _AiDiffSheet extends StatelessWidget {
  const _AiDiffSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AskAiCubit, AskAiState>(
        builder: (ctx, state) {
          final cubit = ctx.read<AskAiCubit>();
          final changedHunks = state.hunks.where((h) => h.isChanged).toList();

          return _aiShell(
            context: context,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding / 2,
                ),
                child: Row(
                  children: [
                    Text(
                      '✦ ',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${changedHunks.length} ${context.t.diff_viewer_title.toUpperCase()}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    _DiffActionBtn(
                      label: context.t.diff_viewer_accept_all,
                      filled: true,
                      icon: LucideIcons.check,
                      onTap: cubit.applyChanges,
                      theme: theme,
                    ),
                    const SizedBox(width: kDefaultPadding / 2),
                    _DiffActionBtn(
                      label: context.t.diff_viewer_reject_all,
                      filled: false,
                      icon: LucideIcons.x,
                      onTap: cubit.rejectAll,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    kDefaultPadding * 0.75,
                    kDefaultPadding,
                    kDefaultPadding,
                  ),
                  itemCount: changedHunks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: kDefaultPadding / 2),
                  itemBuilder: (_, i) {
                    final hunk = changedHunks[i];
                    final globalIdx = state.hunks.indexOf(hunk);
                    return _DiffHunkCard(
                      hunk: hunk,
                      isDark: isDark,
                      theme: theme,
                      onToggle: (v) => cubit.toggleHunk(globalIdx, v),
                    );
                  },
                ),
              ),
              SizedBox(height: bottomPadding),
            ],
          );
        },
    );
  }
}

// ── Chat bubbles ──────────────────────────────────────────────────────────────

class _AiAssistantBubble extends StatelessWidget {
  const _AiAssistantBubble({required this.text, required this.theme});
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding * 0.75),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: kDefaultPadding / 4 - 3,
              right: kDefaultPadding / 2,
            ),
            child: Icon(
              LucideIcons.sparkles,
              size: 16,
              color: theme.primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiUserBubble extends StatelessWidget {
  const _AiUserBubble({required this.text, required this.theme});
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 0.75,
          vertical: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EB),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            topRight: Radius.circular(kDefaultPadding),
            bottomLeft: Radius.circular(kDefaultPadding),
            bottomRight: Radius.circular(kDefaultPadding / 4),
          ),
        ),
        child: Text(text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
      ),
    );
  }
}

class _AiLoadingBubble extends StatelessWidget {
  const _AiLoadingBubble({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding * 0.75),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: kDefaultPadding / 2),
            child:
                Icon(LucideIcons.sparkles, size: 16, color: theme.primaryColor),
          ),
          SpinKitThreeBounce(color: theme.primaryColor, size: 16),
        ],
      ),
    );
  }
}

class _ReviewChangesButton extends StatelessWidget {
  const _ReviewChangesButton({
    required this.count,
    required this.theme,
    required this.onTap,
  });
  final int count;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 0.75,
          vertical: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.diff, size: 15, color: theme.primaryColor),
            const SizedBox(width: kDefaultPadding / 4),
            Text(
              context.t.ask_ai_review_changes(count: count),
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: kDefaultPadding / 4 - 1),
            Icon(
              LucideIcons.chevronRight,
              size: 15,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diff cards ────────────────────────────────────────────────────────────────

class _DiffHunkCard extends StatelessWidget {
  const _DiffHunkCard({
    required this.hunk,
    required this.isDark,
    required this.theme,
    required this.onToggle,
  });

  final DiffHunk hunk;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<bool> onToggle;

  MarkdownConfig _mdConfig({required bool isRemoved}) {
    final base =
        isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    const textColor = kWhite;
    final deco = isRemoved ? TextDecoration.lineThrough : null;
    return base.copy(
      configs: [
        PConfig(
          textStyle: TextStyle(
            color: textColor,
            height: 1.65,
            fontSize: 14,
            decoration: deco,
            decorationColor: textColor,
            decorationThickness: 1.5,
          ),
        ),
        H1Config(
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                decoration: deco)),
        H2Config(
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: deco)),
        H3Config(
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: deco)),
      ],
    );
  }

  Widget _diffBlock({
    required bool isRemoved,
    required String data,
    required BuildContext context,
    bool roundTop = false,
    bool roundBottom = false,
  }) {
    final decided = hunk.decided;
    final bgColor = isRemoved
        ? kRed.withValues(alpha: 0.07)
        : kGreen.withValues(alpha: 0.07);
    const radius = kDefaultPadding / 2;
    final borderRadius = BorderRadius.only(
      topLeft: roundTop ? const Radius.circular(radius) : Radius.zero,
      topRight: roundTop ? const Radius.circular(radius) : Radius.zero,
      bottomLeft: roundBottom ? const Radius.circular(radius) : Radius.zero,
      bottomRight: roundBottom ? const Radius.circular(radius) : Radius.zero,
    );

    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: BoxDecoration(
                color: isRemoved ? kRed : kGreen,
                borderRadius: BorderRadius.only(
                  topLeft:
                      roundTop ? const Radius.circular(radius) : Radius.zero,
                  bottomLeft:
                      roundBottom ? const Radius.circular(radius) : Radius.zero,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              kDefaultPadding / 2 - 2,
              kDefaultPadding / 2 + 2,
              kDefaultPadding / 2 - 2,
            ),
            child: Column(
              children: [
                MarkdownWidget(
                  data: data,
                  config: _mdConfig(isRemoved: isRemoved),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                ),
                Divider(thickness: 0.5, color: theme.disabledColor),
                if (decided)
                  Row(
                    children: [
                      Icon(
                        hunk.accepted ? LucideIcons.check : LucideIcons.x,
                        size: 12,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: kDefaultPadding / 4),
                      Text(
                        hunk.accepted
                            ? context.t.diff_viewer_accepted
                            : context.t.diff_viewer_rejected,
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _HunkBtn(
                        label: context.t.diff_viewer_accept,
                        filled: true,
                        icon: LucideIcons.check,
                        onTap: () => onToggle(true),
                        theme: theme,
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                      _HunkBtn(
                        label: context.t.diff_viewer_reject,
                        filled: false,
                        icon: LucideIcons.x,
                        onTap: () => onToggle(false),
                        theme: theme,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decided = hunk.decided;
    final hasOld = hunk.originalParagraph != null;
    final hasNew = hunk.revisedParagraph != null;

    return Opacity(
      opacity: decided ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasOld)
              _diffBlock(
                isRemoved: true,
                data: hunk.originalParagraph!,
                roundTop: true,
                roundBottom: !hasNew,
                context: context,
              ),
            if (hasNew)
              _diffBlock(
                isRemoved: false,
                data: hunk.revisedParagraph!,
                roundTop: !hasOld,
                roundBottom: true,
                context: context,
              ),
          ],
        ),
      ),
    );
  }
}

class _DiffActionBtn extends StatelessWidget {
  const _DiffActionBtn({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final fgColor =
        filled ? Colors.white : (isDark ? Colors.white70 : Colors.black54);
    final borderColor = filled
        ? Colors.transparent
        : (isDark ? Colors.white38 : Colors.black26);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 0.75,
          vertical: kDefaultPadding / 4 + 1,
        ),
        decoration: BoxDecoration(
          color: filled ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: kDefaultPadding / 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HunkBtn extends StatelessWidget {
  const _HunkBtn({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = filled ? theme.primaryColor : theme.highlightColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 0.75,
          vertical: kDefaultPadding / 4 + 1,
        ),
        decoration: BoxDecoration(
          color: filled ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: filled ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: kDefaultPadding / 4),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 12,
                fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sits above the input bar when the Ask AI quota is spent or the plan never
/// included it. The Upgrade link is the only one of the three surfaces that
/// has room for a second action.
class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.limit});
  final UsageLimit limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 2,
      ),
      color: Colors.amber.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, size: 16, color: Colors.amber),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(
              limit.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColorDark,
              ),
            ),
          ),
          if (limit.canUpgrade)
            GestureDetector(
              // Null context so pushPage falls back to the global navigator
              // key: this element is defunct the moment the sheet pops.
              onTap: () {
                Navigator.of(context).pop();
                YNavigator.pushPage<void>(null, (_) => const PricingScreen());
              },
              child: Text(
                context.t.usage_upgrade,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
