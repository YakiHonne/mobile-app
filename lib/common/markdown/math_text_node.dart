// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

import '../../utils/utils.dart';

SpanNodeGeneratorWithTag latexGenerator = SpanNodeGeneratorWithTag(
  tag: _latexTag,
  generator: (e, config, visitor) => LatexNode(
    e.attributes,
    e.textContent,
    config,
  ),
);

const _latexTag = 'latex';

class LatexSyntax extends m.InlineSyntax {
  // Regex to match block (`$$...$$`) or inline (`$...$`) LaTeX expressions
  LatexSyntax() : super(r'`\$\$[\s\S]*?\$\$`|`\$.*?\$`');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    try {
      final matchValue = match.group(0)!; // Full match including delimiters
      String content = '';
      bool isInline = true;

      if (matchValue.startsWith(r'`$$') && matchValue.endsWith(r'$$`')) {
        // Block LaTeX syntax - ensure minimum length for valid extraction
        if (matchValue.length >= 6) {
          content = matchValue.substring(3, matchValue.length - 3).trim();
          isInline = false;
        } else {
          // Handle malformed block syntax gracefully
          content = '';
          isInline = false;
        }
      } else if (matchValue.startsWith(r'`$') && matchValue.endsWith(r'$`')) {
        // Inline LaTeX syntax - ensure minimum length for valid extraction
        if (matchValue.length >= 4) {
          content = matchValue.substring(2, matchValue.length - 2).trim();
        } else {
          // Handle malformed inline syntax gracefully
          content = '';
        }
      }

      // Create an element with extracted content
      final el = m.Element.text('latex', content);
      el.attributes['isInline'] = '$isInline';
      el.attributes['content'] = content;

      parser.addNode(el);

      return true;
    } catch (e) {
      lg.i(e);

      return true;
    }
  }
}

class LatexNode extends SpanNode {
  LatexNode(this.attributes, this.textContent, this.config);
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final style = parentStyle ?? config.p.textStyle;
    final context = nostrRepository.mainCubit.context;
    if (content.isEmpty) {
      return TextSpan(style: style, text: textContent);
    }

    try {
      final widget = Math.tex(
        content.trim(),
        mathStyle: MathStyle.text,
        textScaleFactor: 1,
        textStyle: TextStyle(
          fontSize: 16,
          color: isInline ? null : Theme.of(context).primaryColorDark,
        ),
        onErrorFallback: (error) {
          return Text(
            textContent,
            style: style.copyWith(color: Colors.red),
          );
        },
      );

      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: !isInline
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(kDefaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    child: widget,
                  ),
                ),
              )
            : widget,
      );
    } catch (e) {
      lg.i(e);
      return const WidgetSpan(
        child: Text('empty'),
      );
    }
  }
}
