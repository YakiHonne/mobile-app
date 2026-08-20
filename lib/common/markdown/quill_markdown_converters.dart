import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';
import 'package:sizer/sizer.dart';

import '../../utils/constants.dart';
import '../../views/widgets/common_thumbnail.dart';
import '../../views/widgets/content_renderer/content_renderer.dart';
import '../../views/widgets/data_providers.dart';
import '../functions/functions_set.dart';

/// Markdown <-> Quill Delta conversion for the premium article editor.
///
/// Articles are stored as markdown (Nostr long-form, kind 30023) while Quill
/// edits a Delta document, so every load converts in and every save converts
/// back. The configuration here is what keeps that round trip lossless enough
/// to publish:
///
/// * [EmbeddableTableSyntax] + the table embed handler keep markdown tables
///   intact. Without them a table degrades to its concatenated cell text.
/// * [DeltaToMarkdown.escapeSpecialCharactersRelaxed] stops ordinary prose from
///   coming back littered with backslashes (`text.` -> `text\.`).
/// * `encodeHtml: false` leaves raw HTML in articles alone instead of
///   entity-encoding it.
///
/// Known lossy edges, both verified in test/quill_markdown_test.dart:
/// * Image alt text is dropped — markdown_quill keeps only `src` when parsing
///   `img`, so there is nothing left to write back.
/// * `*italic*` normalises to `_italic_` (equivalent markdown, renders the same).
/// Delta embed type for a LaTeX equation.
const String kLatexEmbedType = 'latex';

/// Wraps LaTeX the way the rest of the app writes it.
///
/// The reader's [LatexSyntax] only matches *backtick-wrapped* math
/// (`` `$$…$$` ``), and the classic editor writes that form too
/// (format_markdown.dart). Bare `$$…$$` renders as literal dollar signs, so
/// this is the single spelling both editors must emit.
String latexToMarkdown(String latex) => '`\$\$$latex\$\$`';

/// Matches the `` `$$…$$` `` form on its own line and hands it to Quill as a
/// [kLatexEmbedType] embed.
///
/// A block syntax rather than an inline one because `` `…` `` is ordinary
/// inline code in markdown: left to the default parser it arrives as a `code`
/// attribute on a text run, which no [MarkdownToDelta.customElementToEmbeddable]
/// entry can intercept.
class _LatexBlockSyntax extends md.BlockSyntax {
  const _LatexBlockSyntax();

  @override
  RegExp get pattern => RegExp(r'^\s*`\$\$([\s\S]*?)\$\$`\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    parser.advance();
    // The equation rides in an attribute, not as text: markdown_quill hands the
    // convertor `element.attributes` only (markdown_to_delta.dart:457), so
    // textContent would be unreachable. Same trick EmbeddableTable uses.
    return md.Element.empty(kLatexEmbedType)
      ..attributes['data'] = match.group(1)!.trim();
  }
}

/// Delta embed type for a `nostr:npub…` user mention.
const String kMentionEmbedType = 'mention';

/// The NIP-27 spelling of a mention — the same form the note composer writes
/// and the reader resolves.
String mentionToMarkdown(String npub) => 'nostr:$npub';

/// Matches `nostr:npub…` / `nostr:nprofile…` anywhere in a line.
///
/// Inline rather than a block syntax (unlike [_LatexBlockSyntax]) because
/// mentions belong mid-sentence. Bech32 is alphanumeric, so the character class
/// stops naturally at punctuation and whitespace.
class _MentionInlineSyntax extends md.InlineSyntax {
  _MentionInlineSyntax() : super(r'nostr:((?:npub|nprofile)1[a-z0-9]+)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element.empty(kMentionEmbedType)..attributes['data'] = match.group(1)!,
    );
    return true;
  }
}

final _markdownToDelta = MarkdownToDelta(
  markdownDocument: md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: const [EmbeddableTableSyntax(), _LatexBlockSyntax()],
    inlineSyntaxes: [_MentionInlineSyntax()],
  ),
  customElementToEmbeddable: {
    EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
    kLatexEmbedType: (attributes) =>
        BlockEmbed(kLatexEmbedType, attributes['data'] ?? ''),
    kMentionEmbedType: (attributes) =>
        BlockEmbed(kMentionEmbedType, attributes['data'] ?? ''),
  },
);

final _deltaToMarkdown = DeltaToMarkdown(
  customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
  customEmbedHandlers: {
    EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
    kLatexEmbedType: (embed, out) =>
        out.writeln(latexToMarkdown(embed.value.data.toString())),
    // write, not writeln: a mention sits inside a sentence.
    kMentionEmbedType: (embed, out) =>
        out.write(mentionToMarkdown(embed.value.data.toString())),
  },
);

/// Builds a Quill [Document] from markdown, falling back to an empty document
/// so a malformed draft opens the editor instead of crashing it.
Document markdownToQuillDocument(String markdown) {
  if (markdown.trim().isEmpty) {
    return Document();
  }
  try {
    return Document.fromDelta(_markdownToDelta.convert(markdown));
  } catch (_) {
    // ponytail: a draft that won't parse becomes plain text rather than an
    // error screen — the user keeps their words and can fix the formatting.
    return Document()..insert(0, markdown);
  }
}

/// Serialises a Quill [Document] back to markdown for autosave and publishing.
String quillDocumentToMarkdown(Document document) =>
    _deltaToMarkdown.convert(document.toDelta()).trimRight();

/// Rewrites the math delimiters the rest of the world uses into the app's own
/// `` `$$…$$` `` form, each on its own line so [_LatexBlockSyntax] can see it.
///
/// Nothing outside Yakihonne writes the backtick-wrapped form: LaTeX sources,
/// ChatGPT and Wikipedia all emit `$$…$$`, `$…$`, `\[…\]` or `\(…\)`. Without
/// this, pasted maths misses both the [looksLikeMarkdown] sniff and the block
/// syntax, and lands as literal dollar signs.
///
/// Runs on paste only — a stored draft is already in the app's form, and
/// rewriting on load would reflow equations the writer placed inline.
String normaliseMathDelimiters(String text) {
  // Code fences are left alone: `$$` inside one is sample text, not maths.
  final fences = RegExp(r'^\s*```[\s\S]*?^\s*```', multiLine: true);
  final segments = <String>[];
  var cursor = 0;
  for (final fence in fences.allMatches(text)) {
    segments.add(_normaliseMathSegment(text.substring(cursor, fence.start)));
    segments.add(fence.group(0)!);
    cursor = fence.end;
  }
  segments.add(_normaliseMathSegment(text.substring(cursor)));
  return segments.join();
}

/// The delimiter pairs, longest-first so `$$` wins over `$`.
///
/// Each skips the app's own form by requiring the delimiter *not* to be
/// backtick-hugged — otherwise `` `$$x$$` `` would be unwrapped and rewrapped,
/// and the `$` pattern would then chew the halves of a `$$` pair.
final _mathDelimiters = [
  RegExp(r'\\\[([\s\S]+?)\\\]'), // \[ … \]
  RegExp(r'\\\(([\s\S]+?)\\\)'), // \( … \)
  RegExp(r'(?<![\\`])\$\$([\s\S]+?)(?<!\\)\$\$(?!`)'), // $$ … $$
  RegExp(r'(?<![\\$`])\$([^\$\n]+?)(?<!\\)\$(?![\$`])'), // $ … $
];

String _normaliseMathSegment(String segment) {
  var out = segment;
  for (var i = 0; i < _mathDelimiters.length; i++) {
    // The last pattern is bare `$…$`, the only one that collides with prose.
    final isSingleDollar = i == _mathDelimiters.length - 1;
    out = out.replaceAllMapped(_mathDelimiters[i], (m) {
      final equation = m.group(1)!.trim();
      if (equation.isEmpty ||
          (isSingleDollar && !_looksLikeEquation(equation))) {
        return m.group(0)!;
      }
      // Own line: _LatexBlockSyntax matches a whole line and nothing else.
      return '\n\n${latexToMarkdown(equation)}\n\n';
    });
  }
  return out;
}

/// Whether the text between two bare `$` is maths rather than currency.
///
/// `$…$` is the one ambiguous delimiter: "costs 5$ or 10$ tops" has a perfectly
/// good `$ or 10$` inside it. Requiring a LaTeX command, an operator or a
/// sub/superscript keeps prose out; anything richer would need a TeX parser to
/// decide, which is far more than a paste path deserves.
///
/// ponytail: heuristic, not a parser — a writer whose equation is a bare
/// variable (`$x$`) types it through the equation button instead.
bool _looksLikeEquation(String equation) =>
    RegExp(r'\\[a-zA-Z]+|[=^_{}]|[+\-*/<>]\s*\S').hasMatch(equation);

/// Converts markdown to a Delta for pasting at the caret.
///
/// Returns null when the text carries no markdown syntax, so ordinary prose and
/// bare URLs paste unchanged instead of being run through the parser — which
/// would reflow paragraphs and escape punctuation for no gain.
Delta? markdownPasteToDelta(String text) {
  final normalised = normaliseMathDelimiters(text);
  if (!looksLikeMarkdown(normalised)) {
    return null;
  }
  try {
    return _markdownToDelta.convert(normalised);
  } catch (_) {
    // Unparseable: let the caller fall back to Quill's plain-text paste.
    return null;
  }
}

/// Rewrites the app's own markdown extensions into plain markdown for export.
///
/// A generic parser has no idea what `` `$$…$$` `` or `nostr:npub…` mean, so
/// without this the PDF shows the raw source. Equations become their LaTeX in
/// inline code, and mentions become the npub truncated to something readable —
/// the reader app resolves names from relays, which an export can't do offline.
String pdfExportMarkdown(String markdown) {
  return markdown
      .replaceAllMapped(
    RegExp(r'`\$\$([\s\S]*?)\$\$`'),
    (m) => '`${m.group(1)!.trim()}`',
  )
      .replaceAllMapped(
    RegExp(r'nostr:((?:npub|nprofile)1[a-z0-9]+)'),
    (m) {
      final id = m.group(1)!;
      return '@${id.length > 16 ? '${id.substring(0, 16)}…' : id}';
    },
  );
}

/// Whether [text] carries enough markdown syntax to be worth parsing.
///
/// Deliberately conservative — a false positive reformats text the user pasted
/// verbatim, which is worse than a false negative leaving markdown unformatted.
///
/// Callers that accept foreign markdown should run [normaliseMathDelimiters]
/// first: this only recognises the app's own `` `$$…$$` `` spelling of maths.
bool looksLikeMarkdown(String text) {
  const patterns = [
    r'^#{1,6}\s', // headings
    r'^\s*[-*+]\s', // bullet lists
    r'^\s*\d+\.\s', // ordered lists
    r'^\s*>\s', // blockquotes
    r'^\s*```', // code fences
    r'^\s*\|.*\|', // tables
    r'^\s*(---|\*\*\*|___)\s*$', // horizontal rules
    r'\*\*[^*\n]+\*\*', // bold
    r'~~[^~\n]+~~', // strikethrough
    r'\[[^\]\n]+\]\([^)\n]+\)', // links
    r'!\[[^\]\n]*\]\([^)\n]+\)', // images
    r'`\$\$[\s\S]+?\$\$`', // the app's latex form
  ];

  return patterns.any(
    (p) => RegExp(p, multiLine: true).hasMatch(text),
  );
}

/// Renders image embeds inside the editor.
///
/// Required: Quill throws `UnimplementedError: Embeddable type "image" is not
/// supported by supplied embed builders` the moment an image is inserted or a
/// draft containing one is opened. Images must be inserted as
/// [BlockEmbed.image] rather than as `![](url)` text, because Quill auto-links
/// a bare URL and the markdown escaper then mangles it.
/// Renders LaTeX equations live in the editor, so `$$…$$` shows as maths
/// rather than as its own source.
///
/// Uses flutter_math_fork — the same engine the reader's LatexNode already
/// uses — so what the writer sees matches what the published article renders.
/// Tapping an equation reopens it for editing — that is wired through the
/// editor's own `onTapUp` in article_content.dart, not a GestureDetector here,
/// because Quill claims taps to place the caret and a child recognizer can lose
/// the gesture arena.
class QuillLatexEmbedBuilder extends EmbedBuilder {
  const QuillLatexEmbedBuilder();

  @override
  String get key => kLatexEmbedType;

  @override
  String toPlainText(Embed node) => latexToMarkdown(node.value.data.toString());

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final theme = Theme.of(context);
    final latex = embedContext.node.value.data.toString();

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Math.tex(
          latex,
          mathStyle: MathStyle.text,
          onErrorFallback: (error) => Text(
            latexToMarkdown(latex),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

/// Renders a `nostr:npub…` mention as the user's avatar and name, so the writer
/// sees who they tagged instead of a bech32 string.
///
/// Uses [OptimizedMetadataContainer] — the same container the reader draws
/// mentions with — so the editor and the published article look identical.
class QuillMentionEmbedBuilder extends EmbedBuilder {
  const QuillMentionEmbedBuilder();

  @override
  String get key => kMentionEmbedType;

  /// Sits inside the line rather than claiming a block of its own — a mention
  /// belongs mid-sentence.
  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) =>
      mentionToMarkdown(node.value.data.toString());

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final npub = embedContext.node.value.data.toString();

    String? pubkey;
    try {
      pubkey = Nip19.decodePubkey(npub);
    } catch (_) {
      pubkey = null;
    }

    // An npub that won't decode still publishes fine, so show the raw text
    // rather than an error.
    if (pubkey == null) {
      return Text(
        mentionToMarkdown(npub),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, nip05) => OptimizedMetadataContainer(
        metadata: metadata,
        onOpen: () => openProfileFastAccess(context: context, pubkey: pubkey!),
      ),
    );
  }
}

/// Renders `---` horizontal rules inside the editor.
///
/// Required for the same reason as [QuillImageEmbedBuilder]: markdown_quill
/// parses `---` into a `divider` [BlockEmbed], and an embed with no builder
/// throws `UnimplementedError`. The way back out already works — flutter_quill
/// ships the `divider` -> `---` handler in [DeltaToMarkdown].
class QuillDividerEmbedBuilder extends EmbedBuilder {
  const QuillDividerEmbedBuilder();

  // ponytail: inlined rather than imported — markdown_quill's `horizontalRuleType`
  // lives in an unexported src/utils.dart, and the value is part of the Delta
  // format both packages already agree on.
  @override
  String get key => 'divider';

  @override
  String toPlainText(Embed node) => '\n---\n';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) => Divider(
        height: kDefaultPadding * 1.5,
        color: Theme.of(context).dividerColor,
      );
}

class QuillImageEmbedBuilder extends EmbedBuilder {
  const QuillImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  /// Keeps the markdown source in the plain-text projection, so anything
  /// reading the document as text still sees the image.
  @override
  String toPlainText(Embed node) => '![](${node.value.data})';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: CommonThumbnail(
        image: embedContext.node.value.data.toString(),
        width: double.infinity,
        height: 25.h,
        fit: BoxFit.cover,
        isRound: true,
        radius: kDefaultPadding / 2,
      ),
    );
  }
}

/// Renders a markdown table inside the editor.
///
/// Required for the same reason as [QuillImageEmbedBuilder]: markdown_quill
/// parses a GFM table into an `x-embed-table` [BlockEmbed] whose data is the
/// raw pipe rows, and an embed with no builder throws `UnimplementedError`
/// when a draft containing one is opened or pasted. The way back out already
/// works — the `x-embed-table` -> markdown handler is registered on
/// [_deltaToMarkdown] above.
///
/// The pipe rows are parsed by hand rather than through the markdown package
/// so the editor shows exactly what will publish: the raw rows are already
/// markdown, and re-parsing them would re-apply the app's block syntaxes.
class QuillTableEmbedBuilder extends EmbedBuilder {
  const QuillTableEmbedBuilder();

  @override
  String get key => EmbeddableTable.tableType;

  @override
  String toPlainText(Embed node) => node.value.data.toString();

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final theme = Theme.of(context);
    final table = parseTableRows(embedContext.node.value.data.toString());

    final border = TableBorder(
      horizontalInside: BorderSide(color: theme.dividerColor, width: 0.5),
      verticalInside: BorderSide(color: theme.dividerColor, width: 0.5),
      top: BorderSide(color: theme.dividerColor, width: 0.5),
      bottom: BorderSide(color: theme.dividerColor, width: 0.5),
      left: BorderSide(color: theme.dividerColor, width: 0.5),
      right: BorderSide(color: theme.dividerColor, width: 0.5),
    );

    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.primaryColorDark,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      child: SingleChildScrollView(
        // A wide table must not force the whole editor to scroll; the table
        // itself scrolls horizontally instead.
        scrollDirection: Axis.horizontal,
        child: Table(
          border: border,
          defaultColumnWidth: const IntrinsicColumnWidth(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (var r = 0; r < table.length; r++)
              TableRow(
                decoration: r == 0
                    ? BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.06))
                    : null,
                children: [
                  for (final cell in table[r])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 1.5,
                        vertical: kDefaultPadding / 4,
                      ),
                      child: Text(
                        cell,
                        style:
                            r == 0 ? headerStyle : theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Splits the pipe rows stored in an `x-embed-table` embed into a grid of
/// cells, normalising ragged rows to the header's column count.
///
/// Cell content is left as-is: it is markdown, and the published article
/// parses it inline (bold, links, …). Rendering those here would mean
/// maintaining a second inline parser just for the editor's preview.
List<List<String>> parseTableRows(String data) {
  final lines =
      data.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  if (lines.isEmpty) {
    return const [];
  }

  final rows = <List<String>>[
    for (final line in lines)
      if (!_isDividerLine(line)) splitTableRow(line),
  ];
  if (rows.isEmpty) {
    return const [];
  }

  final columnCount = rows.first.length;
  for (final row in rows) {
    if (row.length < columnCount) {
      row.addAll(List.filled(columnCount - row.length, ''));
    } else if (row.length > columnCount) {
      row.removeRange(columnCount, row.length);
    }
  }
  return rows;
}

/// Splits one pipe row into its cells.
///
/// GFM rows are conventionally written with surrounding pipes, and a bare
/// `split('|')` on `| a | b |` yields a leading and trailing empty string —
/// two phantom columns. Drop them, but only when the row actually starts or
/// ends with a pipe, so a pipe-less row (`a | b`, also legal GFM) keeps both
/// of its cells.
List<String> splitTableRow(String line) {
  var row = line;
  if (row.startsWith('|')) {
    row = row.substring(1);
  }
  if (row.endsWith('|') && !row.endsWith(r'\|')) {
    row = row.substring(0, row.length - 1);
  }
  // Split on unescaped pipes only: '\|' is a literal pipe inside a cell.
  return row
      .split(RegExp(r'(?<!\\)\|'))
      .map((cell) => cell.trim().replaceAll(r'\|', '|'))
      .toList();
}

/// Builds the pipe rows an `x-embed-table` embed stores, from a grid of cells.
///
/// The stored data *is* the published markdown ([EmbeddableTable.toMdSyntax]
/// writes it out verbatim), so it has to be valid GFM: surrounding pipes, a
/// divider row under the header, and no raw pipe or newline inside a cell.
String buildTableMarkdown(List<List<String>> rows) {
  if (rows.isEmpty) {
    return '';
  }
  final columnCount = rows.first.length;

  String line(List<String> cells) => '| ${[
        for (var c = 0; c < columnCount; c++)
          (c < cells.length ? cells[c] : '')
              .replaceAll('|', r'\|')
              .replaceAll(RegExp(r'\s*\n\s*'), ' ')
              .trim(),
      ].join(' | ')} |';

  return [
    line(rows.first),
    '|${List.filled(columnCount, ' --- ').join('|')}|',
    for (final row in rows.skip(1)) line(row),
  ].join('\n');
}

/// The alignment row (`|---|:---:|---:|`) between header and body, which
/// carries no cell content.
bool _isDividerLine(String line) {
  final stripped = line
      .replaceAll('|', '')
      .replaceAll(':', '')
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .replaceAll('\t', '');
  return stripped.isEmpty && line.contains('-');
}
