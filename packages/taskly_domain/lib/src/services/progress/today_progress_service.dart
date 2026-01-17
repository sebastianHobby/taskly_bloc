import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/src/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/services/time/temporal_trigger_service.dart';

class TodayProgress {
  const TodayProgress({required this.doneCount, required this.totalCount});

  final int doneCount;
  final int totalCount;

  double get fraction {
    if (totalCount <= 0) return 0;
    return (doneCount / totalCount).clamp(0.0, 1.0);
  }
}

/// Computes today progress from allocation snapshot membership.
///
/// Source of truth:
/// - total = number of task refs in today's allocation snapshot
/// - done  = number of those tasks whose `completed` is true
class TodayProgressService {
  TodayProgressService({
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required TaskRepositoryContract taskRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _allocationSnapshotRepository = allocationSnapshotRepository,
       _taskRepository = taskRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService;

  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;

  Stream<TodayProgress> watchTodayProgress() {
    final triggers = Rx.merge([
      Stream<void>.value(null),
      _temporalTriggerService.events
          .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
          .map((_) => null),
    ]);

    return triggers
        .map((_) => _dayKeyService.todayDayKeyUtc())
        .distinct((a, b) => a.isAtSameMomentAs(b))
        .switchMap((dayKeyUtc) {
          return _allocationSnapshotRepository
              .watchLatestTaskRefsForUtcDay(dayKeyUtc)
              .switchMap((refs) {
                final ids = refs
                    .map((r) => r.taskId)
                    .where((id) => id.isNotEmpty)
                    .toList(growable: false);

                if (ids.isEmpty) {
                  return Stream.value(const TodayProgress(doneCount: 0, totalCount: 0));
                }

                return _taskRepository.watchByIds(ids).map((tasks) {
                  final doneCount = tasks.where((t) => t.completed).length;
                  return TodayProgress(doneCount: doneCount, totalCount: ids.length);
                });
              });
        })
        .distinct((a, b) => a.doneCount == b.doneCount && a.totalCount == b.totalCount);
  }
}
