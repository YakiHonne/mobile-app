// Standalone checks avoid unrelated Flutter native-asset build hooks.
// dart --disable-dart-dev test/logic/browser_highlight_share_check.dart
// ignore_for_file: avoid_relative_lib_imports
import '../../lib/common/browser_highlight_share.dart';
import '../../lib/repositories/web_highlight_context_repository.dart';

void main() {
  void check(bool condition, String message) {
    if (!condition) {
      throw StateError(message);
    }
  }

  String link(String directive) =>
      'https://example.com/article#:~:text=$directive';
  String? paragraph(String source, String quote,
          {TextFragmentSelector? selector}) =>
      WebHighlightContextRepository.paragraphFromHtml(
        source,
        quote,
        selector: selector,
      );

  final chrome = BrowserHighlightShare.tryParse(
    '“你好 & café + commas, too”\n'
    '${link('before-,%E4%BD%A0%E5%A5%BD%20%26%20caf%C3%A9%20%2B%20commas%2C%20too,-after')}',
  );
  check(chrome?.selectedText == '你好 & café + commas, too',
      'Keep Unicode and punctuation in the quote');
  check(chrome?.sourceUrl == 'https://example.com/article',
      'Separate source URL from the text directive');
  check(
      chrome?.selector?.prefix == 'before' &&
          chrome?.selector?.suffix == 'after',
      'Keep disambiguation hints');
  check(BrowserHighlightShare.tryParse(link('C++'))?.selectedText == 'C++',
      'A literal plus is not a query-string space');
  check(BrowserHighlightShare.tryParse(link('quote'))?.selectedText == 'quote',
      'A link containing a complete quote is sufficient');
  check(BrowserHighlightShare.tryParse(link('begin,end')) == null,
      'Do not invent the middle of a range selection');
  final range = BrowserHighlightShare.tryParse(
    '"begin middle end"\n${link('begin,end')}',
  );
  check(range?.selectedText == 'begin middle end', 'Keep a full range quote');
  check(BrowserHighlightShare.tryParse('wrong quote\n${link('right')}') == null,
      'Do not treat a page title as the selected quote');
  check(BrowserHighlightShare.tryParse('https://example.com/article') == null,
      'Ordinary URL shares are not highlights');
  final generic =
      BrowserHighlightShare.tryParse('A quote\nhttps://example.com');
  check(generic?.selectedText == 'A quote' && !generic!.hasTextFragment,
      'Quote-and-URL shares allow an explicit Highlight action');
  for (final invalid in [
    link(''),
    link('%FF'),
    link('a&text=b'),
    'https://user:pass@example.com#:~:text=quote',
    link('a,b,c'),
    'quote\nhttps://one.example\nhttps://two.example',
    '${'q' * 4001}\nhttps://example.com',
  ]) {
    check(BrowserHighlightShare.tryParse(invalid) == null,
        'Reject ambiguous or malformed payload: $invalid');
  }

  check(
      paragraph(
              '<p>Before <em>the quote</em> after.</p><p>Other paragraph.</p>',
              'the quote') ==
          'Before the quote after.',
      'Keep both sides of the same paragraph without neighboring paragraphs');
  check(
      paragraph('<p>Before a&nbsp; quote<br>after.</p>', 'a quote') ==
          'Before a quote after.',
      'Normalize rendered HTML whitespace');
  check(
      paragraph('<p>Before a\n quote after.</p>', 'a\nquote') ==
          'Before a\nquote after.',
      'Preserve the exact user selection');
  check(paragraph('<p>quote first.</p><p>quote second.</p>', 'quote') == null,
      'Reject repeated quotes across paragraphs');
  check(paragraph('<p>quote then quote.</p>', 'quote') == null,
      'Reject repeated quotes within a paragraph');
  check(
      paragraph('<div><p>first half</p><p>second half</p></div>',
              'first half second half') ==
          null,
      'Never merge paragraphs to match a selection');
  check(
      paragraph('<nav><p>quote menu.</p></nav><p>Before quote after.</p>',
              'quote') ==
          'Before quote after.',
      'Ignore navigation and scripts');
  check(
      paragraph('<p>Before <script>quote</script>quote after.</p>', 'quote') ==
          'Before quote after.',
      'Script text is not page context');
  check(
      paragraph(
              '<div style="display: none"><p>quote hidden.</p></div> '
                  '<p>Before quote after.</p>',
              'quote') ==
          'Before quote after.',
      'Ignore paragraphs in hidden ancestors');
  check(paragraph('<p>quote</p>', 'quote') == null,
      'Omit a context tag containing only the selection');
  check(paragraph('<p>${'x' * 6001} quote.</p>', 'quote') == null,
      'Bound paragraph size');
  check(
      paragraph('<p>Before quote after.</p><p>Different quote ending.</p>',
              'quote',
              selector: const TextFragmentSelector(
                start: 'quote',
                prefix: 'Before',
                suffix: 'after.',
              )) ==
          'Before quote after.',
      'Use fragment hints to disambiguate');
  check(
      paragraph('<p>Before quote after.</p>', 'quote',
              selector: const TextFragmentSelector(
                  start: 'quote', prefix: 'Wrong')) ==
          null,
      'Do not attach context from a different source occurrence');
}
