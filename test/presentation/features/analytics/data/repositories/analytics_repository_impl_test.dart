import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_snapshot.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late AnalyticsRepositoryImpl repo;

  Future<void> seedTaskAndTracker({
    required String taskId,
    required String taskName,
    required String trackerId,
    required String trackerName,
  }) async {
    await db
        .into(db.taskTable)
        .insert(
          TaskTableCompanion(
            id: Value(taskId),
            name: Value(taskName),
          ),
        );

    await db
        .into(db.trackers)
        .insert(
          TrackersCompanion(
            id: Value(trackerId),
            name: Value(trackerName),
            responseType: const Value('scale'),
            entryScope: const Value('allDay'),
          ),
        );
  }

  setUp(() {
    db = createTestDb();
    repo = AnalyticsRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalyticsRepositoryImpl - Snapshots', () {
    test('saveSnapshot and getSnapshots returns saved snapshot', () async {
      final snapshot = AnalyticsSnapshot(
        id: 'snap-1',
        entityType: 'task',
        entityId: 'task-1',
        snapshotDate: DateTime(2025),
        metrics: {'count': 5, 'completed': 3},
      );

      await repo.saveSnapshot(snapshot);

      final results = await repo.getSnapshots(
        entityType: 'task',
        range: TestData.dateRange(
          start: DateTime(2024, 12),
          end: DateTime(2025, 2),
        ),
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'snap-1');
      expect(results.first.entityType, 'task');
      expect(results.first.metrics['count'], 5);
    });

    test('saveSnapshots saves multiple snapshots in batch', () async {
      final snapshots = [
        AnalyticsSnapshot(
          id: 'snap-1',
          entityType: 'task',
          entityId: 'task-1',
          snapshotDate: DateTime(2025),
          metrics: {'count': 5},
        ),
        AnalyticsSnapshot(
          id: 'snap-2',
          entityType: 'task',
          entityId: 'task-2',
          snapshotDate: DateTime(2025, 1, 2),
          metrics: {'count': 10},
        ),
      ];

      await repo.saveSnapshots(snapshots);

      final results = await repo.getSnapshots(
        entityType: 'task',
        range: TestData.dateRange(
          start: DateTime(2024, 12),
          end: DateTime(2025, 2),
        ),
      );

      expect(results, hasLength(2));
    });

    test('getSnapshots filters by entityId when provided', () async {
      await repo.saveSnapshots([
        AnalyticsSnapshot(
          id: 'snap-1',
          entityType: 'task',
          entityId: 'task-1',
          snapshotDate: DateTime(2025),
          metrics: <String, dynamic>{},
        ),
        AnalyticsSnapshot(
          id: 'snap-2',
          entityType: 'task',
          entityId: 'task-2',
          snapshotDate: DateTime(2025),
          metrics: <String, dynamic>{},
        ),
      ]);

      final results = await repo.getSnapshots(
        entityType: 'task',
        entityId: 'task-1',
        range: TestData.dateRange(
          start: DateTime(2024, 12),
          end: DateTime(2025, 2),
        ),
      );

      expect(results, hasLength(1));
      expect(results.first.entityId, 'task-1');
    });
  });

  group('AnalyticsRepositoryImpl - Correlations', () {
    test(
      'saveCorrelation and getCachedCorrelations returns saved correlation',
      () async {
        await seedTaskAndTracker(
          taskId: 'task-1',
          taskName: 'Morning Exercise',
          trackerId: 'tracker-1',
          trackerName: 'Energy Level',
        );

        final correlation = TestData.correlation(
          sourceLabel: 'Morning Exercise',
          targetLabel: 'Energy Level',
          coefficient: 0.82,
          sourceId: 'task-1',
          targetId: 'tracker-1',
        );

        await repo.saveCorrelation(correlation);

        final results = await repo.getCachedCorrelations(
          correlationType: 'task_tracker',
          range: TestData.dateRange(),
        );

        expect(results, hasLength(1));
        expect(results.first.sourceLabel, 'Morning Exercise');
        expect(results.first.coefficient, closeTo(0.82, 0.01));
        expect(results.first.sourceType, 'task');
        expect(results.first.targetType, 'tracker');
      },
    );

    test('saveCorrelation stores statistical significance', () async {
      await seedTaskAndTracker(
        taskId: 'task-1',
        taskName: 'Morning Exercise',
        trackerId: 'tracker-1',
        trackerName: 'Energy Level',
      );

      final correlation = TestData.correlation(
        statisticalSignificance: TestData.statisticalSignificance(
          pValue: 0.003,
        ),
        sourceId: 'task-1',
        targetId: 'tracker-1',
      );

      await repo.saveCorrelation(correlation);

      final results = await repo.getCachedCorrelations(
        correlationType: 'task_tracker',
        range: TestData.dateRange(),
      );

      expect(results.first.statisticalSignificance, isNotNull);
      expect(
        results.first.statisticalSignificance!.pValue,
        closeTo(0.003, 0.001),
      );
      expect(results.first.statisticalSignificance!.isSignificant, isTrue);
    });

    test('saveCorrelation stores performance metrics', () async {
      await seedTaskAndTracker(
        taskId: 'task-1',
        taskName: 'Morning Exercise',
        trackerId: 'tracker-1',
        trackerName: 'Energy Level',
      );

      final correlation = TestData.correlation(
        performanceMetrics: TestData.performanceMetrics(
          calculationTimeMs: 25,
          dataPoints: 50,
        ),
        sourceId: 'task-1',
        targetId: 'tracker-1',
      );

      await repo.saveCorrelation(correlation);

      final results = await repo.getCachedCorrelations(
        correlationType: 'task_tracker',
        range: TestData.dateRange(),
      );

      expect(results.first.performanceMetrics, isNotNull);
      expect(results.first.performanceMetrics!.calculationTimeMs, 25);
      expect(results.first.performanceMetrics!.dataPoints, 50);
      expect(results.first.performanceMetrics!.algorithm, 'pearson_simd');
    });

    test('saveCorrelations saves multiple correlations in batch', () async {
      await seedTaskAndTracker(
        taskId: 'task-1',
        taskName: 'Task 1',
        trackerId: 'tracker-1',
        trackerName: 'Energy Level',
      );
      await db
          .into(db.taskTable)
          .insert(
            const TaskTableCompanion(
              id: Value('task-2'),
              name: Value('Task 2'),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            const TaskTableCompanion(
              id: Value('task-3'),
              name: Value('Task 3'),
            ),
          );

      final correlations = [
        TestData.correlation(
          sourceLabel: 'Task 1',
          sourceId: 'task-1',
          targetLabel: 'Energy Level',
          targetId: 'tracker-1',
        ),
        TestData.correlation(
          sourceLabel: 'Task 2',
          sourceId: 'task-2',
          targetLabel: 'Energy Level',
          targetId: 'tracker-1',
        ),
        TestData.correlation(
          sourceLabel: 'Task 3',
          sourceId: 'task-3',
          targetLabel: 'Energy Level',
          targetId: 'tracker-1',
        ),
      ];

      await repo.saveCorrelations(correlations);

      final results = await repo.getCachedCorrelations(
        correlationType: 'task_tracker',
        range: TestData.dateRange(),
      );

      expect(results, hasLength(3));
    });
  });

  group('AnalyticsRepositoryImpl - Insights', () {
    test('saveInsight and getRecentInsights returns saved insight', () async {
      final insight = TestData.insight(
        title: 'High Correlation Detected',
        description: 'Morning exercise strongly correlates with energy',
        score: 85,
        confidence: 0.95,
      );

      await repo.saveInsight(insight);

      final results = await repo.getRecentInsights(
        range: TestData.dateRange(),
      );

      expect(results, hasLength(1));
      expect(results.first.title, 'High Correlation Detected');
      expect(results.first.insightType, InsightType.correlationDiscovery);
      expect(results.first.score, 85.0);
      expect(results.first.confidence, 0.95);
    });

    test('getRecentInsights respects limit parameter', () async {
      // Save 5 insights
      for (int i = 0; i < 5; i++) {
        await repo.saveInsight(
          TestData.insight(
            id: 'insight-$i',
            title: 'Insight $i',
          ),
        );
      }

      final results = await repo.getRecentInsights(
        range: TestData.dateRange(),
        limit: 3,
      );

      expect(results, hasLength(3));
    });

    test('getRecentInsights filters by date range', () async {
      await repo.saveInsight(
        TestData.insight(
          id: 'old-insight',
          generatedAt: DateTime(2024),
        ),
      );
      await repo.saveInsight(
        TestData.insight(
          id: 'recent-insight',
          generatedAt: DateTime(2025, 1, 15),
        ),
      );

      final results = await repo.getRecentInsights(
        range: TestData.dateRange(
          start: DateTime(2025),
          end: DateTime(2025, 2),
        ),
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'recent-insight');
    });

    test('dismissInsight removes insight', () async {
      final insight = TestData.insight(id: 'insight-1');
      await repo.saveInsight(insight);

      var results = await repo.getRecentInsights(
        range: TestData.dateRange(),
      );
      expect(results, hasLength(1));

      await repo.dismissInsight('insight-1');

      results = await repo.getRecentInsights(
        range: TestData.dateRange(),
      );
      expect(results, isEmpty);
    });

    test('saveInsight updates existing insight', () async {
      final insight1 = TestData.insight(
        id: 'insight-1',
        title: 'Original Title',
      );
      await repo.saveInsight(insight1);

      final insight2 = TestData.insight(
        id: 'insight-1',
        title: 'Updated Title',
      );
      await repo.saveInsight(insight2);

      final results = await repo.getRecentInsights(
        range: TestData.dateRange(),
      );

      expect(results, hasLength(1));
      expect(results.first.title, 'Updated Title');
    });

    test('getRecentInsights handles all insight types', () async {
      await repo.saveInsight(
        TestData.insight(),
      );
      await repo.saveInsight(
        TestData.insight(insightType: InsightType.trendAlert),
      );
      await repo.saveInsight(
        TestData.insight(insightType: InsightType.anomalyDetection),
      );
      await repo.saveInsight(
        TestData.insight(insightType: InsightType.productivityPattern),
      );
      await repo.saveInsight(
        TestData.insight(insightType: InsightType.moodPattern),
      );
      await repo.saveInsight(
        TestData.insight(insightType: InsightType.recommendation),
      );

      final results = await repo.getRecentInsights(
        range: TestData.dateRange(),
      );

      expect(results, hasLength(6));
      expect(
        results.map((i) => i.insightType).toSet(),
        InsightType.values.toSet(),
      );
    });
  });

  group('AnalyticsRepositoryImpl - Edge Cases', () {
    test('getSnapshots returns empty list when no snapshots exist', () async {
      final results = await repo.getSnapshots(
        entityType: 'task',
        range: TestData.dateRange(),
      );

      expect(results, isEmpty);
    });

    test(
      'getCachedCorrelations returns empty list when no correlations exist',
      () async {
        final results = await repo.getCachedCorrelations(
          correlationType: 'task_tracker',
          range: TestData.dateRange(),
        );

        expect(results, isEmpty);
      },
    );

    test(
      'getRecentInsights returns empty list when no insights exist',
      () async {
        final results = await repo.getRecentInsights(
          range: TestData.dateRange(),
        );

        expect(results, isEmpty);
      },
    );

    test('dismissInsight does not throw when insight does not exist', () async {
      await expectLater(
        repo.dismissInsight('non-existent'),
        completes,
      );
    });
  });
}
