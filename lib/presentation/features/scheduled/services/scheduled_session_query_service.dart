import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';

final class ScheduledSessionQueryService {
  ScheduledSessionQueryService({
    required ScheduledOccurrencesService scheduledOccurrencesService,
    required SessionDayKeyService sessionDayKeyService,
    required SessionStreamCacheManager cacheManager,
  }) : _scheduledOccurrencesService = scheduledOccurrencesService,
       _sessionDayKeyService = sessionDayKeyService,
       _cacheManager = cacheManager;

  final ScheduledOccurrencesService _scheduledOccurrencesService;
  final SessionDayKeyService _sessionDayKeyService;
  final SessionStreamCacheManager _cacheManager;
  final Set<_ScopeKey> _knownScopes = <_ScopeKey>{};

  static const Duration _window = Duration(days: 30);

  void start() {
    // Prewarm global scope for instant Scheduled tab load.
    _preloadScope(const GlobalScheduledScope());
  }

  Future<void> stop() async {
    final keys = _knownScopes.toList(growable: false);
    _knownScopes.clear();
    for (final key in keys) {
      await _cacheManager.evict(key);
    }
  }

  ValueStream<ScheduledOccurrencesResult> watchScheduledOccurrences({
    required ScheduledScope scope,
  }) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    return _cacheManager.getOrCreate<ScheduledOccurrencesResult>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  void _preloadScope(ScheduledScope scope) {
    final key = _ScopeKey.fromScope(scope);
    _knownScopes.add(key);
    _cacheManager.preload<ScheduledOccurrencesResult>(
      key: key,
      source: () => _buildScopeStream(scope),
      pauseOnBackground: true,
    );
  }

  Stream<ScheduledOccurrencesResult> _buildScopeStream(ScheduledScope scope) {
    return _sessionDayKeyService.todayDayKeyUtc.switchMap((todayDayKeyUtc) {
      final rangeStart = todayDayKeyUtc;
      final rangeEnd = todayDayKeyUtc.add(_window);
      return _scheduledOccurrencesService.watchScheduledOccurrences(
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        todayDayKeyUtc: todayDayKeyUtc,
        scope: scope,
      );
    });
  }
}

final class _ScopeKey {
  const _ScopeKey._(this.kind, this.id);

  factory _ScopeKey.fromScope(ScheduledScope scope) {
    return switch (scope) {
      GlobalScheduledScope() => const _ScopeKey._('global', ''),
      ProjectScheduledScope(:final projectId) => _ScopeKey._(
        'project',
        projectId,
      ),
      ValueScheduledScope(:final valueId) => _ScopeKey._('value', valueId),
    };
  }

  final String kind;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is _ScopeKey && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}
