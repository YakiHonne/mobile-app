import 'package:flutter/material.dart';

import 'mentions.dart';

/// A custom implementation of [TextEditingController] to support @ mention or other
/// trigger based mentions.
class AnnotationEditingController extends TextEditingController {
  // Generate the Regex pattern for matching all the suggestions in one.
  AnnotationEditingController(this._mapping) {
    _updatePattern();
  }
  Map<String, Annotation> _mapping;
  String? _pattern;

  Map<String, Annotation> get mapping {
    return _mapping;
  }

  set mapping(Map<String, Annotation> value) {
    _mapping = value;
    _updatePattern();
  }

  void _updatePattern() {
    final sortedKeys = _mapping.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    _pattern = sortedKeys.isNotEmpty
        ? "(${sortedKeys.map((key) => RegExp.escape(key)).join('|')})"
        : null;
  }

  String get markupText {
    final someVal = _mapping.isEmpty
        ? text
        : text.splitMapJoin(
            RegExp('$_pattern'),
            onMatch: (Match match) {
              final mention = _mapping[match[0]!] ??
                  _mapping[_mapping.keys.firstWhere(
                    (element) {
                      final reg = RegExp(element);

                      return reg.hasMatch(match[0]!);
                    },
                  )]!;

              if (!mention.disableMarkup) {
                if (mention.markupBuilder != null) {
                  final val = mention.markupBuilder!(
                    mention.trigger,
                    mention.id!,
                    '',
                  );

                  return val;
                } else {
                  return '${mention.trigger}[__${mention.id}__](__${mention.display}__)';
                }
              } else {
                return match[0]!;
              }
            },
            onNonMatch: (String text) {
              return text;
            },
          );

    return someVal;
  }

  @override
  TextSpan buildTextSpan({
    BuildContext? context,
    TextStyle? style,
    bool? withComposing,
  }) {
    final children = <InlineSpan>[];

    if (_pattern == null || _pattern == '()') {
      children.add(TextSpan(text: text, style: style));
    } else {
      try {
        text.splitMapJoin(
          RegExp('$_pattern'),
          onMatch: (Match match) {
            if (_mapping.isNotEmpty) {
              final mention = _mapping[match[0]!] ??
                  _mapping[_mapping.keys.firstWhere(
                    (element) {
                      final reg = RegExp(RegExp.escape(element));
                      return reg.hasMatch(match[0]!);
                    },
                  )]!;

              children.add(
                TextSpan(
                  text: match[0],
                  style: style!.merge(mention.style),
                ),
              );
            }

            return '';
          },
          onNonMatch: (String text) {
            children.add(TextSpan(text: text, style: style));
            return '';
          },
        );
      } catch (e) {
        children.add(TextSpan(text: text, style: style));
      }
    }

    return TextSpan(style: style, children: children);
  }
}
