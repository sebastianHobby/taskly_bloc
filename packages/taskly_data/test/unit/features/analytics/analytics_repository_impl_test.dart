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

      await db.into(db.taskTable).insert(
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
      await db.into(db.analyticsCorrelations).insert(
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
  });
}
