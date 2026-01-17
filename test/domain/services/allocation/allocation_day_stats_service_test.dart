import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_data/db.dart';

import '../../../helpers/test_db.dart';
import '../../../mocks/fake_id_generator.dart';
import '../../../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';

void main() {
  group('AllocationDayStatsService', () {
    test('computes allocated vs completed counts and repeat metric', () async {
      final db = createTestDb();
      addTearDown(db.close);

      final idGenerator = FakeIdGenerator();
      final occurrenceExpander = MockOccurrenceStreamExpanderContract();
      final occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      final valueRepository = ValueRepository(
        driftDb: db,
        idGenerator: idGenerator,
      );
      final projectRepository = ProjectRepository(
        driftDb: db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
      final taskRepository = TaskRepository(
        driftDb: db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
      final settingsRepository = SettingsRepository(driftDb: db);
      final allocationSnapshotRepository = AllocationSnapshotRepository(db: db);

      // Values
      await valueRepository.create(
        name: 'A',
        color: '#000000',
        priority: ValuePriority.medium,
      );
      await valueRepository.create(
        name: 'B',
        color: '#111111',
        priority: ValuePriority.medium,
      );
      final valueAId = idGenerator.valueId(name: 'A');
      final valueBId = idGenerator.valueId(name: 'B');

      // Ensure stats uses the persisted project-health settings (no presets).
      await settingsRepository.save(
        SettingsKey.allocation,
        AllocationConfig(
          focusMode: FocusMode.personalized,
          projectHealthReviewSettings: const ProjectHealthReviewSettings(
            historyWindowDays: 7,
            minCoverageDays: 1,
          ),
        ),
      );

      // Project with primary value A.
      await projectRepository.create(
        name: 'P1',
        valueIds: [valueAId],
      );
      const projectId = 'project-0';

      // Tasks
      await taskRepository.create(
        name: 't1',
        projectId: projectId,
      );
      await taskRepository.create(
        name: 't2',
        projectId: projectId,
        valueIds: [valueBId],
      );
      await taskRepository.create(
        name: 't3',
        valueIds: [valueAId],
      );
      const t1Id = 'task-0';
      const t2Id = 'task-1';
      const t3Id = 'task-2';

      final day = dateOnly(DateTime.utc(2026, 1, 5));
      final prevDay = day.subtract(const Duration(days: 1));

      // Snapshots: prevDay allocates t1 (not completed), day allocates t1 + t3.
      await allocationSnapshotRepository.persistAllocatedForUtcDay(
        dayUtc: prevDay,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 2,
        allocated: [
          AllocationSnapshotEntryInput(
            entity: const AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 'task-0',
            ),
            projectId: projectId,
            effectivePrimaryValueId: valueAId,
            allocationScore: 1,
          ),
        ],
      );
      await allocationSnapshotRepository.persistAllocatedForUtcDay(
        dayUtc: day,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 3,
        allocated: [
          AllocationSnapshotEntryInput(
            entity: const AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 'task-0',
            ),
            projectId: projectId,
            effectivePrimaryValueId: valueAId,
            allocationScore: 1,
          ),
          AllocationSnapshotEntryInput(
            entity: const AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 'task-2',
            ),
            projectId: null,
            effectivePrimaryValueId: valueAId,
            allocationScore: 1,
          ),
        ],
      );

      // Completion history: day completes t1 + t2.
      await db
          .into(db.taskCompletionHistoryTable)
          .insert(
            TaskCompletionHistoryTableCompanion.insert(
              id: idGenerator.taskCompletionId(
                taskId: t1Id,
                occurrenceDate: null,
              ),
              taskId: t1Id,
              completedAt: drift.Value(day.add(const Duration(hours: 12))),
              createdAt: drift.Value(day.add(const Duration(hours: 12))),
              updatedAt: drift.Value(day.add(const Duration(hours: 12))),
            ),
          );
      await db
          .into(db.taskCompletionHistoryTable)
          .insert(
            TaskCompletionHistoryTableCompanion.insert(
              id: idGenerator.taskCompletionId(
                taskId: t2Id,
                occurrenceDate: null,
              ),
              taskId: t2Id,
              completedAt: drift.Value(day.add(const Duration(hours: 13))),
              createdAt: drift.Value(day.add(const Duration(hours: 13))),
              updatedAt: drift.Value(day.add(const Duration(hours: 13))),
            ),
          );

      final service = AllocationDayStatsService(
        allocationSnapshotRepository: allocationSnapshotRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        settingsRepository: settingsRepository,
      );

      final stats = await service.computeForUtcDay(
        dayUtc: day,
        repeatWindowDays: 2,
      );

      expect(stats.allocatedTaskCount, 2);
      expect(stats.allocatedCompletedCount, 1);
      expect(stats.allocatedNotCompletedCount, 1);
      expect(stats.completedUnallocatedCount, 1);

      expect(stats.allocatedByEffectivePrimaryValueId[valueAId], 2);
      expect(stats.completedByEffectivePrimaryValueId[valueAId], 1);
      expect(stats.completedByEffectivePrimaryValueId[valueBId], 1);

      expect(stats.allocatedTasksInProject[projectId], 1);
      expect(stats.completedTasksInProject[projectId], 2);
      expect(stats.projectProgressedToday[projectId], true);

      expect(stats.daysSinceLastAllocatedCoverageSufficient, true);
      expect(stats.daysSinceLastAllocatedForProject[projectId], 0);

      // Repeat: t1 was allocated prevDay but not completed that day.
      expect(stats.repeatCoverageDays, 2);
      expect(stats.repeatAllocatedNotCompletedByTaskId[t1Id], 1);
      expect(stats.repeatAllocatedNotCompletedByTaskId[t3Id], 1);
    });

    test('handles missing allocation snapshot safely', () async {
      final db = createTestDb();
      addTearDown(db.close);

      final idGenerator = FakeIdGenerator();
      final occurrenceExpander = MockOccurrenceStreamExpanderContract();
      final occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      final valueRepository = ValueRepository(
        driftDb: db,
        idGenerator: idGenerator,
      );
      final projectRepository = ProjectRepository(
        driftDb: db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
      final taskRepository = TaskRepository(
        driftDb: db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
      final settingsRepository = SettingsRepository(driftDb: db);
      final allocationSnapshotRepository = AllocationSnapshotRepository(db: db);

      await settingsRepository.save(
        SettingsKey.allocation,
        AllocationConfig(
          focusMode: FocusMode.personalized,
          projectHealthReviewSettings: const ProjectHealthReviewSettings(
            historyWindowDays: 7,
            minCoverageDays: 1,
          ),
        ),
      );

      // Create a project + task, but DO NOT persist an allocation snapshot.
      await valueRepository.create(
        name: 'A',
        color: '#000000',
        priority: ValuePriority.medium,
      );
      final valueId = idGenerator.valueId(name: 'A');

      await projectRepository.create(name: 'P1', valueIds: [valueId]);
      await taskRepository.create(name: 't1', projectId: 'project-0');

      final day = dateOnly(DateTime.utc(2026, 1, 6));

      // Completion history exists for the day.
      await db
          .into(db.taskCompletionHistoryTable)
          .insert(
            TaskCompletionHistoryTableCompanion.insert(
              id: idGenerator.taskCompletionId(
                taskId: 'task-0',
                occurrenceDate: null,
              ),
              taskId: 'task-0',
              completedAt: drift.Value(day.add(const Duration(hours: 8))),
              createdAt: drift.Value(day.add(const Duration(hours: 8))),
              updatedAt: drift.Value(day.add(const Duration(hours: 8))),
            ),
          );

      final service = AllocationDayStatsService(
        allocationSnapshotRepository: allocationSnapshotRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        settingsRepository: settingsRepository,
      );

      final stats = await service.computeForUtcDay(dayUtc: day);

      expect(stats.allocatedTaskCount, 0);
      expect(stats.allocatedCompletedCount, 0);
      expect(stats.allocatedNotCompletedCount, 0);
      expect(stats.completedUnallocatedCount, 1);

      expect(stats.repeatCoverageDays, 0);
      expect(stats.daysSinceLastAllocatedCoverageSufficient, false);
    });
  });
}
