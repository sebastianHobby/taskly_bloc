@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/routines.dart';

void main() {
  testSafe('fortnight snapshot uses monday-anchored 14-day window', () async {
    const service = RoutineScheduleService();
    final routine = Routine(
      id: 'routine-1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Stretch',
      projectId: 'project-1',
      periodType: RoutinePeriodType.fortnight,
      scheduleMode: RoutineScheduleMode.flexible,
      targetCount: 2,
    );

    final snapshot = service.buildSnapshot(
      routine: routine,
      dayKeyUtc: DateTime.utc(2026, 2, 18), // Wednesday
      completions: [
        RoutineCompletion(
          id: 'c1',
          routineId: 'routine-1',
          completedAtUtc: DateTime.utc(2026, 2, 17, 9),
          createdAtUtc: DateTime.utc(2026, 2, 17, 9),
        ),
      ],
      skips: const <RoutineSkip>[],
    );

    expect(snapshot.periodStartUtc, DateTime.utc(2026, 2, 16));
    expect(snapshot.periodEndUtc, DateTime.utc(2026, 3, 1));
    expect(snapshot.daysLeft, 12);
    expect(snapshot.completedCount, 1);
    expect(snapshot.remainingCount, 1);
  });
}
