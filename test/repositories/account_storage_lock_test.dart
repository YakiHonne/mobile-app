import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yakihonne/repositories/account_storage_lock.dart';
import 'package:yakihonne/repositories/account_storage_snapshot.dart';

class _RecordingLock implements AccountStorageLock {
  int acquires = 0;
  int releases = 0;

  @override
  Future<AccountStorageLease> acquire() async {
    acquires++;
    return _RecordingLease(this);
  }
}

class _RecordingLease implements AccountStorageLease {
  _RecordingLease(this._owner);

  final _RecordingLock _owner;

  @override
  Future<void> release() async {
    _owner.releases++;
  }
}

class _UnavailableLock implements AccountStorageLock {
  @override
  Future<AccountStorageLease> acquire() async {
    throw const AccountStorageLockTimeout();
  }
}

AccountStorageSnapshot _empty() => AccountStorageSnapshot(
      keys: {},
      privateKeys: {},
      externalSigners: {},
      externalTypes: {},
      pomegranateSetups: {},
    );

/// Resolves a real `dart` binary. Inside `flutter test`, the reported
/// executable is `flutter_tester`, which cannot run a standalone script.
String _dartExecutable() {
  final candidate = File(
    '${_flutterRoot()}${Platform.pathSeparator}bin'
    '${Platform.pathSeparator}dart',
  );
  if (candidate.existsSync()) {
    return candidate.path;
  }
  return Platform.resolvedExecutable;
}

String _flutterRoot() {
  // e.g. /Users/x/.puro/envs/pipress/flutter/bin/cache/dart-sdk/bin/dart
  final executable = Platform.resolvedExecutable;
  final marker = '${Platform.pathSeparator}bin${Platform.pathSeparator}cache';
  final index = executable.indexOf(marker);
  if (index > 0) {
    return executable.substring(0, index);
  }
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) {
    return env;
  }
  return File(Platform.resolvedExecutable).parent.parent.path;
}

void main() {
  test('file lock creates an empty lock file and re-acquires after release',
      () async {
    final directory = await Directory.systemTemp.createTemp('yaki-lock-');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}nested'
        '${Platform.pathSeparator}account_storage.lock';
    final lock = FileAccountStorageLock(
      path: path,
      timeout: const Duration(milliseconds: 200),
      retryDelay: const Duration(milliseconds: 20),
    );

    final first = await lock.acquire();
    expect(await File(path).readAsString(), isEmpty);
    await first.release();

    final second = await lock.acquire();
    await second.release();
    // Releasing twice is safe.
    await second.release();
  });

  test('a lock instance refuses overlapping acquisition', () async {
    final directory = await Directory.systemTemp.createTemp('yaki-lock-');
    addTearDown(() => directory.delete(recursive: true));
    final lock = FileAccountStorageLock(
      path: '${directory.path}${Platform.pathSeparator}account_storage.lock',
    );
    final lease = await lock.acquire();
    await expectLater(lock.acquire(), throwsStateError);
    await lease.release();
  });

  test('the unlocked lock performs no exclusion', () async {
    const lock = UnlockedAccountStorageLock();
    final first = await lock.acquire();
    final second = await lock.acquire();
    await first.release();
    await second.release();
  });

  test('store acquires and releases the lock around every operation',
      () async {
    final lock = _RecordingLock();
    final data = <String, String>{};
    final store = AccountSnapshotStore(
      read: (key) async => data[key],
      write: (key, value) async => data[key] = value,
      lock: lock,
    );

    await store.load();
    await store.save(_empty());
    expect(lock.acquires, 2);
    expect(lock.releases, 2);
    expect(lock.acquires, lock.releases);
  });

  test('the lock is released when an operation fails', () async {
    final lock = _RecordingLock();
    final store = AccountSnapshotStore(
      read: (key) async {
        if (key == AccountSnapshotStore.snapshotKey) {
          return '{corrupt';
        }
        return null;
      },
      write: (_, __) async {},
      lock: lock,
    );
    await expectLater(
      store.load(),
      throwsA(isA<AccountStorageRecoveryRequired>()),
    );
    expect(lock.acquires, 1);
    expect(lock.releases, 1);
  });

  test('a lock timeout stops an operation before any storage access',
      () async {
    var reads = 0;
    final store = AccountSnapshotStore(
      read: (_) async {
        reads++;
        return null;
      },
      write: (_, __) async {},
      lock: _UnavailableLock(),
    );
    await expectLater(store.load(), throwsA(isA<AccountStorageLockTimeout>()));
    expect(reads, 0);
  });

  test(
    'file locks are per process, so a second handle in this process is not '
    'excluded (documented POSIX behavior)',
    () async {
      final directory = await Directory.systemTemp.createTemp('yaki-lock-');
      addTearDown(() => directory.delete(recursive: true));
      final path =
          '${directory.path}${Platform.pathSeparator}account_storage.lock';
      final first = FileAccountStorageLock(
        path: path,
        timeout: const Duration(milliseconds: 150),
        retryDelay: const Duration(milliseconds: 20),
      );
      final second = FileAccountStorageLock(
        path: path,
        timeout: const Duration(milliseconds: 150),
        retryDelay: const Duration(milliseconds: 20),
      );

      final firstLease = await first.acquire();
      // Dart documents that POSIX advisory locks are process-level, so this
      // succeeds here. Cross-process exclusion needs a separate process and is
      // verified manually on target OSes (see DESKTOP_IMPLEMENTATION.md).
      final secondLease = await second.acquire();
      await firstLease.release();
      await secondLease.release();
    },
  );

  test('lock file never contains account data', () async {
    final directory = await Directory.systemTemp.createTemp('yaki-lock-');
    addTearDown(() => directory.delete(recursive: true));
    final path =
        '${directory.path}${Platform.pathSeparator}account_storage.lock';
    final lock = FileAccountStorageLock(path: path);
    final lease = await lock.acquire();
    expect(jsonEncode(await File(path).readAsString()), '""');
    await lease.release();
  });

  test(
    'a separate process cannot take the lock while it is held',
    () async {
      final directory = await Directory.systemTemp.createTemp('yaki-lock-');
      addTearDown(() => directory.delete(recursive: true));
      final path =
          '${directory.path}${Platform.pathSeparator}account_storage.lock';
      final script =
          File('${directory.path}${Platform.pathSeparator}hold_lock.dart');
      await script.writeAsString('''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  final file = File(args.first);
  await file.parent.create(recursive: true);
  final handle = await file.open(mode: FileMode.append);
  await handle.lock();
  stdout.writeln('locked');
  await Future<void>.delayed(const Duration(seconds: 2));
  await handle.unlock();
  await handle.close();
}
''');

      final holder = await Process.start(
        _dartExecutable(),
        [script.path, path],
      );
      // Wait until the child reports that it holds the lock.
      final locked = await holder.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .firstWhere((line) => line.contains('locked'));
      expect(locked, contains('locked'));

      final contender = FileAccountStorageLock(
        path: path,
        timeout: const Duration(milliseconds: 300),
        retryDelay: const Duration(milliseconds: 25),
      );
      await expectLater(
        contender.acquire(),
        throwsA(isA<AccountStorageLockTimeout>()),
      );
      await holder.exitCode;

      final afterExit = await contender.acquire();
      await afterExit.release();
    },
    skip: Platform.isWindows
        ? 'Manual Windows check required; LockFileEx semantics differ.'
        : false,
  );
}
