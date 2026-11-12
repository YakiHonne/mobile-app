import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/logic/unsent_events_cubit/unsent_events_cubit.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/utils/utils.dart';

class _Connectivity implements Connectivity {
  final changes = StreamController<List<ConnectivityResult>>.broadcast();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.none];
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('failed delivery remains queued and acknowledged retry removes it',
      () async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDatabaseRepository = LocalDatabaseRepository();
    final platform = _Connectivity();
    connectivityService = ConnectivityService(
      repository: ConnectivityRepository(connectivity: platform),
    );
    var sent = false;
    final attemptedRelays = <List<String>?>[];
    final cubit = UnsentEventsCubit(sendEvent: (event, relays) async {
      attemptedRelays.add(relays);
      return sent;
    });
    final event = Event(
      id: 'disposable',
      pubkey: '',
      createdAt: 0,
      kind: 1,
      content: 'fixture',
      tags: [],
      sig: '',
    );
    cubit.addUnsentEvent(event);
    cubit.hasConnection = true;
    await cubit.processUnsentEvents();
    expect(cubit.state.events, contains('disposable'));
    expect(attemptedRelays.single, isNull);

    sent = true;
    await cubit.processUnsentEvents();
    expect(cubit.state.events, isEmpty);
    await cubit.close();
    await connectivityService.dispose();
    await platform.changes.close();
  });
}
