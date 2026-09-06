import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/common/markdown/quill_markdown_converters.dart';

// Articles are stored as markdown but edited as a Quill document, so these
// guard the conversion the premium editor depends on. A regression here means
// published articles silently lose formatting.
void main() {
  String roundTrip(String markdown) =>
      quillDocumentToMarkdown(markdownToQuillDocument(markdown));

  group('round trip preserves', () {
    const lossless = {
      'bold': 'This is **bold** text.',
      'unordered list': '- one\n- two\n- three',
      'ordered list': '1. one\n2. two',
      'link': 'See [example](https://example.com) here.',
      'code fence': '```dart\nvoid main() {}\n```',
      'inline code': 'Use `code` here.',
      'blockquote': '> quoted text',
      'strikethrough': 'This is ~~gone~~.',
      // The two that disqualified other editors: tables need the embed syntax
      // and math must pass through untouched.
      'table': '|a|b|\n|-|-|\n|1|2|',
      // Backtick-wrapped: the reader's LatexSyntax only matches this form, so
      // it is the spelling that has to survive, not bare '$$..$$'.
      'block math': r'`$$E = mc^2$$`',
      // The classic editor wraps the *selection*, so mid-sentence math is
      // routine and existing drafts contain it.
      'inline math': r'A mass of `$$E=mc^2$$` here.',
      'paragraph breaks': 'First para.\n\nSecond para.\n\nThird para.',
      // Prose must not come back escaped (`text\.`), which is why the relaxed
      // content handler is configured.
      'prose punctuation': 'A sentence. Another one! And a third?',
    };

    lossless.forEach((name, markdown) {
      test(name, () => expect(roundTrip(markdown), markdown));
    });
  });

  group('known lossy edges', () {
    test('image survives but alt text is dropped', () {
      // markdown_quill keeps only `src` when parsing `img`, so alt is gone by
      // the time we serialise back. The URL is what matters for publishing.
      expect(
        roundTrip('![alt text](https://x.com/i.png)'),
        '![](https://x.com/i.png)',
      );
    });

    test('italic normalises to underscore form', () {
      // Equivalent markdown, renders identically.
      expect(roundTrip('This is *italic*.'), 'This is _italic_.');
    });

    test('dots in link text get backslash-escaped', () {
      // The relaxed handler still escapes '.' inside link labels. Renders the
      // same in every markdown viewer; the href is untouched.
      expect(
        roundTrip('Read [yakihonne.com](https://yakihonne.com).'),
        r'Read [yakihonne\.com](https://yakihonne.com).',
      );
    });

    test('blank lines between blocks shift', () {
      // Heading loses its trailing blank line; a table gains trailing ones.
      // Block structure is preserved, which is what rendering depends on.
      expect(roundTrip('# Title\n\n## Sub'), '# Title\n## Sub');
      expect(roundTrip('# Title\n\nBody text.'), '# Title\nBody text.');
      expect(roundTrip(roundTrip('# Title\n\n## Sub')), '# Title\n## Sub');
    });

    test('unused placeholder', () {
      // Cosmetic only: '# Title\n## Sub' parses to the same <h1>/<h2> as the
      // spaced form, and a second pass is stable so it never compounds.
      expect(roundTrip('# Title\n\n## Sub'), '# Title\n## Sub');
      expect(roundTrip('# Title\n\nBody text.'), '# Title\nBody text.');
      expect(roundTrip(roundTrip('# Title\n\n## Sub')), '# Title\n## Sub');
    });
  });

  group('document construction', () {
    test('empty markdown yields an empty document', () {
      expect(quillDocumentToMarkdown(markdownToQuillDocument('')), isEmpty);
      expect(
          quillDocumentToMarkdown(markdownToQuillDocument('   \n')), isEmpty);
    });

    test('a full article keeps every block and its content', () {
      const article = '# Yaki Release Notes\n\n'
          'We shipped **three** things this week.\n\n'
          '- Faster relays\n'
          '- Better search\n'
          '- A new editor\n\n'
          '> Feedback welcome.\n\n'
          '|feature|status|\n|-|-|\n|relays|done|\n\n'
          'Read more at [yakihonne.com](https://yakihonne.com).';
      final out = roundTrip(article);

      // Blank-line placement between blocks shifts (see lossy edges), so assert
      // on content rather than byte equality: nothing may be dropped.
      expect(out, contains('# Yaki Release Notes'));
      expect(out, contains('We shipped **three** things this week.'));
      expect(out, contains('- Faster relays'));
      expect(out, contains('- Better search'));
      expect(out, contains('- A new editor'));
      expect(out, contains('> Feedback welcome.'));
      expect(out, contains('|feature|status|'));
      expect(out, contains('|relays|done|'));
      expect(out, contains('(https://yakihonne.com)'));

      // Stable on a second pass, so repeated open/save never compounds.
      expect(roundTrip(out), out);
    });
  });

  group('editor wiring', () {
    test('replacing the document past a stale selection does not throw', () {
      // The AI-apply and draft-load path: a long document, caret near the end,
      // then a much shorter document takes its place.
      const long = '# Long Article\n\n'
          'A first paragraph with a decent amount of text in it.\n\n'
          'A second paragraph, also reasonably long, to push offsets out.';
      final controller = QuillController(
        document: markdownToQuillDocument(long),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);

      controller.updateSelection(
        const TextSelection.collapsed(offset: long.length - 10),
        ChangeSource.local,
      );

      controller
        ..document = markdownToQuillDocument('# Tiny')
        ..updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

      expect(quillDocumentToMarkdown(controller.document), '# Tiny');
    });

    test('document changes stream fires on edit', () async {
      final controller = QuillController(
        document: markdownToQuillDocument('start'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);

      var fired = 0;
      final sub = controller.changes.listen((_) => fired++);
      addTearDown(sub.cancel);

      controller.document.insert(5, ' more');
      await Future<void>.delayed(Duration.zero);

      expect(fired, greaterThan(0));
      expect(quillDocumentToMarkdown(controller.document), contains('more'));
    });
  });

  // The custom toolbar buttons insert raw markdown at the caret, since Quill has
  // no native format for math, images, separators or smart widgets. This mirrors
  // _insertRaw and checks the inserted source survives back to markdown.
  group('raw markdown insertion', () {
    String insertInto(String initial, String markdown, {int? at}) {
      final controller = QuillController(
        document: markdownToQuillDocument(initial),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);

      final index = (at ?? controller.selection.baseOffset)
          .clamp(0, controller.document.length - 1);
      final text = '\n$markdown\n';
      controller.replaceText(
        index,
        0,
        text,
        TextSelection.collapsed(offset: index + text.length),
      );
      return quillDocumentToMarkdown(controller.document);
    }

    // Inserts an embed the way the toolbar buttons do, rather than raw text.
    String insertEmbed(String seed, BlockEmbed embed) {
      final controller = QuillController(
        document: markdownToQuillDocument(seed),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);
      final index =
          controller.selection.baseOffset.clamp(0, controller.document.length - 1);
      controller.replaceText(
          index, 0, embed, TextSelection.collapsed(offset: index + 1));
      return quillDocumentToMarkdown(controller.document);
    }

    test('math inserts as an embed and serialises backtick-wrapped', () {
      expect(insertEmbed('Intro text.', const BlockEmbed('latex', 'E = mc^2')),
          contains(r'`$$E = mc^2$$`'));
    });

    test('markdown paste converts, plain text does not', () {
      // Gate on _onClipboardPaste: a false positive reformats text the user
      // pasted verbatim, which is worse than leaving markdown unformatted.
      const markdown = {
        'heading': '# Title\n\nBody.',
        'bullets': '- one\n- two',
        'ordered': '1. one\n2. two',
        'quote': '> quoted',
        'fence': '```dart\nvoid main() {}\n```',
        'table': '|a|b|\n|-|-|\n|1|2|',
        'bold': 'Some **bold** text.',
        'link': 'See [example](https://example.com).',
        'latex': r'`$$E = mc^2$$`',
      };
      for (final entry in markdown.entries) {
        expect(markdownPasteToDelta(entry.value), isNotNull,
            reason: '${entry.key} should paste as rich text');
      }

      const plain = {
        'prose': 'Just a sentence. And another one!',
        'bare url': 'https://example.com/some/path',
        'multi-line prose': 'First line\nSecond line\nThird line',
        'math in prose': r'The cost is 5$ or 10$ tops.',
        'hyphen mid-sentence': 'A well-known example - see it here.',
      };
      for (final entry in plain.entries) {
        expect(markdownPasteToDelta(entry.value), isNull,
            reason: '${entry.key} should paste unchanged');
      }
    });

    test('foreign math delimiters paste as equations', () {
      // Nothing outside the app writes the backtick-wrapped form: LaTeX
      // sources, ChatGPT and Wikipedia all emit these instead.
      const foreign = {
        r'block $$': r'$$E = mc^2$$',
        r'inline $': r'Einstein wrote $E = mc^2$ in 1905.',
        r'display \[': r'\[E = mc^2\]',
        r'inline \(': r'Einstein wrote \(E = mc^2\) in 1905.',
      };
      for (final entry in foreign.entries) {
        final delta = markdownPasteToDelta(entry.value);
        expect(delta, isNotNull, reason: '${entry.key} should paste as maths');
        final doc = Document.fromDelta(delta!);
        expect(quillDocumentToMarkdown(doc), contains(r'`$$E = mc^2$$`'),
            reason: '${entry.key} should survive as a latex embed');
      }
    });

    test('normalising math leaves the app form and code fences alone', () {
      // Re-wrapping would turn `$$x$$` into ``$$`$$x$$`$$``.
      expect(normaliseMathDelimiters(r'`$$E = mc^2$$`'), r'`$$E = mc^2$$`');
      // `$$` inside a fence is sample text, not maths.
      const fence = '```sh\n' r'echo $$ dollars $$' '\n```';
      expect(normaliseMathDelimiters(fence), fence);
    });

    test('pasted markdown keeps its formatting through the round trip', () {
      final delta = markdownPasteToDelta('# Title\n\n- one\n- two')!;
      final out = quillDocumentToMarkdown(Document.fromDelta(delta));
      expect(out, contains('# Title'));
      expect(out, contains('one'));
    });

    test('mention inserts as an embed and serialises as nostr:npub', () {
      const npub = 'npub1qqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0';
      final out =
          insertEmbed('Hey ', const BlockEmbed('mention', npub));
      expect(out, contains('nostr:$npub'));
    });

    test('mention round-trips back to an embed mid-sentence', () {
      const npub = 'npub1qqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0';
      final doc = markdownToQuillDocument('Thanks nostr:$npub for the help.');
      final hasEmbed = doc.toDelta().toList().any(
            (op) => op.data is Map && (op.data! as Map).containsKey('mention'),
          );
      expect(hasEmbed, isTrue, reason: 'should parse into a mention embed');

      final out = quillDocumentToMarkdown(doc);
      expect(out, contains('nostr:$npub'));
      // The surrounding prose must survive on the same line.
      expect(out, contains('Thanks'));
      expect(out, contains('for the help'));
    });

    test('pdf export flattens the app-specific markdown extensions', () {
      // A generic markdown parser has no idea what these mean, so they would
      // otherwise show as raw source in the exported PDF.
      const npub = 'npub1qqqsyqcyq5rqwzqfpg9scrgwpugpzysnzs23v9ccrydpk8qarc0';
      final out = pdfExportMarkdown(
        'Mass `\$\$E = mc^2\$\$` and thanks nostr:$npub for it.',
      );
      expect(out, isNot(contains(r'$$')));
      expect(out, contains('`E = mc^2`'));
      expect(out, isNot(contains('nostr:')));
      expect(out, contains('@npub1qqqsyqcyq5'));
      // Ordinary prose is untouched.
      expect(out, contains('Mass'));
      expect(out, contains('for it.'));
    });

    test('a stale equation offset resolves to a non-embed leaf', () {
      // Guards _editMath: the sheet is awaited, so an autosave or draft reload
      // can rebuild the document while it is open. An in-range offset is not
      // enough — writing at one that no longer holds the embed would eat a
      // character of prose, so the edit path checks the leaf's identity.
      final controller = QuillController(
        document: markdownToQuillDocument(r'`$$E = mc^2$$`'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);

      final embedOffset = controller.document
          .querySegmentLeafNode(0)
          .leaf!
          .documentOffset;
      expect(controller.document.querySegmentLeafNode(embedOffset).leaf,
          isA<Embed>());

      // The document is rebuilt under the captured offset, as a draft reload
      // would do. The same offset must no longer look like a latex embed.
      controller.document = markdownToQuillDocument('Just prose, much longer.');
      final leaf = controller.document.querySegmentLeafNode(embedOffset).leaf;
      expect(leaf is Embed && leaf.value.type == 'latex', isFalse);
    });

    test('math embed round-trips back to an embed, not text', () {
      // The reopen path: markdown -> embed. If this regressed to a text run the
      // equation would stop rendering live in the editor.
      final doc = markdownToQuillDocument(r'`$$E = mc^2$$`');
      expect(doc.toDelta().toList().any((op) => op.data is Map), isTrue);
      expect(quillDocumentToMarkdown(doc), contains(r'`$$E = mc^2$$`'));
    });

    test('divider inserts as an embed and renders as a rule', () {
      // Regression: the separator button used to insert '---' as raw text,
      // which parsed back into a divider embed with no builder and threw
      // UnimplementedError on the next draft open.
      expect(insertEmbed('Above.', const BlockEmbed('divider', 'hr')),
          anyOf(contains('---'), contains('- - -')));
    });

    test('image must be an embed, not raw text', () {
      // Raw text gets auto-linked and escaped into
      // '![]([https://x\\.com/i\\.png\\)](...))' — hence _insertImage uses
      // BlockEmbed.image instead.
      expect(
        insertInto('Intro text.', '![](https://x.com/i.png)'),
        isNot(contains('![](https://x.com/i.png)')),
      );

      final controller = QuillController(
        document: markdownToQuillDocument('Intro text.'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);
      controller.document.insert(0, BlockEmbed.image('https://x.com/i.png'));
      expect(
        quillDocumentToMarkdown(controller.document),
        contains('![](https://x.com/i.png)'),
      );
    });

    test('a bare url in text gets auto-linked', () {
      // Why smart widgets insert an naddr scheme rather than a URL.
      expect(
        insertInto('Intro.', 'https://yakihonne.com/x'),
        contains('](https://yakihonne.com/x)'),
      );
    });

    test('naddr scheme inserts cleanly', () {
      const naddr = 'naddr1qqxnzdesxqmnxvpexqunzvpcqy28wumn8ghj7';
      expect(insertInto('Intro.', naddr), contains(naddr));
    });

    test('separator survives insertion', () {
      // Serialises as '- - -', which renders as the same <hr>.
      final out = insertInto('Above.', '---');
      expect(out, anyOf(contains('---'), contains('- - -')));
    });

    test('inserting at the end of the document is in range', () {
      final controller = QuillController(
        document: markdownToQuillDocument('Short.'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);
      // A caret past the end must clamp rather than throw.
      final index = 9999.clamp(0, controller.document.length - 1);
      controller.replaceText(
          index, 0, '\nx\n', TextSelection.collapsed(offset: index + 3));
      expect(quillDocumentToMarkdown(controller.document), contains('x'));
    });
  });

  // The table sheet builds the embed's data with buildTableMarkdown and reads
  // it back with parseTableRows, and that same data is what publishes verbatim
  // (EmbeddableTable.toMdSyntax writes it out unchanged). If the two disagree,
  // editing a table corrupts it.
  group('table', () {
    test('grid survives build -> markdown -> parse', () {
      const grid = [
        ['Name', 'Role'],
        ['Ada', 'Engineer'],
        ['Bob', ''],
      ];
      expect(parseTableRows(buildTableMarkdown(grid)), grid);
    });

    test('a cell containing a pipe survives', () {
      const grid = [
        ['Header'],
        ['a | b'],
      ];
      final markdown = buildTableMarkdown(grid);
      // Escaped on the way out, so the row doesn't split into two columns.
      expect(markdown, contains(r'\|'));
      expect(parseTableRows(markdown), grid);
    });

    test('surrounding pipes do not become empty columns', () {
      expect(
        parseTableRows('| a | b |\n| --- | --- |\n| c | d |'),
        [
          ['a', 'b'],
          ['c', 'd'],
        ],
      );
    });

    test('inserting next to prose keeps the table on its own line', () {
      // EmbeddableTable.toMdSyntax writes the data with no leading newline, so
      // an embed dropped at the end of a prose line could serialise as
      // 'Above.| a | b |' — which no longer parses as a table on reload.
      final controller = QuillController(
        document: markdownToQuillDocument('Above.'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      addTearDown(controller.dispose);

      final index = 6.clamp(0, controller.document.length - 1);
      controller.replaceText(
        index,
        0,
        BlockEmbed(
          'x-embed-table',
          buildTableMarkdown(const [
            ['a', 'b'],
            ['1', '2'],
          ]),
        ),
        TextSelection.collapsed(offset: index + 1),
      );

      final out = quillDocumentToMarkdown(controller.document);
      expect(out, contains('Above.'));
      expect(
        RegExp(r'^\| a \| b \|', multiLine: true).hasMatch(out),
        isTrue,
        reason: 'header row must start a line, not trail the prose: $out',
      );
      expect(parseTableRows(out.split('Above.').last), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('the divider matches the column count after a resize', () {
      final markdown = buildTableMarkdown(const [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
      // A stale 2-column divider under a 3-column header stops the whole block
      // parsing as a table.
      expect(markdown.split('\n')[1], '| --- | --- | --- |');
      expect(parseTableRows(roundTrip(markdown)), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });
  });
}
