import 'dart:math' as math;

import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_completion.dart';
import 'package:taskly_domain/src/routines/model/routine_progress.dart';
import 'package:taskly_domain/src/routines/model/routine_skip.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';
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
    final periodType = _periodTypeFor(routine.routineType);
    final periodStart = switch (periodType) {
      RoutinePeriodType.week => _weekStart(today),
      RoutinePeriodType.month => _monthStart(today),
    };
    final periodEnd = switch (periodType) {
      RoutinePeriodType.week => periodStart.add(const Duration(days: 6)),
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

    final windowPhase = periodType == RoutinePeriodType.month
        ? _monthlyWindowPhase(routine, today: today)
        : null;

    final nextRecommendedDayUtc = _nextRecommendedDay(
      routine,
      today: today,
      periodEndUtc: periodEnd,
      remainingCount: remaining,
      daysLeft: daysLeft,
      windowPhase: windowPhase,
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
      windowPhase: windowPhase,
      nextRecommendedDayUtc: nextRecommendedDayUtc,
    );
  }

  RoutinePeriodType _periodTypeFor(RoutineType type) {
    return switch (type) {
      RoutineType.weeklyFixed => RoutinePeriodType.week,
      RoutineType.weeklyFlexible => RoutinePeriodType.week,
      RoutineType.monthlyFixed => RoutinePeriodType.month,
      RoutineType.monthlyFlexible => RoutinePeriodType.month,
    };
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
    required RoutineWindowPhase? windowPhase,
  }) {
    if (remainingCount <= 0) return null;

    return switch (routine.routineType) {
      RoutineType.weeklyFixed => _nextFixedDay(
        today: today,
        scheduleDays: routine.scheduleDays,
      ),
      RoutineType.weeklyFlexible => _nextFlexibleDay(
        routine: routine,
        today: today,
        periodEndUtc: periodEndUtc,
        remainingCount: remainingCount,
        daysLeft: daysLeft,
      ),
      RoutineType.monthlyFixed ||
      RoutineType.monthlyFlexible => _nextMonthlyWindowDay(
        today: today,
        windowPhase: windowPhase,
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

  DateTime? _nextMonthlyWindowDay({
    required DateTime today,
    required RoutineWindowPhase? windowPhase,
  }) {
    final normalized = dateOnly(today);
    return switch (windowPhase) {
      RoutineWindowPhase.thisWeek => normalized.add(const Duration(days: 1)),
      RoutineWindowPhase.nextWeek => _weekStart(normalized).add(
        const Duration(days: 7),
      ),
      RoutineWindowPhase.laterThisMonth => _weekStart(normalized).add(
        const Duration(days: 14),
      ),
      null => null,
    };
  }

  RoutineWindowPhase _monthlyWindowPhase(
    Routine routine, {
    required DateTime today,
  }) {
    final currentWeek = _weekOfMonth(today);
    final nextWeek = math.min(5, currentWeek + 1);
    final isLastWeek = _isLastWeekOfMonth(today);
    final preferred = routine.preferredWeeks;

    final prefersCurrent =
        preferred.contains(currentWeek) ||
        (preferred.contains(5) && isLastWeek);
    if (prefersCurrent) return RoutineWindowPhase.thisWeek;

    final isNextLastWeek = _isLastWeekOfMonth(
      today.add(const Duration(days: 7)),
    );
    final prefersNext =
        preferred.contains(nextWeek) || (preferred.contains(5) && isNextLastWeek);
    if (prefersNext) return RoutineWindowPhase.nextWeek;

    return RoutineWindowPhase.laterThisMonth;
  }

  DateTime _weekStart(DateTime dayKeyUtc) {
    final normalized = dateOnly(dayKeyUtc);
    final delta = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: delta));
  }

  DateTime _monthStart(DateTime dayKeyUtc) {
    return DateTime.utc(dayKeyUtc.year, dayKeyUtc.month);
  }

  DateTime _monthEnd(DateTime dayKeyUtc) {
    final start = DateTime.utc(dayKeyUtc.year, dayKeyUtc.month);
    final nextMonth = DateTime.utc(start.year, start.month + 1);
    return nextMonth.subtract(const Duration(days: 1));
  }

  int _weekOfMonth(DateTime dayKeyUtc) {
    final day = dayKeyUtc.day;
    if (day <= 7) return 1;
    if (day <= 14) return 2;
    if (day <= 21) return 3;
    if (day <= 28) return 4;
    return 5;
  }

  bool _isLastWeekOfMonth(DateTime dayKeyUtc) {
    final end = _monthEnd(dayKeyUtc);
    return end.difference(dayKeyUtc).inDays < 7;
  }
}
