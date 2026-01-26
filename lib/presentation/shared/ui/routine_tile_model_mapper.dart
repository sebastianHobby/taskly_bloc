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
  final periodType = snapshot.periodType;
  final baseTargetLabel = periodType == RoutinePeriodType.week
      ? context.l10n.routineTargetWeekly(snapshot.targetCount)
      : context.l10n.routineTargetMonthly(snapshot.targetCount);

  final remainingLabel = context.l10n.routineRemaining(snapshot.remainingCount);

  final windowLabel = periodType == RoutinePeriodType.week
      ? _weeklyWindowLabel(context, snapshot)
      : _monthlyWindowLabel(context, snapshot);

  final cadenceSegments = _cadenceSegments(context, routine);
  final targetLabel = _joinSegments([...cadenceSegments, baseTargetLabel]);
  final supportBadges = isCatchUpDay
      ? [
          TasklyBadgeData(
            label: context.l10n.routineCatchUpSupportLine,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tone: TasklyBadgeTone.soft,
          ),
        ]
      : const <TasklyBadgeData>[];

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
    badges: [...badges, ...supportBadges],
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
  return context.l10n.routineWindowMonthlyByDate(
    endLabel,
    snapshot.daysLeft,
  );
}

List<String> _cadenceSegments(BuildContext context, Routine routine) {
  if (routine.routineType == RoutineType.weeklyFixed) {
    final scheduleDays = routine.scheduleDays;
    if (scheduleDays.isEmpty) {
      return [context.l10n.routineCadenceScheduledLabel];
    }
    return [
      context.l10n.routineCadenceScheduledLabel,
      _scheduledDaysLabel(context, scheduleDays),
    ];
  }
  return [context.l10n.routineCadenceFlexibleLabel];
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

String _joinSegments(List<String> segments) {
  return segments
      .map((text) => text.trim())
      .where((text) => text.isNotEmpty)
      .join(' \u00b7 ');
}
