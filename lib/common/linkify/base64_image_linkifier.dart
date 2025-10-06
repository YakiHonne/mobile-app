import '../common_regex.dart';
import 'linkify.dart';

class Base64ImageLinkifier extends Linkifier {
  const Base64ImageLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement && element.text.isNotEmpty) {
        _parseTextForInvoices(element.text, result);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  void _parseTextForInvoices(String text, List<LinkifyElement> result) {
    text.splitMapJoin(
      base64ImageRegex,
      onMatch: (match) {
        result.add(UrlElement(match.group(0)!));
        return '';
      },
      onNonMatch: (text) {
        if (text.isNotEmpty) {
          result.add(TextElement(text));
        }
        return '';
      },
    );
  }
}
