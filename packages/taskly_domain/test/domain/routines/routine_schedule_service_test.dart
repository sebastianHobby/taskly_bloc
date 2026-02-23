@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/routines.dart';

void main() {
  const service = RoutineScheduleService();

  Routine routine({
    required String id,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    int targetCount = 1,
    List<int> scheduleDays = const <int>[],
    List<int> scheduleMonthDays = const <int>[],
    int? minSpacingDays,
    int? restDayBuffer,
  }) {
    return Routine(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Routine $id',
      projectId: 'project-1',
      periodType: periodType,
      scheduleMode: scheduleMode,
      targetCount: targetCount,
      scheduleDays: scheduleDays,
      scheduleMonthDays: scheduleMonthDays,
      minSpacingDays: minSpacingDays,
      restDayBuffer: restDayBuffer,
    );
  }

  RoutineCompletion completion({
    required String routineId,
    required DateTime atUtc,
  }) {
    return RoutineCompletion(
      id: 'c-$routineId-${atUtc.millisecondsSinceEpoch}',
      routineId: routineId,
      completedAtUtc: atUtc,
      createdAtUtc: atUtc,
    );
  }

  RoutineSkip skip({
    required String routineId,
    required RoutineSkipPeriodType periodType,
    required DateTime periodKeyUtc,
  }) {
    return RoutineSkip(
      id: 's-$routineId-${periodKeyUtc.millisecondsSinceEpoch}',
      routineId: routineId,
      periodType: periodType,
      periodKeyUtc: periodKeyUtc,
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );
  }

  testSafe('fortnight snapshot uses monday-anchored 14-day window', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'routine-1',
        periodType: RoutinePeriodType.fortnight,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 2,
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 18), // Wednesday
      completions: [
        completion(routineId: 'routine-1', atUtc: DateTime.utc(2026, 2, 17, 9)),
      ],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.periodStartUtc, DateTime.utc(2026, 2, 16));
    expect(snapshot.periodEndUtc, DateTime.utc(2026, 3, 1));
    expect(snapshot.daysLeft, 12);
    expect(snapshot.completedCount, 1);
    expect(snapshot.remainingCount, 1);
    expect(snapshot.status, RoutineStatus.onPace);
  });

  testSafe('day routine has no next recommended day', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'day-1',
        periodType: RoutinePeriodType.day,
        scheduleMode: RoutineScheduleMode.flexible,
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 18),
      completions: const <RoutineCompletion>[],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.periodStartUtc, DateTime.utc(2026, 2, 18));
    expect(snapshot.periodEndUtc, DateTime.utc(2026, 2, 18));
    expect(snapshot.daysLeft, 1);
    expect(snapshot.nextRecommendedDayUtc, isNull);
  });

  testSafe('weekly scheduled picks next configured weekday', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'week-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 2,
        scheduleDays: const [DateTime.monday, DateTime.friday],
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 18), // Wednesday
      completions: const <RoutineCompletion>[],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.periodStartUtc, DateTime.utc(2026, 2, 16));
    expect(snapshot.periodEndUtc, DateTime.utc(2026, 2, 22));
    expect(snapshot.nextRecommendedDayUtc, DateTime.utc(2026, 2, 20));
  });

  testSafe('monthly scheduled rolls to next month when needed', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'month-1',
        periodType: RoutinePeriodType.month,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 2,
        scheduleMonthDays: const [5, 20],
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 25),
      completions: const <RoutineCompletion>[],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.periodStartUtc, DateTime.utc(2026, 2, 1));
    expect(snapshot.periodEndUtc, DateTime.utc(2026, 2, 28));
    expect(snapshot.nextRecommendedDayUtc, DateTime.utc(2026, 3, 5));
  });

  testSafe('skip for period yields restWeek with zero remaining', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'week-skip',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 3,
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 18),
      completions: const <RoutineCompletion>[],
      skips: [
        skip(
          routineId: 'week-skip',
          periodType: RoutineSkipPeriodType.week,
          periodKeyUtc: DateTime.utc(2026, 2, 16),
        ),
      ],
    );

    expect(snapshot.remainingCount, 0);
    expect(snapshot.status, RoutineStatus.restWeek);
    expect(snapshot.nextRecommendedDayUtc, isNull);
  });

  testSafe('catchUp when remaining count is greater than days left', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'week-catch-up',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 6,
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 22), // Sunday => 1 day left
      completions: const <RoutineCompletion>[],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.daysLeft, 1);
    expect(snapshot.remainingCount, 6);
    expect(snapshot.status, RoutineStatus.catchUp);
  });

  testSafe('tightWeek when remaining is near days left threshold', () async {
    final snapshot = service.buildSnapshot(
      routine: routine(
        id: 'week-tight',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 4,
      ),
      dayKeyUtc: DateTime.utc(2026, 2, 20), // Friday => 3 days left
      completions: [
        completion(routineId: 'week-tight', atUtc: DateTime.utc(2026, 2, 17)),
      ],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.daysLeft, 3);
    expect(snapshot.remainingCount, 3);
    expect(snapshot.status, RoutineStatus.tightWeek);
  });

  testSafe(
    'flexible spacing honors min spacing and clamps to period end',
    () async {
      final snapshot = service.buildSnapshot(
        routine: routine(
          id: 'week-flex',
          periodType: RoutinePeriodType.week,
          scheduleMode: RoutineScheduleMode.flexible,
          targetCount: 2,
          minSpacingDays: 10,
          restDayBuffer: 2,
        ),
        dayKeyUtc: DateTime.utc(2026, 2, 20), // Friday, period end Sunday
        completions: const <RoutineCompletion>[],
        skips: const <RoutineSkip>[],
      );

      expect(snapshot.nextRecommendedDayUtc, DateTime.utc(2026, 2, 22));
    },
  );
}
