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
  final createdDay = dateOnly(routine.createdAt);
  final isCreatedToday = createdDay.isAtSameMomentAs(today);
  final remaining = snapshot.remainingCount;

  if (remaining <= 0) {
    return RoutineDayPolicyResult(
      isEligibleToday: false,
      isCatchUpDay: false,
      cadenceKind: _cadenceKindFor(routine),
    );
  }

  final isScheduled = routine.scheduleMode == RoutineScheduleMode.scheduled;
  final scheduleDays =
      routine.periodType == RoutinePeriodType.week && isScheduled
      ? routine.scheduleDays
      : const <int>[];

  if (routine.periodType == RoutinePeriodType.week &&
      isScheduled &&
      scheduleDays.isNotEmpty) {
    final lastScheduledDay = _lastScheduledDay(
      today,
      scheduleDays,
      snapshot.periodStartUtc,
    );
    final nextScheduledDay = _nextScheduledDay(
      today,
      scheduleDays,
      snapshot.periodEndUtc,
    );
    final isScheduledToday = scheduleDays.contains(today.weekday);
    final missedLast =
        lastScheduledDay != null &&
        !lastScheduledDay.isBefore(createdDay) &&
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

  if (routine.periodType == RoutinePeriodType.month) {
    if (isScheduled) {
      final scheduleDates = routine.scheduleMonthDays;
      final isScheduledToday = scheduleDates.contains(today.day);
      return RoutineDayPolicyResult(
        isEligibleToday: isScheduledToday,
        isCatchUpDay: false,
        cadenceKind: RoutineCadenceKind.scheduled,
      );
    }
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: !isCreatedToday && remaining > snapshot.daysLeft,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  if (routine.periodType == RoutinePeriodType.day) {
    return RoutineDayPolicyResult(
      isEligibleToday: true,
      isCatchUpDay: !isCreatedToday && remaining > snapshot.daysLeft,
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
  final isCatchUp = !isCreatedToday && isBehind;

  if (scheduleDays.isEmpty) {
    return RoutineDayPolicyResult(
      isEligibleToday: isBehind || eligibleBySpacing,
      isCatchUpDay: isCatchUp,
      cadenceKind: RoutineCadenceKind.flexible,
    );
  }

  return RoutineDayPolicyResult(
    isEligibleToday: false,
    isCatchUpDay: isCatchUp,
    cadenceKind: RoutineCadenceKind.flexible,
  );
}

RoutineCadenceKind _cadenceKindFor(Routine routine) {
  return routine.scheduleMode == RoutineScheduleMode.scheduled
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
