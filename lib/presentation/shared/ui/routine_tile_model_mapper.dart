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
  bool highlightCompleted = true,
  bool showProgress = false,
  bool forceProgress = false,
  bool showScheduleRow = false,
  DateTime? dayKeyUtc,
  List<RoutineCompletion>? completionsInPeriod,
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final remainingLabel = context.l10n.routineRemaining(snapshot.remainingCount);
  final windowLabel = _windowLabel(context, routine, snapshot);
  final targetLabel = _cadenceLabel(context, routine);

  final effectiveShowProgress =
      showProgress &&
      (_supportsProgress(routine.routineType) ||
          (forceProgress && routine.routineType == RoutineType.weeklyFixed));

  final progressData = effectiveShowProgress
      ? TasklyRoutineProgressData(
          completedCount: snapshot.completedCount,
          targetCount: snapshot.targetCount,
          windowLabel: windowLabel,
          caption: _progressCaption(context, snapshot),
        )
      : null;

  TasklyRoutineScheduleRowData? scheduleRow;
  if (showScheduleRow &&
      routine.routineType == RoutineType.weeklyFixed &&
      routine.scheduleDays.isNotEmpty &&
      dayKeyUtc != null &&
      completionsInPeriod != null) {
    scheduleRow = _buildScheduleRow(
      context,
      routine: routine,
      dayKeyUtc: dayKeyUtc,
      completions: completionsInPeriod,
      status: snapshot.status,
    );
  }
  return TasklyRoutineRowData(
    id: routine.id,
    title: routine.name,
    targetLabel: targetLabel,
    remainingLabel: remainingLabel,
    windowLabel: windowLabel,
    progress: progressData,
    scheduleRow: scheduleRow,
    valueChip: routine.value?.toChipData(context),
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
        ? context.l10n.routineLoggedLabel
        : context.l10n.myDayDoTodayAction,
  );
}

String _weeklyWindowLabel(
  BuildContext context,
  RoutineCadenceSnapshot snapshot,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.E(locale);
  final startLabel = formatter.format(snapshot.periodStartUtc.toLocal());
  final endLabel = formatter.format(snapshot.periodEndUtc.toLocal());

  return context.l10n.routineWindowWeekly(
    snapshot.daysLeft,
    startLabel,
    endLabel,
  );
}

String _monthlyWindowLabel(
  BuildContext context,
  RoutineCadenceSnapshot snapshot,
) {
  final localizations = MaterialLocalizations.of(context);
  final endDate = snapshot.periodEndUtc.toLocal();
  final endLabel = localizations.formatMediumDate(endDate);
  return context.l10n.routineWindowMonthlyEnds(endLabel);
}

String _cadenceLabel(BuildContext context, Routine routine) {
  return routine.routineType == RoutineType.weeklyFixed
      ? context.l10n.routineCadenceScheduledLabel
      : context.l10n.routineCadenceFlexibleLabel;
}

String _windowLabel(
  BuildContext context,
  Routine routine,
  RoutineCadenceSnapshot snapshot,
) {
  if (routine.routineType == RoutineType.weeklyFixed) {
    final scheduleDays = routine.scheduleDays;
    if (scheduleDays.isEmpty) {
      return _weeklyWindowLabel(context, snapshot);
    }
    final daysLabel = _scheduledDaysLabel(context, scheduleDays);
    return context.l10n.routineWindowScheduledDays(daysLabel);
  }

  if (snapshot.periodType == RoutinePeriodType.week) {
    return _weeklyWindowLabel(context, snapshot);
  }

  return _monthlyWindowLabel(context, snapshot);
}

String _progressCaption(
  BuildContext context,
  RoutineCadenceSnapshot snapshot,
) {
  if (snapshot.targetCount <= 0) return '';
  return switch (snapshot.periodType) {
    RoutinePeriodType.week => context.l10n.routineProgressCaptionWeekly(
      snapshot.completedCount,
      snapshot.targetCount,
    ),
    RoutinePeriodType.month => context.l10n.routineProgressCaptionMonthly(
      snapshot.completedCount,
      snapshot.targetCount,
    ),
  };
}

String _scheduledDaysLabel(BuildContext context, List<int> scheduleDays) {
  if (scheduleDays.isEmpty) return '';
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.E(locale);
  final sorted = scheduleDays.toSet().toList()..sort();
  return sorted
      .map((day) => formatter.format(DateTime.utc(2024, 1, day)))
      .join('/');
}

bool _supportsProgress(RoutineType type) {
  return type == RoutineType.weeklyFlexible ||
      type == RoutineType.monthlyFlexible;
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

  final completionDays = <DateTime>{};
  for (final completion in completions) {
    completionDays.add(dateOnly(completion.completedAtUtc));
  }

  final weekStart = _weekStart(today);
  final days = <TasklyRoutineScheduleDay>[];

  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final isBeforeCreation = day.isBefore(createdDay);
    final isScheduled = scheduleDays.contains(day.weekday);
    final isToday = day.isAtSameMomentAs(today);
    final label = _dayLetter(context, day);
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
