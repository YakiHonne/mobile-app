import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/logic/main_cubit/deep_link_listener.dart';

void main() {
  test('cold and running links share one delivery stream', () async {
    final links = StreamController<Uri>();
    final received = <DeepLinkKind>[];
    final listener = DeepLinkListener(
      links.stream,
      (uri) => received.add(classifyDeepLink(uri)),
    );
    links
      ..add(Uri.parse('nostr:npub1fixture'))
      ..add(Uri.parse('nostr+walletconnect://fixture?secret=disposable'))
      ..add(Uri.parse('https://yakihonne.com/lightning-wallet/alby?code=fake'));
    await Future<void>.delayed(Duration.zero);
    expect(received,
        [DeepLinkKind.other, DeepLinkKind.walletConnect, DeepLinkKind.alby]);
    await listener.dispose();
    await links.close();
  });

  test('an unrelated host cannot be mistaken for an Alby callback', () {
    expect(
      classifyDeepLink(
          Uri.parse('https://example.com/yakihonne.com/lightning-wallet/alby')),
      DeepLinkKind.other,
    );
  });
  test('queues a Nostr link until the main view is ready', () async {
    final links = StreamController<Uri>();
    final inbox = DeepLinkInbox(links.stream);
    final delivered = <Uri>[];
    Future<bool> handle(Uri uri) async {
      delivered.add(uri);
      return true;
    }

    links.add(Uri.parse('nostr:npub1fixture'));
    await Future<void>.delayed(Duration.zero);
    inbox.attach(handle);
    await Future<void>.delayed(Duration.zero);
    expect(delivered.single.toString(), 'nostr:npub1fixture');
    inbox.retry();
    await Future<void>.delayed(Duration.zero);
    expect(delivered.length, 1);
    inbox.detach(handle);
    await inbox.dispose();
    await links.close();
  });
  test('a repeated running link is not suppressed after startup', () async {
    final links = StreamController<Uri>();
    final uri = Uri.parse('nostr:npub1fixture');
    final inbox = DeepLinkInbox(links.stream, initialLink: uri);
    final received = <Uri>[];
    inbox.attach((link) async {
      received.add(link);
      return true;
    });
    links.add(uri);
    await Future<void>.delayed(Duration.zero);
    expect(received, [uri, uri]);
    links.add(uri);
    await Future<void>.delayed(Duration.zero);
    expect(received, [uri, uri, uri]);
    await inbox.dispose();
    await links.close();
  });

  test('multiple rapid links are delivered in order once attached', () async {
    final links = StreamController<Uri>();
    final inbox = DeepLinkInbox(links.stream);
    final received = <String>[];
    for (var i = 0; i < 5; i++) {
      links.add(Uri.parse('nostr:note1$i'));
    }
    await Future<void>.delayed(Duration.zero);
    inbox.attach((uri) async {
      received.add(uri.toString());
      return true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      'nostr:note10',
      'nostr:note11',
      'nostr:note12',
      'nostr:note13',
      'nostr:note14',
    ]);
    await inbox.dispose();
    await links.close();
  });

  test('a handler error does not block later links', () async {
    final links = StreamController<Uri>();
    final inbox = DeepLinkInbox(links.stream);
    final received = <String>[];
    inbox.attach((uri) async {
      received.add(uri.toString());
      if (uri.toString().endsWith('fail')) {
        throw StateError('bad link');
      }
      return true;
    });
    links
      ..add(Uri.parse('nostr:note1fail'))
      ..add(Uri.parse('nostr:note1ok'));
    await Future<void>.delayed(Duration.zero);
    expect(received, ['nostr:note1fail', 'nostr:note1ok']);
    await inbox.dispose();
    await links.close();
  });

  test('an early link is buffered while the handler is detached', () async {
    final links = StreamController<Uri>();
    final inbox = DeepLinkInbox(links.stream);
    final received = <String>[];
    Future<bool> handler(Uri uri) async {
      received.add(uri.toString());
      return true;
    }

    inbox.attach(handler);
    inbox.detach(handler);
    links.add(Uri.parse('nostr:note1later'));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    inbox.attach(handler);
    await Future<void>.delayed(Duration.zero);
    expect(received, ['nostr:note1later']);
    await inbox.dispose();
    await links.close();
  });
}
