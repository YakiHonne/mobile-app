import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:html/parser.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:string_validator/string_validator.dart';

import '../../common/common_regex.dart';
import '../../common/markdown/code_wrapper_widget.dart';
import '../../common/markdown/html_support.dart';
import '../../common/markdown/iframe.dart';
import '../../common/markdown/math_text_node.dart';
import '../../common/markdown/nostr_scheme.dart';
import '../../utils/utils.dart';
import '../gallery_view/gallery_view.dart';
import 'common_thumbnail.dart';
import 'curation_container.dart';

class MarkDownWidget extends StatelessWidget {
  const MarkDownWidget({
    super.key,
    required this.content,
    required this.onLinkClicked,
  });

  final String content;
  final Function(String) onLinkClicked;

  @override
  Widget build(BuildContext context) {
    CodeWrapperWidget codeWrapper(child, text, language) => CodeWrapperWidget(
          child: child,
          text: text,
          language: language,
        );

    final isDark = themeCubit.isDark;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      removeTop: true,
      child: MarkdownWidget(
        data: content,
        shrinkWrap: true,
        markdownGenerator: MarkdownGenerator(
          generators: [
            latexGenerator,
            nostrGenerator,
          ],
          inlineSyntaxList: [
            LatexSyntax(),
            NostrSyntax(),
          ],
          textGenerator: (node, config, visitor) =>
              CustomTextNode(node.textContent, config, visitor),
        ),
        config: isDark
            ? MarkdownConfig.darkConfig.copy(
                configs: [
                  if (isDark)
                    PreConfig.darkConfig.copy(
                      wrapper: codeWrapper,
                      textStyle:
                          Theme.of(context).textTheme.labelLarge!.copyWith(
                                color: kWhite,
                              ),
                    )
                  else
                    const PreConfig().copy(wrapper: codeWrapper),
                  ...configs(context)
                ],
              )
            : MarkdownConfig.defaultConfig.copy(
                configs: [
                  if (isDark)
                    PreConfig.darkConfig.copy(wrapper: codeWrapper)
                  else
                    const PreConfig().copy(wrapper: codeWrapper),
                  ...configs(context),
                ],
              ),
        physics: const ScrollPhysics(
          parent: NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  List<WidgetConfig> configs(BuildContext context) {
    return [
      ImgConfig(
        builder: (url, attributes) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  openGallery(
                    source: MapEntry(
                      url,
                      UrlType.image,
                    ),
                    context: context,
                    index: 0,
                  );
                },
                child: url.isEmpty
                    ? const SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: NoMediaPlaceHolder(),
                      )
                    : CommonThumbnail(
                        image: url,
                        radius: 0,
                        isRound: false,
                      ),
              ),
            ),
          );
        },
      ),
      BlockquoteConfig(
        textColor: Theme.of(context).highlightColor,
      ),
      const ListConfig(),
      LinkConfig(
        onTap: onLinkClicked,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),
      ),
    ];
  }
}

class CustomTextNode extends ElementNode {
  CustomTextNode(this.text, this.config, this.visitor);
  final String text;
  final MarkdownConfig config;
  final WidgetVisitor visitor;

  @override
  Future<void> onAccepted(SpanNode parent) async {
    final textStyle = config.p.textStyle.merge(parentStyle);
    children.clear();

    if (isURL(text)) {
      accept(LinkifierNode(text));
      return;
    } else if (!text.contains(htmlRep) &&
        !(text.startsWith(r'$$') && text.endsWith(r'$$'))) {
      accept(TextNode(text: text, style: textStyle));
      return;
    } else if (text.trim().startsWith('<blockquote class=')) {
      accept(BlockQuoteNode(text));
      return;
    } else if (text.trim().startsWith('<img') &&
        text.trim().contains('src="')) {
      final document = parse(text);
      final dom.Element? link = document.querySelector('img');
      accept(LinkifierNode('${link != null ? link.attributes['src'] : ''}'));
    } else if (text.toLowerCase().contains('iframe')) {
      final urlMatches = urlRegExp.allMatches(text);
      final List<String> urls = urlMatches
          .map((urlMatch) => text.substring(urlMatch.start, urlMatch.end))
          .toList();

      if (urls.isNotEmpty) {
        accept(IframeNode(urls.first));
      }

      return;
    }
  }
}
