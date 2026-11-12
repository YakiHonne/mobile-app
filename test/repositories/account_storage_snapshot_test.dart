import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/repositories/account_storage_snapshot.dart';

AccountStorageSnapshot emptySnapshot() => AccountStorageSnapshot(
      keys: {},
      privateKeys: {},
      externalSigners: {},
      externalTypes: {},
      pomegranateSetups: {},
    );

void main() {
  test('legacy reads do not write, including on a read failure', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'disposable-key'}),
    };
    var writes = 0;
    var fail = false;
    final store = AccountSnapshotStore(
      read: (key) async {
        if (fail && key == 'keys_is_private_map') {
          throw StateError('locked');
        }
        return data[key];
      },
      write: (key, value) async {
        writes++;
        data[key] = value;
      },
    );

    final snapshot = await store.load();
    expect(snapshot.keys, {'0': 'disposable-key'});
    fail = true;
    await expectLater(store.load(), throwsStateError);
    expect(writes, 0);
    expect(data['private_keys_map'], isNotNull);
  });

  test('a failed save propagates and preserves the previous snapshot',
      () async {
    final data = <String, String>{};
    var fail = false;
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async {
        if (fail) {
          throw StateError('unavailable');
        }
        data[key] = value;
      },
    );
    await store.save(await store.load());
    final previous = data[AccountSnapshotStore.snapshotKey];
    final next = emptySnapshot()..keys['0'] = 'disposable-key';
    fail = true;
    await expectLater(store.save(next), throwsStateError);
    expect(data[AccountSnapshotStore.snapshotKey], previous);
    expect((await store.load()).keys, isEmpty);
  });

  test('malformed snapshot requires explicit recovery, not a legacy fallback',
      () async {
    final data = <String, String>{
      AccountSnapshotStore.snapshotKey: '{bad',
      'private_keys_map': '{}',
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (_, __) async => fail('unexpected write'),
    );
    await expectLater(
      store.load(),
      throwsA(isA<AccountStorageRecoveryRequired>().having(
        (value) => value.reason,
        'reason',
        AccountRecoveryReason.corruptSnapshot,
      )),
    );
    expect(data['private_keys_map'], '{}');
  });

  test('uncertain writes require a reload before another save', () async {
    final data = <String, String>{};
    var failAfterWrite = true;
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async {
        data[key] = value;
        if (failAfterWrite) {
          throw StateError('outcome unknown');
        }
      },
    );
    final snapshot = await store.load();
    snapshot.keys['0'] = 'disposable-key';
    await expectLater(store.save(snapshot), throwsStateError);
    // The backend may have kept the value even though it reported failure.
    failAfterWrite = false;
    await expectLater(store.save(snapshot), throwsA(isA<AccountStorageConflict>()));
    final reloaded = await store.load();
    expect(reloaded.keys, {'0': 'disposable-key'});
    await store.save(reloaded);
  });

  test('active account and remote signer migrate with the maps', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'1': 'disposable-key'}),
      'remote_signers_map': jsonEncode(['disposable-signer']),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    final snapshot = await store.load(legacyActiveIndex: 1);
    await store.save(snapshot);
    final restored = await store.load(legacyActiveIndex: 0);
    expect(restored.activeIndex, 1);
    expect(restored.remoteSigners, ['disposable-signer']);
    expect(restored.keys, {'1': 'disposable-key'});
  });

  test('failed remote signer read blocks a later save', () async {
    final store = AccountSnapshotStore(
      read: (key) async {
        if (key == 'remote_signers_map') {
          throw StateError('locked');
        }
        return null;
      },
      write: (_, __) async => fail('unexpected write'),
    );
    await expectLater(store.load(), throwsStateError);
    await expectLater(store.save(emptySnapshot()), throwsStateError);
  });

  test('legacy account changes after migration require explicit recovery',
      () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first-key'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    await store.save(await store.load());
    data['private_keys_map'] = jsonEncode({'0': 'changed-by-older-version'});
    await expectLater(
      store.load(),
      throwsA(isA<AccountStorageRecoveryRequired>().having(
        (value) => value.reason,
        'reason',
        AccountRecoveryReason.legacyChanged,
      )),
    );
    await expectLater(store.save(emptySnapshot()), throwsA(anything));
  });

  test('verified migration resumes after interrupted legacy cleanup', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'disposable-key'}),
      'keys_is_private_map': jsonEncode({'0': true}),
    };
    var failCleanup = true;
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async {
        if (key == 'keys_is_private_map' && failCleanup) {
          throw StateError('cleanup failed');
        }
        data.remove(key);
      },
    );
    final snapshot = await store.load();
    await expectLater(store.save(snapshot), throwsStateError);
    expect(data[AccountSnapshotStore.snapshotKey], isNotNull);
    expect(data['private_keys_map'], isNull);
    expect(data['keys_is_private_map'], isNotNull);
    failCleanup = false;
    final restored = await store.load();
    await store.finishMigration();
    expect(restored.keys, {'0': 'disposable-key'});
    expect(restored.privateKeys, {'0': true});
    expect(data['keys_is_private_map'], isNull);
  });

  test('a write that cannot be read back leaves legacy data intact', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'disposable-key'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (_, __) async {},
      delete: (key) async => data.remove(key),
    );
    final snapshot = await store.load();
    await expectLater(store.save(snapshot), throwsStateError);
    expect(data['private_keys_map'], isNotNull);
  });

  test('legacy changes after load block saving and preserve both copies',
      () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    final snapshot = await store.load();
    data['private_keys_map'] = jsonEncode({'0': 'changed'});
    await expectLater(store.save(snapshot), throwsA(isA<LegacyAccountsChanged>()));
    expect(data['private_keys_map'], jsonEncode({'0': 'changed'}));
    expect(data[AccountSnapshotStore.snapshotKey], isNull);
  });

  test('legacy changes during migration are not deleted', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first'}),
      'keys_is_private_map': jsonEncode({'0': true}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async {
        data.remove(key);
        if (key == 'private_keys_map') {
          data['keys_is_private_map'] = jsonEncode({'0': false});
        }
      },
    );
    await expectLater(
        store.save(await store.load()), throwsA(isA<LegacyAccountsChanged>()));
    expect(data['keys_is_private_map'], jsonEncode({'0': false}));
    expect(data[AccountSnapshotStore.snapshotKey], isNotNull);
    await expectLater(
      store.load(),
      throwsA(isA<AccountStorageRecoveryRequired>()),
    );
  });

  test('save retains the previous snapshot as a backup', () async {
    final data = <String, String>{};
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    final first = emptySnapshot()..keys['0'] = 'first';
    await store.save(await store.load());
    await store.save(first);
    final second = emptySnapshot()..keys['0'] = 'second';
    await store.save(second);
    expect((await store.load()).keys, {'0': 'second'});
    final backup = await store.loadBackup();
    expect(backup?.keys, {'0': 'first'});
  });

  test('no backup is written on the first save', () async {
    final data = <String, String>{};
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    await store.load();
    await store.save(emptySnapshot()..keys['0'] = 'first');
    expect(data[AccountSnapshotStore.backupKey], isNull);
    expect(await store.loadBackup(), isNull);
  });

  test('restoring a backup quarantines the unreadable primary', () async {
    final data = <String, String>{};
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await store.save(await store.load());
    await store.save(emptySnapshot()..keys['0'] = 'first');
    await store.save(emptySnapshot()..keys['0'] = 'second');
    data[AccountSnapshotStore.snapshotKey] = '{corrupt';
    final broken = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await expectLater(
      broken.load(),
      throwsA(isA<AccountStorageRecoveryRequired>().having(
        (value) => value.hasBackup,
        'hasBackup',
        isTrue,
      )),
    );
    final restored = await broken.restoreBackup();
    expect(restored.keys, {'0': 'first'});
    expect(data[AccountSnapshotStore.snapshotKey], isNot('{corrupt'));
    expect(
      data[AccountSnapshotStore.conflictKey],
      contains('{corrupt'),
    );
  });

  test('keeping the snapshot quarantines diverged legacy values', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await store.save(await store.load());
    data['private_keys_map'] = jsonEncode({'0': 'legacy-newer'});
    final reload = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await expectLater(
      reload.load(),
      throwsA(isA<AccountStorageRecoveryRequired>()),
    );
    await reload.keepSnapshot(activeIndex: 0);
    expect((await reload.load()).keys, {'0': 'first'});
    expect(data['private_keys_map'], isNull);
    expect(
      data[AccountSnapshotStore.conflictKey],
      contains('legacy-newer'),
    );
  });

  test('keeping legacy values retains the replaced snapshot as a backup',
      () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await store.save(await store.load());
    data['private_keys_map'] = jsonEncode({'0': 'legacy-newer'});
    final reload = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await expectLater(
      reload.load(),
      throwsA(isA<AccountStorageRecoveryRequired>()),
    );
    final adopted = await reload.keepLegacy(legacyActiveIndex: 0);
    expect(adopted.keys, {'0': 'legacy-newer'});
    final backup = await AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    ).loadBackup();
    expect(backup?.keys, {'0': 'first'});
  });

  test('keeping legacy values refuses to erase saved accounts', () async {
    final data = <String, String>{
      'private_keys_map': jsonEncode({'0': 'first'}),
    };
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await store.save(await store.load());
    // A different legacy value diverges while legacy accounts are gone.
    data['private_keys_map'] = jsonEncode({});
    final reload = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await expectLater(
      reload.load(),
      throwsA(isA<AccountStorageRecoveryRequired>()),
    );
    await expectLater(reload.keepLegacy(), throwsFormatException);
    expect(data[AccountSnapshotStore.snapshotKey], contains('first'));
  });

  test('a snapshot replaced by another process blocks a stale save', () async {
    final data = <String, String>{};
    final first = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    await first.save(await first.load());
    await first.save(emptySnapshot()..keys['0'] = 'first');
    final second = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      delete: (key) async => data.remove(key),
    );
    await second.load();
    // A third process saves between second's load and save.
    final third = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
    );
    await third.save(await third.load());
    await third.save(emptySnapshot()..keys['0'] = 'third');
    await expectLater(
      second.save(emptySnapshot()..keys['0'] = 'stale'),
      throwsA(isA<AccountStorageConflict>()),
    );
    expect((await first.load()).keys, {'0': 'third'});
  });
}
