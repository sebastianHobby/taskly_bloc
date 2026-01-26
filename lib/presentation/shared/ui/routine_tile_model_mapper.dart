import 'package:flutter/material.dart';
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
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final periodType = snapshot.periodType;
  final targetLabel = periodType == RoutinePeriodType.week
      ? context.l10n.routineTargetWeekly(snapshot.targetCount)
      : context.l10n.routineTargetMonthly(snapshot.targetCount);

  final remainingLabel =
      context.l10n.routineRemaining(snapshot.remainingCount);

  final windowLabel = periodType == RoutinePeriodType.week
      ? _weeklyWindowLabel(context, snapshot)
      : _monthlyWindowLabel(context, snapshot);

  return TasklyRoutineRowData(
    id: routine.id,
    title: routine.name,
    targetLabel: targetLabel,
    remainingLabel: remainingLabel,
    windowLabel: windowLabel,
    statusLabel: _statusLabel(context, snapshot.status),
    statusTone: _statusTone(snapshot.status),
    valueChip: routine.value == null ? null : routine.value!.toChipData(context),
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
    skipPeriodLabel: skipPeriodLabel ?? context.l10n.routineSkipPeriodLabel,
    pauseLabel: context.l10n.routinePauseLabel,
    editLabel: context.l10n.routineEditLabel,
  );
}

TasklyRoutineRowLabels buildRoutineListLabels(BuildContext context) {
  return TasklyRoutineRowLabels(
    editLabel: context.l10n.routineEditLabel,
  );
}

String _statusLabel(BuildContext context, RoutineStatus status) {
  return switch (status) {
    RoutineStatus.onPace => context.l10n.routineStatusOnPace,
    RoutineStatus.tightWeek => context.l10n.routineStatusTightWeek,
    RoutineStatus.catchUp => context.l10n.routineStatusCatchUp,
    RoutineStatus.restWeek => context.l10n.routineStatusRestWeek,
  };
}

TasklyRoutineStatusTone _statusTone(RoutineStatus status) {
  return switch (status) {
    RoutineStatus.onPace => TasklyRoutineStatusTone.onPace,
    RoutineStatus.tightWeek => TasklyRoutineStatusTone.tightWeek,
    RoutineStatus.catchUp => TasklyRoutineStatusTone.catchUp,
    RoutineStatus.restWeek => TasklyRoutineStatusTone.restWeek,
  };
}

String _weeklyWindowLabel(BuildContext context, RoutineCadenceSnapshot snapshot) {
  final localizations = MaterialLocalizations.of(context);
  final startLabel = localizations.formatShortWeekday(
    snapshot.periodStartUtc.toLocal(),
  );
  final endLabel = localizations.formatShortWeekday(
    snapshot.periodEndUtc.toLocal(),
  );

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
  return switch (snapshot.windowPhase) {
    RoutineWindowPhase.thisWeek => context.l10n.routineWindowMonthlyThisWeek,
    RoutineWindowPhase.nextWeek => context.l10n.routineWindowMonthlyNextWeek,
    RoutineWindowPhase.laterThisMonth =>
      context.l10n.routineWindowMonthlyLater,
    null => context.l10n.routineWindowMonthlyLater,
  };
}
