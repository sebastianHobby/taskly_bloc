import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

TasklyRoutineRowData buildRoutineRowData(
  BuildContext context, {
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  bool selected = false,
  bool completed = false,
  bool highlightCompleted = false,
  bool showScheduleRow = false,
  DateTime? dayKeyUtc,
  List<RoutineCompletion>? completionsInPeriod,
  List<RoutineSkip>? skipsInPeriod,
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final scheduleRow =
      (showScheduleRow &&
          routine.periodType == RoutinePeriodType.week &&
          routine.scheduleMode == RoutineScheduleMode.scheduled &&
          routine.scheduleDays.isNotEmpty &&
          dayKeyUtc != null &&
          completionsInPeriod != null &&
          skipsInPeriod != null)
      ? _buildScheduleRow(
          context,
          routine: routine,
          dayKeyUtc: dayKeyUtc,
          completions: completionsInPeriod,
          skips: skipsInPeriod,
          status: snapshot.status,
        )
      : null;

  final dotRow = _buildDotRow(context, routine: routine, snapshot: snapshot);
  final actionLineText = _buildActionLineText(
    context,
    routine: routine,
    snapshot: snapshot,
    scheduleRowShown: scheduleRow != null,
  );

  return TasklyRoutineRowData(
    id: routine.id,
    title: routine.name,
    actionLineText: actionLineText,
    dotRow: dotRow,
    scheduleRow: scheduleRow,
    leadingIcon: routine.value?.toChipData(context),
    selected: selected,
    completed: completed,
    highlightCompleted: highlightCompleted,
    badges: badges,
    labels: labels,
  );
}

TasklyRoutineRowLabels buildRoutineExecutionLabels(
  BuildContext context, {
  required bool completed,
}) {
  return TasklyRoutineRowLabels(
    primaryActionLabel: completed
        ? context.l10n.routineUnlogLabel
        : context.l10n.routineLogLabel,
  );
}

String? _buildActionLineText(
  BuildContext context, {
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  required bool scheduleRowShown,
}) {
  final l10n = context.l10n;
  final periodType = routine.periodType;
  final scheduleMode = routine.scheduleMode;

  if (periodType == RoutinePeriodType.day) return null;
  if (scheduleMode == RoutineScheduleMode.scheduled &&
      periodType == RoutinePeriodType.week &&
      scheduleRowShown) {
    return null;
  }

  if (scheduleMode == RoutineScheduleMode.scheduled &&
      periodType == RoutinePeriodType.month) {
    final targetCount = routine.scheduleMonthDays.isNotEmpty
        ? routine.scheduleMonthDays.length
        : snapshot.targetCount;
    final nextDay = snapshot.nextRecommendedDayUtc;
    if (nextDay == null) {
      return l10n.routineActionLineMonthlyScheduledNoNext(
        snapshot.completedCount,
        targetCount,
      );
    }
    final nextLabel = l10n.routineDayOfMonthOrdinal(nextDay.day);
    return l10n.routineActionLineMonthlyScheduled(
      snapshot.completedCount,
      targetCount,
      nextLabel,
    );
  }

  if (scheduleMode == RoutineScheduleMode.flexible &&
      periodType != RoutinePeriodType.day) {
    return l10n.routineActionLineFlexible(
      snapshot.completedCount,
      snapshot.targetCount,
      snapshot.daysLeft,
    );
  }

  return null;
}

TasklyRoutineDotRowData? _buildDotRow(
  BuildContext context, {
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
}) {
  if (routine.periodType != RoutinePeriodType.day ||
      routine.scheduleMode != RoutineScheduleMode.flexible) {
    return null;
  }

  return TasklyRoutineDotRowData(
    completedCount: snapshot.completedCount,
    targetCount: snapshot.targetCount,
    label: context.l10n.routineDailyGoalLabel(snapshot.targetCount),
  );
}

TasklyRoutineScheduleRowData _buildScheduleRow(
  BuildContext context, {
  required Routine routine,
  required DateTime dayKeyUtc,
  required List<RoutineCompletion> completions,
  required List<RoutineSkip> skips,
  required RoutineStatus status,
}) {
  final today = dateOnly(dayKeyUtc);
  final createdDay = dateOnly(routine.createdAt);
  final scheduleDays = routine.scheduleDays.toSet();

  final weekStart = _weekStart(today);
  final weekEnd = weekStart.add(const Duration(days: 6));

  final completionDays = <DateTime>{};
  for (final completion in completions) {
    final day = dateOnly(
      completion.completedDayLocal ?? completion.completedAtUtc,
    );
    if (day.isBefore(weekStart) || day.isAfter(weekEnd)) continue;
    completionDays.add(day);
  }

  final skipCreatedDay = _skipCreatedDayForWeek(
    routineId: routine.id,
    weekStart: weekStart,
    skips: skips,
  );
  final hasWeekSkip =
      skipCreatedDay != null || status == RoutineStatus.restWeek;

  final daysToShow = <int>{...scheduleDays};
  final orderedDays = daysToShow.toList()..sort();

  final days = <TasklyRoutineScheduleDay>[];
  for (final weekday in orderedDays) {
    final day = weekStart.add(Duration(days: weekday - 1));
    final isBeforeCreation = day.isBefore(createdDay);
    final isScheduled = scheduleDays.contains(weekday);
    final isToday = day.isAtSameMomentAs(today);
    final isCompleted = completionDays.contains(day);

    final isMissed =
        !isBeforeCreation &&
        isScheduled &&
        day.isBefore(today) &&
        !isCompleted &&
        !hasWeekSkip &&
        status != RoutineStatus.restWeek;
    final isSkipped =
        !isBeforeCreation &&
        isScheduled &&
        !isCompleted &&
        hasWeekSkip &&
        (skipCreatedDay == null || !day.isBefore(skipCreatedDay));

    final state = isBeforeCreation
        ? TasklyRoutineScheduleDayState.none
        : isCompleted
        ? TasklyRoutineScheduleDayState.loggedScheduled
        : isSkipped
        ? TasklyRoutineScheduleDayState.skippedScheduled
        : isMissed
        ? TasklyRoutineScheduleDayState.missedScheduled
        : isScheduled
        ? TasklyRoutineScheduleDayState.scheduled
        : TasklyRoutineScheduleDayState.none;

    final label = _dayLetter(context, day);

    days.add(
      TasklyRoutineScheduleDay(
        label: label,
        isToday: isToday,
        state: state,
      ),
    );
  }

  return TasklyRoutineScheduleRowData(
    days: days,
  );
}

String _dayLetter(BuildContext context, DateTime day) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.E(locale);
  final label = formatter.format(day.toLocal());
  if (label.isEmpty) return '';
  return label.characters.first;
}

DateTime _weekStart(DateTime dayKeyUtc) {
  final normalized = dateOnly(dayKeyUtc);
  final delta = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: delta));
}

DateTime? _skipCreatedDayForWeek({
  required String routineId,
  required DateTime weekStart,
  required List<RoutineSkip> skips,
}) {
  DateTime? earliest;
  for (final skip in skips) {
    if (skip.routineId != routineId) continue;
    if (skip.periodType != RoutineSkipPeriodType.week) continue;
    if (!dateOnly(skip.periodKeyUtc).isAtSameMomentAs(weekStart)) continue;
    final createdDay = dateOnly(skip.createdAtUtc);
    if (earliest == null || createdDay.isBefore(earliest)) {
      earliest = createdDay;
    }
  }
  return earliest;
}
