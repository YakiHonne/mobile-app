import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_core_enhanced/nostr_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakihonne/globals.dart';
import 'package:yakihonne/logic/settings_cubit/settings_cubit.dart';
import 'package:yakihonne/models/app_models/settings_data.dart';
import 'package:yakihonne/repositories/account_storage_snapshot.dart';
import 'package:yakihonne/repositories/localdatabase_repository.dart';
import 'package:yakihonne/repositories/nostr_data_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDatabaseRepository = LocalDatabaseRepository();
  });

  test('desktop initialization loads legacy accounts without writing',
      () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'disposable-public-key'}),
      'keys_is_private_map': jsonEncode({'0': false}),
    };
    var writes = 0;
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: AccountSnapshotStore(
        read: (key) async => data[key],
        write: (key, value) async => writes++,
      ),
    );
    addTearDown(cubit.close);
    await cubit.init();
    expect(cubit.keyMap, {'0': 'disposable-public-key'});
    expect(writes, 0);
  });

  test('a failed desktop read stops initialization without writing', () async {
    var writes = 0;
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: AccountSnapshotStore(
        read: (key) async {
          if (key == 'keys_is_private_map') {
            throw StateError('locked');
          }
          return key == 'private_keys_map'
              ? jsonEncode({'0': 'disposable-public-key'})
              : null;
        },
        write: (key, value) async => writes++,
      ),
    );
    addTearDown(cubit.close);
    await expectLater(cubit.init(), throwsStateError);
    expect(cubit.keyMap, isEmpty);
    expect(writes, 0);
  });

  test('failed account removal leaves the active account in memory', () async {
    await prefs.setString(
      'settings',
      jsonEncode(SettingData(privateKeyIndex: 0).toJson()),
    );
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'disposable-public-key'}),
      'keys_is_private_map': jsonEncode({'0': false}),
    };
    var errors = 0;
    var popped = false;
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      storageErrorHandler: () => errors++,
      accountStore: AccountSnapshotStore(
        read: (key) async => data[key],
        write: (_, __) async => throw StateError('write failed'),
      ),
    );
    addTearDown(cubit.close);
    await cubit.init();
    await cubit.onLogoutTap(0, onPop: () => popped = true);
    expect(cubit.keyMap, {'0': 'disposable-public-key'});
    expect(cubit.privateKeyIndex, 0);
    expect(errors, 1);
    expect(popped, isFalse);
    expect(data.containsKey(AccountSnapshotStore.snapshotKey), isFalse);
  });

  test('failed account addition does not publish an account', () async {
    nostrRepository = NostrDataRepository();
    var errors = 0;
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      storageErrorHandler: () => errors++,
      accountStore: AccountSnapshotStore(
        read: (_) async => null,
        write: (_, __) async => throw StateError('write failed'),
      ),
    );
    addTearDown(cubit.close);
    await cubit.init();
    await expectLater(
      cubit.addAndChangeKey('disposable-public-key', false, false),
      throwsStateError,
    );
    expect(cubit.keyMap, isEmpty);
    expect(cubit.privateKeyIndex, isNull);
    expect(errors, 1);
  });

  test('removing another account saves the complete snapshot first', () async {
    await prefs.setString(
      'settings',
      jsonEncode(SettingData(privateKeyIndex: 0).toJson()),
    );
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first', '1': 'second'}),
      'keys_is_private_map': jsonEncode({'0': false, '1': false}),
    };
    var popped = false;
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    final cubit =
        SettingsCubit(desktopStorageOverride: true, accountStore: store);
    addTearDown(cubit.close);
    await cubit.init();
    await cubit.onLogoutTap(1, onPop: () => popped = true);
    final stored = await store.load();
    expect(stored.keys, {'0': 'first'});
    expect(stored.activeIndex, 0);
    expect(cubit.keyMap, {'0': 'first'});
    expect(popped, isTrue);
    expect(data['private_keys_map'], isNull);
  });

  test('overlapping account changes cannot save stale maps', () async {
    await prefs.setString(
      'settings',
      jsonEncode(SettingData(privateKeyIndex: 0).toJson()),
    );
    final data = <String, String>{
      'private_keys_map':
          jsonEncode({'0': 'first', '1': 'second', '2': 'third'}),
      'keys_is_private_map': jsonEncode({'0': false, '1': false, '2': false}),
    };
    final started = Completer<void>();
    final release = Completer<void>();
    var errors = 0;
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async {
        started.complete();
        await release.future;
        data[key] = value;
      },
    );
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: store,
      storageErrorHandler: () => errors++,
    );
    addTearDown(cubit.close);
    await cubit.init();
    final first = cubit.onLogoutTap(1, onPop: () {});
    await started.future;
    await cubit.onLogoutTap(2, onPop: () {});
    release.complete();
    await first;
    expect(errors, 1);
    expect(cubit.keyMap, {'0': 'first', '2': 'third'});
    expect((await store.load()).keys, cubit.keyMap);
  });

  test('uncertain removal requires restart and reloads the saved outcome',
      () async {
    await prefs.setString(
      'settings',
      jsonEncode(SettingData(privateKeyIndex: 0).toJson()),
    );
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first', '1': 'second'}),
      'keys_is_private_map': jsonEncode({'0': false, '1': false}),
    };
    var errors = 0;
    var uncertain = true;
    AccountSnapshotStore newStore() => AccountSnapshotStore(
          read: (key) async => data[key],
          write: (key, value) async {
            data[key] = value;
            if (uncertain) {
              throw StateError('outcome unknown');
            }
          },
          delete: (key) async => data.remove(key),
        );
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: newStore(),
      storageErrorHandler: () => errors++,
    );
    addTearDown(cubit.close);
    await cubit.init();
    await cubit.onLogoutTap(1, onPop: () {});
    expect(cubit.keyMap, {'0': 'first', '1': 'second'});
    await cubit.onLoginTap(1, () {});
    expect(errors, 2);
    expect(cubit.privateKeyIndex, 0);

    uncertain = false;
    final restarted = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: newStore(),
    );
    addTearDown(restarted.close);
    await restarted.init();
    expect(restarted.keyMap, {'0': 'first'});
    expect(restarted.privateKeyIndex, 0);
  });

  test('remote signer removal follows a verified account save', () async {    await prefs.setString(
      'settings',
      jsonEncode(SettingData(privateKeyIndex: 0).toJson()),
    );
    nc = NostrCore(loadRemoteCache: false);
    nostrRepository = NostrDataRepository();
    final remoteKey = '2' * 64;
    final signer = jsonEncode({
      'secret': '1' * 64,
      'relays': 'wss://example.invalid',
      'bunkerPubkey': '3' * 64,
      'publicKey': remoteKey,
      'connectionSecret': 'fixture',
    });
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first', '1': remoteKey}),
      'keys_is_private_map': jsonEncode({'0': false, '1': false}),
      'keys_is_external_map': jsonEncode({'1': true}),
      'external_keys_map': jsonEncode({'1': 'Bunker'}),
      'remote_signers_map': jsonEncode([signer]),
    };
    await nostrRepository.loadRemoteSigners(
        storedSigners: jsonEncode([signer]));
    var failWrite = true;
    AccountSnapshotStore newStore() => AccountSnapshotStore(
          read: (key) async => data[key],
          write: (key, value) async {
            if (failWrite) {
              throw StateError('locked');
            }
            data[key] = value;
          },
          delete: (key) async => data.remove(key),
        );
    final failed = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: newStore(),
      storageErrorHandler: () {},
    );
    addTearDown(failed.close);
    await failed.init();
    await failed.onLogoutTap(1, onPop: () {});
    expect(failed.keyMap['1'], remoteKey);
    expect(nostrRepository.remoteSigners.containsKey(remoteKey), isTrue);
    expect(data['remote_signers_map'], jsonEncode([signer]));

    failWrite = false;
    final restarted = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: newStore(),
    );
    addTearDown(restarted.close);
    await restarted.init();
    await restarted.onLogoutTap(1, onPop: () {});
    expect(nostrRepository.remoteSigners.containsKey(remoteKey), isFalse);
    final snapshot = await newStore().load();
    expect(snapshot.keys, {'0': 'first'});
    expect(snapshot.remoteSigners, isEmpty);
    expect(data['remote_signers_map'], isNull);
  });

  test('corrupt startup snapshot exposes recovery instead of empty accounts',
      () async {
    final data = <String, String>{
      AccountSnapshotStore.snapshotKey: '{bad',
      'private_keys_map': jsonEncode({'0': 'first'}),
    };
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: AccountSnapshotStore(
        read: (key) async => data[key],
        write: (key, value) async => data[key] = value,
      ),
    );
    addTearDown(cubit.close);
    await expectLater(cubit.init(), throwsA(isA<Object>()));
    expect(
      cubit.pendingRecovery?.reason,
      AccountRecoveryReason.corruptSnapshot,
    );
    expect(cubit.keyMap, isEmpty);
    // Nothing was deleted or overwritten while showing the prompt.
    expect(data[AccountSnapshotStore.snapshotKey], '{bad');
    expect(data['private_keys_map'], isNotNull);
  });

  test('restoring a backup from the recovery prompt loads those accounts',
      () async {
    final data = <String, String>{};
    AccountSnapshotStore newStore() => AccountSnapshotStore(
          read: (key) async => data[key],
          write: (key, value) async => data[key] = value,
        );
    final seeder = newStore();
    await seeder.load(legacyActiveIndex: 0);
    await seeder.save(AccountStorageSnapshot(
      keys: {'0': 'first-key', '1': 'second-key'},
      privateKeys: {'0': false, '1': false},
      externalSigners: {},
      externalTypes: {},
      pomegranateSetups: {},
      activeIndex: 0,
    ));
    await seeder.save(AccountStorageSnapshot(
      keys: {'0': 'first-key'},
      privateKeys: {'0': false},
      externalSigners: {},
      externalTypes: {},
      pomegranateSetups: {},
      activeIndex: 0,
    ));
    // Simulate a corrupt primary while a valid backup remains.
    data[AccountSnapshotStore.snapshotKey] = '{corrupt';

    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      accountStore: newStore(),
    );
    addTearDown(cubit.close);
    await expectLater(cubit.init(), throwsA(isA<Object>()));
    expect(cubit.pendingRecovery?.hasBackup, isTrue);
    await cubit.recoverFromBackup();
    expect(cubit.pendingRecovery, isNull);
    expect(cubit.keyMap.values, contains('first-key'));
  });

  test('diverged legacy data blocks mutations until recovered', () async {
    final data = <String, String>{};
    AccountSnapshotStore newStore() => AccountSnapshotStore(
          read: (key) async => data[key],
          write: (key, value) async => data[key] = value,
        );
    final seeder = newStore();
    await seeder.load(legacyActiveIndex: 0);
    await seeder.save(AccountStorageSnapshot(
      keys: {'0': 'saved-key'},
      privateKeys: {'0': false},
      externalSigners: {},
      externalTypes: {},
      pomegranateSetups: {},
      activeIndex: 0,
    ));
    // Older version writes legacy values afterwards.
    data['private_keys_map'] = jsonEncode({'0': 'legacy-key'});

    var errors = 0;
    final cubit = SettingsCubit(
      desktopStorageOverride: true,
      storageErrorHandler: () => errors++,
      accountStore: newStore(),
    );
    addTearDown(cubit.close);
    await expectLater(cubit.init(), throwsA(isA<Object>()));
    expect(cubit.pendingRecovery?.reason, AccountRecoveryReason.legacyChanged);
    await cubit.onLoginTap(0, () {});
    expect(errors, greaterThan(0));

    await cubit.recoverKeepSnapshot();
    expect(cubit.pendingRecovery, isNull);
    expect(cubit.keyMap.values, contains('saved-key'));
    expect(cubit.keyMap.values, isNot(contains('legacy-key')));
  });
}
