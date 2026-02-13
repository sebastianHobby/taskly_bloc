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
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final scheduleRow =
      (showScheduleRow &&
          routine.periodType == RoutinePeriodType.week &&
          routine.scheduleMode == RoutineScheduleMode.scheduled &&
          routine.scheduleDays.isNotEmpty &&
          dayKeyUtc != null &&
          completionsInPeriod != null)
      ? _buildScheduleRow(
          context,
          routine: routine,
          dayKeyUtc: dayKeyUtc,
          completions: completionsInPeriod,
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
        ? context.l10n.doneLabel
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

  final completedWeekdays = completionDays.map((day) => day.weekday).toSet();
  final unscheduledWeekdays = completedWeekdays.difference(scheduleDays);

  final daysToShow = <int>{...scheduleDays, ...unscheduledWeekdays};
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
        status != RoutineStatus.restWeek;

    final state = isBeforeCreation
        ? TasklyRoutineScheduleDayState.none
        : isCompleted
        ? (isScheduled
              ? TasklyRoutineScheduleDayState.loggedScheduled
              : TasklyRoutineScheduleDayState.loggedUnscheduled)
        : isMissed
        ? TasklyRoutineScheduleDayState.missedScheduled
        : isScheduled
        ? TasklyRoutineScheduleDayState.scheduled
        : TasklyRoutineScheduleDayState.none;

    final label = _dayLabel(
      context,
      day,
      addMarker: isCompleted && !isScheduled,
    );

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

String _dayLabel(
  BuildContext context,
  DateTime day, {
  required bool addMarker,
}) {
  final base = _dayLetter(context, day);
  return addMarker ? '$base*' : base;
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
