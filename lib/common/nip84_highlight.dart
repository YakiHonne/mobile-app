// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../common/browser_highlight_share.dart';
import '../common/common_regex.dart';
import '../logic/write_note_cubit/write_note_cubit.dart';
import '../models/app_models/diverse_functions.dart';
import '../models/article_model.dart';
import '../repositories/nostr_functions_repository.dart';
import '../repositories/web_highlight_context_repository.dart';
import '../utils/bot_toast_util.dart';
import '../utils/utils.dart';
import '../views/widgets/buttons_containers_widgets.dart';
import '../views/widgets/data_providers.dart';
import '../views/widgets/dotted_container.dart';
import '../views/widgets/fluid_sheet.dart';
import '../views/widgets/modal_sheet_container.dart';
import '../views/widgets/note_stats.dart';
import '../views/widgets/profile_picture.dart';
import '../views/write_note_view/write_note_view.dart';

/// Opens the NIP-84 composer after text is selected from a Nostr event.
Future<void> publishNip84Highlight({
  required BuildContext context,
  required String selectedText,
  required String sourceContent,
  required Nip84HighlightSource source,
}) async {
  if (selectedText.trim().isEmpty || !canSign()) {
    return;
  }

  await showAppModalSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => Nip84HighlightComposer(
      selectedText: selectedText,
      sourceContent: sourceContent,
      source: source,
    ),
  );
}

/// Opens the NIP-84 composer for text selected outside YakiHonne.
Future<void> publishExternalNip84Highlight({
  required BuildContext context,
  required String selectedText,
  String? sourceUrl,
  String? sourceContent,
  TextFragmentSelector? textSelector,
}) async {
  if (selectedText.trim().isEmpty || !canSign()) {
    return;
  }

  await showAppModalSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder: (_) => Nip84HighlightComposer.external(
      selectedText: selectedText,
      initialSourceUrl: sourceUrl,
      sourceContent: sourceContent,
      textSelector: textSelector,
    ),
  );
}

class Nip84HighlightComposer extends HookWidget {
  const Nip84HighlightComposer({
    super.key,
    required this.selectedText,
    required this.sourceContent,
    required this.source,
  })  : initialSourceUrl = null,
        textSelector = null;

  const Nip84HighlightComposer.external({
    super.key,
    required this.selectedText,
    this.initialSourceUrl,
    String? sourceContent,
    this.textSelector,
  })  : sourceContent = sourceContent ?? selectedText,
        source = null;

  final String selectedText;
  final String sourceContent;
  final Nip84HighlightSource? source;
  final String? initialSourceUrl;
  final TextFragmentSelector? textSelector;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(MentionTagTextEditingController.new, []);
    final sourceUrlController =
        useTextEditingController(text: initialSourceUrl);
    final signer = useState(currentSigner!);
    final scheduled = useState<DateTime?>(null);
    final isPublishing = useState(false);
    final isExternalSource = source == null;
    useListenable(sourceUrlController);

    final resolvedContext = useState<({String url, String? paragraph})?>(null);
    final sourceUrl =
        Nip84HighlightSource.tryExternal(sourceUrlController.text) == null
            ? null
            : sourceUrlController.text.trim();
    final initialUrl = initialSourceUrl?.trim();
    final suppliedContext = isExternalSource && sourceUrl != initialUrl
        ? null
        : _selectedParagraphContext(sourceContent, selectedText);
    final shouldResolve =
        isExternalSource && sourceUrl != null && suppliedContext == null;
    final isResolvingContext =
        shouldResolve && resolvedContext.value?.url != sourceUrl;
    final paragraphContext = suppliedContext ??
        (resolvedContext.value?.url == sourceUrl
            ? resolvedContext.value?.paragraph
            : null);

    useEffect(() {
      if (!shouldResolve) {
        return null;
      }
      var active = true;
      WebHighlightContextRepository? repository;
      final timer = Timer(const Duration(milliseconds: 500), () async {
        repository = WebHighlightContextRepository();
        final paragraph = await repository!.loadParagraph(
          sourceUrl: sourceUrl,
          selectedText: selectedText,
          selector: sourceUrl == initialUrl ? textSelector : null,
        );
        if (active) {
          resolvedContext.value = (url: sourceUrl, paragraph: paragraph);
        }
      });
      return () {
        active = false;
        timer.cancel();
        repository?.close();
      };
    }, [sourceUrl, shouldResolve, selectedText]);

    useEffect(() {
      return controller.dispose;
    }, [controller]);

    Future<void> publish() async {
      if (isPublishing.value || isResolvingContext) {
        return;
      }

      final highlightSource =
          source ?? Nip84HighlightSource.tryExternal(sourceUrlController.text);
      if (highlightSource == null) {
        BotToastUtils.showError(context.t.addValidUrl.capitalizeFirst());
        return;
      }

      isPublishing.value = true;
      final comment = getRawText(controller).trim();
      final sourceRelays = highlightSource.isExternal
          ? const <String>[]
          : await getEventSeenOnRelays(
              id: highlightSource.isReplaceable
                  ? highlightSource.identifier!
                  : highlightSource.id!,
              isReplaceable: highlightSource.isReplaceable,
            );
      final tags = <List<String>>[
        getClientTag(),
        highlightSource.toTag(sourceRelays),
        if (paragraphContext != null) ['context', paragraphContext],
        if (highlightSource.pubkey?.isNotEmpty ?? false)
          [
            'p',
            highlightSource.pubkey!,
            if (sourceRelays.isNotEmpty) sourceRelays.first else '',
            'author',
          ],
        if (comment.isNotEmpty) ['comment', comment],
        ...getPtags(comment).map((pubkey) => ['p', pubkey, '', 'mention']),
        ...urlRegExp
            .allMatches(comment)
            .map((match) => ['r', match.group(0)!, 'mention']),
      ];

      final cancel = BotToastUtils.showLoading();

      try {
        final event = await Event.genEvent(
          kind: EventKind.HIGHLIGHT,
          tags: tags,
          content: selectedText.trim(),
          signer: signer.value,
        );
        if (event == null) {
          BotToastUtils.showError(
            context.t.errorGeneratingEvent.capitalizeFirst(),
          );
          return;
        }

        final sent = await NostrFunctionsRepository.sendEvent(
          event: event,
          relays: await broadcastRelays(highlightSource.pubkey),
          setProgress: true,
          destinationPubkey: highlightSource.pubkey,
        );
        if (sent) {
          BotToastUtils.showSuccess(context.t.highlights.capitalizeFirst());
          if (context.mounted) {
            Navigator.pop(context);
          }
        } else {
          BotToastUtils.showError(
              context.t.errorSendingEvent.capitalizeFirst());
        }
      } finally {
        cancel();
        isPublishing.value = false;
      }
    }

    return BlocProvider(
      create: (_) => WriteNoteCubit(null, isMention: false, isQuote: false),
      child: ModalSheetContainer(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const Center(child: ModalBottomSheetHandle()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppIconButton(
                      icon: LucideIcons.x,
                      onClicked: () => Navigator.pop(context),
                    ),
                    Text(
                      context.t.highlights.capitalizeFirst(),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    AppIconButton(
                      icon: FeatureIcons.send,
                      iconSize: kDefaultPadding,
                      iconColor: kWhite,
                      backgroundColor: Theme.of(context).primaryColor,
                      onClicked: isResolvingContext ? null : publish,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              if (isExternalSource) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                  ),
                  child: TextField(
                    controller: sourceUrlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: '${context.t.source} ${context.t.url}',
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding / 2),
                if (isResolvingContext)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: kDefaultPadding / 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitCircle(
                          color: Theme.of(context).primaryColor,
                          size: kDefaultPadding,
                        ),
                        const SizedBox(width: kDefaultPadding / 2),
                        Text(context.t.loading),
                      ],
                    ),
                  ),
              ],
              Expanded(
                child: NoteWritingComponent(
                  controller: controller,
                  scheduled: scheduled,
                  scrollController: scrollController,
                  signer: signer,
                  onSignerChanged: (value) => signer.value = value,
                  enableMedia: false,
                  enableEnergyMapper: false,
                  attachment: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding / 2,
                    ),
                    child: _ComposerHighlightPreview(
                      text: selectedText,
                      paragraphContext: paragraphContext,
                      source: source ??
                          Nip84HighlightSource.external(
                            url: sourceUrlController.text,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _selectedParagraphContext(String source, String selectedText) {
  final exact = selectedText.trim();
  final selectionStart = source.indexOf(exact);

  if (exact.isEmpty || selectionStart < 0) {
    return null;
  }

  final beforeSelection = source.substring(0, selectionStart);
  final paragraphBreaks =
      RegExp(r'\r?\n\s*\r?\n').allMatches(beforeSelection).toList();
  final paragraphStart = paragraphBreaks.isEmpty ? 0 : paragraphBreaks.last.end;
  final afterSelection = source.substring(selectionStart + exact.length);
  final nextParagraphBreak =
      RegExp(r'\r?\n\s*\r?\n').firstMatch(afterSelection);
  final paragraphEnd = nextParagraphBreak == null
      ? source.length
      : selectionStart + exact.length + nextParagraphBreak.start;
  final paragraph = source.substring(paragraphStart, paragraphEnd).trim();

  return paragraph == exact ? null : paragraph;
}

class _ComposerHighlightPreview extends StatelessWidget {
  const _ComposerHighlightPreview({
    required this.text,
    required this.source,
    required this.paragraphContext,
  });

  final String text;
  final Nip84HighlightSource source;
  final String? paragraphContext;

  Widget _quote(BuildContext context) {
    final theme = Theme.of(context);
    final exact = text.trim();
    final paragraph = paragraphContext;
    final offset = paragraph?.indexOf(exact) ?? -1;
    if (paragraph == null || offset < 0) {
      return SelectableText(
        exact,
        style:
            theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
      );
    }
    return SelectableText.rich(
      TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        children: [
          TextSpan(text: paragraph.substring(0, offset)),
          TextSpan(
            text: exact,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.22),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: paragraph.substring(offset + exact.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (source.isExternal) {
      final label = source.url?.isEmpty ?? true
          ? context.t.source.capitalizeFirst()
          : source.url!;
      return HighlightContainer(
        header: Text(
          '${context.t.highlightedFrom} $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        content: _quote(context),
        footer: source.url?.isEmpty ?? true
            ? null
            : HighlightSourceFooter(
                label: source.url!,
                showExternalLink: true,
              ),
      );
    }

    return SingleEventProvider(
      id: source.isReplaceable ? source.identifier! : source.id!,
      isReplaceable: source.isReplaceable,
      author: source.isReplaceable ? source.pubkey : null,
      child: (event) => HighlightContainer(
        header: _header(context, event),
        content: _quote(context),
        footer: HighlightSourceFooter(
          label: '$baseUrl${_encoded(event)}',
          showExternalLink: true,
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Event? event) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          LucideIcons.highlighter,
          size: kDefaultPadding * 1.3,
          color: theme.primaryColor,
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Expanded(
          child: event == null
              ? Text(
                  '${context.t.highlightedFrom} ${source.reference}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  spacing: kDefaultPadding / 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.t.highlightedFrom,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: kDefaultPadding / 2),
                        MetadataProvider(
                          pubkey: event.pubkey,
                          child: (metadata, _) => ProfilePicture3(
                            image: metadata.picture,
                            pubkey: metadata.pubkey,
                            size: kDefaultPadding + 2,
                            padding: 0,
                            strokeWidth: 0,
                            strokeColor: kTransparent,
                            onClicked: () {},
                          ),
                        ),
                      ],
                    ),
                    _sourceLabel(context, event),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sourceLabel(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    if (event.kind == EventKind.LONG_FORM) {
      final title = Article.fromEvent(event).title.trim();
      return _sourceLabelText(
        context,
        context.t.article.capitalizeFirst(),
        title.isEmpty ? context.t.untitledArticle : title,
        style,
      );
    }
    final excerpt = event.content.replaceAll(RegExp(r'\s+'), ' ').trim();
    final truncated =
        excerpt.length > 100 ? '${excerpt.substring(0, 100)}…' : excerpt;
    return _sourceLabelText(
      context,
      context.t.note.capitalizeFirst(),
      truncated.isEmpty ? context.t.untitledNote : truncated,
      style,
    );
  }

  Widget _sourceLabelText(
    BuildContext context,
    String type,
    String label,
    TextStyle? style,
  ) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '[$type] ',
            style: style?.copyWith(color: theme.highlightColor),
          ),
          TextSpan(
            text: label,
            style: style?.copyWith(color: theme.primaryColorDark),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _encoded(Event? event) {
    if (event == null) {
      return source.encoded;
    }
    final relays = event.seenOn;
    if (source.isReplaceable && event.dTag != null && event.dTag!.isNotEmpty) {
      final identifier =
          event.dTag!.runes.map((code) => code.toRadixString(16)).join();
      return Nip19.encodeShareableEntity(
        'naddr',
        identifier,
        relays,
        event.pubkey,
        event.kind,
      );
    }
    return Nip19.encodeShareableEntity(
      'nevent',
      event.id,
      relays,
      event.pubkey,
      event.kind,
    );
  }
}

class Nip84HighlightSource {
  const Nip84HighlightSource.note({
    required this.id,
    required this.pubkey,
  })  : identifier = null,
        url = null,
        isReplaceable = false;

  const Nip84HighlightSource.article({
    required this.id,
    required this.pubkey,
    required this.identifier,
  })  : url = null,
        isReplaceable = true;

  const Nip84HighlightSource.external({
    required this.url,
  })  : id = null,
        pubkey = null,
        identifier = null,
        isReplaceable = false;

  final String? id;
  final String? pubkey;
  final String? identifier;
  final String? url;
  final bool isReplaceable;

  bool get isExternal => url != null;

  static Nip84HighlightSource? tryExternal(String url) {
    final cleaned = _cleanExternalUrl(url);
    return cleaned == null ? null : Nip84HighlightSource.external(url: cleaned);
  }

  List<String> toTag(List<String> relays) {
    if (isExternal) {
      return ['r', url!, 'source'];
    }

    if (isReplaceable) {
      return ['a', '${EventKind.LONG_FORM}:$pubkey:$identifier'];
    }
    return ['e', id!, if (relays.isNotEmpty) relays.first];
  }

  String get reference => isExternal
      ? url!
      : isReplaceable
          ? '${EventKind.LONG_FORM}:$pubkey:$identifier'
          : id!;

  String get encoded {
    if (isExternal) {
      return url!;
    }

    if (isReplaceable) {
      final identifierHex =
          identifier!.runes.map((code) => code.toRadixString(16)).join();
      return Nip19.encodeShareableEntity(
        'naddr',
        identifierHex,
        const [],
        pubkey,
        EventKind.LONG_FORM,
      );
    }
    return Nip19.encodeShareableEntity(
      'nevent',
      id!,
      const [],
      pubkey,
      EventKind.TEXT_NOTE,
    );
  }
}

String? _cleanExternalUrl(String value) {
  final parsed = Uri.tryParse(value.trim());
  if (parsed == null ||
      !parsed.hasAuthority ||
      (parsed.scheme != 'http' && parsed.scheme != 'https')) {
    return null;
  }

  const trackerKeys = {
    'fbclid',
    'gclid',
    'mc_cid',
    'mc_eid',
    'ref',
    'ref_src',
  };
  final query = Map<String, String>.from(parsed.queryParameters)
    ..removeWhere(
      (key, _) =>
          key.toLowerCase().startsWith('utm_') ||
          trackerKeys.contains(key.toLowerCase()),
    );
  return parsed.replace(fragment: '', queryParameters: query).toString();
}
