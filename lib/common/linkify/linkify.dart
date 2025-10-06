import 'package:flutter/material.dart';

import 'email.dart';
import 'url.dart';

export 'email.dart' show EmailElement, EmailLinkifier;
export 'phone_number.dart' show PhoneNumberElement, PhoneNumberLinkifier;
export 'url.dart' show UrlElement, UrlLinkifier;
export 'user_tag.dart' show UserTagElement, UserTagLinkifier;

@immutable
abstract class LinkifyElement {
  const LinkifyElement(this.text, [String? originText])
      : originText = originText ?? text;
  final String text;
  final String originText;

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText);

  bool equals(other) => other is LinkifyElement && other.text == text;
}

class LinkableElement extends LinkifyElement {
  const LinkableElement(String? text, this.url, [String? originText])
      : super(text ?? url, originText);
  final String url;

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url);

  @override
  bool equals(other) =>
      other is LinkableElement && super.equals(other) && other.url == url;
}

/// Represents an element containing text
class TextElement extends LinkifyElement {
  const TextElement(super.text);

  @override
  String toString() {
    return "TextElement: '$text'";
  }

  @override
  bool operator ==(other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText);

  @override
  bool equals(other) => other is TextElement && super.equals(other);
}

abstract class Linkifier {
  const Linkifier();

  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  );
}

class LinkifyOptions {
  const LinkifyOptions({
    this.humanize = true,
    this.removeWww = false,
    this.looseUrl = false,
    this.defaultToHttps = false,
    this.excludeLastPeriod = true,
  });

  /// Removes http/https from shown URLs.
  final bool humanize;

  /// Removes www. from shown URLs.
  final bool removeWww;

  /// Enables loose URL parsing (any string with "." is a URL).
  final bool looseUrl;

  /// When used with [looseUrl], default to `https` instead of `http`.
  final bool defaultToHttps;

  /// Excludes `.` at end of URLs.
  final bool excludeLastPeriod;
}

const _urlLinkifier = UrlLinkifier();
const _emailLinkifier = EmailLinkifier();
const defaultLinkifiers = [_urlLinkifier, _emailLinkifier];

/// Turns [text] into a list of [LinkifyElement]
///
/// Use [humanize] to remove http/https from the start of the URL shown.
/// Will default to `false` (if `null`)
///
/// Uses [linkTypes] to enable some types of links (URL, email).
/// Will default to all (if `null`).
List<LinkifyElement> linkify(
  String text, {
  LinkifyOptions options = const LinkifyOptions(),
  List<Linkifier> linkifiers = defaultLinkifiers,
}) {
  var list = <LinkifyElement>[TextElement(text)];

  if (text.isEmpty) {
    return [];
  }

  if (linkifiers.isEmpty) {
    return list;
  }

  for (final linkifier in linkifiers) {
    list = linkifier.parse(list, options);
  }

  return list;
}
