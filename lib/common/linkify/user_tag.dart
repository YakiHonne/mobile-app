import 'linkify.dart';

/// For details on how this RegEx works, go to this link.
/// https://regex101.com/r/QN046t/1
final _userTagRegex = RegExp(
  r'^(.*?)@([\w@]+(?:[.!][\w@]+)*)',
  caseSensitive: false,
  dotAll: true,
);

class UserTagLinkifier extends Linkifier {
  const UserTagLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    for (final element in elements) {
      if (element is TextElement) {
        var match = _userTagRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          var textElement = '';
          var text = element.text.replaceFirst(match.group(0)!, '');
          while (match?.group(1)?.contains(RegExp(r'[\w@]$')) ?? false) {
            textElement += match!.group(0)!;
            match = _userTagRegex.firstMatch(text);
            if (match == null) {
              textElement += text;
              text = '';
            } else {
              text = text.replaceFirst(match.group(0)!, '');
            }
          }

          if (textElement.isNotEmpty ||
              (match?.group(1)?.isNotEmpty ?? false)) {
            list.add(TextElement(textElement + (match?.group(1) ?? '')));
          }

          if (match?.group(2)?.isNotEmpty ?? false) {
            list.add(UserTagElement('@${match!.group(2)!}'));
          }

          if (text.isNotEmpty) {
            list.addAll(parse([TextElement(text)], options));
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

/// Represents an element containing an user tag
class UserTagElement extends LinkableElement {
  const UserTagElement(this.userTag) : super(userTag, userTag);
  final String userTag;

  @override
  String toString() {
    return "UserTagElement: '$userTag' ($text)";
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url, userTag);

  @override
  bool equals(other) =>
      other is UserTagElement &&
      super.equals(other) &&
      other.userTag == userTag;
}
