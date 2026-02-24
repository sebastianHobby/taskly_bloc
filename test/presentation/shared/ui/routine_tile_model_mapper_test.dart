@Tags(['widget'])
library;

import 'package:flutter/material.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class _RoutineTileHarness extends StatelessWidget {
  const _RoutineTileHarness({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final labels = buildRoutineExecutionLabels(
      context,
      completed: completed,
    );

    final data = TasklyRoutineRowData(
      id: 'routine-1',
      title: 'Morning Flow',
      completed: completed,
      labels: labels,
    );

    final row = TasklyRowSpec.routine(
      key: 'routine-row',
      data: data,
      actions: TasklyRoutineRowActions(
        onPrimaryAction: () {},
      ),
    );

    return TasklyFeedRenderer.buildRow(
      row,
      context: context,
    );
  }
}

void main() {
  testWidgetsSafe(
    'routine tile shows unlog label when completed',
    (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const _RoutineTileHarness(completed: true),
      );
      await tester.pumpForStream();

      final l10n = tester.element(find.byType(_RoutineTileHarness)).l10n;
      expect(find.text(l10n.routineUnlogLabel), findsOneWidget);
    },
  );

  testWidgetsSafe(
    'scheduled row shows only planned days and excludes unscheduled completions',
    (tester) async {
      TasklyRoutineRowData? mapped;
      final dayKeyUtc = DateTime.utc(2025, 1, 16); // Thursday
      final weekStart = DateTime.utc(2025, 1, 13); // Monday

      final routine = Routine(
        id: 'routine-weekly',
        createdAt: DateTime.utc(2024, 12, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        name: 'Weekly routine',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 3,
        scheduleDays: <int>[1, 3, 5], // M, W, F
      );

      final snapshot = RoutineCadenceSnapshot(
        routineId: routine.id,
        periodType: RoutinePeriodType.week,
        periodStartUtc: weekStart,
        periodEndUtc: DateTime.utc(2025, 1, 19),
        targetCount: 3,
        completedCount: 1,
        remainingCount: 2,
        daysLeft: 3,
        status: RoutineStatus.onPace,
      );

      final completions = <RoutineCompletion>[
        RoutineCompletion(
          id: 'completion-mon',
          routineId: routine.id,
          completedAtUtc: DateTime.utc(2025, 1, 13, 9),
          createdAtUtc: DateTime.utc(2025, 1, 13, 9),
          completedDayLocal: DateTime.utc(2025, 1, 13),
        ),
        // Unscheduled completion (Tuesday) should not add a day chip anymore.
        RoutineCompletion(
          id: 'completion-tue',
          routineId: routine.id,
          completedAtUtc: DateTime.utc(2025, 1, 14, 9),
          createdAtUtc: DateTime.utc(2025, 1, 14, 9),
          completedDayLocal: DateTime.utc(2025, 1, 14),
        ),
      ];

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            mapped = buildRoutineRowData(
              context,
              routine: routine,
              snapshot: snapshot,
              showScheduleRow: true,
              dayKeyUtc: dayKeyUtc,
              completionsInPeriod: completions,
              skipsInPeriod: const <RoutineSkip>[],
            );
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpForStream();

      final days =
          mapped?.scheduleRow?.days ?? const <TasklyRoutineScheduleDay>[];
      expect(days.length, 3);
      expect(days.map((d) => d.state).toList(), <TasklyRoutineScheduleDayState>[
        TasklyRoutineScheduleDayState.loggedScheduled,
        TasklyRoutineScheduleDayState.missedScheduled,
        TasklyRoutineScheduleDayState.scheduled,
      ]);
    },
  );

  testWidgetsSafe(
    'scheduled row maps week skip days to skipped state',
    (tester) async {
      TasklyRoutineRowData? mapped;
      final dayKeyUtc = DateTime.utc(2025, 1, 16); // Thursday
      final weekStart = DateTime.utc(2025, 1, 13); // Monday

      final routine = Routine(
        id: 'routine-weekly-skipped',
        createdAt: DateTime.utc(2024, 12, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        name: 'Weekly routine',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 3,
        scheduleDays: const <int>[1, 3, 5], // M, W, F
      );

      final snapshot = RoutineCadenceSnapshot(
        routineId: routine.id,
        periodType: RoutinePeriodType.week,
        periodStartUtc: weekStart,
        periodEndUtc: DateTime.utc(2025, 1, 19),
        targetCount: 3,
        completedCount: 1,
        remainingCount: 2,
        daysLeft: 3,
        status: RoutineStatus.restWeek,
      );

      final completions = <RoutineCompletion>[
        RoutineCompletion(
          id: 'completion-mon',
          routineId: routine.id,
          completedAtUtc: DateTime.utc(2025, 1, 13, 9),
          createdAtUtc: DateTime.utc(2025, 1, 13, 9),
          completedDayLocal: DateTime.utc(2025, 1, 13),
        ),
      ];

      final skips = <RoutineSkip>[
        RoutineSkip(
          id: 'skip-week',
          routineId: routine.id,
          periodType: RoutineSkipPeriodType.week,
          periodKeyUtc: weekStart,
          createdAtUtc: DateTime.utc(2025, 1, 15, 8),
        ),
      ];

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) {
            mapped = buildRoutineRowData(
              context,
              routine: routine,
              snapshot: snapshot,
              showScheduleRow: true,
              dayKeyUtc: dayKeyUtc,
              completionsInPeriod: completions,
              skipsInPeriod: skips,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pumpForStream();

      final days =
          mapped?.scheduleRow?.days ?? const <TasklyRoutineScheduleDay>[];
      expect(days.map((d) => d.state).toList(), <TasklyRoutineScheduleDayState>[
        TasklyRoutineScheduleDayState.loggedScheduled,
        TasklyRoutineScheduleDayState.skippedScheduled,
        TasklyRoutineScheduleDayState.skippedScheduled,
      ]);
    },
  );
}
