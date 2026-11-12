import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Thrown when another process holds the account-storage lock past the
/// deadline. Callers must treat this as storage being temporarily unavailable
/// and must not attempt a write.
class AccountStorageLockTimeout implements Exception {
  const AccountStorageLockTimeout();

  @override
  String toString() => 'AccountStorageLockTimeout';
}

/// Holds an acquired cross-process lock until [release] is called.
///
/// The OS releases the underlying lock if the process exits or crashes, so a
/// crashed process cannot leave a stale lock behind.
abstract class AccountStorageLease {
  Future<void> release();
}

/// Serializes account-storage work across processes.
abstract class AccountStorageLock {
  Future<AccountStorageLease> acquire();
}

/// No-op used by tests and non-desktop callers. It provides no cross-process
/// protection; production desktop wiring must supply [FileAccountStorageLock].
class UnlockedAccountStorageLock implements AccountStorageLock {
  const UnlockedAccountStorageLock();

  @override
  Future<AccountStorageLease> acquire() async => const _NoopLease();
}

class _NoopLease implements AccountStorageLease {
  const _NoopLease();

  @override
  Future<void> release() async {}
}

/// Cross-process advisory lock backed by an OS file lock.
///
/// The lock file contains no account data. On Linux (`flock`) and Windows
/// (`LockFileEx`) a second handle in another process cannot take the same lock
/// while it is held. POSIX advisory locks are per process, so this only
/// protects against separate processes, not isolates in the same process.
class FileAccountStorageLock implements AccountStorageLock {
  FileAccountStorageLock({
    required this.path,
    this.timeout = const Duration(seconds: 5),
    this.retryDelay = const Duration(milliseconds: 100),
  });

  final String path;
  final Duration timeout;
  final Duration retryDelay;

  bool _acquired = false;

  @override
  Future<AccountStorageLease> acquire() async {
    if (_acquired) {
      throw StateError('Account storage lock is already held in this process');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    // Exclusive locks require a writable handle; append does not truncate.
    final handle = await file.open(mode: FileMode.append);
    _acquired = true;
    try {
      final deadline = DateTime.now().add(timeout);
      while (true) {
        try {
          await handle.lock();
          return _FileLease(handle, this);
        } on FileSystemException {
          if (DateTime.now().isAfter(deadline)) {
            throw const AccountStorageLockTimeout();
          }
          await Future<void>.delayed(retryDelay);
        }
      }
    } catch (_) {
      _acquired = false;
      await handle.close();
      rethrow;
    }
  }

  void _released() {
    _acquired = false;
  }
}

class _FileLease implements AccountStorageLease {
  _FileLease(this._handle, this._owner);

  final RandomAccessFile _handle;
  final FileAccountStorageLock _owner;
  bool _released = false;

  @override
  Future<void> release() async {
    if (_released) {
      return;
    }
    _released = true;
    try {
      await _handle.unlock();
    } on FileSystemException {
      // Unlock is best effort: closing the handle also releases the lock.
    }
    await _handle.close();
    _owner._released();
  }
}

/// Describes where the desktop account lock file lives.
///
/// Resolved lazily because the support directory is only available once the
/// Flutter binding has initialized platform plugins. Returns null when the
/// directory cannot be resolved so callers can fall back to unlocked storage
/// rather than failing to start.
class DesktopAccountStorageLockFactory {
  DesktopAccountStorageLockFactory({
    this.timeout = const Duration(seconds: 5),
    this.retryDelay = const Duration(milliseconds: 100),
  });

  final Duration timeout;
  final Duration retryDelay;

  Future<AccountStorageLock?> create() async {
    try {
      final directory = await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      return FileAccountStorageLock(
        path: '${directory.path}${Platform.pathSeparator}account_storage.lock',
        timeout: timeout,
        retryDelay: retryDelay,
      );
    } catch (_) {
      return null;
    }
  }
}
