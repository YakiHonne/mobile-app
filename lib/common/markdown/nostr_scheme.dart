// ignore_for_file: public_member_api_docs, sort_constructors_first, depend_on_referenced_packages
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../utils/utils.dart';
import '../../views/article_view/article_view.dart';
import '../../views/curation_view/curation_view.dart';
import '../../views/profile_view/profile_view.dart';
import '../../views/smart_widgets_view/widgets/global_smart_widget_container.dart';
import '../../views/widgets/article_container.dart';
import '../../views/widgets/common_thumbnail.dart';
import '../../views/widgets/content_renderer/content_renderer.dart';
import '../../views/widgets/data_providers.dart';
import '../../views/widgets/note_container.dart';
import '../../views/widgets/profile_picture.dart';
import '../common_regex.dart';

SpanNodeGeneratorWithTag nostrGenerator = SpanNodeGeneratorWithTag(
  tag: _nostrTag,
  generator: (e, config, visitor) => NostrNode(
    e.attributes,
    e.textContent,
    config,
  ),
);

const _nostrTag = 'nostr';

class NostrSyntax extends m.InlineSyntax {
  NostrSyntax()
      : super(
          nostrSchemeRegex.pattern,
          caseSensitive: false,
        );

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input.toLowerCase();

    final matchValue = input.substring(match.start, match.end);
    String content = '';

    const initial = 'nostr:';

    if (matchValue.startsWith(initial)) {
      content = matchValue.substring(6, matchValue.length);
    } else {
      content = matchValue;
    }

    final m.Element el = m.Element.text(_nostrTag, matchValue);
    el.attributes['content'] = content;

    parser.addNode(el);
    return true;
  }
}

class NostrNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  NostrNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final map = getMap(content);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: getView(nostrDecode: map),
    );
  }

  Map<String, dynamic> getMap(String content) {
    try {
      final RegExpMatch? selectedMatch = Nip19.nip19regex.firstMatch(content);
      final key = selectedMatch!.group(2)! + selectedMatch.group(3)!;
      Map<String, dynamic> map = {};

      if (selectedMatch.group(2) == 'npub1') {
        map['prefix'] = 'npub';
        map['special'] = Nip19.decodePubkey(key);
      } else if (selectedMatch.group(2) == 'note1') {
        map['prefix'] = 'note';
        map['special'] = Nip19.decodeNote(key);
      } else {
        map = Nip19.decodeShareableEntity(key);
      }

      return map;
    } catch (_) {
      return {};
    }
  }

  Widget getView({
    required Map<String, dynamic> nostrDecode,
  }) {
    if (nostrDecode['prefix'] == 'nprofile' ||
        nostrDecode['prefix'] == 'npub') {
      if (nostrDecode['special'] == '') {
        return RegularText(text: attributes['content'] ?? '');
      } else {
        return ArticleNprofile(
          pubkey: nostrDecode['special'],
        );
      }
    } else if (nostrDecode['prefix'] == 'note' ||
        nostrDecode['prefix'] == 'nevent') {
      return ArticleNote(
        noteId: nostrDecode['special'],
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.LONG_FORM) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.article,
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.CURATION_ARTICLES) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.curation,
      );
    } else if (nostrDecode['prefix'] == 'naddr' &&
        nostrDecode['kind'] == EventKind.SMART_WIDGET_ENH) {
      final hexCode = hex.decode(nostrDecode['special']);
      final id = String.fromCharCodes(hexCode);

      return NaddrArticleContainer(
        eventId: id,
        pubkey: nostrDecode['author'],
        naddrType: ArticleNaddrTypes.smart,
      );
    } else {
      return RegularText(text: attributes['content'] ?? '');
    }
  }
}

class RegularText extends StatelessWidget {
  final String text;

  const RegularText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class ArticleNprofile extends StatelessWidget {
  const ArticleNprofile({
    super.key,
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, nip05) => OptimizedMetadataContainer(
        metadata: metadata,
        onOpen: () => openProfileFastAccess(
          context: context,
          pubkey: pubkey,
        ),
        linkStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).primaryColor,
            ),
      ),

      // Center(
      //   child: ArticleUserMention(
      //     metadata: metadata,
      //     onClicked: () => Navigator.pushNamed(
      //       context,
      //       ProfileView.routeName,
      //       arguments: [pubkey],
      //     ),
      //   ),
      // ),
    );
  }
}

class ArticleUserMention extends StatelessWidget {
  const ArticleUserMention({
    super.key,
    required this.metadata,
    required this.onClicked,
  });

  final Metadata metadata;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
        child: Row(
          children: [
            ProfilePicture2(
              image: metadata.picture,
              pubkey: metadata.pubkey,
              size: 30,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.getName(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metadata.about.isNotEmpty)
                    Text(
                      metadata.about,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: Theme.of(context).highlightColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NaddrArticleContainer extends HookWidget {
  const NaddrArticleContainer({
    super.key,
    required this.pubkey,
    required this.eventId,
    required this.naddrType,
  });

  final String pubkey;
  final String eventId;
  final ArticleNaddrTypes naddrType;

  @override
  Widget build(BuildContext context) {
    useMemoized(
      () {
        metadataCubit.requestMetadata(pubkey);
      },
    );

    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, nip05) {
        return SingleEventProvider(
          id: eventId,
          isReplaceable: true,
          child: (event) {
            final component = event != null
                ? naddrType == ArticleNaddrTypes.article
                    ? Article.fromEvent(event)
                    : naddrType == ArticleNaddrTypes.curation
                        ? Curation.fromEvent(event, '')
                        : SmartWidget.fromEvent(event)
                : null;

            if (component == null) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                  color: Theme.of(context).primaryColorLight,
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'This is ${naddrType == ArticleNaddrTypes.article ? 'an article' : naddrType == ArticleNaddrTypes.article ? 'a curation' : 'a smart widget'} event',
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'By: ',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ProfileView.routeName,
                                arguments: [metadata.pubkey],
                              );
                            },
                            child: Text(
                              metadata.getName(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(
                                    color: kMainColor,
                                  ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }

            if (naddrType == ArticleNaddrTypes.smart) {
              final sm = component as SmartWidget;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 4,
                ),
                child: GlobalSmartWidgetContainer(
                  smartWidgetModel: sm,
                  disableActions: true,
                ),
              );
            } else {
              DateTime createdAt;
              DateTime publishedAt;
              String title;
              String about;
              String backgroundImage;
              String placeHolder;

              if (naddrType == ArticleNaddrTypes.article) {
                final article = component as Article;
                createdAt = article.createdAt;
                publishedAt = article.publishedAt;
                title = article.title;
                about = article.summary;
                backgroundImage = article.image;
                placeHolder = article.placeholder;
              } else {
                final curation = component as Curation;
                createdAt = curation.createdAt;
                publishedAt = curation.publishedAt;
                title = curation.title;
                about = curation.description;
                backgroundImage = curation.image;
                placeHolder = curation.placeHolder;
              }

              return GestureDetector(
                onTap: () {
                  if (naddrType == ArticleNaddrTypes.article) {
                    Navigator.pushNamed(
                      context,
                      ArticleView.routeName,
                      arguments: component as Article,
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      CurationView.routeName,
                      arguments: component as Curation,
                    );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kDefaultPadding + 5),
                    color: Theme.of(context).cardColor,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: kDefaultPadding,
                            ),
                            foregroundDecoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).cardColor,
                                  kTransparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                stops: const [
                                  0.1,
                                  0.5,
                                ],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(kDefaultPadding),
                                topRight: Radius.circular(kDefaultPadding),
                              ),
                              child: CommonThumbnail(
                                image: backgroundImage,
                                placeholder: placeHolder,
                                width: double.infinity,
                                height: 70,
                                radius: 0,
                                isRound: false,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: kDefaultPadding / 2,
                                ),
                                child: ProfilePicture2(
                                  size: 60,
                                  image: metadata.picture,
                                  pubkey: metadata.pubkey,
                                  padding: 0,
                                  strokeWidth: 3,
                                  strokeColor: Theme.of(context).cardColor,
                                  onClicked: () {},
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: kDefaultPadding / 2,
                                  top: kDefaultPadding / 2,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: kDefaultPadding / 4,
                                    horizontal: kDefaultPadding / 2,
                                  ),
                                  child: Text(
                                    naddrType == ArticleNaddrTypes.article
                                        ? 'Article'
                                        : 'Curation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: kMainColor,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: kDefaultPadding / 2,
                                ),
                                child: Text(
                                  metadata.getName(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: kDefaultPadding,
                          right: kDefaultPadding,
                          bottom: kDefaultPadding,
                          top: kDefaultPadding / 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (metadata.about.isNotEmpty) ...[
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              Text(
                                about,
                                style: Theme.of(context).textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                              PublishDateRow(
                                createdAtDate: createdAt,
                                publishedAtDate: publishedAt,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class ArticleNote extends StatelessWidget {
  const ArticleNote({
    super.key,
    required this.noteId,
  });

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return SingleEventProvider(
      id: noteId,
      isReplaceable: false,
      child: (event) {
        final note = event != null ? DetailedNoteModel.fromEvent(event) : null;

        if (note == null) {
          return Text(Nip19.encodeNote(noteId));
        }

        return NoteContainer(note: note);
      },
    );
  }

  Widget getView({
    required BuildContext context,
    required DetailedNoteModel note,
    required Metadata metadata,
  }) {
    final noteRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePicture2(
          image: metadata.picture,
          pubkey: metadata.pubkey,
          size: 35,
          padding: 3,
          strokeWidth: 1,
          strokeColor: Theme.of(context).primaryColorDark,
          onClicked: () {
            openProfileFastAccess(context: context, pubkey: metadata.pubkey);
          },
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metadata.getName(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dateFormat3.format(note.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Divider(
                height: kDefaultPadding,
              ),
              ParsedText(text: note.content),
            ],
          ),
        ),
      ],
    );

    return noteRow;
  }
}
