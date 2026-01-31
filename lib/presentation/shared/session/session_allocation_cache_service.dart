import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';

import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';

/// Session-scoped cache for My Day allocation snapshots.
///
/// Uses repo/settings streams as invalidation triggers and recomputes
/// allocation on changes, day boundary, or resume.
final class SessionAllocationCacheService {
  SessionAllocationCacheService({
    required SessionStreamCacheManager cacheManager,
    required SessionDayKeyService sessionDayKeyService,
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ProjectAnchorStateRepositoryContract projectAnchorStateRepository,
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
  }) : _cacheManager = cacheManager,
       _sessionDayKeyService = sessionDayKeyService,
       _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _projectAnchorStateRepository = projectAnchorStateRepository,
       _settingsRepository = settingsRepository,
       _valueRepository = valueRepository;

  final SessionStreamCacheManager _cacheManager;
  final SessionDayKeyService _sessionDayKeyService;
  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ProjectAnchorStateRepositoryContract _projectAnchorStateRepository;
  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;

  static const Object _cacheKey = 'session.allocation.snapshot';

  ValueStream<AllocationResult> watchAllocationSnapshot() {
    return _cacheManager.getOrCreate<AllocationResult>(
      key: _cacheKey,
      source: _allocationSnapshotStream,
      pauseOnBackground: true,
    );
  }

  void start() {
    _cacheManager.preload<AllocationResult>(
      key: _cacheKey,
      source: _allocationSnapshotStream,
      pauseOnBackground: true,
    );
  }

  Future<AllocationResult> prewarm() async {
    return watchAllocationSnapshot().first;
  }

  Future<void> stop() => _cacheManager.evict(_cacheKey);

  Stream<AllocationResult> _allocationSnapshotStream() {
    final triggers = Rx.merge<void>([
      _sessionDayKeyService.todayDayKeyUtc.map((_) {}),
      _settingsRepository.watch(SettingsKey.allocation).map((_) {}),
      _valueRepository.watchAll().map((_) {}),
      _taskRepository.watchAll(TaskQuery.incomplete()).map((_) {}),
      _taskRepository.watchCompletionHistory().map((_) {}),
      _projectRepository.watchAll().map((_) {}),
      _projectAnchorStateRepository.watchAll().map((_) {}),
    ]).debounceTime(const Duration(milliseconds: 150));

    return triggers
        .startWith(null)
        .switchMap(
          (_) => Stream.fromFuture(
            _allocationOrchestrator.getAllocationSnapshot(),
          ),
        );
  }
}
