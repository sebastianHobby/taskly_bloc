import 'dart:math' as math;

import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_completion.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_progress.dart';
import 'package:taskly_domain/src/routines/model/routine_skip.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';
import 'package:taskly_domain/time.dart';

final class RoutineScheduleService {
  const RoutineScheduleService();

  RoutineCadenceSnapshot buildSnapshot({
    required Routine routine,
    required DateTime dayKeyUtc,
    required List<RoutineCompletion> completions,
    required List<RoutineSkip> skips,
  }) {
    final today = dateOnly(dayKeyUtc);
    final periodType = routine.periodType;
    final periodStart = switch (periodType) {
      RoutinePeriodType.day => today,
      RoutinePeriodType.week => _weekStart(today),
      RoutinePeriodType.fortnight => _fortnightStart(today),
      RoutinePeriodType.month => _monthStart(today),
    };
    final periodEnd = switch (periodType) {
      RoutinePeriodType.day => periodStart,
      RoutinePeriodType.week => periodStart.add(const Duration(days: 6)),
      RoutinePeriodType.fortnight => periodStart.add(const Duration(days: 13)),
      RoutinePeriodType.month => _monthEnd(today),
    };

    final periodKey = dateOnly(periodStart);
    final skip = _hasSkipForPeriod(
      skips,
      routineId: routine.id,
      periodType: periodType,
      periodKeyUtc: periodKey,
    );

    final completedCount = _countCompletionsForPeriod(
      completions,
      routineId: routine.id,
      periodStartUtc: periodStart,
      periodEndUtc: periodEnd,
    );

    final remaining = skip
        ? 0
        : math.max(0, routine.targetCount - completedCount);

    final daysLeft = math.max(
      0,
      periodEnd.difference(today).inDays + 1,
    );

    final status = _statusFor(
      remainingCount: remaining,
      daysLeft: daysLeft,
      isSkipped: skip,
    );

    final nextRecommendedDayUtc = _nextRecommendedDay(
      routine,
      today: today,
      periodEndUtc: periodEnd,
      remainingCount: remaining,
      daysLeft: daysLeft,
    );

    return RoutineCadenceSnapshot(
      routineId: routine.id,
      periodType: periodType,
      periodStartUtc: periodStart,
      periodEndUtc: periodEnd,
      targetCount: routine.targetCount,
      completedCount: completedCount,
      remainingCount: remaining,
      daysLeft: daysLeft,
      status: status,
      nextRecommendedDayUtc: nextRecommendedDayUtc,
    );
  }

  bool _hasSkipForPeriod(
    List<RoutineSkip> skips, {
    required String routineId,
    required RoutinePeriodType periodType,
    required DateTime periodKeyUtc,
  }) {
    return skips.any(
      (skip) =>
          skip.routineId == routineId &&
          skip.periodType.name == periodType.name &&
          dateOnly(skip.periodKeyUtc).isAtSameMomentAs(periodKeyUtc),
    );
  }

  int _countCompletionsForPeriod(
    List<RoutineCompletion> completions, {
    required String routineId,
    required DateTime periodStartUtc,
    required DateTime periodEndUtc,
  }) {
    var count = 0;
    for (final completion in completions) {
      if (completion.routineId != routineId) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(periodStartUtc) || day.isAfter(periodEndUtc)) continue;
      count += 1;
    }
    return count;
  }

  RoutineStatus _statusFor({
    required int remainingCount,
    required int daysLeft,
    required bool isSkipped,
  }) {
    if (isSkipped) return RoutineStatus.restWeek;
    if (remainingCount <= 0) return RoutineStatus.onPace;
    if (remainingCount > daysLeft) return RoutineStatus.catchUp;
    if (remainingCount >= math.max(0, daysLeft - 1)) {
      return RoutineStatus.tightWeek;
    }
    return RoutineStatus.onPace;
  }

  DateTime? _nextRecommendedDay(
    Routine routine, {
    required DateTime today,
    required DateTime periodEndUtc,
    required int remainingCount,
    required int daysLeft,
  }) {
    if (remainingCount <= 0) return null;

    return switch (routine.periodType) {
      RoutinePeriodType.day => null,
      RoutinePeriodType.week =>
        routine.scheduleMode == RoutineScheduleMode.scheduled
            ? _nextFixedDay(
                today: today,
                scheduleDays: routine.scheduleDays,
              )
            : _nextFlexibleDay(
                routine: routine,
                today: today,
                periodEndUtc: periodEndUtc,
                remainingCount: remainingCount,
                daysLeft: daysLeft,
              ),
      RoutinePeriodType.fortnight => _nextFlexibleDay(
        routine: routine,
        today: today,
        periodEndUtc: periodEndUtc,
        remainingCount: remainingCount,
        daysLeft: daysLeft,
      ),
      RoutinePeriodType.month =>
        routine.scheduleMode == RoutineScheduleMode.scheduled
            ? _nextMonthlyScheduledDay(
                today: today,
                scheduleMonthDays: routine.scheduleMonthDays,
              )
            : _nextFlexibleDay(
                routine: routine,
                today: today,
                periodEndUtc: periodEndUtc,
                remainingCount: remainingCount,
                daysLeft: daysLeft,
              ),
    };
  }

  DateTime? _nextFixedDay({
    required DateTime today,
    required List<int> scheduleDays,
  }) {
    if (scheduleDays.isEmpty) return null;
    final normalized = dateOnly(today);
    for (var i = 1; i <= 7; i++) {
      final candidate = normalized.add(Duration(days: i));
      if (scheduleDays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    return null;
  }

  DateTime? _nextFlexibleDay({
    required Routine routine,
    required DateTime today,
    required DateTime periodEndUtc,
    required int remainingCount,
    required int daysLeft,
  }) {
    if (remainingCount <= 0 || daysLeft <= 0) return null;

    final idealSpacing = math.max(1, (daysLeft / remainingCount).floor());
    var spacing = idealSpacing;

    final buffer = routine.restDayBuffer;
    if (buffer != null && buffer >= 0) {
      if (remainingCount <= (daysLeft - buffer)) {
        spacing = math.max(spacing, buffer + 1);
      }
    }

    final minSpacing = routine.minSpacingDays;
    if (minSpacing != null && minSpacing >= 0) {
      spacing = math.max(spacing, minSpacing + 1);
    }

    final candidate = dateOnly(today).add(Duration(days: spacing));
    if (candidate.isAfter(periodEndUtc)) return periodEndUtc;
    return candidate;
  }

  DateTime? _nextMonthlyScheduledDay({
    required DateTime today,
    required List<int> scheduleMonthDays,
  }) {
    if (scheduleMonthDays.isEmpty) return null;
    final normalized = dateOnly(today);
    final sorted = scheduleMonthDays.toSet().toList()..sort();
    for (final day in sorted) {
      if (day <= normalized.day) continue;
      return DateTime.utc(normalized.year, normalized.month, day);
    }
    final nextMonth = DateTime.utc(normalized.year, normalized.month + 1, 1);
    return DateTime.utc(nextMonth.year, nextMonth.month, sorted.first);
  }

  DateTime _weekStart(DateTime dayKeyUtc) {
    final normalized = dateOnly(dayKeyUtc);
    final delta = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: delta));
  }

  DateTime _monthStart(DateTime dayKeyUtc) {
    return DateTime.utc(dayKeyUtc.year, dayKeyUtc.month);
  }

  DateTime _fortnightStart(DateTime dayKeyUtc) {
    final weekStart = _weekStart(dayKeyUtc);
    final anchor = DateTime.utc(1970, 1, 5); // Monday
    final deltaDays = weekStart.difference(anchor).inDays;
    final periodIndex = _floorDiv(deltaDays, 14);
    return anchor.add(Duration(days: periodIndex * 14));
  }

  int _floorDiv(int value, int divisor) {
    if (value >= 0) return value ~/ divisor;
    return -(((-value) + divisor - 1) ~/ divisor);
  }

  DateTime _monthEnd(DateTime dayKeyUtc) {
    final start = DateTime.utc(dayKeyUtc.year, dayKeyUtc.month);
    final nextMonth = DateTime.utc(start.year, start.month + 1);
    return nextMonth.subtract(const Duration(days: 1));
  }
}
