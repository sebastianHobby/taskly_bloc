import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide AttentionRule;
import 'package:taskly_bloc/data/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/attention_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/domain/models/settings/project_health_review_settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';

import '../../../helpers/test_db.dart';
import '../../../mocks/fake_id_generator.dart';
import '../../../mocks/repository_mocks.dart';

void main() {
  group('AttentionEvaluator project-health reviews', () {
    Future<
      ({
        AppDatabase db,
        FakeIdGenerator idGenerator,
        ValueRepository valueRepository,
        ProjectRepository projectRepository,
        TaskRepository taskRepository,
        SettingsRepository settingsRepository,
        AllocationSnapshotRepository allocationSnapshotRepository,
        AttentionRepository attentionRepository,
        AttentionEvaluator evaluator,
      })
    >
    harness() async {
      final db = createTestDb();
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
      final attentionRepository = AttentionRepository(db: db);

      final evaluator = AttentionEvaluator(
        attentionRepository: attentionRepository,
        allocationSnapshotRepository: allocationSnapshotRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        settingsRepository: settingsRepository,
      );

      return (
        db: db,
        idGenerator: idGenerator,
        valueRepository: valueRepository,
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        settingsRepository: settingsRepository,
        allocationSnapshotRepository: allocationSnapshotRepository,
        attentionRepository: attentionRepository,
        evaluator: evaluator,
      );
    }

    AttentionRule reviewRule({required String id, required String predicate}) {
      final now = DateTime.now();
      return AttentionRule(
        id: id,
        ruleKey: 'test_review_project_$predicate',
        ruleType: AttentionRuleType.review,
        triggerType: AttentionTriggerType.realtime,
        triggerConfig: const <String, dynamic>{},
        entitySelector: {'entity_type': 'project', 'predicate': predicate},
        severity: AttentionSeverity.info,
        displayConfig: {
          'title': 'Test',
          'description': 'Test',
          'icon': 'info',
        },
        resolutionActions: const ['reviewed', 'dismissed'],
        active: true,
        source: AttentionEntitySource.userCreated,
        createdAt: now,
        updatedAt: now,
      );
    }

    test(
      'highValueNeglected emits item when thresholds + coverage met',
      () async {
        final h = await harness();
        addTearDown(() async => closeTestDb(h.db));

        // Values
        await h.valueRepository.create(
          name: 'A',
          color: '#000000',
          priority: ValuePriority.high,
        );
        final valueAId = h.idGenerator.valueId(name: 'A');

        // Projects: P1 should be flagged, P2 used for snapshot coverage.
        await h.projectRepository.create(name: 'P1', valueIds: [valueAId]);
        await h.projectRepository.create(name: 'P2', valueIds: [valueAId]);
        const p1Id = 'project-0';
        const p2Id = 'project-1';

        // One task in P2 so snapshots have an entity.
        await h.taskRepository.create(name: 't2', projectId: p2Id);
        const t2Id = 'task-0';

        // Settings: make rule easy to satisfy.
        await h.settingsRepository.save(
          SettingsKey.allocation,
          const AllocationConfig(
            focusMode: FocusMode.personalized,
            projectHealthReviewSettings: ProjectHealthReviewSettings(
              historyWindowDays: 14,
              minCoverageDays: 3,
              highValueImportanceThreshold: 3,
              highValueNeglectedDaysThreshold: 7,
              highValueNeglectedTopK: 3,
            ),
          ),
        );

        // Seed rule.
        await h.attentionRepository.upsertRule(
          reviewRule(id: 'rule-1', predicate: 'highValueNeglected'),
        );

        // Provide snapshot coverage in the window (but do not allocate P1).
        final today = dateOnly(DateTime.now().toUtc());
        for (var i = 0; i < 3; i++) {
          await h.allocationSnapshotRepository.persistAllocatedForUtcDay(
            dayUtc: today.subtract(Duration(days: i)),
            allocated: [
              AllocationSnapshotEntryInput(
                entity: const AllocationEntityRef(
                  type: AllocationSnapshotEntityType.task,
                  id: t2Id,
                ),
                projectId: p2Id,
                effectivePrimaryValueId: valueAId,
                allocationScore: 1,
              ),
            ],
          );
        }

        final items = await h.evaluator.evaluateReviews();
        expect(items.where((i) => i.entityId == p1Id), isNotEmpty);
      },
    );

    test('settings change invalidates project-health state_hash', () async {
      final h = await harness();
      addTearDown(() async => closeTestDb(h.db));

      await h.valueRepository.create(
        name: 'A',
        color: '#000000',
        priority: ValuePriority.high,
      );
      final valueAId = h.idGenerator.valueId(name: 'A');

      await h.projectRepository.create(name: 'P1', valueIds: [valueAId]);
      await h.projectRepository.create(name: 'P2', valueIds: [valueAId]);
      const p1Id = 'project-0';
      const p2Id = 'project-1';

      await h.taskRepository.create(name: 't2', projectId: p2Id);
      const t2Id = 'task-0';

      await h.attentionRepository.upsertRule(
        reviewRule(id: 'rule-1', predicate: 'highValueNeglected'),
      );

      final today = dateOnly(DateTime.now().toUtc());
      for (var i = 0; i < 3; i++) {
        await h.allocationSnapshotRepository.persistAllocatedForUtcDay(
          dayUtc: today.subtract(Duration(days: i)),
          allocated: [
            AllocationSnapshotEntryInput(
              entity: const AllocationEntityRef(
                type: AllocationSnapshotEntityType.task,
                id: t2Id,
              ),
              projectId: p2Id,
              effectivePrimaryValueId: valueAId,
              allocationScore: 1,
            ),
          ],
        );
      }

      await h.settingsRepository.save(
        SettingsKey.allocation,
        const AllocationConfig(
          focusMode: FocusMode.personalized,
          projectHealthReviewSettings: ProjectHealthReviewSettings(
            historyWindowDays: 14,
            minCoverageDays: 3,
            highValueImportanceThreshold: 3,
            highValueNeglectedDaysThreshold: 7,
            highValueNeglectedTopK: 3,
          ),
        ),
      );

      final itemsA = await h.evaluator.evaluateReviews();
      final p1ItemA = itemsA.firstWhere((i) => i.entityId == p1Id);
      final hashA = p1ItemA.metadata?['state_hash'] as String?;
      expect(hashA, isNotNull);

      await h.settingsRepository.save(
        SettingsKey.allocation,
        const AllocationConfig(
          focusMode: FocusMode.personalized,
          projectHealthReviewSettings: ProjectHealthReviewSettings(
            historyWindowDays: 14,
            minCoverageDays: 3,
            highValueImportanceThreshold: 3,
            highValueNeglectedDaysThreshold: 8,
            highValueNeglectedTopK: 3,
          ),
        ),
      );

      final itemsB = await h.evaluator.evaluateReviews();
      final p1ItemB = itemsB.firstWhere((i) => i.entityId == p1Id);
      final hashB = p1ItemB.metadata?['state_hash'] as String?;

      expect(hashB, isNotNull);
      expect(hashB, isNot(equals(hashA)));
    });

    test(
      'noAllocatableTasks gating writes first-day but does not emit yet',
      () async {
        final h = await harness();
        addTearDown(() async => closeTestDb(h.db));

        await h.valueRepository.create(
          name: 'A',
          color: '#000000',
          priority: ValuePriority.medium,
        );
        final valueAId = h.idGenerator.valueId(name: 'A');

        await h.projectRepository.create(name: 'P1', valueIds: [valueAId]);
        const p1Id = 'project-0';

        // Task is not allocatable: starts tomorrow.
        final today = dateOnly(DateTime.now().toUtc());
        await h.taskRepository.create(
          name: 't1',
          projectId: p1Id,
          startDate: today.add(const Duration(days: 1)),
        );

        await h.attentionRepository.upsertRule(
          reviewRule(id: 'rule-1', predicate: 'noAllocatableTasks'),
        );

        await h.settingsRepository.save(
          SettingsKey.allocation,
          const AllocationConfig(
            focusMode: FocusMode.personalized,
            projectHealthReviewSettings: ProjectHealthReviewSettings(
              noAllocatableGatingDays: 2,
              noAllocatableTopK: 3,
            ),
          ),
        );

        final items = await h.evaluator.evaluateReviews();
        expect(items.where((i) => i.entityId == p1Id), isEmpty);

        final cfg = await h.settingsRepository.load(SettingsKey.allocation);
        expect(
          cfg.projectHealthReviewSettings.noAllocatableFirstDayUtc[p1Id],
          isNotNull,
        );
      },
    );

    test(
      'noAllocatableTasks emits after gate has persisted long enough',
      () async {
        final h = await harness();
        addTearDown(() async => closeTestDb(h.db));

        await h.valueRepository.create(
          name: 'A',
          color: '#000000',
          priority: ValuePriority.medium,
        );
        final valueAId = h.idGenerator.valueId(name: 'A');

        await h.projectRepository.create(name: 'P1', valueIds: [valueAId]);
        const p1Id = 'project-0';

        // Task is not allocatable: starts tomorrow.
        final today = dateOnly(DateTime.now().toUtc());
        await h.taskRepository.create(
          name: 't1',
          projectId: p1Id,
          startDate: today.add(const Duration(days: 1)),
        );

        await h.attentionRepository.upsertRule(
          reviewRule(id: 'rule-1', predicate: 'noAllocatableTasks'),
        );

        final firstDayIso = today
            .subtract(const Duration(days: 2))
            .toIso8601String();

        await h.settingsRepository.save(
          SettingsKey.allocation,
          AllocationConfig(
            focusMode: FocusMode.personalized,
            projectHealthReviewSettings: ProjectHealthReviewSettings(
              noAllocatableGatingDays: 2,
              noAllocatableTopK: 3,
              noAllocatableFirstDayUtc: {p1Id: firstDayIso},
            ),
          ),
        );

        final items = await h.evaluator.evaluateReviews();
        expect(items.where((i) => i.entityId == p1Id), isNotEmpty);
      },
    );
  });
}
