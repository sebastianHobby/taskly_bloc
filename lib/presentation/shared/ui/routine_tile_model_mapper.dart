import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

TasklyRoutineRowData buildRoutineRowData(
  BuildContext context, {
  required Routine routine,
  required RoutineCadenceSnapshot snapshot,
  bool selected = false,
  bool completed = false,
  bool isCatchUpDay = false,
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final remainingLabel = context.l10n.routineRemaining(snapshot.remainingCount);
  final windowLabel = _windowLabel(context, routine, snapshot);
  final targetLabel = _cadenceLabel(context, routine);

  return TasklyRoutineRowData(
    id: routine.id,
    title: routine.name,
    targetLabel: targetLabel,
    remainingLabel: remainingLabel,
    windowLabel: windowLabel,
    statusLabel: _statusLabel(
      context,
      snapshot.status,
      isCatchUpDay: isCatchUpDay,
    ),
    statusTone: _statusTone(
      snapshot.status,
      isCatchUpDay: isCatchUpDay,
    ),
    valueChip: routine.value?.toChipData(context),
    selected: selected,
    completed: completed,
    badges: badges,
    labels: labels,
  );
}

TasklyRoutineRowLabels buildRoutinePlanLabels(
  BuildContext context, {
  String? skipPeriodLabel,
}) {
  return TasklyRoutineRowLabels(
    primaryActionLabel: context.l10n.routinePrimaryActionLabel,
    pauseLabel: context.l10n.routinePauseLabel,
    editLabel: context.l10n.routineEditLabel,
  );
}

TasklyRoutineRowLabels buildRoutineListLabels(BuildContext context) {
  return TasklyRoutineRowLabels(
    editLabel: context.l10n.routineEditLabel,
  );
}

String _statusLabel(
  BuildContext context,
  RoutineStatus status, {
  required bool isCatchUpDay,
}) {
  if (isCatchUpDay) return context.l10n.routineStatusCatchUp;
  return switch (status) {
    RoutineStatus.restWeek => context.l10n.routineStatusRestWeek,
    _ => context.l10n.routineStatusOnPace,
  };
}

TasklyRoutineStatusTone _statusTone(
  RoutineStatus status, {
  required bool isCatchUpDay,
}) {
  if (isCatchUpDay) return TasklyRoutineStatusTone.catchUp;
  return switch (status) {
    RoutineStatus.restWeek => TasklyRoutineStatusTone.restWeek,
    _ => TasklyRoutineStatusTone.onPace,
  };
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

String _scheduledDaysLabel(BuildContext context, List<int> scheduleDays) {
  if (scheduleDays.isEmpty) return '';
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.E(locale);
  final sorted = scheduleDays.toSet().toList()..sort();
  return sorted
      .map((day) => formatter.format(DateTime.utc(2024, 1, day)))
      .join('/');
}
