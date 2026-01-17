import '../../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_data/repositories.dart';

import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';

void main() {
  group('AnalyticsServiceImpl', () {
    testSafe(
      'stubs mood analytics but still calls journal repository',
      () async {
        final analyticsRepo = MockAnalyticsRepositoryContract();
        final taskRepo = MockTaskRepositoryContract();
        final projectRepo = MockProjectRepositoryContract();
        final valueRepo = MockValueRepositoryContract();
        final journalRepo = MockJournalRepositoryContract();

        final service = AnalyticsServiceImpl(
          analyticsRepo: analyticsRepo,
          taskRepo: taskRepo,
          projectRepo: projectRepo,
          valueRepo: valueRepo,
          journalRepo: journalRepo,
        );

        final range = DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 7),
        );

        when(
          () => journalRepo.getDailyMoodAverages(range: range),
        ).thenAnswer((_) async => <DateTime, double>{});

        when(
          () => journalRepo.getTrackerValues(
            trackerId: any<String>(named: 'trackerId'),
            range: range,
          ),
        ).thenAnswer((_) async => <DateTime, double>{});

        final trend = await service.getMoodTrend(range: range);
        expect(trend, isA<TrendData>());
        expect(trend.points, isEmpty);

        final dist = await service.getMoodDistribution(range: range);
        expect(dist, isEmpty);

        final summary = await service.getMoodSummary(range: range);
        expect(summary.totalEntries, 0);

        final trackerTrend = await service.getTrackerTrend(
          trackerId: 't1',
          range: range,
        );
        expect(trackerTrend.points, isEmpty);

        verify(() => journalRepo.getDailyMoodAverages(range: range)).called(3);
        verify(
          () => journalRepo.getTrackerValues(trackerId: 't1', range: range),
        ).called(1);
      },
    );

    testSafe('calculateCorrelation returns stable stub messaging', () async {
      final analyticsRepo = MockAnalyticsRepositoryContract();
      final taskRepo = MockTaskRepositoryContract();
      final projectRepo = MockProjectRepositoryContract();
      final valueRepo = MockValueRepositoryContract();
      final journalRepo = MockJournalRepositoryContract();

      final service = AnalyticsServiceImpl(
        analyticsRepo: analyticsRepo,
        taskRepo: taskRepo,
        projectRepo: projectRepo,
        valueRepo: valueRepo,
        journalRepo: journalRepo,
      );

      final range = DateRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 2),
      );

      final result = await service.calculateCorrelation(
        request: CorrelationRequest.moodVsEntity(
          entityId: 'x',
          entityType: EntityType.task,
          range: range,
        ),
      );

      expect(result.sampleSize, 0);
      expect(result.insight, isNotEmpty);
    });

    testSafe('task stats read tasks from repository watchAll()', () async {
      final analyticsRepo = MockAnalyticsRepositoryContract();
      final taskRepo = MockTaskRepositoryContract();
      final projectRepo = MockProjectRepositoryContract();
      final valueRepo = MockValueRepositoryContract();
      final journalRepo = MockJournalRepositoryContract();

      final service = AnalyticsServiceImpl(
        analyticsRepo: analyticsRepo,
        taskRepo: taskRepo,
        projectRepo: projectRepo,
        valueRepo: valueRepo,
        journalRepo: journalRepo,
      );

      final tasks = [
        TestData.task(name: 'A', completed: false),
        TestData.task(name: 'B', completed: true),
      ];

      when(taskRepo.watchAll).thenAnswer((_) => Stream.value(tasks));

      final stat = await service.getTaskStat(
        entityId: 'x',
        entityType: EntityType.task,
        statType: TaskStatType.completedCount,
      );

      expect(stat.value, 1);

      final stats = await service.getTaskStats(
        entityId: 'x',
        entityType: EntityType.project,
        statTypes: {TaskStatType.totalCount, TaskStatType.completedCount},
      );

      expect(stats[TaskStatType.totalCount]!.value, 2);
      expect(stats[TaskStatType.completedCount]!.value, 1);

      verify(taskRepo.watchAll).called(2);
    });
  });
}
