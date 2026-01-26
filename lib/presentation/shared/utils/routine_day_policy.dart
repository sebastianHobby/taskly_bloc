import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';

enum RoutineCadenceKind { scheduled, flexible }

@immutable
final class RoutineDayPolicyResult {
  const RoutineDayPolicyResult({
    required this.isEligibleToday,
    required this.isCatchUpDay,
    required this.cadenceKind,
    this.lastScheduledDayUtc,
  });

  final bool isEligibleToday;
  final bool isCatchUpDay;
  final RoutineCadenceKind cadenceKind;
  final DateTime? lastScheduledDayUtc;
}

RoutineDayPolicyResult evaluateRoutineDayPolicy({
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  required DateTime dayKeyUtc,
  required List<RoutineCompletion> completions,
}) {
  final today = dateOnly(dayKeyUtc);
  final remaining = snapshot.remainingCount;

  if (remaining <= 0) {
    return RoutineDayPolicyResult(
      isEligibleToday: false,
      isCatchUpDay: false,
      cadenceKind: _cadenceKindFor(routine),
    );
  }

  if (routine.routineType == RoutineType.weeklyFixed &&
      routine.scheduleDays.isNotEmpty) {
    final lastScheduledDay = _lastScheduledDay(
      today,
      routine.scheduleDays,
      snapshot.periodStartUtc,
    );
    final nextScheduledDay = _nextScheduledDay(
      today,
      routine.scheduleDays,
      snapshot.periodEndUtc,
    );
    final isScheduledToday = routine.scheduleDays.contains(today.weekday);
    final missedLast =
        lastScheduledDay != null &&
        !_completedOnDay(
          completions,
          routineId: routine.id,
          dayKeyUtc: lastScheduledDay,
        );
    final isCatchUp =
        !isScheduledToday &&
        missedLast &&
        (nextScheduledDay == null || today.isBefore(nextScheduledDay));
    return RoutineDayPolicyResult(
      isEligibleToday: isScheduledToday || isCatchUp,
      isCatchUpDay: isCatchUp,
      cadenceKind: RoutineCadenceKind.scheduled,
      lastScheduledDayUtc: lastScheduledDay,
    );
  }

  final isMonthly =
      routine.routineType == RoutineType.monthlyFlexible ||
      routine.routineType == RoutineType.monthlyFixed;
  if (isMonthly) {
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: remaining > snapshot.daysLeft,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  final spacing = _spacingFor(routine, remaining, snapshot.daysLeft);
  final lastCompletionDay = _lastCompletionDay(
    completions,
    routineId: routine.id,
    periodStartUtc: snapshot.periodStartUtc,
    periodEndUtc: snapshot.periodEndUtc,
    todayUtc: today,
  );
  final daysSinceLast = lastCompletionDay == null
      ? 999
      : today.difference(lastCompletionDay).inDays;
  final eligibleBySpacing = daysSinceLast >= spacing;
  final isBehind = remaining > snapshot.daysLeft;

  if (routine.scheduleDays.isEmpty) {
    return RoutineDayPolicyResult(
      isEligibleToday: isBehind || eligibleBySpacing,
      isCatchUpDay: isBehind,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  final isSuggestedToday = routine.scheduleDays.contains(today.weekday);
  if (isSuggestedToday && eligibleBySpacing) {
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: isBehind,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  final lastSuggestedDay = _lastScheduledDay(
    today,
    routine.scheduleDays,
    snapshot.periodStartUtc,
  );
  final nextSuggestedDay = _nextScheduledDay(
    today,
    routine.scheduleDays,
    snapshot.periodEndUtc,
  );
  final missedLastSuggested =
      lastSuggestedDay != null &&
      !_completedOnDay(
        completions,
        routineId: routine.id,
        dayKeyUtc: lastSuggestedDay,
      );
  final inCatchUpWindow =
      lastSuggestedDay != null &&
      !isSuggestedToday &&
      missedLastSuggested &&
      (nextSuggestedDay == null || today.isBefore(nextSuggestedDay));
  if (inCatchUpWindow) {
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: true,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  final earliestSpacingDay = _earliestSpacingDay(
    today,
    lastCompletionDay,
    spacing,
  );
  final nextSuggestedEligibleDay = _nextScheduledDayOnOrAfter(
    earliestSpacingDay,
    routine.scheduleDays,
    snapshot.periodEndUtc,
  );
  if (nextSuggestedEligibleDay == null && eligibleBySpacing) {
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: isBehind,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  return RoutineDayPolicyResult(
    isEligibleToday: false,
    isCatchUpDay: isBehind,
    cadenceKind: RoutineCadenceKind.flexible,
  );
}

RoutineCadenceKind _cadenceKindFor(Routine routine) {
  return routine.routineType == RoutineType.weeklyFixed
      ? RoutineCadenceKind.scheduled
      : RoutineCadenceKind.flexible;
}

int _spacingFor(Routine routine, int remaining, int daysLeft) {
  if (remaining <= 0 || daysLeft <= 0) return 0;
  final idealSpacing = math.max(1, (daysLeft / remaining).floor());
  var spacing = idealSpacing;
  final buffer = routine.restDayBuffer;
  if (buffer != null && buffer >= 0) {
    if (remaining <= (daysLeft - buffer)) {
      spacing = math.max(spacing, buffer + 1);
    }
  }
  final minSpacing = routine.minSpacingDays;
  if (minSpacing != null && minSpacing >= 0) {
    spacing = math.max(spacing, minSpacing + 1);
  }
  return spacing;
}

DateTime? _lastCompletionDay(
  List<RoutineCompletion> completions, {
  required String routineId,
  required DateTime periodStartUtc,
  required DateTime periodEndUtc,
  required DateTime todayUtc,
}) {
  DateTime? latest;
  for (final completion in completions) {
    if (completion.routineId != routineId) continue;
    final day = dateOnly(completion.completedAtUtc);
    if (day.isBefore(periodStartUtc) || day.isAfter(periodEndUtc)) continue;
    if (day.isAfter(todayUtc)) continue;
    if (latest == null || day.isAfter(latest)) {
      latest = day;
    }
  }
  return latest;
}

bool _completedOnDay(
  List<RoutineCompletion> completions, {
  required String routineId,
  required DateTime dayKeyUtc,
}) {
  final target = dateOnly(dayKeyUtc);
  return completions.any(
    (completion) =>
        completion.routineId == routineId &&
        dateOnly(completion.completedAtUtc).isAtSameMomentAs(target),
  );
}

DateTime _earliestSpacingDay(
  DateTime today,
  DateTime? lastCompletionDay,
  int spacing,
) {
  if (lastCompletionDay == null) return today;
  final candidate = lastCompletionDay.add(Duration(days: spacing));
  if (candidate.isBefore(today)) return today;
  return candidate;
}

DateTime? _lastScheduledDay(
  DateTime today,
  List<int> scheduleDays,
  DateTime periodStartUtc,
) {
  var cursor = today;
  while (!cursor.isBefore(periodStartUtc)) {
    if (scheduleDays.contains(cursor.weekday)) return cursor;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return null;
}

DateTime? _nextScheduledDay(
  DateTime today,
  List<int> scheduleDays,
  DateTime periodEndUtc,
) {
  var cursor = today.add(const Duration(days: 1));
  while (!cursor.isAfter(periodEndUtc)) {
    if (scheduleDays.contains(cursor.weekday)) return cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
  return null;
}

DateTime? _nextScheduledDayOnOrAfter(
  DateTime start,
  List<int> scheduleDays,
  DateTime periodEndUtc,
) {
  var cursor = start;
  while (!cursor.isAfter(periodEndUtc)) {
    if (scheduleDays.contains(cursor.weekday)) return cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
  return null;
}
