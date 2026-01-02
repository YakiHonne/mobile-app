import 'package:convert/convert.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:override_text_scale_factor/override_text_scale_factor.dart';

import '../../../common/common_regex.dart';
import '../../../common/linkify/linkifiers.dart';
import '../../../common/media_handler/media_handler.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/detailed_note_model.dart';
import '../../../models/poll_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../gallery_view/gallery_view.dart';
import '../../note_view/note_view.dart';
import '../../smart_widgets_view/widgets/smart_widget_container.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../common_thumbnail.dart';
import '../custom_icon_buttons.dart';
import '../data_providers.dart';
import '../link_previewer.dart';
import '../no_content_widgets.dart';
import '../note_container.dart';
import '../parsed_media_container.dart';
import '../profile_picture.dart';
import 'hidden_media_container.dart';
import 'url_type_checker.dart';

/// Callback for clicked link
typedef LinkCallback = void Function(LinkableElement link);

/// Performance-optimized content renderer with memory leak fixes and optimizations
class ContentRenderer extends HookWidget {
  const ContentRenderer({
    super.key,
    required this.text,
    this.linkifiers = defaultLinkifiers,
    this.onOpen,
    this.onClicked,
    this.options = const LinkifyOptions(),
    this.style,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.minLines,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.softWrap = true,
    this.strutStyle,
    this.locale,
    this.scrollPhysics,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.isScreenshot,
    this.disableNoteParsing,
    this.disableUrlParsing,
    this.inverseNoteColor,
    this.useMouseRegion = true,
    this.hideMedia,
    this.height,
  });

  final String text;
  final List<Linkifier> linkifiers;
  final LinkCallback? onOpen;
  final VoidCallback? onClicked;
  final LinkifyOptions options;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final int? minLines;
  final TextOverflow? overflow;
  final double textScaleFactor;
  final bool softWrap;
  final StrutStyle? strutStyle;
  final Locale? locale;
  final ScrollPhysics? scrollPhysics;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final bool? isScreenshot;
  final bool? disableNoteParsing;
  final bool? disableUrlParsing;
  final bool? inverseNoteColor;
  final bool useMouseRegion;
  final double? height;
  final bool? hideMedia;

  @override
  Widget build(BuildContext context) {
    // Early return for empty content
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // Memoize parsed elements to avoid re-parsing
    final elements = _getLinkifyElements(text.trim());

    if (elements.isEmpty) {
      return _buildEmptyContent(context);
    }

    // Memoize instant URL types
    final instantUrlTypes =
        UrlTypeChecker.getInstantUrlTypes(elements, disableUrlParsing);

    return FutureBuilder<Map<int, UrlType>>(
      initialData: instantUrlTypes,
      future: UrlTypeChecker.getUrlTypesAsync(
        elements,
        instantUrlTypes,
        disableUrlParsing,
      ),
      builder: (context, snapshot) {
        final urlTypes = snapshot.data ?? {};

        return _OptimizedSelectableText(
          textSpan: _buildMainTextSpan(
            elements,
            urlTypes,
            context,
            scrollPhysics,
          ),
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: maxLines,
          minLines: minLines,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          onTap: onClicked,
          scrollPhysics: scrollPhysics,
        );
      },
    );
  }

  /// Extract linkify elements with error handling and caching
  List<LinkifyElement> _getLinkifyElements(String content) {
    try {
      return linkify(content, options: options, linkifiers: linkifiers)
          .where((element) => element.text.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error parsing linkify elements: $e');
      return [TextElement(content)];
    }
  }

  /// Build empty content widget
  Widget _buildEmptyContent(BuildContext context) {
    return Text(
      'No content',
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        color: Theme.of(context).highlightColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Build the main text span with optimization
  TextSpan _buildMainTextSpan(
    List<LinkifyElement> elements,
    Map<int, UrlType> urlTypes,
    BuildContext context,
    ScrollPhysics? scrollPhysics,
  ) {
    return TextSpan(
      children: _buildOptimizedTextSpanChildren(
        elements,
        urlTypes,
        context,
        scrollPhysics,
      ),
    );
  }

  /// Optimized text span building with reduced widget creation
  List<InlineSpan> _buildOptimizedTextSpanChildren(
    List<LinkifyElement> elements,
    Map<int, UrlType> urlTypes,
    BuildContext context,
    ScrollPhysics? scrollPhysics,
  ) {
    if (elements.isEmpty) {
      return [_buildNoContentSpan(context)];
    }

    final filteredData = _FilteredElementsData.fromElements(elements, urlTypes);
    final consecutiveMedia = _groupConsecutiveMedia(filteredData.urlTypes);
    final spans = <InlineSpan>[];

    // Process elements in batches to avoid blocking UI
    for (int i = 0; i < filteredData.elements.length; i++) {
      final element = filteredData.elements[i];

      if (element is LinkableElement) {
        _processOptimizedLinkableElement(
          element,
          i,
          consecutiveMedia,
          filteredData,
          spans,
          context,
          scrollPhysics,
        );
      } else {
        spans.add(_buildTextSpan(element.text, context));
      }
    }

    return spans;
  }

  /// Process linkable elements with optimization
  void _processOptimizedLinkableElement(
    LinkableElement element,
    int index,
    List<Map<int, UrlType>> consecutiveMedia,
    _FilteredElementsData filteredData,
    List<InlineSpan> spans,
    BuildContext context,
    ScrollPhysics? scrollPhysics,
  ) {
    final mediaGroup = _findMediaGroup(consecutiveMedia, index);

    if (mediaGroup != null && mediaGroup.keys.first == index) {
      _addOptimizedMediaContainer(
        mediaGroup,
        filteredData.elements,
        spans,
        index,
      );
    } else if (mediaGroup == null) {
      _addOptimizedSpecializedWidget(
        element,
        filteredData.urlTypes,
        index,
        spans,
        context,
        scrollPhysics,
      );
    }
  }

  /// Find media group for given index
  Map<int, UrlType>? _findMediaGroup(
    List<Map<int, UrlType>> consecutiveMedia,
    int index,
  ) {
    for (final group in consecutiveMedia) {
      if (group.keys.contains(index)) {
        return group;
      }
    }
    return null;
  }

  /// Add optimized media container widget
  void _addOptimizedMediaContainer(
    Map<int, UrlType> mediaGroup,
    List<LinkifyElement> elements,
    List<InlineSpan> spans,
    int index,
  ) {
    final mediaEntries = <MapEntry<String, UrlType>>[];

    for (final entry in mediaGroup.entries) {
      final element = elements[entry.key] as LinkableElement;
      final url = UrlTypeChecker.getElementUrl(element);
      mediaEntries.add(MapEntry(url, entry.value));
    }

    _addNewlineIfNeeded(spans, elements, index);

    spans.add(WidgetSpan(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: MediaContainer(
          media: mediaEntries,
          hideMedia: hideMedia ?? false,
          invertColor: inverseNoteColor ?? false,
        ),
      ),
    ));

    _addTrailingNewlineIfNeeded(spans, elements, index);
  }

  /// Add optimized specialized widget based on element type
  void _addOptimizedSpecializedWidget(
    LinkableElement element,
    Map<int, UrlType> urlTypes,
    int index,
    List<InlineSpan> spans,
    BuildContext context,
    ScrollPhysics? scrollPhysics,
  ) {
    // Use type checking instead of runtimeType for better performance
    if (element is InvoiceElement) {
      spans.add(_buildOptimizedInvoiceWidget(element: element));
    } else if (element is RelayElement) {
      spans.add(_buildOptimizedRelayWidget(element: element));
    } else if (element is UserSchemeElement) {
      spans.add(_buildOptimizedMetadataWidget(element: element));
    } else if (element is ZapPollElement) {
      spans.add(
          _buildOptimizedZapPollWidget(element: element, context: context));
    } else if (element is NoteElement) {
      spans.add(
        _buildOptimizedNoteWidget(
          element: element,
          context: context,
          scrollPhysics: scrollPhysics,
        ),
      );
    } else if (element is ArtCurSchemeElement) {
      spans.add(_buildOptimizedArtCurWidget(
        element: element,
        index: index,
        urlTypes: urlTypes,
        context: context,
      ));
    } else if (element is Neventlement) {
      spans.add(_buildOptimizedNeventWidget(
        element: element,
        index: index,
        urlTypes: urlTypes,
        context: context,
      ));
    } else if (element is TagElement) {
      spans.add(_buildOptimizedTagSpan(element, context));
    } else {
      spans.add(_buildOptimizedUrlWidget(
        element: element,
        context: context,
        disableUrlParsing: disableUrlParsing,
      ));
    }
  }

  /// Optimized widget builders with proper memory management
  WidgetSpan _buildOptimizedRelayWidget({required RelayElement element}) {
    return WidgetSpan(
      child: _OptimizedRelayContainer(
        relay: element.url,
        onOpen: () => onOpen?.call(element),
        linkStyle: linkStyle,
      ),
    );
  }

  /// Optimized widget builders with proper memory management
  WidgetSpan _buildOptimizedInvoiceWidget({required InvoiceElement element}) {
    return WidgetSpan(
      child: OverrideTextScaleFactor(
        child: _OptimizedInvoiceContainer(
          key: ValueKey('invoice_${element.url}'),
          invoice: element.url,
          inverseNoteColor: inverseNoteColor,
        ),
      ),
    );
  }

  InlineSpan _buildOptimizedMetadataWidget({
    required UserSchemeElement element,
  }) {
    return WidgetSpan(
      child: MetadataProvider(
        key: ValueKey('metadata_${element.url}'),
        child: (metadata, nip05) {
          return OptimizedMetadataContainer(
            metadata: metadata,
            onOpen: () => onOpen?.call(element),
            linkStyle: linkStyle,
          );
        },
        pubkey: element.url,
      ),
    );
  }

  WidgetSpan _buildOptimizedZapPollWidget({
    required ZapPollElement element,
    required BuildContext context,
  }) {
    return WidgetSpan(
      child: OverrideTextScaleFactor(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
          child: PollContainer(
            key: ValueKey('poll_${element.url}'),
            poll: PollModel.fromJson(element.url),
            includeUser: true,
            contentColor: Theme.of(context).primaryColorDark,
            backgroundColor: inverseNoteColor != null
                ? Theme.of(context).scaffoldBackgroundColor
                : Theme.of(context).cardColor,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildOptimizedNoteWidget({
    required NoteElement element,
    required BuildContext context,
    ScrollPhysics? scrollPhysics,
  }) {
    final noteId = element.url;

    return disableNoteParsing != null
        ? _buildDefaultTextSpan(element, context,
            text: Nip19.encodeNote(noteId))
        : WidgetSpan(
            child: OverrideTextScaleFactor(
              key: ValueKey('note_$noteId'),
              child: SingleEventProvider(
                id: noteId,
                isReplaceable: false,
                child: (event) => _buildNote(
                  event: event,
                  context: context,
                  text: Nip19.encodeNote(noteId),
                  scrollPhysics: scrollPhysics,
                ),
              ),
            ),
          );
  }

  Widget _buildNote({
    Event? event,
    required String text,
    required BuildContext context,
    DetailedNoteModel? model,
    ScrollPhysics? scrollPhysics,
  }) {
    if (event == null && model == null) {
      return _unsupportedEventContainer(context, text, true, isNote: true);
    }

    final note = model ?? DetailedNoteModel.fromEvent(event!);

    return MutedUserProvider(
      pubkey: note.pubkey,
      child: (isMuted) {
        if (isMuted) {
          return MutedUserActionBox(
            pubkey: note.pubkey,
          );
        }

        return NoteContainer(
          note: note,
          inverseNoteColor: inverseNoteColor,
          vMargin: kDefaultPadding / 4,
          disableVisualParsing: true,
          scrollPhysics: scrollPhysics,
          enableHidingMedia: hideMedia ?? true,
        );
      },
    );
  }

  InlineSpan _buildOptimizedNeventWidget({
    required Neventlement element,
    required int index,
    required Map<int, UrlType> urlTypes,
    required BuildContext context,
  }) {
    if (element.url.isEmpty) {
      return _buildDefaultTextSpan(element, context);
    }

    return WidgetSpan(
      child: OverrideTextScaleFactor(
        child: _OptimizedNeventWidget(
          key: ValueKey('nevent_${element.text}'),
          element: element,
          contentRenderer: this,
        ),
      ),
    );
  }

  InlineSpan _buildOptimizedArtCurWidget({
    required ArtCurSchemeElement element,
    required int index,
    required Map<int, UrlType> urlTypes,
    required BuildContext context,
  }) {
    if (element.url.isEmpty) {
      return _buildDefaultTextSpan(element, context);
    }

    return WidgetSpan(
      child: OverrideTextScaleFactor(
        child: SingleEventProvider(
          key: ValueKey('artcur_${element.url}'),
          id: element.url,
          isReplaceable: true,
          child: (event) => getBaseEventWidget(
            event: event,
            text: element.text,
            context: context,
            isEventSupported: element.kind != 'unknown',
          ),
        ),
      ),
    );
  }

  Widget getBaseEventWidget({
    required String text,
    required BuildContext context,
    Event? event,
    bool isMuted = false,
    bool isEventSupported = true,
    Widget? noModelWidget,
  }) {
    final model = getBaseEventModel(event);

    if (model == null) {
      return noModelWidget ??
          _unsupportedEventContainer(context, text, isEventSupported);
    }

    return MutedUserProvider(
      pubkey: event!.pubkey,
      child: (isMuted) {
        if (isUserMuted(event.pubkey)) {
          return MutedUserActionBox(
            pubkey: event.pubkey,
          );
        }

        if (model is DetailedNoteModel) {
          return disableNoteParsing != null
              ? _OptimizedTappableText(
                  text: Nip19.encodeNote(model.id),
                  style: linkStyle,
                  onTap: () => YNavigator.pushPage(
                    context,
                    (_) => NoteView(note: model),
                  ),
                )
              : _buildNote(text: text, context: context, model: model);
        }

        if (model is PollModel) {
          return PollContainer(
            poll: model,
            includeUser: true,
          );
        }

        return ParsedMediaContainer(baseEventModel: model);
      },
    );
  }

  Container _unsupportedEventContainer(
    BuildContext context,
    String text,
    bool isEventSupported, {
    bool isNote = false,
  }) {
    final textWidget = Text(
      isEventSupported
          ? isNote
              ? context.t.noteLoading
              : context.t.eventLoading
          : context.t.unsupportedKind,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: Theme.of(context).highlightColor,
          ),
    );

    final widgets = <Widget>[];

    if (isEventSupported) {
      widgets.add(
        Expanded(
          child: Row(
            children: [
              Flexible(child: textWidget),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              SpinKitCircle(
                color: Theme.of(context).highlightColor,
                size: 15,
              ),
            ],
          ),
        ),
      );
    } else {
      widgets.add(
        Expanded(
          child: textWidget,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).cardColor,
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).dividerColor,
        ),
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: Row(
        spacing: kDefaultPadding / 4,
        children: [
          ...widgets,
          CustomIconButton(
            onClicked: () {
              Clipboard.setData(
                ClipboardData(
                  text: text,
                ),
              );

              BotToastUtils.showSuccess(context.t.idCopied);
            },
            icon: FeatureIcons.copy,
            size: 15,
            backgroundColor: kTransparent,
            vd: -4,
          ),
          if (!isEventSupported)
            CustomIconButton(
              onClicked: () {
                openWebPage(url: 'https://njump.me/$text');
              },
              icon: FeatureIcons.shareGlobal,
              size: 15,
              backgroundColor: kTransparent,
              vd: -4,
            ),
        ],
      ),
    );
  }

  TextSpan _buildDefaultTextSpan(
    LinkableElement element,
    BuildContext context, {
    String? text,
  }) {
    return TextSpan(
      text: text ?? element.text,
      recognizer: _createTapGestureRecognizer(() => onOpen?.call(element)),
      style: linkStyle ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  InlineSpan _buildOptimizedTagSpan(TagElement element, BuildContext context) {
    return WidgetSpan(
      child: _OptimizedTagContainer(
        tag: element.text,
        onOpen: () => onOpen?.call(element),
        linkStyle: linkStyle,
      ),
    );
  }

  InlineSpan _buildOptimizedUrlWidget({
    required LinkableElement element,
    required BuildContext context,
    bool? disableUrlParsing,
  }) {
    final url = UrlTypeChecker.getElementUrl(element);

    if (!urlRegExp.hasMatch(url) ||
        (disableUrlParsing != null && disableUrlParsing)) {
      return TextSpan(
        text: element.text,
        style: linkStyle,
        recognizer: _createTapGestureRecognizer(() => onOpen?.call(element)),
      );
    }

    final cu = cleanUrl(url);

    if (audioUrlRegex.hasMatch(cu)) {
      return WidgetSpan(
        child: AudioDisplayer(
          key: ValueKey('audio_$url'),
          url: url,
          inverseNoteColor: inverseNoteColor,
        ),
      );
    }

    final last = cu.split('/').last;
    final linkPreview =
        nostrRepository.currentAppCustomization?.enableLinkPreview ?? true;

    if (nostrSchemeRegex.hasMatch(last) &&
        nostrIndexersUrls.any(
          (url) => cu.contains(url),
        ) &&
        (last.startsWith('nevent') ||
            last.startsWith('naddr') ||
            last.startsWith('npub') ||
            last.startsWith('nprofile') ||
            last.startsWith('note'))) {
      if (last.startsWith('npub') || last.startsWith('nprofile')) {
        final isNpub = last.startsWith('npub');
        String pubkey = '';

        if (isNpub) {
          pubkey = Nip19.decodePubkey(last);
        } else {
          final decode = Nip19.decodeShareableEntity(last);
          pubkey = decode['special'] ?? '';
        }

        return WidgetSpan(
          child: MetadataProvider(
            child: (metadata, n05) => OptimizedMetadataContainer(
              metadata: metadata,
              onOpen: () =>
                  openProfileFastAccess(context: context, pubkey: pubkey),
            ),
            pubkey: pubkey,
          ),
        );
      } else {
        String id = '';
        bool isReplaceable = false;
        bool supportedEvent = true;

        if (last.startsWith('note')) {
          id = Nip19.decodeNote(last);
          isReplaceable = false;
        } else if (last.startsWith('naddr')) {
          final decode = Nip19.decodeShareableEntity(last);
          final hexCode = hex.decode(decode['special']);
          id = String.fromCharCodes(hexCode);
          isReplaceable = true;
          supportedEvent = isSupportedEvent(decode['kind']);
        } else {
          final decode = Nip19.decodeShareableEntity(last);
          id = decode['special'] ?? '';
          isReplaceable = false;
          supportedEvent = isSupportedEvent(decode['kind']);
        }

        final noModelWidget = linkPreview
            ? UrlPreviewContainer(
                key: ValueKey('url_$url'),
                url: url,
                inverseContainerColor: inverseNoteColor,
              )
            : GestureDetector(
                onTap: () => onOpen?.call(element),
                child: Text(
                  url,
                  style: linkStyle,
                ),
              );

        return WidgetSpan(
          child: SingleEventProvider(
            id: id,
            isReplaceable: isReplaceable,
            child: (event) {
              return getBaseEventWidget(
                text: '',
                context: context,
                event: event,
                isEventSupported: supportedEvent,
                noModelWidget: noModelWidget,
              );
            },
          ),
        );
      }
    }

    return _buildOptimizedUrlLastWidget(
        linkPreview: linkPreview, url: url, element: element);
  }

  InlineSpan _buildOptimizedUrlLastWidget({
    required bool linkPreview,
    required String url,
    required LinkableElement element,
  }) {
    if (youtubeRegExp.hasMatch(url)) {
      return WidgetSpan(
        child: YoutubeVideoContainer(
          key: ValueKey('url_$url'),
          url: url,
          inverseContainerColor: inverseNoteColor,
        ),
      );
    } else if (linkPreview) {
      return WidgetSpan(
        child: UrlPreviewContainer(
          key: ValueKey('url_$url'),
          url: url,
          inverseContainerColor: inverseNoteColor,
        ),
      );
    } else {
      return TextSpan(
        text: url,
        style: linkStyle,
        recognizer: _createTapGestureRecognizer(() => onOpen?.call(element)),
      );
    }
  }

  /// Helper methods with optimizations

  /// Create gesture recognizer with proper disposal
  TapGestureRecognizer _createTapGestureRecognizer(VoidCallback onTap) {
    return TapGestureRecognizer()..onTap = onTap;
  }

  TextSpan _buildTextSpan(String text, BuildContext context) {
    return TextSpan(
      text: text,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  TextSpan _buildNoContentSpan(BuildContext context) {
    return TextSpan(
      text: 'No content',
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        color: Theme.of(context).highlightColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  void _addNewlineIfNeeded(
      List<InlineSpan> spans, List<LinkifyElement> elements, int index) {
    if (index != 0 && !elements[index - 1].text.endsWith('\n')) {
      spans.add(const TextSpan(text: '\n'));
    }
  }

  void _addTrailingNewlineIfNeeded(
      List<InlineSpan> spans, List<LinkifyElement> elements, int index) {
    if (!elements[index].text.endsWith('\n') &&
        index + 1 <= elements.length - 1) {
      final nextText = elements[index + 1].text;
      if (!newLineRegex.hasMatch(nextText)) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
  }
}

/// Optimized SelectableText wrapper
class _OptimizedSelectableText extends StatefulWidget {
  const _OptimizedSelectableText({
    required this.textSpan,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.minLines,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.onTap,
    this.scrollPhysics,
  });

  final TextSpan textSpan;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final int? minLines;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final VoidCallback? onTap;
  final ScrollPhysics? scrollPhysics;

  @override
  State<_OptimizedSelectableText> createState() =>
      _OptimizedSelectableTextState();
}

class _OptimizedSelectableTextState extends State<_OptimizedSelectableText> {
  final List<TapGestureRecognizer?> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _extractRecognizers(widget.textSpan);
  }

  @override
  void didUpdateWidget(_OptimizedSelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textSpan != widget.textSpan) {
      _disposeRecognizers();
      _extractRecognizers(widget.textSpan);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _extractRecognizers(InlineSpan span) {
    if (span is TextSpan) {
      if (span.recognizer is TapGestureRecognizer) {
        _recognizers.add(span.recognizer as TapGestureRecognizer?);
      }
      span.children?.forEach(_extractRecognizers);
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer?.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      widget.textSpan,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      onTap: widget.onTap,
      scrollPhysics: widget.scrollPhysics,
    );
  }
}

/// Optimized tappable text widget
class _OptimizedTappableText extends StatefulWidget {
  const _OptimizedTappableText({
    required this.text,
    required this.onTap,
    this.style,
  });

  final String text;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  State<_OptimizedTappableText> createState() => _OptimizedTappableTextState();
}

class _OptimizedTappableTextState extends State<_OptimizedTappableText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer()..onTap = widget.onTap;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: widget.text,
        style: widget.style,
        recognizer: _recognizer,
      ),
    );
  }
}

/// Optimized Nevent widget
class _OptimizedNeventWidget extends StatelessWidget {
  const _OptimizedNeventWidget({
    super.key,
    required this.element,
    required this.contentRenderer,
  });

  final Neventlement element;
  final ContentRenderer contentRenderer;

  @override
  Widget build(BuildContext context) {
    final entity = Nip19.decodeShareableEntity(element.text);
    final id = entity['special'];
    final kind = entity['kind'];

    return SingleEventProvider(
      id: id,
      isReplaceable: isReplaceable(kind),
      child: (event) => contentRenderer.getBaseEventWidget(
        event: event,
        text: element.text,
        context: context,
      ),
    );
  }
}

class _OptimizedTagContainer extends StatelessWidget {
  const _OptimizedTagContainer({
    required this.tag,
    required this.onOpen,
    this.linkStyle,
  });

  final String tag;
  final Function() onOpen;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return OverrideTextScaleFactor(
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onOpen,
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              color: kNavyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kDefaultPadding / 3),
              border: Border.all(
                width: 0.5,
                color: kNavyBlue.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 4,
              children: [
                Flexible(
                  child: Text(
                    tag,
                    style: linkStyle?.copyWith(
                      color: kNavyBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SvgPicture.asset(
                  FeatureIcons.shareExternal,
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptimizedRelayContainer extends StatelessWidget {
  const _OptimizedRelayContainer({
    required this.relay,
    required this.onOpen,
    this.linkStyle,
  });

  final String relay;
  final Function() onOpen;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return OverrideTextScaleFactor(
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onOpen,
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kDefaultPadding / 3),
              border: Border.all(
                width: 0.5,
                color: kGreen.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 4,
              children: [
                Flexible(
                  child: Text(
                    relay,
                    style: linkStyle?.copyWith(
                      color: kGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SvgPicture.asset(
                  FeatureIcons.shareExternal,
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OptimizedMetadataContainer extends StatelessWidget {
  const OptimizedMetadataContainer({
    super.key,
    required this.metadata,
    required this.onOpen,
    this.linkStyle,
  });

  final Metadata metadata;
  final Function() onOpen;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return OverrideTextScaleFactor(
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onOpen,
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kDefaultPadding / 3),
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).primaryColor.withValues(
                      alpha: 0.2,
                    ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kDefaultPadding / 4,
              children: [
                ProfilePicture3(
                  size: 17,
                  pubkey: metadata.pubkey,
                  image: metadata.picture,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: onOpen,
                ),
                Flexible(
                  child: Text(
                    metadata.getName(),
                    style: linkStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Optimized invoice container
class _OptimizedInvoiceContainer extends StatelessWidget {
  const _OptimizedInvoiceContainer({
    super.key,
    required this.invoice,
    this.inverseNoteColor,
  });

  final String invoice;
  final bool? inverseNoteColor;

  @override
  Widget build(BuildContext context) {
    if (invoice.startsWith('lnurl')) {
      final lud16 = Zap.getLud16FromLud06(invoice);

      if (lud16 == null) {
        return _errorWidget(context, context.t.invalidInvoiceLnurl);
      }

      return _lightningAddressContainer(context, lud16);
    }

    final amount = getlnbcValue(invoice).toInt();

    if (amount == -1) {
      return _errorWidget(context, context.t.invalidInvoice);
    }

    return _invoiceContainer(context, amount);
  }

  Container _lightningAddressContainer(BuildContext context, String lud16) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.lightningAddress.capitalize(),
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                    Text(
                      lud16,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              CustomIconButton(
                onClicked: () => _copyLightningAddress(context, lud16),
                icon: FeatureIcons.copy,
                size: 17,
                vd: -1,
                backgroundColor: inverseNoteColor == null
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).cardColor,
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _performZap(context, lud16: lud16),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(context.t.zap.capitalizeFirst()),
            ),
          ),
        ],
      ),
    );
  }

  Container _invoiceContainer(BuildContext context, int amount) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.invoice.capitalize(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: kDefaultPadding / 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          FeatureIcons.zapAmount,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: kDefaultFontSize / 2),
                        Expanded(
                          child: Text(
                            '$amount SATS',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CustomIconButton(
                onClicked: () => _copyInvoice(context),
                icon: FeatureIcons.copy,
                size: 17,
                vd: -1,
                backgroundColor: inverseNoteColor == null
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).cardColor,
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _performZap(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(context.t.pay),
            ),
          ),
        ],
      ),
    );
  }

  Container _errorWidget(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      child: Row(
        spacing: kDefaultPadding / 2,
        children: [
          SvgPicture.asset(
            ToastsIcons.error,
            width: 25,
            height: 25,
          ),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLightningAddress(BuildContext context, String lightningAddress) {
    Clipboard.setData(ClipboardData(text: lightningAddress));
    BotToastUtils.showSuccess(context.t.lnCopied);
  }

  void _copyInvoice(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invoice));
    BotToastUtils.showSuccess(context.t.invoiceCopied);
  }

  void _performZap(BuildContext context, {String? lud16}) {
    doIfCanSign(
      func: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) => SendZapsView(
            metadata: Metadata.empty().copyWith(
              lud06: lud16 ?? invoice,
              lud16: lud16 ?? invoice,
            ),
            lnbc: lud16 != null ? null : invoice,
            zapSplits: const [],
            isZapSplit: false,
          ),
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      context: context,
    );
  }
}

/// Helper class for filtered elements data (unchanged but optimized)
class _FilteredElementsData {
  _FilteredElementsData(this.elements, this.urlTypes);

  factory _FilteredElementsData.fromElements(
    List<LinkifyElement> originalElements,
    Map<int, UrlType> originalTypes,
  ) {
    final filteredElements = List<LinkifyElement>.from(originalElements);
    final newTypes = Map<int, UrlType>.from(originalTypes);

    // Remove empty elements between media items
    for (int i = filteredElements.length - 1; i >= 0; i--) {
      final element = filteredElements[i];

      if (element is! LinkableElement &&
          _shouldRemoveElement(element, newTypes, i)) {
        filteredElements.removeAt(i);
        _adjustTypeIndices(newTypes, i);
      }
    }

    return _FilteredElementsData(filteredElements, newTypes);
  }

  final List<LinkifyElement> elements;
  final Map<int, UrlType> urlTypes;

  static bool _shouldRemoveElement(
    LinkifyElement element,
    Map<int, UrlType> types,
    int currentIndex,
  ) {
    final trimmed = element.text.trim();

    if (trimmed.isEmpty || trimmed == '\n' || trimmed == '\n\n') {
      final prevType = types[currentIndex - 1];
      final nextType = types[currentIndex + 1];

      return (prevType == UrlType.image || prevType == UrlType.video) &&
          (nextType == UrlType.image || nextType == UrlType.video);
    }

    return false;
  }

  static void _adjustTypeIndices(Map<int, UrlType> types, int removedIndex) {
    final keysToUpdate = types.keys.where((key) => key > removedIndex).toList();

    for (final key in keysToUpdate) {
      types[key - 1] = types[key]!;
      types.remove(key);
    }
  }
}

/// Group consecutive media items (unchanged)
List<Map<int, UrlType>> _groupConsecutiveMedia(Map<int, UrlType> data) {
  final mediaTypes = data.entries
      .where((e) => e.value == UrlType.image || e.value == UrlType.video)
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  if (mediaTypes.isEmpty) {
    return [];
  }

  final result = <Map<int, UrlType>>[];
  var currentGroup = <int, UrlType>{};
  int? previousIndex;

  for (final entry in mediaTypes) {
    if (previousIndex == null || entry.key - previousIndex == 1) {
      currentGroup[entry.key] = entry.value;
    } else {
      if (currentGroup.isNotEmpty) {
        result.add(Map.from(currentGroup));
      }
      currentGroup = {entry.key: entry.value};
    }
    previousIndex = entry.key;
  }

  if (currentGroup.isNotEmpty) {
    result.add(currentGroup);
  }

  return result;
}

/// Original container widgets preserved for compatibility
class InvoiceContainer extends StatelessWidget {
  const InvoiceContainer({
    super.key,
    required this.invoice,
    this.inverseNoteColor,
  });

  final String invoice;
  final bool? inverseNoteColor;

  @override
  Widget build(BuildContext context) {
    final amount = getlnbcValue(invoice).toInt();

    if (amount == -1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: inverseNoteColor != null
              ? Theme.of(context).scaffoldBackgroundColor
              : Theme.of(context).cardColor,
        ),
        child: Center(child: Text(context.t.invalidInvoice)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        color: inverseNoteColor != null
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.invoice.capitalize(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: kDefaultPadding / 8),
                    Row(
                      children: [
                        SvgPicture.asset(
                          FeatureIcons.zapAmount,
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: kDefaultFontSize / 2),
                        Text(
                          '$amount SATS',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CustomIconButton(
                onClicked: () => _copyInvoice(context),
                icon: FeatureIcons.copy,
                size: 17,
                vd: -1,
                backgroundColor: inverseNoteColor == null
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).cardColor,
              ),
            ],
          ),
          const SizedBox(height: kDefaultPadding / 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _payInvoice(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(context.t.pay),
            ),
          ),
        ],
      ),
    );
  }

  void _copyInvoice(BuildContext context) {
    Clipboard.setData(ClipboardData(text: invoice));
    BotToastUtils.showSuccess(context.t.invoiceCopied);
  }

  void _payInvoice(BuildContext context) {
    doIfCanSign(
      func: () {
        showModalBottomSheet(
          context: context,
          elevation: 0,
          builder: (_) => SendZapsView(
            metadata: Metadata.empty().copyWith(
              lud06: invoice,
              lud16: invoice,
            ),
            lnbc: invoice,
            zapSplits: const [],
            isZapSplit: false,
            onSuccess: (preimage, amount) => YNavigator.pop(context),
          ),
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      context: context,
    );
  }
}

class MediaContainer extends HookWidget {
  const MediaContainer({
    super.key,
    required this.media,
    required this.hideMedia,
    required this.invertColor,
  });

  final List<MapEntry<String, UrlType>> media;
  final bool hideMedia;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: media.length > 1
          ? GalleryImageView(
              media: {for (final e in media) e.key: e.value},
              seperatorColor: Theme.of(context).scaffoldBackgroundColor,
              width: MediaQuery.of(context).size.width,
              onDownload: MediaUtils.shareImage,
              height: 180,
              isHidden: hideMedia,
              invertColor: invertColor,
            )
          : _buildSingleMedia(context),
    );
  }

  Widget _buildSingleMedia(BuildContext context) {
    final mediaItem = media.first;
    final enableAutoplay =
        nostrRepository.currentAppCustomization?.enableAutoPlay ?? true;
    return mediaItem.value == UrlType.image
        ? Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            ),
            constraints: BoxConstraints(maxHeight: 35.h),
            child: MediaImage(
              url: mediaItem.key,
              isHidden: hideMedia,
              invertColor: invertColor,
            ),
          )
        : CustomVideoPlayer(
            link: mediaItem.key,
            removePadding: false,
            autoPlay: enableAutoplay,
            enableSound: false,
          );
  }
}

class MediaImage extends HookWidget {
  const MediaImage({
    super.key,
    required this.url,
    required this.isHidden,
    required this.invertColor,
  });

  final String url;
  final bool isHidden;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    final hideImageStatus = useState(isHidden);

    return GestureDetector(
      onTap: () => _openGallery(context),
      child: Stack(
        children: [
          CommonThumbnail(
            image: url,
            height: 0,
            radius: kDefaultPadding / 2,
            isRound: true,
            useDefaultNoMedia: false,
          ),
          if (hideImageStatus.value)
            HiddenMediaContainer(
              hideImageStatus: hideImageStatus,
              invertColor: invertColor,
              includeMessage: true,
              url: url,
            ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context) {
    openGallery(
      source: MapEntry(url, UrlType.image),
      context: context,
      index: 0,
    );
  }
}
