import '../common_regex.dart';
import 'linkify.dart';

class CustomUrlLinkifier extends Linkifier {
  const CustomUrlLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement) {
        _parseTextForUrls(element.text, result, options);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  void _parseTextForUrls(
    String text,
    List<LinkifyElement> result,
    LinkifyOptions options,
  ) {
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      result.add(TextElement(text));
      return;
    }

    int lastEnd = 0;

    for (final match in matches) {
      // Add text before URL
      if (match.start > lastEnd) {
        result.add(TextElement(text.substring(lastEnd, match.start)));
      }

      // Add URL element
      final url = match.group(0);
      result.add(UrlElement(url!, url, text));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      result.add(TextElement(text.substring(lastEnd)));
    }
  }
}

class RelayLinkifier extends Linkifier {
  const RelayLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement) {
        _parseTextForUrls(element.text, result, options);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  void _parseTextForUrls(
    String text,
    List<LinkifyElement> result,
    LinkifyOptions options,
  ) {
    final matches = contentRelayRegExp.allMatches(text);

    if (matches.isEmpty) {
      result.add(TextElement(text));
      return;
    }

    int lastEnd = 0;

    for (final match in matches) {
      // Add text before URL
      if (match.start > lastEnd) {
        result.add(TextElement(text.substring(lastEnd, match.start)));
      }

      // Add URL element
      final url = match.group(0);
      result.add(RelayElement(url!, url, text));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      result.add(TextElement(text.substring(lastEnd)));
    }
  }
}

/// Represents an element containing a link
class RelayElement extends LinkableElement {
  const RelayElement(String url, [String? text, String? originText])
      : super(text, url, originText);

  @override
  String toString() {
    return "RelayElement: '$url' ($text)";
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url);

  @override
  bool equals(other) => other is UrlElement && super.equals(other);
}
