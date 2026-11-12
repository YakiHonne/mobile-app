import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';

class FakeConnectivity implements Connectivity {
  final changes = StreamController<List<ConnectivityResult>>.broadcast();
  final initial = Completer<List<ConnectivityResult>>();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => initial.future;
}

void main() {
  test('initial check reports available interfaces once', () async {
    final platform = FakeConnectivity();
    final repository = ConnectivityRepository(connectivity: platform);
    final changes = <bool>[];
    final subscription =
        repository.connectivityChangeStream.listen(changes.add);

    platform.initial.complete([ConnectivityResult.vpn]);
    await Future<void>.delayed(Duration.zero);
    platform.changes.add([ConnectivityResult.other]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.hasConnection, isTrue);
    expect(changes, [true]);

    await subscription.cancel();
    await repository.dispose();
    await platform.changes.close();
  });

  test('a stale initial check cannot override a newer offline event', () async {
    final platform = FakeConnectivity();
    final repository = ConnectivityRepository(connectivity: platform);
    final changes = <bool>[];
    final subscription =
        repository.connectivityChangeStream.listen(changes.add);

    platform.changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    platform.changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    platform.initial.complete([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.hasConnection, isFalse);
    expect(changes, [true, false]);

    await subscription.cancel();
    await repository.dispose();
    await platform.changes.close();
  });
  test('DNS failure does not change known interface availability', () async {
    final platform = FakeConnectivity();
    final repository = ConnectivityRepository(
      connectivity: platform,
      lookup: (_) async => [],
    );
    expect(repository.hasKnownConnection, isFalse);
    platform.initial.complete([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.hasKnownConnection, isTrue);
    expect(await repository.checkInternetConnection(), isFalse);
    expect(repository.hasConnection, isTrue);
    await repository.dispose();
    await platform.changes.close();
  });
  test('platform errors mark status unknown without inventing a transition',
      () async {
    final platform = FakeConnectivity();
    final repository = ConnectivityRepository(connectivity: platform);
    final changes = <bool>[];
    final subscription =
        repository.connectivityChangeStream.listen(changes.add);
    platform.initial.complete([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    platform.changes.addError(StateError('fixture'));
    await Future<void>.delayed(Duration.zero);
    expect(repository.hasKnownConnection, isFalse);
    platform.changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.hasKnownConnection, isTrue);
    expect(changes, [true]);
    await subscription.cancel();
    await repository.dispose();
    await platform.changes.close();
  });
}
