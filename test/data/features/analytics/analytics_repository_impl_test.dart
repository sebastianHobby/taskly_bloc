import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/domain/analytics/model/analytics_insight.dart';
import 'package:taskly_bloc/domain/analytics/model/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_result.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late AppDatabase db;
  late AnalyticsRepositoryImpl repo;

  setUp(() {
    db = createTestDb();
    repo = AnalyticsRepositoryImpl(db, IdGenerator.withUserId('user-1'));
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('AnalyticsRepositoryImpl', () {
    testSafe('saveSnapshot inserts and getSnapshots returns it', () async {
      final snapshot = AnalyticsSnapshot(
        id: '',
        entityType: 'task',
        snapshotDate: DateTime.utc(2026, 1, 1),
        metrics: const <String, dynamic>{'score': 1},
        entityId: 't1',
      );

      await repo.saveSnapshot(snapshot);

      final results = await repo.getSnapshots(
        entityType: 'task',
        entityId: 't1',
        range: DateRange(
          start: DateTime.utc(2025, 12, 31),
          end: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.entityType, 'task');
      expect(results.single.entityId, 't1');
      expect(results.single.metrics['score'], 1);
    });

    testSafe('saveSnapshot updates when id already exists', () async {
      final date = DateTime.utc(2026, 1, 1);

      final first = AnalyticsSnapshot(
        id: '',
        entityType: 'project',
        snapshotDate: date,
        metrics: const <String, dynamic>{'x': 1},
        entityId: 'p1',
      );

      await repo.saveSnapshot(first);

      final id = IdGenerator.withUserId('user-1').analyticsSnapshotId(
        entityType: 'project',
        entityId: 'p1',
        snapshotDate: date,
      );

      final second = AnalyticsSnapshot(
        id: id,
        entityType: 'project',
        snapshotDate: date,
        metrics: const <String, dynamic>{'x': 2},
        entityId: 'p1',
      );

      await repo.saveSnapshot(second);

      final results = await repo.getSnapshots(
        entityType: 'project',
        entityId: 'p1',
        range: DateRange(start: date, end: date),
      );

      expect(results, hasLength(1));
      expect(results.single.metrics['x'], 2);
    });

    testSafe(
      'saveSnapshots persists multiple snapshots in one transaction',
      () async {
        final snapshots = [
          AnalyticsSnapshot(
            id: '',
            entityType: 'task',
            snapshotDate: DateTime.utc(2026, 1, 1),
            metrics: const {'m': 1},
            entityId: 'a',
          ),
          AnalyticsSnapshot(
            id: '',
            entityType: 'task',
            snapshotDate: DateTime.utc(2026, 1, 2),
            metrics: const {'m': 2},
            entityId: 'b',
          ),
        ];

        await repo.saveSnapshots(snapshots);

        final results = await repo.getSnapshots(
          entityType: 'task',
          range: DateRange(
            start: DateTime.utc(2026, 1, 1),
            end: DateTime.utc(2026, 1, 2),
          ),
        );

        expect(results, hasLength(2));
      },
    );

    testSafe('getSnapshots orders by snapshotDate desc', () async {
      await repo.saveSnapshot(
        AnalyticsSnapshot(
          id: '',
          entityType: 'task',
          snapshotDate: DateTime.utc(2026, 1, 1),
          metrics: const {'m': 1},
          entityId: 't-order',
        ),
      );
      await repo.saveSnapshot(
        AnalyticsSnapshot(
          id: '',
          entityType: 'task',
          snapshotDate: DateTime.utc(2026, 1, 2),
          metrics: const {'m': 2},
          entityId: 't-order',
        ),
      );

      final results = await repo.getSnapshots(
        entityType: 'task',
        entityId: 't-order',
        range: DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(results.map((s) => s.snapshotDate), [
        DateTime.utc(2026, 1, 2),
        DateTime.utc(2026, 1, 1),
      ]);
    });

    testSafe('correlations: save + read cache by type and range', () async {
      final now = DateTime.now();
      final corr = CorrelationResult(
        sourceLabel: 'Task A',
        targetLabel: 'Project B',
        coefficient: 0.5,
        strength: CorrelationStrength.moderatePositive,
        sourceType: 'task',
        sourceId: 'task-a',
        targetType: 'project',
        targetId: 'project-b',
      );

      await repo.saveCorrelation(corr);

      final results = await repo.getCachedCorrelations(
        correlationType: 'task_project',
        range: DateRange(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.sourceId, 'task-a');
      expect(results.single.targetId, 'project-b');
    });

    testSafe(
      'correlations: resolves labels from task/project tables',
      () async {
        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: const Value('task-a'),
                name: 'Task A',
              ),
            );
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion(
                id: const Value('project-b'),
                name: const Value('Project B'),
                completed: const Value(false),
              ),
            );

        final now = DateTime.utc(2026, 1, 10);
        await db
            .into(db.analyticsCorrelations)
            .insert(
              AnalyticsCorrelationsCompanion(
                id: const Value('corr-1'),
                correlationType: const Value('task_project'),
                sourceType: const Value('task'),
                sourceId: const Value('task-a'),
                targetType: const Value('project'),
                targetId: const Value('project-b'),
                periodStart: Value(now.subtract(const Duration(days: 30))),
                periodEnd: Value(now),
                coefficient: const Value(0.4),
                sampleSize: const Value(10),
                strength: const Value('moderatePositive'),
                insight: const Value(''),
                computedAt: Value(now),
              ),
              mode: InsertMode.insertOrAbort,
            );

        final results = await repo.getCachedCorrelations(
          correlationType: 'task_project',
          range: DateRange(
            start: DateTime.utc(2026, 1, 1),
            end: DateTime.utc(2026, 2, 1),
          ),
        );

        expect(results, hasLength(1));
        expect(results.single.sourceLabel, 'Task A');
        expect(results.single.targetLabel, 'Project B');
      },
    );

    testSafe(
      'correlations: invalid JSON + unknown strength fall back safely',
      () async {
        final now = DateTime.utc(2026, 1, 10);

        // Use raw SQL to bypass the JSON type converters so we can persist
        // invalid JSON in the underlying TEXT columns.
        await db.customStatement(
          'INSERT OR ABORT INTO analytics_correlations '
          '(id, correlation_type, source_type, source_id, target_type, target_id, '
          'period_start, period_end, coefficient, sample_size, strength, insight, computed_at, '
          'statistical_significance, performance_metrics) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'corr-2',
            'task_project',
            'task',
            'task-x',
            'project',
            'project-y',
            now.subtract(const Duration(days: 30)),
            now,
            0.6,
            10,
            'not-a-strength',
            '',
            now,
            'not-json',
            'not-json',
          ],
        );

        final results = await repo.getCachedCorrelations(
          correlationType: 'task_project',
          range: DateRange(
            start: DateTime.utc(2026, 1, 1),
            end: DateTime.utc(2026, 2, 1),
          ),
        );

        expect(results, hasLength(1));
        expect(results.single.strength, CorrelationStrength.strongPositive);
        expect(results.single.statisticalSignificance, isNull);
        expect(results.single.performanceMetrics, isNull);
        expect(results.single.sourceLabel, 'task-task-x');
        expect(results.single.targetLabel, 'project-project-y');
      },
    );

    testSafe(
      'correlations: saveCorrelation infers general correlationType for unknown ids',
      () async {
        final now = DateTime.now();
        await repo.saveCorrelation(
          CorrelationResult(
            sourceLabel: 'A',
            targetLabel: 'B',
            coefficient: 0,
            strength: CorrelationStrength.negligible,
            sourceId: 'foo',
            targetId: 'bar',
          ),
        );

        final results = await repo.getCachedCorrelations(
          correlationType: 'general',
          range: DateRange(
            start: now.subtract(const Duration(days: 1)),
            end: now.add(const Duration(days: 1)),
          ),
        );

        expect(results, hasLength(1));
      },
    );

    testSafe('insights: save + recent insights within range', () async {
      final generatedAt = DateTime.utc(2026, 1, 5);
      final insight = AnalyticsInsight(
        id: '',
        insightType: InsightType.trendAlert,
        title: 'Up',
        description: 'Going up',
        generatedAt: generatedAt,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 1, 31),
        metadata: const {'k': 'v'},
      );

      await repo.saveInsight(insight);

      final results = await repo.getRecentInsights(
        range: DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.title, 'Up');
    });

    testSafe('insights: dismissInsight removes row', () async {
      final generatedAt = DateTime.utc(2026, 1, 5);
      final insight = AnalyticsInsight(
        id: '',
        insightType: InsightType.trendAlert,
        title: 'Dismiss me',
        description: 'x',
        generatedAt: generatedAt,
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 1, 31),
        metadata: const <String, dynamic>{},
      );

      await repo.saveInsight(insight);

      final all = await repo.getRecentInsights(
        range: DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      );
      expect(all, hasLength(1));

      await repo.dismissInsight(all.single.id);

      final after = await repo.getRecentInsights(
        range: DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      );
      expect(after, isEmpty);
    });
  });
}
