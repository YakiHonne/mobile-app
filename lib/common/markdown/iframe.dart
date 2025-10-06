// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:markdown_widget/widget/all.dart';

import '../../utils/utils.dart';
import '../../views/widgets/link_previewer.dart';

class BlockQuoteNode extends SpanNode {
  final String html;

  BlockQuoteNode(this.html);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: XWebView(
        html: html,
      ),
    );
  }
}

class XWebView extends StatefulWidget {
  const XWebView({
    super.key,
    required this.html,
  });

  final String html;

  @override
  State<XWebView> createState() => _XWebViewState();
}

class _XWebViewState extends State<XWebView> {
  double height = 1;

  @override
  void initState() {
    super.initState();
  }

  String getHtmlString(String tweetId) {
    return """
      <html>
      
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>img {max-width: 100%; height: auto}</style>
        </head>
        <body>
            <div id="container"></div>
        </body>
        <script id="twitter-wjs" type="text/javascript" async defer src="https://platform.twitter.com/widgets.js" onload="createMyTweet()"></script>
        <script>
          function  createMyTweet() {  
            var twtter = window.twttr;
      
            twttr.widgets.createTweet(
              '$tweetId',
              document.getElementById('container'),
            )
          }
        </script>
        <script>
          function outputsize() {
              if (typeof window.flutter_inappwebview !== "undefined" && typeof window.flutter_inappwebview.callHandler !== "undefined")
                 window.flutter_inappwebview.callHandler('newHeight', document.getElementById("container").offsetHeight);
              }

          new ResizeObserver(outputsize).observe(container)
        </script>
        
      </html>
    """;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.html.split('status/').last.split('?').first;

    return SizedBox(
      height: height + 20,
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          supportZoom: false,
        ),
        initialUrlRequest: URLRequest(
          url: WebUri.uri(
            Uri.parse(
              Uri.dataFromString(
                getHtmlString(id),
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8'),
              ).toString(),
            ),
          ),
        ),
        onWebViewCreated: (controller) {
          controller.addJavaScriptHandler(
            handlerName: 'newHeight',
            callback: (List<dynamic> arguments) async {
              final int? height = arguments.isNotEmpty
                  ? arguments[0]
                  : await controller.getContentHeight();
              if (mounted) {
                setState(() => this.height = height!.toDouble());
              }
            },
          );
        },
      ),
    );
  }
}

class IframeNode extends SpanNode {
  final String url;

  IframeNode(this.url);
  @override
  InlineSpan build() {
    return WidgetSpan(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            supportZoom: false,
          ),
          initialUrlRequest: URLRequest(
            url: WebUri.uri(
              Uri.parse(url),
            ),
          ),
        ),
      ),
    );
  }
}

class LinkifierNode extends SpanNode {
  final String url;

  LinkifierNode(this.url);

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: LinkPreviewer(
        url: url,
        onOpen: () => openWebPage(url: url),
        textStyle: const TextStyle(
          color: kMainColor,
        ),
        urlType: UrlType.text,
        checkType: true,
      ),
    );
  }
}
