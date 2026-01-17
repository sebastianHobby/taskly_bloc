import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/src/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_domain/src/attention/model/attention_item.dart';
import 'package:taskly_domain/src/attention/query/attention_query.dart';

/// An [AttentionEngineContract] decorator that caches and shares evaluations.
///
/// - Multiple subscribers to the same semantic query share a single upstream
///   evaluation stream.
/// - Late subscribers receive the latest emitted value immediately.
/// - If a cached stream errors, it is evicted so future subscribers can retry.
class CachedAttentionEngine implements AttentionEngineContract {
  CachedAttentionEngine({required AttentionEngineContract inner})
    : _inner = inner;

  final AttentionEngineContract _inner;

  final Map<_AttentionQueryCacheKey, Stream<List<AttentionItem>>> _cache =
      <_AttentionQueryCacheKey, Stream<List<AttentionItem>>>{};

  @override
  Stream<List<AttentionItem>> watch(AttentionQuery query) {
    final key = _AttentionQueryCacheKey.fromQuery(query);

    final cached = _cache[key];
    if (cached != null) return cached;

    final shared = _inner
        .watch(query)
        .doOnError((_, __) {
          // Do not permanently cache errors.
          _cache.remove(key);
        })
        // Share the upstream work and replay the latest value.
        .publishReplay(maxSize: 1)
        .refCount();

    _cache[key] = shared;
    return shared;
  }

  /// Evict all cached queries.
  void invalidateAll() => _cache.clear();

  /// Evict the cached stream for [query], if any.
  void invalidate(AttentionQuery query) {
    _cache.remove(_AttentionQueryCacheKey.fromQuery(query));
  }
}

final class _AttentionQueryCacheKey {
  const _AttentionQueryCacheKey({
    required this.bucketMask,
    required this.entityTypeMask,
    required this.minSeverityIndex,
  });

  factory _AttentionQueryCacheKey.fromQuery(AttentionQuery query) {
    int? bucketMask;
    final buckets = query.buckets;
    if (buckets != null) {
      var mask = 0;
      for (final b in buckets) {
        mask |= 1 << b.index;
      }
      bucketMask = mask;
    }

    int? entityTypeMask;
    final entityTypes = query.entityTypes;
    if (entityTypes != null) {
      var mask = 0;
      for (final t in entityTypes) {
        mask |= 1 << t.index;
      }
      entityTypeMask = mask;
    }

    return _AttentionQueryCacheKey(
      bucketMask: bucketMask,
      entityTypeMask: entityTypeMask,
      minSeverityIndex: query.minSeverity?.index,
    );
  }

  final int? bucketMask;
  final int? entityTypeMask;
  final int? minSeverityIndex;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _AttentionQueryCacheKey &&
            other.bucketMask == bucketMask &&
            other.entityTypeMask == entityTypeMask &&
            other.minSeverityIndex == minSeverityIndex);
  }

  @override
  int get hashCode => Object.hash(bucketMask, entityTypeMask, minSeverityIndex);
}
