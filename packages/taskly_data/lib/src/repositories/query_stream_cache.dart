import 'dart:collection';

import 'package:rxdart/rxdart.dart';

/// A small LRU cache for query-keyed shared streams.
///
/// This is intended to prevent duplicate database watchers when multiple
/// consumers request the same stream concurrently.
///
/// Notes:
/// - Cached values are [ValueStream]s created via `shareValue()`.
/// - Even when a stream is cached, RxDart will only keep the upstream
///   subscription alive while there are listeners.
/// - The cache itself is size-bounded to avoid unbounded growth.
class QueryStreamCache<K, T> {
  QueryStreamCache({required int maxEntries})
    : assert(maxEntries > 0, 'maxEntries must be > 0'),
      _maxEntries = maxEntries;

  final int _maxEntries;

  /// Maintains insertion order; we treat the last entry as most-recent.
  final LinkedHashMap<K, ValueStream<T>> _cache = LinkedHashMap();

  bool containsKey(K key) => _cache.containsKey(key);

  /// Returns a cached stream if present, updating LRU order.
  ValueStream<T>? get(K key) {
    final value = _cache.remove(key);
    if (value == null) return null;
    _cache[key] = value;
    return value;
  }

  /// Returns an existing cached stream for [key], or creates and caches one.
  ///
  /// The [create] callback must return a *cold* stream (or at least a stream
  /// that is safe to share). This method will convert it to a [ValueStream]
  /// with `shareValue()`.
  ValueStream<T> getOrCreate(K key, Stream<T> Function() create) {
    final existing = get(key);
    if (existing != null) return existing;

    final shared = create().shareValue();
    _cache[key] = shared;

    _evictIfNeeded();

    return shared;
  }

  void clear() => _cache.clear();

  void remove(K key) => _cache.remove(key);

  void _evictIfNeeded() {
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}
