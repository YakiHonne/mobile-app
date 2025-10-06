import 'package:flutter/foundation.dart';

import '../common_regex.dart';
import 'linkify.dart';

class TagLinkifier extends Linkifier {
  const TagLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final result = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement && element.text.isNotEmpty) {
        _parseTextForTags(element.text, result);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  void _parseTextForTags(String text, List<LinkifyElement> result) {
    text.splitMapJoin(
      hashtagsRegExp,
      onMatch: (match) {
        result.add(TagElement(match.group(0)!));
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

@immutable
class TagElement extends LinkableElement {
  const TagElement(String tag, [String? text]) : super(text, tag);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagElement && other.text == text && other.url == url);

  @override
  String toString() => "TagElement: '$url'";
}
