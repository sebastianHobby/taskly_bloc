import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';

bool isRoutineCompleteForDay({
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  required DateTime dayKeyUtc,
  required List<RoutineCompletion> completionsInPeriod,
}) {
  if (routine.periodType == RoutinePeriodType.day) {
    return snapshot.remainingCount <= 0;
  }

  final today = dateOnly(dayKeyUtc);
  return completionsInPeriod.any(
    (completion) =>
        completion.routineId == routine.id &&
        dateOnly(
          completion.completedDayLocal ?? completion.completedAtUtc,
        ).isAtSameMomentAs(today),
  );
}
