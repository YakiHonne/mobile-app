import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';
import 'package:yakihonne/i18n/translations/translations.g.dart';
import 'package:yakihonne/models/app_models/app_customization.dart';
import 'package:yakihonne/models/event_relation.dart';
import 'package:yakihonne/repositories/nostr_functions_repository.dart';
import 'package:yakihonne/utils/constants.dart';
import 'package:yakihonne/views/notifications_view/widgets/notification_event_quote.dart';

void main() {
  const recipient =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const highlighter =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  Event highlight(List<List<String>> tags, {String pubkey = highlighter}) =>
      Event.partial(
        pubkey: pubkey,
        kind: EventKind.HIGHLIGHT,
        content: 'Selected text',
        tags: tags,
      );

  test('accepts source authors including unmarked legacy p tags', () {
    for (final tag in [
      ['p', recipient, '', 'author'],
      ['p', recipient],
      ['p', recipient, 'wss://relay.example'],
      ['p', recipient, '', ''],
    ]) {
      expect(
        NostrFunctionsRepository.isHighlightForAuthor(
            highlight([tag]), recipient),
        isTrue,
      );
    }
  });

  test('rejects mentions, editors, unrelated users, malformed tags and self',
      () {
    for (final event in [
      highlight([
        ['p', recipient, '', 'mention']
      ]),
      highlight([
        ['p', recipient, '', 'editor']
      ]),
      highlight([
        ['p', highlighter, '', 'author']
      ]),
      highlight([
        ['p'],
        []
      ]),
      highlight([
        ['p', recipient, '', 'author']
      ], pubkey: recipient),
      Event.partial(tags: [
        ['p', recipient]
      ]),
    ]) {
      expect(
        NostrFunctionsRepository.isHighlightForAuthor(event, recipient),
        isFalse,
      );
    }
  });

  for (final source in [
    (tag: ['a', '30023:$recipient:article'], type: 'article'),
    (tag: ['e', highlighter], type: 'note'),
  ]) {
    testWidgets('names the ${source.type} source and separates the excerpt',
        (tester) async {
      final event = highlight([
        ['p', recipient, '', 'author'],
        source.tag,
      ]);
      final metadata =
          Metadata.empty(pubkey: highlighter).copyWith(name: 'Alice');
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: NotificationEventQuote(
                eventRelation: EventRelation.fromEvent(event),
                metadata: metadata,
                onRelatedEvent: (_) {},
                onClick: () {},
              ),
            ),
          ),
        ),
      );
      final description =
          find.text('Alice highlighted from your ${source.type}');
      final excerpt = find.text('Selected text');
      expect(description, findsOneWidget);
      expect(excerpt, findsOneWidget);
      expect(
        tester.getTopLeft(excerpt).dy - tester.getBottomLeft(description).dy,
        kDefaultPadding / 4,
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('old settings enable highlights and explicit preference survives reload',
      () {
    final legacy = AppCustomization(pubkey: recipient).toMap()
      ..remove('notifHighlights');
    expect(AppCustomization.fromMap(legacy).notifHighlights, isTrue);
    final disabled =
        AppCustomization(pubkey: recipient, notifHighlights: false);
    expect(
        AppCustomization.fromJson(disabled.toJson()).notifHighlights, isFalse);
  });

  test('highlight subscription is independent of mentions and preserves range',
      () {
    final customization = AppCustomization(
      pubkey: recipient,
      notifMentionsReplies: false,
      notifReactions: false,
      notifReposts: false,
      notifZaps: false,
    );
    final filters = NostrFunctionsRepository.getNotificationsFilter(
      pubkey: recipient,
      since: 100,
      until: 200,
      limit: 40,
      c: customization,
    ).whereType<Filter>().toList();
    expect(filters, hasLength(1));
    expect(filters.single.kinds, [EventKind.HIGHLIGHT]);
    expect(filters.single.p, [recipient]);
    expect(filters.single.since, 100);
    expect(filters.single.until, 200);
    expect(filters.single.limit, 40);

    customization.notifHighlights = false;
    expect(
      NostrFunctionsRepository.getNotificationsFilter(
        pubkey: recipient,
        c: customization,
      ).whereType<Filter>(),
      isEmpty,
    );
  });
}
