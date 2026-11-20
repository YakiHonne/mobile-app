/// In-memory LRU cache with TTL for Namecoin name resolution results.
///
/// Ported from Amethyst's NamecoinLookupCache.kt (MIT License, Vitor Pamplona).

import 'dart:async';
import 'dart:collection';

import 'namecoin_name_resolver.dart';

class _CachedResult {
  final NamecoinNostrResult? result;
  final int timestamp; // seconds since epoch

  _CachedResult(this.result)
      : timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

class NamecoinLookupCache {
  final int maxEntries;
  final int ttlSecs;

  final LinkedHashMap<String, _CachedResult> _cache =
      LinkedHashMap<String, _CachedResult>();
  final Completer<void> _lock = Completer<void>()..complete(null);

  NamecoinLookupCache({
    this.maxEntries = 500,
    this.ttlSecs = 3600, // 1 hour
  });

  String _cacheKey(String identifier) => identifier.trim().toLowerCase();

  /// Get a cached result. Returns null if not found or expired.
  NamecoinNostrResult? get(String identifier) {
    final key = _cacheKey(identifier);
    final entry = _cache[key];
    if (entry == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final age = now - entry.timestamp;
    if (age > ttlSecs) {
      _cache.remove(key);
      return null;
    }

    return entry.result;
  }

  /// Check if a result is cached (even if the result itself is null/not-found).
  bool contains(String identifier) {
    final key = _cacheKey(identifier);
    final entry = _cache[key];
    if (entry == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final age = now - entry.timestamp;
    if (age > ttlSecs) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Cache a result.
  void put(String identifier, NamecoinNostrResult? result) {
    final key = _cacheKey(identifier);

    // Evict oldest entries if over capacity
    while (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CachedResult(result);
  }

  /// Remove a specific entry.
  void invalidate(String identifier) {
    _cache.remove(_cacheKey(identifier));
  }

  /// Clear all entries.
  void clear() {
    _cache.clear();
  }
}
