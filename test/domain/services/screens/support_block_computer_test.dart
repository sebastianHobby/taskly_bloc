import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DateRange(
        start: DateTime(2000),
        end: DateTime(2000, 1, 2),
      ),
    );
    registerFallbackValue(TrendGranularity.daily);
  });

  group('SupportBlockComputer', () {
    late TaskStatsCalculator statsCalculator;
    late MockAnalyticsService analyticsService;
    late SupportBlockComputer computer;

    setUp(() {
      statsCalculator = TaskStatsCalculator();
      analyticsService = MockAnalyticsService();
      computer = SupportBlockComputer(statsCalculator, analyticsService);
    });

    group('computeBreakdown', () {
      test('groups by project and computes stat per group', () async {
        final tasks = [
          Task(
            id: 't1',
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
            name: 'A',
            completed: false,
            projectId: 'p1',
            project: Project(
              id: 'p1',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
              name: 'Work',
              completed: false,
            ),
          ),
          Task(
            id: 't2',
            createdAt: DateTime(2025, 1, 2),
            updatedAt: DateTime(2025, 1, 2),
            name: 'B',
            completed: true,
            projectId: 'p1',
            project: Project(
              id: 'p1',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
              name: 'Work',
              completed: false,
            ),
          ),
          Task(
            id: 't3',
            createdAt: DateTime(2025, 1, 3),
            updatedAt: DateTime(2025, 1, 3),
            name: 'C',
            completed: true,
            projectId: 'p2',
            project: Project(
              id: 'p2',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
              name: 'Home',
              completed: false,
            ),
          ),
        ];

        final block =
            SupportBlock.breakdown(
                  statType: TaskStatType.totalCount,
                  dimension: BreakdownDimension.project,
                )
                as BreakdownBlock;

        final result = await computer.computeBreakdown(block, tasks);

        expect(result.keys, containsAll(['Work', 'Home']));
        expect(result['Work']!.value, 2);
        expect(result['Home']!.value, 1);
      });

      test(
        'groups by label type and allows tasks in multiple groups',
        () async {
          final label1 = Label(
            id: 'l1',
            name: 'Errands',
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          );
          final label2 = Label(
            id: 'l2',
            name: 'Health',
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          );

          final tasks = [
            Task(
              id: 't1',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
              name: 'A',
              completed: false,
              labels: [label1, label2],
            ),
            Task(
              id: 't2',
              createdAt: DateTime(2025, 1, 2),
              updatedAt: DateTime(2025, 1, 2),
              name: 'B',
              completed: false,
              labels: [label2],
            ),
          ];

          final block =
              SupportBlock.breakdown(
                    statType: TaskStatType.totalCount,
                    dimension: BreakdownDimension.label,
                  )
                  as BreakdownBlock;

          final result = await computer.computeBreakdown(block, tasks);

          expect(result['Errands']!.value, 1);
          expect(result['Health']!.value, 2);
        },
      );
    });

    group('computeFilteredTasks', () {
      test('filters tasks using QueryFilter<TaskPredicate> JSON', () async {
        final tasks = [
          Task(
            id: 't1',
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
            name: 'Open',
            completed: false,
          ),
          Task(
            id: 't2',
            createdAt: DateTime(2025, 1, 2),
            updatedAt: DateTime(2025, 1, 2),
            name: 'Done',
            completed: true,
          ),
        ];

        final block =
            SupportBlock.filteredList(
                  title: 'Open tasks',
                  entityType: 'task',
                  filterJson: <String, Object?>{
                    'shared': <Map<String, Object?>>[
                      <String, Object?>{
                        'type': 'bool',
                        'field': 'completed',
                        'operator': 'isFalse',
                      },
                    ],
                    'orGroups': const <Object?>[],
                  },
                )
                as FilteredListBlock;

        final result = await computer.computeFilteredTasks(
          block,
          tasks,
          now: DateTime(2025, 1, 3),
        );

        expect(result.map((t) => t.id), const <String>['t1']);
      });

      test('returns empty list when entityType is unsupported', () async {
        final block =
            SupportBlock.filteredList(
                  title: 'Anything',
                  entityType: 'project',
                  filterJson: const {},
                )
                as FilteredListBlock;

        final result = await computer.computeFilteredTasks(
          block,
          const <Task>[],
          now: DateTime(2025),
        );

        expect(result, isEmpty);
      });
    });

    group('computeMoodCorrelation', () {
      test(
        'computes a correlation result from mood trend + task activity days',
        () async {
          final start = DateTime(2025);
          final range = DateRange(start: start, end: DateTime(2025, 1, 21));

          // Mood is high on activity days, low otherwise.
          final activityDays = {
            DateTime(2025, 1, 2),
            DateTime(2025, 1, 5),
            DateTime(2025, 1, 8),
            DateTime(2025, 1, 11),
            DateTime(2025, 1, 14),
            DateTime(2025, 1, 17),
            DateTime(2025, 1, 20),
          };

          final points = List<TrendPoint>.generate(20, (i) {
            final day = start.add(Duration(days: i + 1));
            final value = activityDays.contains(day) ? 10.0 : 1.0;
            return TrendPoint(date: day, value: value, sampleCount: 1);
          });

          when(
            () => analyticsService.getMoodTrend(
              range: any(named: 'range'),
              granularity: any(named: 'granularity'),
            ),
          ).thenAnswer(
            (_) async => TrendData(
              points: points,
              granularity: TrendGranularity.daily,
            ),
          );

          // Tasks created on the activity days.
          final tasks = activityDays
              .map(
                (d) => Task(
                  id: d.toIso8601String(),
                  createdAt: d.add(const Duration(hours: 12)),
                  updatedAt: d.add(const Duration(hours: 12)),
                  name: 'Task',
                  completed: false,
                ),
              )
              .toList(growable: false);

          final block =
              SupportBlock.moodCorrelation(
                    statType: TaskStatType.totalCount,
                    range: range,
                  )
                  as MoodCorrelationBlock;

          final result = await computer.computeMoodCorrelation(block, tasks);

          expect(result.sampleSize, isNotNull);
          expect(result.sampleSize, greaterThanOrEqualTo(10));
          expect(result.coefficient, greaterThan(0.2));
        },
      );
    });
  });
}
