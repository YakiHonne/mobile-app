// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
// Aliased: it re-exports pdf/widgets.dart, whose Document, Header, SizedBox and
// EdgeInsets all collide with Material's and Quill's.
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as pw;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart' show EmbeddableTable;
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/markdown/quill_markdown_converters.dart';
import '../../../../logic/ask_ai_cubit/ask_ai_cubit.dart';
import '../../../../logic/write_article_cubit/write_article_cubit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/theme/custom/text_theme.dart';
import '../../../../utils/utils.dart';
import '../../../wallet_view/widgets/user_to_zap_view.dart';
import '../../../widgets/buttons_containers_widgets.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/fluid_blur_container.dart';
import '../../../widgets/fluid_sheet.dart';
import '../../../widgets/modal_sheet_container.dart';
import '../../../widgets/smart_widget_selection.dart';
import '../../second_reader/second_reader_screen.dart';
import 'article_ai_panel.dart';
import 'article_editor_shared.dart';
import 'article_image_selector.dart';

/// The premium article editor: real WYSIWYG on top of flutter_quill.
///
/// Markdown stays the source of truth — articles are Nostr long-form events
/// (kind 30023) — so the document is converted in on load and back out on every
/// save. That boundary lives in common/markdown/quill_markdown_converters.dart.

/// One heading level, on the app's own font scale.
///
/// Headings get breathing room above and none below, so a heading sits with the
/// paragraph it introduces rather than floating between blocks.
DefaultTextBlockStyle _headerStyle(ThemeData theme, double fontSize) =>
    DefaultTextBlockStyle(
      theme.textTheme.bodyLarge!.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      HorizontalSpacing.zero,
      const VerticalSpacing(kDefaultPadding / 2, 0),
      VerticalSpacing.zero,
      null,
    );

/// Inline code, on the app's theme.
///
/// Quill's default hardcodes `Colors.grey.shade100` for the background, which
/// is near-invisible on a light scaffold and glaring on a dark one. The primary
/// colour at low alpha reads as a tint in either.
///
/// The header1-6 overrides are not optional: [InlineCodeStyle] falls back to
/// Quill's own defaults per heading level, so setting only `style` would leave
/// inline code inside a heading unthemed.
InlineCodeStyle _inlineCodeStyle(ThemeData theme) {
  final base = theme.textTheme.bodyLarge!.copyWith(
    fontFamily: 'monospace',
    color: theme.primaryColor,
  );

  TextStyle sized(double fontSize) => base.copyWith(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      );

  return InlineCodeStyle(
    style: base,
    backgroundColor: theme.primaryColor.withValues(alpha: 0.08),
    radius: const Radius.circular(kDefaultPadding / 4),
    header1: sized(FontSizes.headlineLarge),
    header2: sized(FontSizes.headlineMedium),
    header3: sized(FontSizes.headlineSmall),
    header4: sized(FontSizes.titleLarge),
    header5: sized(FontSizes.titleMedium),
    header6: sized(FontSizes.titleSmall),
  );
}

/// Code blocks, on the app's theme.
///
/// Quill's default hardcodes a `Colors.grey.shade50` background (effectively
/// white on every theme) with `Colors.blue.shade900` text.
DefaultTextBlockStyle _codeBlockStyle(ThemeData theme) => DefaultTextBlockStyle(
      theme.textTheme.bodyMedium!.copyWith(
        height: 1.4,
      ),
      HorizontalSpacing.zero,
      const VerticalSpacing(kDefaultPadding / 2, kDefaultPadding / 2),
      VerticalSpacing.zero,
      BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 3),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
    );

/// Heading picker: one icon that expands the six levels horizontally in place.
///
/// Replaces Quill's own dropdown, which opens a vertical menu of text labels
/// ("Heading 1"…) and can't be restyled — [QuillToolbarSelectHeaderStyleDropdownButtonOptions]
/// exposes only the trigger icon, not the menu.
class _HeadingPicker extends StatefulWidget {
  const _HeadingPicker({
    required this.controller,
    required this.onFormatted,
  });

  final QuillController controller;

  /// Pushes the change to the cubit. formatSelection on a collapsed caret may
  /// not emit a DocChange, and the publish flow reads cubit state — so without
  /// this a heading applied just before tapping Next would be lost.
  final VoidCallback onFormatted;

  @override
  State<_HeadingPicker> createState() => _HeadingPickerState();
}

class _HeadingPickerState extends State<_HeadingPicker> {
  /// Body text first, then the six heading levels — one uniform set, so
  /// clearing a heading is a choice in the same row rather than a special case.
  /// `Attribute.header` carries a null value, which is how Quill spells "no
  /// heading".
  static const _levels = <(Attribute<int?>, IconData)>[
    (Attribute.header, LucideIcons.type),
    (Attribute.h1, LucideIcons.heading1),
    (Attribute.h2, LucideIcons.heading2),
    (Attribute.h3, LucideIcons.heading3),
    (Attribute.h4, LucideIcons.heading4),
    (Attribute.h5, LucideIcons.heading5),
    (Attribute.h6, LucideIcons.heading6),
  ];

  bool _expanded = false;
  int? _lastLevel;

  @override
  void initState() {
    super.initState();
    // The active level changes as the caret moves, not just when a button is
    // tapped, so the icon has to follow the selection — collapsed too, which is
    // the state it is in most of the time.
    widget.controller.addListener(_onSelectionChanged);
    _lastLevel = _current?.value as int?;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (!mounted) {
      return;
    }
    // The controller notifies on every keystroke; only rebuild when the heading
    // level actually changed.
    final level = _current?.value as int?;
    if (level != _lastLevel) {
      setState(() => _lastLevel = level);
    }
  }

  /// The heading attribute covering the caret, or null for body text.
  Attribute<dynamic>? get _current {
    final attr =
        widget.controller.getSelectionStyle().attributes[Attribute.header.key];
    return attr?.value == null ? null : attr;
  }

  void _apply(Attribute<int?> level) {
    // Attribute.header's value is null, so selecting the body-text entry clears
    // the heading through the same call as setting one.
    widget.controller.formatSelection(level);
    widget.onFormatted();
    setState(() => _lastLevel = _current?.value as int?);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _current;

    Widget button({
      required IconData icon,
      required bool selected,
      required VoidCallback onTap,
    }) =>
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 25),
          visualDensity: VisualDensity.compact,
          style: selected
              ? IconButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                )
              : null,
        );

    if (!_expanded) {
      return button(
        // Shows which level is active without expanding. orElse matters: the
        // header value comes from the Delta, so a pasted or externally-written
        // draft can carry a level outside 1-6, and a bare firstWhere would
        // throw inside build() and replace the toolbar with an error box.
        icon: current == null
            ? LucideIcons.type
            : _levels
                .firstWhere(
                  (l) => l.$1.value == current.value,
                  orElse: () => (Attribute.header, LucideIcons.type),
                )
                .$2,
        selected: current != null,
        onTap: () => setState(() => _expanded = true),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          icon: LucideIcons.chevronLeft,
          selected: false,
          onTap: () => setState(() => _expanded = false),
        ),
        for (final (attribute, icon) in _levels)
          button(
            icon: icon,
            selected: current?.value == attribute.value,
            onTap: () => _apply(attribute),
          ),
      ],
    );
  }
}

// ── Live markdown editor section (premium) ────────────────────────────────────
//
// Obsidian/Typora-style: syntax markers show only on the line holding the
// caret, every other line renders formatted. The source of truth stays a
// markdown string, which is what the cubit, autosave and AI diff all expect.

class ArticlePremiumEditor extends StatefulWidget {
  const ArticlePremiumEditor({
    super.key,
    required this.initialContent,
    required this.cubit,
    required this.onDeleteDraft,
    required this.titleController,
    required this.onTitleChanged,
  });
  final String initialContent;
  final WriteArticleCubit cubit;
  final VoidCallback onDeleteDraft;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;

  @override
  State<ArticlePremiumEditor> createState() => ArticlePremiumEditorState();
}

class ArticlePremiumEditorState extends State<ArticlePremiumEditor> {
  late final QuillController _controller;
  late final AskAiCubit _askAiCubit;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  StreamSubscription<DocChange>? _docSub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Built once and never rebuilt from cubit state: re-deriving the document
    // from state.content on every emit would fight the editor while typing.
    _controller = QuillController(
      document: markdownToQuillDocument(widget.initialContent),
      selection: const TextSelection.collapsed(offset: 0),
      // Quill marks the clipboard API experimental; it is the only hook that
      // can insert a Delta on paste, so revisit this on a package upgrade.
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onClipboardPaste: _onClipboardPaste,
        ),
      ),
    );
    _docSub = _controller.changes.listen((_) => _onDocumentChanged());
    _askAiCubit = AskAiCubit(
      readMarkdown: () => quillDocumentToMarkdown(_controller.document),
      // Replacing the document doesn't emit through the debounce path, so push
      // to the cubit here or the AI's edit never reaches autosave/publish.
      writeMarkdown: (markdown) async {
        _setMarkdown(markdown);
        widget.cubit.setContentText(markdown);
      },
    );
  }

  @override
  void deactivate() {
    // Leaving the editor (Next, back, or a sheet) must not lose the last 400ms
    // of typing: the publish flow reads cubit state, not the document.
    _flushToCubit();
    super.deactivate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _docSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _askAiCubit.close();
    super.dispose();
  }

  // ponytail: debounced instead of per-keystroke — serialising the whole
  // document to markdown on every character is wasted work when the cubit only
  // needs it for autosave and publish.
  void _onDocumentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _flushToCubit);
  }

  void _flushToCubit() {
    _debounce?.cancel();
    widget.cubit.setContentText(quillDocumentToMarkdown(_controller.document));
  }

  // Replaces the whole document. Collapsing the selection first matters: Quill
  // keeps the old selection against the new document otherwise, which throws
  // once the offset lands past the shorter content.
  void _setMarkdown(String markdown) {
    _debounce?.cancel();
    _controller
      ..document = markdownToQuillDocument(markdown)
      ..updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
  }

  /// Pastes markdown from the clipboard as formatted content.
  ///
  /// Quill's own `pasteMarkdown()` only fires for a markdown *file* on the
  /// clipboard, so copying markdown as text lands as literal characters. This
  /// converts it through the same boundary the editor loads drafts with, which
  /// also keeps tables and `$$math$$` intact.
  ///
  /// Returns false for anything that doesn't look like markdown so Quill's
  /// default plain-text paste still runs.
  Future<bool> _onClipboardPaste() async {
    final selection = _controller.selection;
    if (!selection.isValid) {
      return false;
    }

    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text == null || text.isEmpty) {
      return false;
    }

    final delta = markdownPasteToDelta(text);
    if (delta == null) {
      return false;
    }

    _controller.replaceText(
      selection.start,
      selection.end - selection.start,
      delta,
      TextSelection.collapsed(offset: selection.end),
    );
    return true;
  }

  /// Exports the article as a PDF and hands it to the system share sheet.
  ///
  /// Converts the *markdown*, not the live Delta: markdown is what actually
  /// publishes, so the PDF matches the article a reader gets rather than the
  /// editor's in-memory state. It also means images survive — htmltopdfwidgets
  /// fetches and embeds them, which a Delta-based converter would skip.
  Future<void> _exportPdf() async {
    final title = widget.titleController.text.trim();
    // Read off context before the awaits below, not after.
    final errorMessage = context.t.errorSendingEvent;
    // Generating and fetching images takes long enough to need feedback.
    final cancel = BotToastUtils.showLoading();

    try {
      final markdown = quillDocumentToMarkdown(_controller.document);

      final widgets = await pw.HTMLToPdf().convertMarkdown(
        pdfExportMarkdown(markdown),
        // GitHub-flavored so tables and strikethrough render, matching how the
        // article itself is parsed.
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );

      final pdf = pw.Document()
        ..addPage(
          pw.MultiPage(
            pageFormat: pw.PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (_) => [
              if (title.isNotEmpty) ...[
                pw.Header(level: 0, text: title),
                pw.SizedBox(height: 12),
              ],
              ...widgets,
            ],
          ),
        );

      final dir = await getTemporaryDirectory();
      // Sanitised: the title becomes a filename, and '/' would fork a path.
      final safeTitle =
          title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final file = File(
        '${dir.path}/${safeTitle.isEmpty ? 'article' : safeTitle}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await shareContent(
        files: [XFile(file.path)],
        subject: title.isEmpty ? null : title,
      );
    } catch (e) {
      lg.i(e);
      BotToastUtils.showError(errorMessage);
    } finally {
      cancel();
    }
  }

  Future<void> _deleteDraft() async {
    // _setMarkdown cancels the pending debounce, so no stale setContentText
    // lands after the draft is deleted.
    _setMarkdown('');
    widget.onDeleteDraft();
  }

  // Inserts raw markdown at the caret, for the constructs Quill has no native
  // format for: math, images and the horizontal rule. They survive the Delta
  // round trip as plain text, so they publish correctly even though the editor
  // shows them as source.
  void _insertRaw(String markdown, {bool ownLine = true}) {
    final index = _controller.selection.baseOffset.clamp(
      0,
      _controller.document.length - 1,
    );
    final text = ownLine ? '\n$markdown\n' : markdown;
    _controller.replaceText(
      index,
      0,
      text,
      TextSelection.collapsed(offset: index + text.length),
    );
  }

  /// A real embed, not the raw text '---', for the same reason as the image
  /// insert: as text it round-trips back through markdown into a `divider`
  /// embed on the next draft open, and the two paths must agree.
  void _insertSeparator() {
    final index = _controller.selection.baseOffset.clamp(
      0,
      _controller.document.length - 1,
    );
    // replaceText, not document.insert: the button fires with the cursor live,
    // and document.insert leaves the controller's selection at a stale offset
    // that throws RangeError on the next keystroke.
    _controller.replaceText(
      index,
      0,
      const BlockEmbed('divider', 'hr'),
      TextSelection.collapsed(offset: index + 1),
    );
  }

  Future<void> _insertImage() async {
    await showAppModalSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => ImageSelector(
        onTap: (link, {imeta}) {
          // A real embed, not raw text: inserting '![](url)' as characters gets
          // auto-linked and escaped into '![]([https://x\.com...](...))'.
          final index = _controller.selection.baseOffset.clamp(
            0,
            _controller.document.length - 1,
          );
          _controller.document.insert(index, BlockEmbed.image(link));
          // Preserve the imeta association the classic editor tracks, so
          // published events keep their image metadata tags.
          if (imeta != null) {
            widget.cubit.addImeta(imeta);
          }
        },
      ),
    );
  }

  Future<void> _insertSmartWidget() async {
    await showAppModalSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => SmartWidgetSelection(
        onWidgetAdded: (sw) {
          _insertRaw(sw.getScheme());
          YNavigator.pop(sheetContext);
        },
      ),
    );
  }

  /// Tags a user picked from the search sheet.
  ///
  /// An embed, not the raw `nostr:npub…` text, so the editor shows the avatar
  /// and name. It serialises back to the NIP-27 form the note composer writes
  /// and the reader resolves.
  Future<void> _insertMention() async {
    await showAppModalSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => UserToZap(
        onUserSelected: (user) {
          final index = _controller.selection.baseOffset.clamp(
            0,
            _controller.document.length - 1,
          );
          _controller.replaceText(
            index,
            0,
            BlockEmbed(kMentionEmbedType, Nip19.encodePubkey(user.pubkey)),
            TextSelection.collapsed(offset: index + 1),
          );
          YNavigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _insertMath() async {
    final latex = await showMathEquationSheet(context);

    if (latex != null && latex.isNotEmpty) {
      // An embed, not raw text, so the equation renders live in the editor.
      // The markdown spelling lives in latexToMarkdown() — the reader only
      // matches the backtick-wrapped form, which bare '$$..$$' is not.
      final index = _controller.selection.baseOffset.clamp(
        0,
        _controller.document.length - 1,
      );
      _controller.replaceText(
        index,
        0,
        BlockEmbed(kLatexEmbedType, latex),
        TextSelection.collapsed(offset: index + 1),
      );
    }
  }

  /// Inserts a table, defaulting to 2x2 with an empty header.
  Future<void> _insertTable() async {
    final data = await showTableSheet(context);
    if (data == null || data.isEmpty) {
      return;
    }
    final index = _controller.selection.baseOffset.clamp(
      0,
      _controller.document.length - 1,
    );
    _controller.replaceText(
      index,
      0,
      BlockEmbed(EmbeddableTable.tableType, data),
      TextSelection.collapsed(offset: index + 1),
    );
  }

  /// Opens the equation or table editor when a tap lands on that embed.
  ///
  /// Routed through the editor's own tap callback rather than a GestureDetector
  /// inside the embed builder: Quill's editor claims taps to place the caret,
  /// so a child recognizer can lose the gesture arena and never fire.
  bool _onEditorTapUp(
    TapUpDetails details,
    TextPosition Function(Offset offset) getPosition,
  ) {
    final offset = getPosition(details.globalPosition).offset;
    final leaf = _controller.document.querySegmentLeafNode(offset).leaf;
    if (leaf is! Embed) {
      return false;
    }
    switch (leaf.value.type) {
      case kLatexEmbedType:
        _editMath(leaf.value.data.toString(), leaf.documentOffset);
      case EmbeddableTable.tableType:
        _editTable(leaf.value.data.toString(), leaf.documentOffset);
      default:
        return false;
    }
    // Consume the tap so the caret doesn't also move into the embed.
    return true;
  }

  /// Reopens the table sheet for an existing embed and swaps it in place.
  ///
  /// The offset guard is the same one [_editMath] needs, for the same reason:
  /// the sheet is awaited, so a debounced autosave or draft reload can rebuild
  /// the document underneath it and leave the offset pointing at prose.
  Future<void> _editTable(String data, int offset) async {
    final updated = await showTableSheet(context, initial: data);
    if (updated == null || updated == data) {
      return;
    }
    if (offset < 0 || offset >= _controller.document.length) {
      return;
    }
    final leaf = _controller.document.querySegmentLeafNode(offset).leaf;
    if (leaf is! Embed || leaf.value.type != EmbeddableTable.tableType) {
      return;
    }

    // The sheet returns an empty string for its Delete action: replacing the
    // embed with nothing removes the table.
    _controller.replaceText(
      offset,
      1,
      updated.isEmpty ? '' : BlockEmbed(EmbeddableTable.tableType, updated),
      TextSelection.collapsed(offset: offset + (updated.isEmpty ? 0 : 1)),
    );
  }

  /// Reopens the equation sheet for an existing embed and swaps it in place.
  Future<void> _editMath(String latex, int offset) async {
    final updated = await showMathEquationSheet(context, initial: latex);
    if (updated == null || updated == latex) {
      return;
    }

    // The offset was captured when the embed was tapped, and the sheet is
    // awaited: a debounced autosave or a draft reload can rebuild the document
    // in the meantime. An in-range check is not enough — after a rebuild the
    // offset still lands somewhere, just not on this equation, and writing
    // there would eat a character of the user's prose. Confirm the leaf is
    // still a latex embed before replacing it.
    if (offset < 0 || offset >= _controller.document.length) {
      return;
    }
    final leaf = _controller.document.querySegmentLeafNode(offset).leaf;
    if (leaf is! Embed || leaf.value.type != kLatexEmbedType) {
      return;
    }

    _controller.replaceText(
      offset,
      1,
      BlockEmbed(kLatexEmbedType, updated),
      TextSelection.collapsed(offset: offset + 1),
    );
  }

  Widget _toolbarSurface(Widget child) {
    final theme = Theme.of(context);
    return isFluid()
        ? FluidBlurContainer(
            borderRadius: kDefaultPadding / 2,
            blur: false,
            child: child,
          )
        : Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border.all(color: theme.dividerColor, width: 0.5),
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            child: child,
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteArticleCubit, WriteArticleState>(
      listenWhen: (previous, current) =>
          previous.tryToLoad != current.tryToLoad,
      // The stored draft loads asynchronously, so it can land after initState
      // built the document. Rebuild it when that happens.
      listener: (context, state) => _setMarkdown(state.content),
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                children: [
                  TextFormField(
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
                  Expanded(
                    child: QuillEditor.basic(
                      controller: _controller,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                      config: QuillEditorConfig(
                        placeholder: context.t.whatsOnYourMind,
                        embedBuilders: const [
                          QuillImageEmbedBuilder(),
                          QuillDividerEmbedBuilder(),
                          QuillLatexEmbedBuilder(),
                          QuillMentionEmbedBuilder(),
                          QuillTableEmbedBuilder(),
                        ],
                        // Tapping an equation reopens it for editing.
                        onTapUp: _onEditorTapUp,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kDefaultPadding / 1.5,
                          vertical: kDefaultPadding / 2,
                        ),
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            theme.textTheme.bodyLarge!,
                            HorizontalSpacing.zero,
                            VerticalSpacing.zero,
                            VerticalSpacing.zero,
                            null,
                          ),
                          // All six levels, on the app's own scale: Quill only
                          // styles h1-h3 by default and leaves h4-h6 at its
                          // built-in sizes, which don't match the theme.
                          h1: _headerStyle(theme, FontSizes.headlineLarge),
                          h2: _headerStyle(theme, FontSizes.headlineMedium),
                          h3: _headerStyle(theme, FontSizes.headlineSmall),
                          h4: _headerStyle(theme, FontSizes.titleLarge),
                          h5: _headerStyle(theme, FontSizes.titleMedium),
                          h6: _headerStyle(theme, FontSizes.titleSmall),
                          placeHolder: DefaultTextBlockStyle(
                            theme.textTheme.bodyLarge!
                                .copyWith(color: theme.hintColor),
                            HorizontalSpacing.zero,
                            VerticalSpacing.zero,
                            VerticalSpacing.zero,
                            null,
                          ),
                          inlineCode: _inlineCodeStyle(theme),
                          code: _codeBlockStyle(theme),
                        ),
                        onLaunchUrl: (url) => openWebPage(url: url),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quill's own toolbar: this is what makes it a WYSIWYG editor rather
          // than a styled text box — the user formats via buttons, never by
          // typing markdown syntax.

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: _toolbarSurface(
              ClipRRect(
                borderRadius:
                    BorderRadiusGeometry.circular(kDefaultPadding / 2),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: QuillSimpleToolbar(
                          controller: _controller,
                          // Everything hidden below has no markdown equivalent,
                          // so it would be silently dropped on save — a user
                          // colouring text would watch it vanish on reload.
                          // Underline is hidden for the same reason: Quill emits
                          // <u>, which would leak raw HTML into the article.

                          config: QuillSimpleToolbarConfig(
                            // Every visible button gets a Lucide icon, matching
                            // the rest of the app. The four custom buttons below
                            // already use them.
                            buttonOptions: QuillSimpleToolbarButtonOptions(
                              // base is shared by every button, so the active
                              // state is defined once here rather than per icon.
                              base: QuillToolbarBaseButtonOptions(
                                iconTheme: QuillIconTheme(
                                  iconButtonSelectedData: IconButtonData(
                                    color: Colors.white,
                                    style: IconButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              undoHistory:
                                  const QuillToolbarHistoryButtonOptions(
                                iconData: LucideIcons.undo2,
                              ),
                              redoHistory:
                                  const QuillToolbarHistoryButtonOptions(
                                iconData: LucideIcons.redo2,
                              ),
                              bold: const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.bold,
                              ),
                              italic:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.italic,
                              ),
                              strikeThrough:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.strikethrough,
                              ),
                              inlineCode:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.code,
                              ),
                              listNumbers:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.listOrdered,
                              ),
                              listBullets:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.list,
                              ),
                              toggleCheckList:
                                  const QuillToolbarToggleCheckListButtonOptions(
                                iconData: LucideIcons.listChecks,
                              ),
                              codeBlock:
                                  const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.squareCode,
                              ),
                              quote: const QuillToolbarToggleStyleButtonOptions(
                                iconData: LucideIcons.quote,
                              ),
                              linkStyle:
                                  const QuillToolbarLinkStyleButtonOptions(
                                iconData: LucideIcons.link,
                              ),
                            ),

                            // Replaced by _HeadingPicker, which shows icons and
                            // expands in place instead of opening a vertical
                            // menu of text labels.
                            showHeaderStyle: false,
                            multiRowsDisplay: false,
                            showFontFamily: false,
                            showFontSize: false,
                            showBackgroundColorButton: false,
                            showColorButton: false,
                            showSubscript: false,
                            showSuperscript: false,
                            showSearchButton: false,
                            showClearFormat: false,
                            showIndent: false,
                            showUnderLineButton: false,
                            color: kTransparent,
                            // The classic editor's remaining actions, which Quill
                            // has no native format for.
                            customButtons: [
                              QuillToolbarCustomButtonOptions(
                                childBuilder: (dynamic _, dynamic __) =>
                                    _HeadingPicker(
                                  controller: _controller,
                                  onFormatted: _flushToCubit,
                                ),
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.atSign, size: 25),
                                tooltip: context.t.tagUser.capitalizeFirst(),
                                onPressed: _insertMention,
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.image, size: 25),
                                tooltip: context.t.imageUrl,
                                onPressed: _insertImage,
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.sigma, size: 25),
                                tooltip: context.t.mathEquation,
                                onPressed: _insertMath,
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.table, size: 25),
                                tooltip: context.t.table.capitalizeFirst(),
                                onPressed: _insertTable,
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.minus, size: 25),
                                tooltip: context.t.separator.capitalizeFirst(),
                                onPressed: _insertSeparator,
                              ),
                              QuillToolbarCustomButtonOptions(
                                icon: const Icon(LucideIcons.layoutGrid,
                                    size: 25),
                                tooltip:
                                    context.t.smartWidget.capitalizeFirst(),
                                onPressed: _insertSmartWidget,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        indent: kDefaultPadding / 2,
                        endIndent: kDefaultPadding / 2,
                      ),
                      CustomIconButton(
                        onClicked: _exportPdf,
                        icon: LucideIcons.fileDown,
                        size: 25,
                        backgroundColor: kTransparent,
                        borderRadius: kDefaultPadding / 2,
                      ),
                      CustomIconButton(
                        onClicked: () =>
                            confirmDeleteDraft(context, _deleteDraft),
                        icon: FeatureIcons.trash,
                        size: 25,
                        backgroundColor: kTransparent,
                        iconColor: Colors.red,
                        borderRadius: kDefaultPadding / 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding / 2,
              kDefaultPadding / 4,
              kDefaultPadding / 2,
              kDefaultPadding / 2,
            ),
            child: AiButtonRow(
              onSecondReader: () => showSecondReader(
                context,
                quillDocumentToMarkdown(_controller.document),
                onFixWithAi: (prefill) => showArticleAskAi(
                  context,
                  _askAiCubit,
                  prefill: prefill,
                ),
              ),
              onAskAi: () => openAskAi(context, _askAiCubit),
            ),
          ),
        ],
      ),
    );
  }
}

// Owns its own TextEditingController so the widget lifecycle disposes it. Doing
// that by hand around showDialog throws "A TextEditingController was used after
// being disposed", because the dialog's exit animation keeps rebuilding the
// TextField after the future has already completed.
/// Prompts for a LaTeX equation, live-previewing it as the user types.
///
/// Returns the raw LaTeX, or null if dismissed. Pass [initial] to edit an
/// existing equation rather than insert a new one.
Future<String?> showMathEquationSheet(
  BuildContext context, {
  String? initial,
}) =>
    showAppModalSheet<String>(
      context: context,
      backgroundColor: kTransparent,
      builder: (_) => _MathEquationSheet(initial: initial),
    );

class _MathEquationSheet extends StatefulWidget {
  const _MathEquationSheet({this.initial});

  final String? initial;

  @override
  State<_MathEquationSheet> createState() => _MathEquationSheetState();
}

// Stays a StatefulWidget deliberately: creating the controller in the caller
// and disposing it after the future completes still throws "used after being
// disposed", because the sheet's exit animation rebuilds the field.
class _MathEquationSheetState extends State<_MathEquationSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final latex = _controller.text.trim();
    if (latex.isNotEmpty) {
      Navigator.of(context).pop(latex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initial != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ModalSheetContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    context.t.mathEquation.capitalizeFirst(),
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
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 3,
                    minLines: 1,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: r'E = mc^2',
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    // Live preview needs a rebuild per keystroke.
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  _preview(theme),
                  const SizedBox(height: kDefaultPadding),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed:
                          _controller.text.trim().isEmpty ? null : _submit,
                      child: Text(
                        isEditing
                            ? context.t.save.capitalizeFirst()
                            : context.t.add.capitalizeFirst(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders what the equation will look like, so the writer doesn't have to
  /// insert it to find out the LaTeX was wrong.
  Widget _preview(ThemeData theme) {
    final latex = _controller.text.trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.all(kDefaultPadding / 1.5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      alignment: Alignment.center,
      child: latex.isEmpty
          ? Text(
              context.t.preview.capitalizeFirst(),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            )
          : Math.tex(
              latex,
              mathStyle: MathStyle.text,
              textStyle: TextStyle(
                fontSize: 16,
                color: theme.primaryColorDark,
              ),
              onErrorFallback: (_) => Text(
                context.t.invalidEquation.capitalizeFirst(),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
    );
  }
}

/// Prompts for a table's cells and size.
///
/// Returns the pipe rows an `x-embed-table` embed stores — which is also the
/// markdown that publishes — or null if dismissed. Returns an empty string from
/// the Delete action, which the caller treats as "remove this table".
/// Pass [initial] to edit an existing table rather than insert a new one.
Future<String?> showTableSheet(
  BuildContext context, {
  String? initial,
}) =>
    showAppModalSheet<String>(
      context: context,
      backgroundColor: kTransparent,
      builder: (_) => _TableSheet(initial: initial),
    );

class _TableSheet extends StatefulWidget {
  const _TableSheet({this.initial});

  final String? initial;

  @override
  State<_TableSheet> createState() => _TableSheetState();
}

// Stateful for the same reason as _MathEquationSheet: the sheet's exit
// animation keeps rebuilding the fields after the future completes, so the
// controllers have to outlive the caller's await.
class _TableSheetState extends State<_TableSheet> {
  /// The controllers are the source of truth, not a parallel List<String>.
  /// Rebuilding fields from a value list would show stale text after a row is
  /// removed, since a TextFormField's initialValue doesn't re-apply on rebuild.
  late final List<List<TextEditingController>> _rows = _initialRows();

  List<List<TextEditingController>> _initialRows() {
    final parsed = widget.initial == null || widget.initial!.isEmpty
        ? const <List<String>>[]
        : parseTableRows(widget.initial!);
    // A fresh table starts 2x2: a header row and one body row.
    final grid = parsed.isEmpty
        ? const [
            ['', ''],
            ['', ''],
          ]
        : parsed;
    return [
      for (final row in grid)
        [for (final cell in row) TextEditingController(text: cell)],
    ];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  int get _columnCount => _rows.isEmpty ? 0 : _rows.first.length;

  void _addRow() => setState(
        () => _rows.add([
          for (var c = 0; c < _columnCount; c++) TextEditingController(),
        ]),
      );

  void _removeRow() {
    if (_rows.length <= 1) {
      return;
    }
    setState(() {
      for (final controller in _rows.removeLast()) {
        controller.dispose();
      }
    });
  }

  // Columns are added to every row at once: parseTableRows tolerates a ragged
  // grid when rendering, but ragged markdown doesn't publish as a table.
  void _addColumn() => setState(() {
        for (final row in _rows) {
          row.add(TextEditingController());
        }
      });

  void _removeColumn() {
    if (_columnCount <= 1) {
      return;
    }
    setState(() {
      for (final row in _rows) {
        row.removeLast().dispose();
      }
    });
  }

  void _submit() => Navigator.of(context).pop(
        buildTableMarkdown([
          for (final row in _rows) [for (final c in row) c.text],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initial != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        // isScrollControlled lets the sheet grow to the full screen, so without
        // a cap a tall grid pushes the buttons past the bottom edge instead of
        // making the grid scroll. Leave room for the keyboard, which the
        // viewInsets padding above has already shifted the sheet by.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8 -
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ModalSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      context.t.table.capitalizeFirst(),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding,
                  kDefaultPadding / 2,
                ),
                child: _sizeControls(theme),
              ),
              // Only the grid scrolls. The steppers above and the buttons below
              // stay put, so adding rows can't push the Save button off-screen.
              Flexible(
                child: ScrollShadow(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: kDefaultPadding,
                    ),
                    child: ScrollShadow(
                      child: SingleChildScrollView(
                        // The grid can outgrow the sheet in either direction.
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            for (var r = 0; r < _rows.length; r++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: kDefaultPadding / 2,
                                ),
                                child: Row(
                                  children: [
                                    for (var c = 0; c < _rows[r].length; c++)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: kDefaultPadding / 2,
                                        ),
                                        child: SizedBox(
                                          width: 30.w,
                                          child: TextField(
                                            controller: _rows[r][c],
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: r == 0
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              filled: true,
                                              fillColor: theme.cardColor,
                                              hintText: r == 0
                                                  ? context.t.title
                                                      .capitalizeFirst()
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kDefaultPadding,
                  0,
                  kDefaultPadding,
                  kDefaultPadding,
                ),
                child: Row(
                  children: [
                    // Only when editing: the row steppers stop at one row, so
                    // removing the table is the one thing they can't do. An empty
                    // result is the caller's cue to delete it.
                    if (isEditing) ...[
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(''),
                        child: Text(context.t.delete.capitalizeFirst()),
                      ),
                      const SizedBox(width: kDefaultPadding / 2),
                    ],
                    Expanded(
                      child: TextButton(
                        onPressed: _submit,
                        child: Text(
                          isEditing
                              ? context.t.save.capitalizeFirst()
                              : context.t.add.capitalizeFirst(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Row and column steppers. The first row is the header and the grid must
  /// stay rectangular, so both counts stop at 1 rather than 0.
  Widget _sizeControls(ThemeData theme) {
    Widget stepper(
            String label, int count, VoidCallback? remove, VoidCallback add) =>
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Row(
                children: [
                  AppIconButton(
                    icon: LucideIcons.minus,
                    onClicked: remove,
                    iconSize: 14,
                    backgroundColor: theme.cardColor,
                    size: 28,
                    buttonRadius: 14,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  AppIconButton(
                    icon: LucideIcons.plus,
                    onClicked: add,
                    iconSize: 14,
                    backgroundColor: theme.cardColor,
                    size: 28,
                    buttonRadius: 14,
                  ),
                ],
              ),
            ],
          ),
        );

    return Row(
      children: [
        stepper(
          context.t.rows.capitalizeFirst(),
          _rows.length,
          _rows.length > 1 ? _removeRow : null,
          _addRow,
        ),
        const SizedBox(width: kDefaultPadding),
        stepper(
          context.t.columns.capitalizeFirst(),
          _columnCount,
          _columnCount > 1 ? _removeColumn : null,
          _addColumn,
        ),
      ],
    );
  }
}

// ── AppFlowy editor section ───────────────────────────────────────────────────
