/// Keeps entries used by open views out of the shared LRU eviction set.
class ActiveStatsCache {
  final _references = <String, int>{};

  void retain(String id) =>
      _references.update(id, (count) => count + 1, ifAbsent: () => 1);

  void release(String id) {
    final count = _references[id];
    if (count == null) {
      return;
    }
    if (count == 1) {
      _references.remove(id);
    } else {
      _references[id] = count - 1;
    }
  }

  Set<String> get protectedKeys => _references.keys.toSet();
}

Set<K> selectCacheKeys<K>(
  Iterable<K> sortedKeys,
  int maxSize,
  Set<K> protectedKeys,
) {
  final keys = sortedKeys.toList();
  return {
    ...keys.where(protectedKeys.contains),
    ...keys.where((key) => !protectedKeys.contains(key)).take(maxSize),
  };
}
