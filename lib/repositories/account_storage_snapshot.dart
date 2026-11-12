import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'account_storage_lock.dart';

/// Raised when legacy account values changed after this version last saw them.
///
/// Typically an older build wrote them, or a process that ignores the lock did.
/// The snapshot must not be overwritten automatically: the user has to choose
/// between the snapshot, the legacy values or a retained backup.
class LegacyAccountsChanged implements Exception {
  const LegacyAccountsChanged();

  @override
  String toString() => 'LegacyAccountsChanged';
}

/// Raised when a saved snapshot is unreadable and only a backup may be used.
class AccountSnapshotCorrupt implements Exception {
  const AccountSnapshotCorrupt();

  @override
  String toString() => 'AccountSnapshotCorrupt';
}

/// Raised when the primary snapshot changed after this store loaded it.
///
/// Another process saved accounts first, so the in-memory maps are stale.
/// The caller must reload before applying a change; it must not overwrite.
class AccountStorageConflict implements Exception {
  const AccountStorageConflict();

  @override
  String toString() => 'AccountStorageConflict';
}

/// Why startup could not choose an account state on its own.
enum AccountRecoveryReason { corruptSnapshot, legacyChanged }

/// Raised by [AccountSnapshotStore.load] when the user must choose how to
/// recover. No data has been written or deleted at this point.
class AccountStorageRecoveryRequired implements Exception {
  const AccountStorageRecoveryRequired(this.reason, {this.hasBackup = false});

  final AccountRecoveryReason reason;
  final bool hasBackup;

  @override
  String toString() => 'AccountStorageRecoveryRequired(${reason.name})';
}

/// A single secure-storage value for the related account maps.
///
/// Loading never migrates or writes: a failed legacy read must not be mistaken
/// for an empty store. Callers must only publish in-memory changes after save
/// completes successfully.
class AccountStorageSnapshot {
  AccountStorageSnapshot({
    required this.keys,
    required this.privateKeys,
    required this.externalSigners,
    required this.externalTypes,
    required this.pomegranateSetups,
    this.activeIndex,
    this.remoteSigners = const [],
  });

  final Map<String, dynamic> keys;
  final Map<String, dynamic> privateKeys;
  final Map<String, dynamic> externalSigners;
  final Map<String, dynamic> externalTypes;
  final Map<String, dynamic> pomegranateSetups;
  final int? activeIndex;
  final List<String> remoteSigners;

  Map<String, Object> toJson() => {
        'version': 1,
        'keys': keys,
        'privateKeys': privateKeys,
        'externalSigners': externalSigners,
        'externalTypes': externalTypes,
        'pomegranateSetups': pomegranateSetups,
        'activeIndex': activeIndex ?? -1,
        'remoteSigners': remoteSigners,
      };
}

/// The callbacks must propagate storage errors and must not log their values.
///
/// Every read-modify-write sequence runs while holding [lock]. The lock is
/// optional: tests and non-desktop callers may pass [UnlockedAccountStorageLock]
/// or null. Production Windows/Linux wiring supplies [FileAccountStorageLock],
/// whose OS-level file lock is released on process exit or crash, so a crashed
/// process cannot leave a stale lock behind. The lock file never contains
/// account data.
///
/// Because a process that ignores the lock can still write, [save] also
/// compares the primary value with the one this store loaded and refuses to
/// overwrite a newer value ([AccountStorageConflict]).
class AccountSnapshotStore {
  AccountSnapshotStore({
    required this.read,
    required this.write,
    this.delete,
    this.lock,
  });

  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;
  final Future<void> Function(String key)? delete;
  final AccountStorageLock? lock;

  bool _loaded = false;
  bool _busy = false;
  bool _legacyDiverged = false;
  Map<String, String>? _legacyHashes;
  String? _loadedSnapshot;
  String? _observedPrimary;

  static const snapshotKey = 'account_snapshot_v1';
  static const backupKey = 'account_snapshot_v1_backup';
  static const conflictKey = 'account_legacy_conflict_v1';
  static const legacyKeys = [
    'private_keys_map',
    'keys_is_private_map',
    'keys_is_external_map',
    'external_keys_map',
    'pomegranate_setups_map',
  ];
  static const _fields = [
    'keys',
    'privateKeys',
    'externalSigners',
    'externalTypes',
    'pomegranateSetups',
  ];

  /// True when legacy values changed after the snapshot was written.
  bool get legacyDiverged => _legacyDiverged;

  /// Reads the current accounts. Never writes or deletes.
  ///
  /// Throws [AccountStorageRecoveryRequired] when the primary snapshot is
  /// unreadable or the legacy values diverged, so the caller can offer an
  /// explicit choice. Nothing is changed in that case.
  Future<AccountStorageSnapshot> load({int? legacyActiveIndex}) async {
    return _exclusive(() async {
      final stored = await read(snapshotKey);
      _observedPrimary = stored;
      if (stored != null) {
        late final _DecodedSnapshot decoded;
        try {
          decoded = _decodeSnapshot(stored);
        } catch (_) {
          _resetLoaded();
          throw AccountStorageRecoveryRequired(
            AccountRecoveryReason.corruptSnapshot,
            hasBackup: await read(backupKey) != null,
          );
        }
        final currentHashes = await _readLegacyHashes();
        _legacyHashes = Map<String, String>.from(decoded.hashes);
        _loadedSnapshot = stored;
        if (_hashesDiverge(currentHashes, decoded.hashes)) {
          _legacyDiverged = true;
          _loaded = true;
          throw AccountStorageRecoveryRequired(
            AccountRecoveryReason.legacyChanged,
            hasBackup: await read(backupKey) != null,
          );
        }
        _legacyDiverged = false;
        _loaded = true;
        return decoded.snapshot;
      }

      final values = <dynamic>[];
      final hashes = <String, String>{};
      for (final key in legacyKeys) {
        final value = await read(key);
        hashes[key] = _hash(value);
        values.add(value == null ? <String, dynamic>{} : jsonDecode(value));
      }
      final signersJson = await read('remote_signers_map');
      hashes['remote_signers_map'] = _hash(signersJson);
      final dynamic signers = signersJson == null ? [] : jsonDecode(signersJson);
      if (signers is! List || signers.any((value) => value is! String)) {
        throw const FormatException('Invalid remote signers');
      }
      final snapshot = _fromMaps(
        values,
        activeIndex: legacyActiveIndex,
        remoteSigners: List<String>.from(signers),
      );
      _legacyHashes = hashes;
      _loadedSnapshot = null;
      _legacyDiverged = false;
      _loaded = true;
      return snapshot;
    });
  }

  /// Reads the retained previous snapshot without changing the primary.
  ///
  /// Returns null if no backup exists. Throws [AccountSnapshotCorrupt] if a
  /// backup exists but cannot be validated.
  Future<AccountStorageSnapshot?> loadBackup({int? legacyActiveIndex}) {
    return _exclusive(() async {
      final stored = await read(backupKey);
      if (stored == null) {
        return null;
      }
      try {
        final decoded = _decodeSnapshot(stored);
        return decoded.snapshot;
      } catch (_) {
        throw const AccountSnapshotCorrupt();
      }
    });
  }

  /// Restores the retained backup as the primary value, after the user chose
  /// that recovery path.
  ///
  /// The unreadable primary is quarantined under [conflictKey] first, so this
  /// never silently discards data. Refuses if the primary changed since the
  /// failing load. Must be called after [load] raised
  /// [AccountStorageRecoveryRequired] for a corrupt snapshot.
  Future<AccountStorageSnapshot> restoreBackup() {
    return _exclusive(() async {
      final _StoredBackup backup;
      try {
        backup = await _readValidBackup();
      } catch (_) {
        throw const AccountSnapshotCorrupt();
      }
      await _verifyPrimaryUnchanged();
      final corrupt = _observedPrimary;
      if (corrupt != null) {
        final quarantine = jsonEncode({
          'version': 1,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          'primary': corrupt,
        });
        await write(conflictKey, quarantine);
        if (await read(conflictKey) != quarantine) {
          throw StateError('Corrupt snapshot could not be quarantined');
        }
      }
      final encoded = backup.encoded;
      await write(snapshotKey, encoded);
      if (await read(snapshotKey) != encoded) {
        throw StateError('Account snapshot could not be verified');
      }
      _loadedSnapshot = encoded;
      _observedPrimary = encoded;
      _legacyHashes = Map<String, String>.from(backup.decoded.hashes);
      _legacyDiverged = false;
      _loaded = true;
      return backup.decoded.snapshot;
    });
  }

  /// Explicitly resolves diverged legacy values by keeping the snapshot.
  ///
  /// The conflicting legacy values are quarantined under [conflictKey] before
  /// the legacy keys are removed, so nothing is silently lost. Must be called
  /// after [load] raised [AccountStorageRecoveryRequired] for `legacyChanged`.
  Future<void> keepSnapshot({required int? activeIndex}) {
    return _exclusive(() async {
      final current = _loadedSnapshot;
      if (current == null) {
        throw StateError('No saved accounts to keep');
      }
      await _verifyPrimaryUnchanged();
      final legacy = await _readLegacyValues();
      final quarantine = jsonEncode({
        'version': 1,
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'values': legacy,
      });
      await write(conflictKey, quarantine);
      if (await read(conflictKey) != quarantine) {
        throw StateError('Legacy conflict backup could not be written');
      }
      await _deleteLegacyValues();
      final hashes = await _readLegacyHashes();
      final decoded = _decodeSnapshot(current);
      final updated = jsonEncode({
        ...decoded.snapshot.toJson(),
        'activeIndex': activeIndex ?? decoded.snapshot.activeIndex ?? -1,
        'legacyHashes': hashes,
      });
      await write(snapshotKey, updated);
      if (await read(snapshotKey) != updated) {
        throw StateError('Account snapshot could not be verified');
      }
      _legacyHashes = hashes;
      _loadedSnapshot = updated;
      _observedPrimary = updated;
      _legacyDiverged = false;
      _loaded = true;
    });
  }

  /// Explicitly resolves diverged legacy values by adopting them.
  ///
  /// Refuses to replace a non-empty snapshot with an empty legacy store. The
  /// current primary snapshot is retained as a backup before any write, so the
  /// values it replaces can still be recovered.
  Future<AccountStorageSnapshot> keepLegacy({int? legacyActiveIndex}) {
    return _exclusive(() async {
      await _verifyPrimaryUnchanged();
      final values = <dynamic>[];
      final hashes = <String, String>{};
      for (final key in legacyKeys) {
        final value = await read(key);
        hashes[key] = _hash(value);
        values.add(value == null ? <String, dynamic>{} : jsonDecode(value));
      }
      final signersJson = await read('remote_signers_map');
      hashes['remote_signers_map'] = _hash(signersJson);
      final dynamic signers = signersJson == null ? [] : jsonDecode(signersJson);
      if (signers is! List || signers.any((value) => value is! String)) {
        throw const FormatException('Invalid remote signers');
      }
      final adopted = _fromMaps(
        values,
        activeIndex: legacyActiveIndex,
        remoteSigners: List<String>.from(signers),
      );
      final current = _loadedSnapshot;
      final currentCount =
          current == null ? 0 : _decodeSnapshot(current).snapshot.keys.length;
      if (adopted.keys.isEmpty && currentCount > 0) {
        throw const FormatException('Refusing to replace saved accounts');
      }
      if (current != null) {
        await _writeVerified(backupKey, current);
      }
      final encoded = jsonEncode({
        ...adopted.toJson(),
        'legacyHashes': hashes,
      });
      await _writeVerified(snapshotKey, encoded);
      _legacyHashes = hashes;
      _loadedSnapshot = encoded;
      _observedPrimary = encoded;
      _legacyDiverged = false;
      _loaded = true;
      return adopted;
    });
  }

  /// Call only after the caller has validated the complete loaded account data.
  Future<void> finishMigration() {
    return _exclusive(() async {
      final expected = _loadedSnapshot;
      if (expected == null) {
        return;
      }
      await _cleanupLegacy(expected);
    });
  }

  Future<void> save(AccountStorageSnapshot snapshot) {
    return _exclusive(() async {
      if (!_loaded) {
        throw StateError('Account storage must be loaded before saving');
      }
      await _verifyLegacyUnchanged();
      // Compare-and-swap: if another process replaced the primary value since
      // this store loaded it, refuse the write instead of overwriting it.
      await _verifyPrimaryUnchanged();
      final encoded = jsonEncode({
        ...snapshot.toJson(),
        'legacyHashes': _legacyHashes,
      });
      final previous = _loadedSnapshot;
      if (previous != null && previous != encoded) {
        // Retain the last verified snapshot before replacing it. If this write
        // fails the primary is untouched, so no data is lost.
        await _writeVerified(backupKey, previous);
      }
      await _writeVerified(snapshotKey, encoded);
      await _cleanupLegacy(encoded);
      _loadedSnapshot = encoded;
      _observedPrimary = encoded;
      _loaded = true;
    });
  }

  /// Releases any resources. The OS lock is taken per operation, so this only
  /// clears in-memory state.
  void dispose() {
    _resetLoaded();
  }

  Future<void> _cleanupLegacy(String expectedSnapshot) async {
    final remove = delete;
    if (remove == null) {
      return;
    }
    await _verifyLegacyUnchanged();
    for (final key in [...legacyKeys, 'remote_signers_map']) {
      final value = await read(key);
      if (value == null) {
        continue;
      }
      if (_hash(value) != _legacyHashes?[key]) {
        throw const LegacyAccountsChanged();
      }
      if (await read(snapshotKey) != expectedSnapshot) {
        throw const AccountStorageConflict();
      }
      await remove(key);
      if (await read(key) != null ||
          await read(snapshotKey) != expectedSnapshot) {
        throw StateError('Account migration cleanup could not be verified');
      }
    }
  }

  Future<void> _verifyLegacyUnchanged() async {
    final expected = _legacyHashes;
    if (expected == null) {
      throw StateError('Legacy account metadata is unavailable');
    }
    final current = await _readLegacyHashes();
    if (_hashesDiverge(current, expected)) {
      _legacyDiverged = true;
      throw const LegacyAccountsChanged();
    }
  }

  Future<void> _verifyPrimaryUnchanged() async {
    if (await read(snapshotKey) != _observedPrimary) {
      throw const AccountStorageConflict();
    }
  }

  Future<void> _writeVerified(String key, String value) async {
    await write(key, value);
    if (await read(key) != value) {
      throw StateError('Account storage write could not be verified');
    }
  }

  Future<_StoredBackup> _readValidBackup() async {
    final stored = await read(backupKey);
    if (stored == null) {
      throw const AccountSnapshotCorrupt();
    }
    return _StoredBackup(stored, _decodeSnapshot(stored));
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy) {
      throw StateError('Account storage operation already in progress');
    }
    _busy = true;
    try {
      final source = lock;
      if (source == null) {
        return await action();
      }
      final lease = await source.acquire();
      try {
        return await action();
      } finally {
        await lease.release();
      }
    } finally {
      _busy = false;
    }
  }

  void _resetLoaded() {
    _loaded = false;
    _loadedSnapshot = null;
    _legacyHashes = null;
    _legacyDiverged = false;
  }

  bool _hashesDiverge(
      Map<String, String> current, Map<String, dynamic> expected) {
    return current.entries.any((entry) =>
        expected[entry.key] != entry.value && entry.value != _hash(null));
  }

  String _hash(String? value) =>
      sha256.convert(utf8.encode(value == null ? '0' : '1$value')).toString();

  Future<Map<String, String>> _readLegacyHashes() async {
    final hashes = <String, String>{};
    for (final key in [...legacyKeys, 'remote_signers_map']) {
      hashes[key] = _hash(await read(key));
    }
    return hashes;
  }

  Future<Map<String, String?>> _readLegacyValues() async {
    final values = <String, String?>{};
    for (final key in [...legacyKeys, 'remote_signers_map']) {
      values[key] = await read(key);
    }
    return values;
  }

  Future<void> _deleteLegacyValues() async {
    final remove = delete;
    if (remove == null) {
      return;
    }
    for (final key in [...legacyKeys, 'remote_signers_map']) {
      if (await read(key) != null) {
        await remove(key);
        if (await read(key) != null) {
          throw StateError('Legacy account cleanup could not be verified');
        }
      }
    }
  }

  _DecodedSnapshot _decodeSnapshot(String stored) {
    final decoded = jsonDecode(stored);
    if (decoded is! Map || decoded['version'] != 1) {
      throw const FormatException('Invalid account snapshot');
    }
    final active = decoded['activeIndex'];
    final signers = decoded['remoteSigners'];
    if (active is! int ||
        active < -1 ||
        signers is! List ||
        signers.any((value) => value is! String)) {
      throw const FormatException('Invalid account snapshot metadata');
    }
    final hashes = decoded['legacyHashes'];
    if (hashes is! Map<String, dynamic> ||
        hashes.length != legacyKeys.length + 1 ||
        hashes.values.any((value) => value is! String)) {
      throw const FormatException('Invalid legacy account metadata');
    }
    return _DecodedSnapshot(
      snapshot: _fromMaps(
        _fields.map((field) => decoded[field]).toList(),
        activeIndex: active == -1 ? null : active,
        remoteSigners: List<String>.from(signers),
      ),
      hashes: hashes,
    );
  }

  AccountStorageSnapshot _fromMaps(
    List<dynamic> values, {
    int? activeIndex,
    required List<String> remoteSigners,
  }) {
    final maps = values.map((value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid account map');
      }
      return value;
    }).toList();
    if (maps[0].values.any((value) => value is! String) ||
        maps[1].values.any((value) => value is! bool) ||
        maps[2].values.any((value) => value is! bool) ||
        maps[3].values.any((value) => value is! String) ||
        maps[4].values.any((value) => value is! Map)) {
      throw const FormatException('Invalid account map values');
    }
    return AccountStorageSnapshot(
      keys: maps[0],
      privateKeys: maps[1],
      externalSigners: maps[2],
      externalTypes: maps[3],
      pomegranateSetups: maps[4],
      activeIndex: activeIndex,
      remoteSigners: remoteSigners,
    );
  }
}

class _DecodedSnapshot {
  const _DecodedSnapshot({required this.snapshot, required this.hashes});

  final AccountStorageSnapshot snapshot;
  final Map<String, dynamic> hashes;
}

class _StoredBackup {
  const _StoredBackup(this.encoded, this.decoded);

  final String encoded;
  final _DecodedSnapshot decoded;
}
