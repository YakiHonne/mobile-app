import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/logic/main_cubit/desktop_link_channel.dart';

const _channelName = 'yakihonne/link_readiness';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> nativeCalls;

  setUp(() {
    nativeCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(_channelName),
      (call) async {
        nativeCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(_channelName), null);
  });

  Future<void> nativeLink(String value) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      _channelName,
      const StandardMethodCodec()
          .encodeMethodCall(MethodCall('link', value)),
      (_) {},
    );
  }

  test('ready is sent to the native runner', () async {
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    await channel.ready();
    expect(nativeCalls.single.method, 'ready');
  });

  test('ready swallows a missing native handler', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(_channelName), null);
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    await channel.ready();
  });

  test('a link that arrives before the listener is buffered once', () async {
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    await nativeLink('nostr:npub1early');
    final received = <Uri>[];
    final subscription = channel.links.listen(received.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    expect(received.map((uri) => uri.toString()), ['nostr:npub1early']);
    // A later retry does not redeliver the buffered link.
    await Future<void>.delayed(Duration.zero);
    expect(received.length, 1);
  });

  test('multiple rapid links keep order', () async {
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    final received = <String>[];
    final subscription =
        channel.links.listen((uri) => received.add(uri.toString()));
    addTearDown(subscription.cancel);
    await nativeLink('nostr:note1a');
    await nativeLink('nostr:note1b');
    await nativeLink('nostr:note1c');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['nostr:note1a', 'nostr:note1b', 'nostr:note1c']);
  });

  test('early links keep order and are bounded', () async {
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    for (var i = 0; i < 25; i++) {
      await nativeLink('nostr:note$i');
    }
    final received = <String>[];
    final subscription =
        channel.links.listen((uri) => received.add(uri.toString()));
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    // The oldest 5 are dropped once the 20-slot buffer overflows.
    expect(received.length, 20);
    expect(received.first, 'nostr:note5');
    expect(received.last, 'nostr:note24');
  });

  test('non-Nostr and malformed values are ignored', () async {
    final channel = DesktopLinkChannel();
    addTearDown(channel.dispose);
    final received = <Uri>[];
    final subscription = channel.links.listen(received.add);
    addTearDown(subscription.cancel);
    await nativeLink('https://example.com/not-a-nostr-link');
    await nativeLink('');
    await nativeLink('nostr:note1valid');
    await Future<void>.delayed(Duration.zero);
    expect(received.map((uri) => uri.toString()), ['nostr:note1valid']);
  });

  test('links after dispose are dropped without throwing', () async {
    final channel = DesktopLinkChannel();
    await channel.dispose();
    await nativeLink('nostr:note1late');
  });
}
