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
  List<TasklyBadgeData> badges = const <TasklyBadgeData>[],
  TasklyRoutineRowLabels? labels,
}) {
  final periodType = snapshot.periodType;
  final targetLabel = periodType == RoutinePeriodType.week
      ? context.l10n.routineTargetWeekly(snapshot.targetCount)
      : context.l10n.routineTargetMonthly(snapshot.targetCount);

  final remainingLabel = context.l10n.routineRemaining(snapshot.remainingCount);

  final windowLabel = periodType == RoutinePeriodType.week
      ? _weeklyWindowLabel(context, snapshot)
      : _monthlyWindowLabel(context, snapshot);

  final suggestedDayBadges = _suggestedDayBadges(
    context,
    routine: routine,
  );

  return TasklyRoutineRowData(
    id: routine.id,
    title: routine.name,
    targetLabel: targetLabel,
    remainingLabel: remainingLabel,
    windowLabel: windowLabel,
    statusLabel: _statusLabel(context, snapshot.status),
    statusTone: _statusTone(snapshot.status),
    valueChip: routine.value?.toChipData(context),
    selected: selected,
    completed: completed,
    badges: [...badges, ...suggestedDayBadges],
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
  return context.l10n.routineWindowMonthlyByDate(
    endLabel,
    snapshot.daysLeft,
  );
}

List<TasklyBadgeData> _suggestedDayBadges(
  BuildContext context, {
  required Routine routine,
}) {
  if (routine.routineType != RoutineType.weeklyFlexible &&
      routine.routineType != RoutineType.weeklyFixed) {
    return const <TasklyBadgeData>[];
  }

  final scheduleDays = routine.scheduleDays;
  if (scheduleDays.isEmpty) return const <TasklyBadgeData>[];

  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.E(locale);
  final scheme = Theme.of(context).colorScheme;
  final sorted = scheduleDays.toSet().toList()..sort();

  return [
    for (final day in sorted)
      TasklyBadgeData(
        label: formatter.format(DateTime.utc(2024, 1, day)),
        color: scheme.onSurfaceVariant,
        tone: TasklyBadgeTone.outline,
      ),
  ];
}
