@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AnalyticsRepositoryImpl', () {
    testSafe('saveSnapshot inserts and getSnapshots filters', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      final now = DateTime.utc(2025, 1, 10);
      final snapshot = AnalyticsSnapshot(
        id: '',
        entityType: 'task',
        entityId: 'task-1',
        snapshotDate: now,
        metrics: const {'a': 1},
      );

      await repo.saveSnapshot(snapshot);

      final results = await repo.getSnapshots(
        entityType: 'task',
        entityId: 'task-1',
        range: DateRange(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.entityId, equals('task-1'));
      expect(results.single.metrics['a'], equals(1));
    });

    testSafe('saveSnapshot updates when row exists', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      final date = DateTime.utc(2025, 1, 2);
      const id = 'snap-1';

      await repo.saveSnapshot(
        AnalyticsSnapshot(
          id: id,
          entityType: 'project',
          entityId: 'project-1',
          snapshotDate: date,
          metrics: const {'x': 1},
        ),
      );

      await repo.saveSnapshot(
        AnalyticsSnapshot(
          id: id,
          entityType: 'project',
          entityId: 'project-1',
          snapshotDate: date,
          metrics: const {'x': 2},
        ),
      );

      final row = await db.select(db.analyticsSnapshots).getSingle();
      expect(row.metrics['x'], equals(2));
    });

    testSafe('saveCorrelation infers types and inserts', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      await repo.saveCorrelation(
        CorrelationResult(
          sourceLabel: 'Task',
          targetLabel: 'Project',
          coefficient: 0.4,
          strength: CorrelationStrength.moderatePositive,
          sourceId: 'task-1',
          targetId: 'project-1',
        ),
      );

      final row = await db.select(db.analyticsCorrelations).getSingle();
      expect(row.sourceType, equals('task'));
      expect(row.targetType, equals('project'));
      expect(row.correlationType, equals('task_project'));
    });

    testSafe('getCachedCorrelations resolves labels and parses JSON', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('task-1'),
              name: 'Task One',
              completed: const drift.Value(false),
            ),
          );

      final significance = StatisticalSignificance(
        pValue: 0.01,
        tStatistic: 2.0,
        degreesOfFreedom: 10,
        standardError: 0.1,
        isSignificant: true,
      );
      await db
          .into(db.analyticsCorrelations)
          .insert(
            AnalyticsCorrelationsCompanion(
              id: const drift.Value('c1'),
              correlationType: const drift.Value('task_project'),
              sourceType: const drift.Value('task'),
              sourceId: const drift.Value('task-1'),
              targetType: const drift.Value('project'),
              targetId: const drift.Value('project-1'),
              periodStart: drift.Value(DateTime.utc(2025, 1, 1)),
              periodEnd: drift.Value(DateTime.utc(2025, 1, 2)),
              coefficient: const drift.Value(0.6),
              sampleSize: const drift.Value(5),
              strength: drift.Value(CorrelationStrength.strongPositive.name),
              insight: const drift.Value('ok'),
              valueWithSource: const drift.Value(1.0),
              valueWithoutSource: const drift.Value(0.0),
              computedAt: drift.Value(DateTime.utc(2025, 1, 2)),
              statisticalSignificance: drift.Value(significance.toJson()),
            ),
          );

      final results = await repo.getCachedCorrelations(
        correlationType: 'task_project',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 3),
        ),
      );

      expect(results.single.sourceLabel, equals('Task One'));
      expect(results.single.statisticalSignificance?.pValue, equals(0.01));
    });

    testSafe('saveInsight/getRecentInsights/dismissInsight', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      final insight = AnalyticsInsight(
        id: '',
        insightType: InsightType.correlationDiscovery,
        title: 'Hello',
        description: 'World',
        generatedAt: DateTime.utc(2025, 1, 1),
        periodStart: DateTime.utc(2024, 12, 1),
        periodEnd: DateTime.utc(2024, 12, 31),
        metadata: const {'x': 1},
        score: 0.5,
        confidence: 0.8,
        isPositive: true,
      );

      await repo.saveInsight(insight);

      final results = await repo.getRecentInsights(
        range: DateRange(
          start: DateTime.utc(2024, 12, 1),
          end: DateTime.utc(2025, 2, 1),
        ),
      );
      expect(results.length, equals(1));

      await repo.dismissInsight(results.single.id);
      final remaining = await db.select(db.analyticsInsights).get();
      expect(remaining, isEmpty);
    });

    testSafe('saveSnapshots and saveCorrelations batch paths', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );
      final day = DateTime.utc(2025, 2, 1);

      await repo.saveSnapshots([
        AnalyticsSnapshot(
          id: '',
          entityType: 'task',
          entityId: 'task-1',
          snapshotDate: day,
          metrics: const {'v': 1},
        ),
        AnalyticsSnapshot(
          id: '',
          entityType: 'project',
          entityId: 'project-1',
          snapshotDate: day,
          metrics: const {'v': 2},
        ),
      ]);

      await repo.saveCorrelations([
        CorrelationResult(
          sourceLabel: 'S',
          targetLabel: 'T',
          coefficient: 0.2,
          strength: CorrelationStrength.weakPositive,
          sourceId: 'unknown-a',
          targetId: 'unknown-b',
        ),
      ]);

      expect(await db.select(db.analyticsSnapshots).get(), hasLength(2));
      expect(await db.select(db.analyticsCorrelations).get(), hasLength(1));
    });

    testSafe(
      'getCachedCorrelations fallback labels and parse fallbacks',
      () async {
        final db = createAutoClosingDb();
        final repo = AnalyticsRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );

        await db
            .into(db.analyticsCorrelations)
            .insert(
              AnalyticsCorrelationsCompanion(
                id: const drift.Value('c-fallback'),
                correlationType: const drift.Value('general'),
                sourceType: const drift.Value('unknown'),
                sourceId: const drift.Value('src-1'),
                targetType: const drift.Value('unknown'),
                targetId: const drift.Value('tgt-1'),
                periodStart: drift.Value(DateTime.utc(2025, 1, 1)),
                periodEnd: drift.Value(DateTime.utc(2025, 1, 2)),
                coefficient: const drift.Value(0.0),
                sampleSize: const drift.Value(1),
                strength: const drift.Value('not-a-real-strength'),
                insight: const drift.Value(''),
                computedAt: drift.Value(DateTime.utc(2025, 1, 2)),
                statisticalSignificance: const drift.Value({'bad': 'value'}),
                performanceMetrics: const drift.Value({'bad': 'value'}),
              ),
            );

        final results = await repo.getCachedCorrelations(
          correlationType: 'general',
          range: DateRange(
            start: DateTime.utc(2025, 1, 1),
            end: DateTime.utc(2025, 1, 3),
          ),
        );

        expect(results.single.sourceLabel, 'unknown-src-1');
        expect(results.single.targetLabel, 'unknown-tgt-1');
        expect(results.single.strength, CorrelationStrength.negligible);
        expect(results.single.statisticalSignificance, isNull);
        expect(results.single.performanceMetrics, isNull);
      },
    );

    testSafe('helper methods cover parsing and threshold branches', () async {
      final db = createAutoClosingDb();
      final repo = AnalyticsRepositoryImpl(
        db,
        IdGenerator.withUserId('user-1'),
      );

      expect(
        repo.parseStrength('strongPositive'),
        CorrelationStrength.strongPositive,
      );
      expect(repo.parseStrength('invalid'), isNull);

      expect(repo.inferEntityTypeFromId('task-123'), 'task');
      expect(repo.inferEntityTypeFromId('project-123'), 'project');
      expect(repo.inferEntityTypeFromId('tracker-123'), 'tracker');
      expect(repo.inferEntityTypeFromId('label-123'), 'label');
      expect(repo.inferEntityTypeFromId('mystery'), 'unknown');

      expect(
        repo.inferCorrelationType(sourceType: 'task', targetType: 'project'),
        'task_project',
      );
      expect(
        repo.inferCorrelationType(sourceType: 'unknown', targetType: 'project'),
        'general',
      );

      expect(
        repo.strengthFromCoefficient(0.8),
        CorrelationStrength.strongPositive,
      );
      expect(
        repo.strengthFromCoefficient(0.4),
        CorrelationStrength.moderatePositive,
      );
      expect(
        repo.strengthFromCoefficient(0.2),
        CorrelationStrength.weakPositive,
      );
      expect(
        repo.strengthFromCoefficient(-0.2),
        CorrelationStrength.weakNegative,
      );
      expect(
        repo.strengthFromCoefficient(-0.4),
        CorrelationStrength.moderateNegative,
      );
      expect(
        repo.strengthFromCoefficient(-0.8),
        CorrelationStrength.strongNegative,
      );
      expect(
        repo.strengthFromCoefficient(0.01),
        CorrelationStrength.negligible,
      );

      expect(
        repo.parseInsightType('not-a-type'),
        InsightType.correlationDiscovery,
      );
      expect(repo.fallbackLabel('task', 't1'), 'task-t1');
    });

    testSafe(
      'resolveEntityLabelsByType resolves task project and tracker labels',
      () async {
        final db = createAutoClosingDb();
        final repo = AnalyticsRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );

        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: const drift.Value('task-1'),
                name: 'Task Label',
                completed: const drift.Value(false),
              ),
            );
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion.insert(
                id: const drift.Value('project-1'),
                name: 'Project Label',
                completed: false,
                primaryValueId: const drift.Value('v1'),
              ),
            );
        await db
            .into(db.trackerDefinitions)
            .insert(
              TrackerDefinitionsCompanion.insert(
                id: const drift.Value('tracker-1'),
                name: 'Tracker Label',
                scope: 'entry',
                roles: const drift.Value('[]'),
                valueType: 'number',
                config: const drift.Value('{}'),
                goal: const drift.Value('{}'),
                createdAt: drift.Value(DateTime.utc(2025, 1, 1)),
                updatedAt: drift.Value(DateTime.utc(2025, 1, 1)),
              ),
            );

        final labels = await repo.resolveEntityLabelsByType({
          'task': {'task-1'},
          'project': {'project-1'},
          'tracker': {'tracker-1'},
        });

        expect(labels['task-1'], 'Task Label');
        expect(labels['project-1'], 'Project Label');
        expect(labels['tracker-1'], 'Tracker Label');
      },
    );
  });
}
