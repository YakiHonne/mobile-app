import 'package:flutter/foundation.dart';

import '../common_regex.dart';
import 'linkify.dart';

class InvoiceLinkifier extends Linkifier {
  const InvoiceLinkifier();

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
      invoiceRegex,
      onMatch: (match) {
        result.add(InvoiceElement(match.group(0)!));
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
class InvoiceElement extends LinkableElement {
  const InvoiceElement(String invoice, [String? text]) : super(text, invoice);

  @override
  int get hashCode => Object.hash(text, url);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceElement && other.text == text && other.url == url);

  @override
  String toString() => "InvoiceElement: '$url'";
}
