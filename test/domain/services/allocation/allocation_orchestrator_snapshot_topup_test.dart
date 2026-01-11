import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';

import '../../../helpers/fallback_values.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';

class MockAllocationSnapshotRepositoryContract extends Mock
    implements AllocationSnapshotRepositoryContract {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

void main() {
  setUpAll(registerAllFallbackValues);

  Value value({required String id}) {
    final normalizedId = id.length >= 8 ? id : id.padRight(8, '0');
    final now = DateTime.utc(2026, 1, 1);
    return Value(
      id: normalizedId,
      createdAt: now,
      updatedAt: now,
      name: 'V',
      priority: ValuePriority.high,
    );
  }

  Task task({required String id, required Value v}) {
    final now = DateTime.utc(2026, 1, 1);
    return Task(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: id,
      completed: false,
      values: [v],
      primaryValueId: v.id,
    );
  }

  group('AllocationOrchestrator snapshot top-up', () {
    test(
      'tops up when previous snapshot had shortage and pool increased',
      () async {
        final taskRepository = MockTaskRepositoryContract();
        final valueRepository = MockValueRepositoryContract();
        final settingsRepository = MockSettingsRepositoryContract();
        final analyticsService = MockAnalyticsService();
        final projectRepository = MockProjectRepositoryContract();
        final snapshotRepository = MockAllocationSnapshotRepositoryContract();
        final dayKeyService = MockHomeDayKeyService();

        when(
          () => dayKeyService.todayDayKeyUtc(nowUtc: any(named: 'nowUtc')),
        ).thenReturn(DateTime.utc(2026, 1, 2));
        when(dayKeyService.todayDayKeyUtc).thenReturn(
          DateTime.utc(2026, 1, 2),
        );

        final v = value(id: 'v1');
        final t1 = task(id: 't1', v: v);
        final t2 = task(id: 't2', v: v);
        final t3 = task(id: 't3', v: v);

        final tasksSubject = BehaviorSubject<List<Task>>.seeded([t1, t2, t3]);
        addTearDown(tasksSubject.close);

        when(
          () => taskRepository.watchAll(any()),
        ).thenAnswer((_) => tasksSubject.stream);
        when(
          projectRepository.watchAll,
        ).thenAnswer((_) => Stream.value(const []));
        when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
          (_) => Stream.value(const AllocationConfig(dailyLimit: 3)),
        );

        when(valueRepository.getAll).thenAnswer((_) async => [v]);
        when(
          () => analyticsService.getRecentCompletionsByValue(
            days: any(named: 'days'),
          ),
        ).thenAnswer((_) async => const {});

        when(() => snapshotRepository.getLatestForUtcDay(any())).thenAnswer(
          (invocation) async {
            final dayUtc = invocation.positionalArguments.first as DateTime;
            return AllocationSnapshot(
              id: 'snap-1',
              dayUtc: dayUtc,
              version: 1,
              capAtGeneration: 3,
              candidatePoolCountAtGeneration: 1,
              allocated: const [
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't1',
                  ),
                ),
              ],
            );
          },
        );

        when(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: any(named: 'dayUtc'),
            capAtGeneration: any(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: any(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: any(named: 'allocated'),
          ),
        ).thenAnswer((_) async {});

        final orchestrator = AllocationOrchestrator(
          taskRepository: taskRepository,
          valueRepository: valueRepository,
          settingsRepository: settingsRepository,
          analyticsService: analyticsService,
          projectRepository: projectRepository,
          dayKeyService: dayKeyService,
          allocationSnapshotRepository: snapshotRepository,
        );

        final sub = orchestrator.watchAllocation().listen((_) {});
        addTearDown(sub.cancel);

        await pumpEventQueue();

        final captured = verify(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: captureAny(named: 'dayUtc'),
            capAtGeneration: captureAny(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: captureAny(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: captureAny(named: 'allocated'),
          ),
        ).captured;

        final allocated = captured[3] as List<AllocationSnapshotEntryInput>;
        expect(
          allocated.map((e) => e.entity.id).toSet(),
          {'t1', 't2', 't3'},
        );
      },
    );

    test(
      'does not top up when previous snapshot was not a shortage',
      () async {
        final taskRepository = MockTaskRepositoryContract();
        final valueRepository = MockValueRepositoryContract();
        final settingsRepository = MockSettingsRepositoryContract();
        final analyticsService = MockAnalyticsService();
        final projectRepository = MockProjectRepositoryContract();
        final snapshotRepository = MockAllocationSnapshotRepositoryContract();
        final dayKeyService = MockHomeDayKeyService();

        when(
          () => dayKeyService.todayDayKeyUtc(nowUtc: any(named: 'nowUtc')),
        ).thenReturn(DateTime.utc(2026, 1, 2));
        when(dayKeyService.todayDayKeyUtc).thenReturn(
          DateTime.utc(2026, 1, 2),
        );

        final v = value(id: 'v1');
        final t1 = task(id: 't1', v: v);
        final t2 = task(id: 't2', v: v);
        final t3 = task(id: 't3', v: v);
        final t4 = task(id: 't4', v: v);

        final tasksSubject = BehaviorSubject<List<Task>>.seeded([
          t1,
          t2,
          t3,
          t4,
        ]);
        addTearDown(tasksSubject.close);

        when(
          () => taskRepository.watchAll(any()),
        ).thenAnswer((_) => tasksSubject.stream);
        when(
          projectRepository.watchAll,
        ).thenAnswer((_) => Stream.value(const []));
        when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
          (_) => Stream.value(const AllocationConfig(dailyLimit: 3)),
        );

        when(valueRepository.getAll).thenAnswer((_) async => [v]);
        when(
          () => analyticsService.getRecentCompletionsByValue(
            days: any(named: 'days'),
          ),
        ).thenAnswer((_) async => const {});

        when(() => snapshotRepository.getLatestForUtcDay(any())).thenAnswer(
          (invocation) async {
            final dayUtc = invocation.positionalArguments.first as DateTime;
            return AllocationSnapshot(
              id: 'snap-1',
              dayUtc: dayUtc,
              version: 1,
              capAtGeneration: 3,
              candidatePoolCountAtGeneration: 4,
              allocated: const [
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't1',
                  ),
                ),
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't2',
                  ),
                ),
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't3',
                  ),
                ),
              ],
            );
          },
        );

        when(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: any(named: 'dayUtc'),
            capAtGeneration: any(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: any(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: any(named: 'allocated'),
          ),
        ).thenAnswer((_) async {});

        final orchestrator = AllocationOrchestrator(
          taskRepository: taskRepository,
          valueRepository: valueRepository,
          settingsRepository: settingsRepository,
          analyticsService: analyticsService,
          projectRepository: projectRepository,
          dayKeyService: dayKeyService,
          allocationSnapshotRepository: snapshotRepository,
        );

        final sub = orchestrator.watchAllocation().listen((_) {});
        addTearDown(sub.cancel);

        await pumpEventQueue();

        final captured = verify(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: captureAny(named: 'dayUtc'),
            capAtGeneration: captureAny(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: captureAny(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: captureAny(named: 'allocated'),
          ),
        ).captured;

        final allocated = captured[3] as List<AllocationSnapshotEntryInput>;
        expect(allocated.map((e) => e.entity.id).toSet(), {'t1', 't2', 't3'});
      },
    );

    test(
      'does not refill after completion even if pool later increases',
      () async {
        final taskRepository = MockTaskRepositoryContract();
        final valueRepository = MockValueRepositoryContract();
        final settingsRepository = MockSettingsRepositoryContract();
        final analyticsService = MockAnalyticsService();
        final projectRepository = MockProjectRepositoryContract();
        final snapshotRepository = MockAllocationSnapshotRepositoryContract();
        final dayKeyService = MockHomeDayKeyService();

        when(
          () => dayKeyService.todayDayKeyUtc(nowUtc: any(named: 'nowUtc')),
        ).thenReturn(DateTime.utc(2026, 1, 2));
        when(dayKeyService.todayDayKeyUtc).thenReturn(
          DateTime.utc(2026, 1, 2),
        );

        final v = value(id: 'v1');
        final t1 = task(id: 't1', v: v);
        final t2 = task(id: 't2', v: v);
        final t4 = task(id: 't4', v: v);
        final t5 = task(id: 't5', v: v);

        // Ensure snapshot persistence still respects daily limit.
        final tasksSubject = BehaviorSubject<List<Task>>.seeded([
          t1,
          t2,
          t4,
          t5,
        ]);
        addTearDown(tasksSubject.close);

        when(
          () => taskRepository.watchAll(any()),
        ).thenAnswer((_) => tasksSubject.stream);
        when(
          projectRepository.watchAll,
        ).thenAnswer((_) => Stream.value(const []));
        when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
          (_) => Stream.value(const AllocationConfig(dailyLimit: 3)),
        );

        when(valueRepository.getAll).thenAnswer((_) async => [v]);
        when(
          () => analyticsService.getRecentCompletionsByValue(
            days: any(named: 'days'),
          ),
        ).thenAnswer((_) async => const {});

        when(() => snapshotRepository.getLatestForUtcDay(any())).thenAnswer(
          (invocation) async {
            final dayUtc = invocation.positionalArguments.first as DateTime;
            return AllocationSnapshot(
              id: 'snap-1',
              dayUtc: dayUtc,
              version: 1,
              capAtGeneration: 3,
              candidatePoolCountAtGeneration: 4,
              allocated: const [
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't1',
                  ),
                ),
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't2',
                  ),
                ),
                AllocationSnapshotEntryInput(
                  entity: AllocationEntityRef(
                    type: AllocationSnapshotEntityType.task,
                    id: 't3',
                  ),
                ),
              ],
            );
          },
        );

        when(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: any(named: 'dayUtc'),
            capAtGeneration: any(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: any(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: any(named: 'allocated'),
          ),
        ).thenAnswer((_) async {});

        final orchestrator = AllocationOrchestrator(
          taskRepository: taskRepository,
          valueRepository: valueRepository,
          settingsRepository: settingsRepository,
          analyticsService: analyticsService,
          projectRepository: projectRepository,
          dayKeyService: dayKeyService,
          allocationSnapshotRepository: snapshotRepository,
        );

        final sub = orchestrator.watchAllocation().listen((_) {});
        addTearDown(sub.cancel);

        await pumpEventQueue();

        final captured = verify(
          () => snapshotRepository.persistAllocatedForUtcDay(
            dayUtc: captureAny(named: 'dayUtc'),
            capAtGeneration: captureAny(named: 'capAtGeneration'),
            candidatePoolCountAtGeneration: captureAny(
              named: 'candidatePoolCountAtGeneration',
            ),
            allocated: captureAny(named: 'allocated'),
          ),
        ).captured;

        final allocated = captured[3] as List<AllocationSnapshotEntryInput>;
        expect(allocated.map((e) => e.entity.id).toSet(), {'t1', 't2'});
      },
    );
  });
}
