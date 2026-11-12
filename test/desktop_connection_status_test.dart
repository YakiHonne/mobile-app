import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:nostr_core_enhanced/utils/enums.dart';
import 'package:yakihonne/repositories/connectivity_repository.dart';
import 'package:yakihonne/utils/utils.dart';
import 'package:yakihonne/views/main_view/desktop/desktop_connection_status.dart';

class _Platform implements Connectivity {
  final changes = StreamController<List<ConnectivityResult>>.broadcast();
  final initial = Completer<List<ConnectivityResult>>();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() => initial.future;
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

class _Core implements NostrCore {
  @override
  final Map<String, int> connectStatus = {};
  @override
  void addConnectStatusListener(ConnectStatusCallBack callback) {}
  @override
  void removeConnectStatusListener(ConnectStatusCallBack callback) {}
  @override
  bool isWebSocketOpen(String url) => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('desktop status distinguishes unknown, offline and interfaces',
      (tester) async {
    final platform = _Platform();
    connectivityService = ConnectivityService(
      repository: ConnectivityRepository(connectivity: platform),
    );
    nc = _Core();
    currentUserRelayList = UserRelayList(
      pubkey: '',
      relays: {'wss://fixture.example': ReadWriteMarker.readWrite},
      createdAt: 0,
      refreshedTimestamp: 0,
    );
    await tester.pumpWidget(TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: DesktopConnectionStatus(compact: false),
          ),
        ),
      ),
    ));
    expect(find.textContaining('Unknown'), findsOneWidget);
    expect(find.textContaining('0/1'), findsOneWidget);
    platform.initial.complete([ConnectivityResult.none]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Offline'), findsOneWidget);
    platform.changes.add([ConnectivityResult.vpn]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Available'), findsOneWidget);
    expect(find.textContaining('0/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await connectivityService.dispose();
      await platform.changes.close();
    });
  });
}
