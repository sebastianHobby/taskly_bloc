import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';

final class ScheduledSessionQueryService {
  ScheduledSessionQueryService({
    required ScheduledOccurrencesService scheduledOccurrencesService,
    required SessionDayKeyService sessionDayKeyService,
    required SessionStreamCacheManager cacheManager,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
  }) : _scheduledOccurrencesService = scheduledOccurrencesService,
       _sessionDayKeyService = sessionDayKeyService,
       _cacheManager = cacheManager,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider;

  final ScheduledOccurrencesService _scheduledOccurrencesService;
  final SessionDayKeyService _sessionDayKeyService;
  final SessionStreamCacheManager _cacheManager;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final Set<_RangeScopeKey> _knownScopes = <_RangeScopeKey>{};

  static const Duration _prewarmWindow = Duration(days: 30);

  void start() {
    _sessionDayKeyService.start();
    final todayDayKeyUtc = _sessionDayKeyService.todayDayKeyUtc.valueOrNull;
    if (todayDayKeyUtc == null) return;

    // Prewarm near-horizon global scope for instant Scheduled tab load.
    _preloadRange(
      scope: const GlobalScheduledScope(),
      rangeStartDay: todayDayKeyUtc,
      rangeEndDay: todayDayKeyUtc.add(_prewarmWindow),
    );
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
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
  }) {
    final rangeStartUtc = _toUtcDay(rangeStartDay);
    final rangeEndUtc = _toUtcDay(rangeEndDay);
    final key = _RangeScopeKey.from(scope, rangeStartUtc, rangeEndUtc);
    _knownScopes.add(key);
    return _cacheManager.getOrCreate<ScheduledOccurrencesResult>(
      key: key,
      source: () => _buildScopeStream(
        scope: scope,
        rangeStartDay: rangeStartUtc,
        rangeEndDay: rangeEndUtc,
      ),
      pauseOnBackground: true,
    );
  }

  void _preloadRange({
    required ScheduledScope scope,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
  }) {
    final rangeStartUtc = _toUtcDay(rangeStartDay);
    final rangeEndUtc = _toUtcDay(rangeEndDay);
    final key = _RangeScopeKey.from(scope, rangeStartUtc, rangeEndUtc);
    _knownScopes.add(key);
    _cacheManager.preload<ScheduledOccurrencesResult>(
      key: key,
      source: () => _buildScopeStream(
        scope: scope,
        rangeStartDay: rangeStartUtc,
        rangeEndDay: rangeEndUtc,
      ),
      pauseOnBackground: true,
    );
  }

  Stream<ScheduledOccurrencesResult> _buildScopeStream({
    required ScheduledScope scope,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
  }) {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return _sessionDayKeyService.todayDayKeyUtc.map(
          (_) => _demoDataProvider.buildScheduledOccurrences(
            rangeStartDay: rangeStartDay,
            rangeEndDay: rangeEndDay,
          ),
        );
      }

      return _sessionDayKeyService.todayDayKeyUtc.switchMap((todayDayKeyUtc) {
        return _scheduledOccurrencesService.watchScheduledOccurrences(
          rangeStartDay: rangeStartDay,
          rangeEndDay: rangeEndDay,
          todayDayKeyUtc: todayDayKeyUtc,
          scope: scope,
        );
      });
    });
  }

  static DateTime _toUtcDay(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day);
}

final class _RangeScopeKey {
  const _RangeScopeKey._(
    this.kind,
    this.id,
    this.rangeStartDay,
    this.rangeEndDay,
  );

  factory _RangeScopeKey.from(
    ScheduledScope scope,
    DateTime rangeStartDay,
    DateTime rangeEndDay,
  ) {
    return switch (scope) {
      GlobalScheduledScope() => _RangeScopeKey._(
        'global',
        '',
        rangeStartDay,
        rangeEndDay,
      ),
      ProjectScheduledScope(:final projectId) => _RangeScopeKey._(
        'project',
        projectId,
        rangeStartDay,
        rangeEndDay,
      ),
      ValueScheduledScope(:final valueId) => _RangeScopeKey._(
        'value',
        valueId,
        rangeStartDay,
        rangeEndDay,
      ),
    };
  }

  final String kind;
  final String id;
  final DateTime rangeStartDay;
  final DateTime rangeEndDay;

  @override
  bool operator ==(Object other) {
    return other is _RangeScopeKey &&
        other.kind == kind &&
        other.id == id &&
        other.rangeStartDay == rangeStartDay &&
        other.rangeEndDay == rangeEndDay;
  }

  @override
  int get hashCode => Object.hash(kind, id, rangeStartDay, rangeEndDay);
}
