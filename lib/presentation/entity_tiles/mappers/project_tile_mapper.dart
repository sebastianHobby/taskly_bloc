import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui.dart';

ProjectTileModel buildProjectListRowTileModel(
  BuildContext context, {
  required Project project,
  int? taskCount,
  int? completedTaskCount,
  bool showTrailingProgressLabel = false,
}) {
  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = project.startDate;
  final startDay = start == null
      ? null
      : DateTime(start.year, start.month, start.day);
  final startDateLabel = (startDay != null && startDay.isAfter(today))
      ? DateLabelFormatter.format(context, start)
      : null;

  final deadlineDateLabel = project.deadlineDate == null
      ? null
      : DateLabelFormatter.format(context, project.deadlineDate);

  final meta = EntityMetaLineModel(
    primaryValue: project.primaryValue?.toChipData(context),
    secondaryValues: project.secondaryValues.isEmpty
        ? const <ValueChipData>[]
        : <ValueChipData>[project.secondaryValues.first.toChipData(context)],
    secondaryValuePresentation:
        EntitySecondaryValuePresentation.singleOutlinedIconOnly,
    startDateLabel: startDateLabel,
    deadlineDateLabel: deadlineDateLabel,
    isOverdue: _isOverdue(project.deadlineDate, completed: project.completed),
    isDueToday: _isDueToday(project.deadlineDate, completed: project.completed),
    isDueSoon: _isDueSoon(project.deadlineDate, completed: project.completed),
    hasRepeat: project.repeatIcalRrule != null,
    showRepeatOnRight: true,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: true,
    priority: project.priority,
    priorityColor: _priorityColor(project.priority),
    priorityPillLabel: project.priority == null
        ? null
        : 'Priority P${project.priority}',
    enableRightOverflowDemotion: true,
    showOverflowIndicatorOnRight: true,
  );

  return ProjectTileModel(
    id: project.id,
    title: project.name,
    completed: project.completed,
    pinned: project.isPinned,
    meta: meta,
    taskCount: taskCount,
    completedTaskCount: completedTaskCount,
    emptyTasksLabel: taskCount == 0 ? 'No tasks yet' : null,
    showTrailingProgressLabel: showTrailingProgressLabel,
  );
}

ProjectAgendaCardModel buildProjectAgendaCardModel(
  BuildContext context, {
  required Project project,
  required bool inProgressStyle,
  required DateTime? endDate,
  int? taskCount,
  int? completedTaskCount,
  Color? accentColor,
  bool showDeadlineChipOnOngoing = true,
}) {
  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = project.startDate;
  final startDay = start == null
      ? null
      : DateTime(start.year, start.month, start.day);
  final startDateLabel = (startDay != null && startDay.isAfter(today))
      ? DateLabelFormatter.format(context, start)
      : null;

  final deadlineDateLabel = project.deadlineDate == null
      ? null
      : DateLabelFormatter.format(context, project.deadlineDate);

  final meta = EntityMetaLineModel(
    primaryValue: project.primaryValue?.toChipData(context),
    secondaryValues: project.secondaryValues.isEmpty
        ? const <ValueChipData>[]
        : <ValueChipData>[project.secondaryValues.first.toChipData(context)],
    secondaryValuePresentation:
        EntitySecondaryValuePresentation.singleOutlinedIconOnly,
    startDateLabel: startDateLabel,
    deadlineDateLabel: deadlineDateLabel,
    showDates: !inProgressStyle || showDeadlineChipOnOngoing,
    showOnlyDeadlineDate: inProgressStyle,
    isOverdue: _isOverdue(project.deadlineDate, completed: project.completed),
    isDueToday: _isDueToday(project.deadlineDate, completed: project.completed),
    isDueSoon: _isDueSoon(project.deadlineDate, completed: project.completed),
    hasRepeat: project.repeatIcalRrule != null,
    showRepeatOnRight: true,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: true,
    priority: project.priority,
    priorityColor: _priorityColor(project.priority),
    priorityPillLabel: project.priority == null
        ? null
        : 'Priority P${project.priority}',
    enableRightOverflowDemotion: true,
    showOverflowIndicatorOnRight: true,
  );

  final base = ProjectTileModel(
    id: project.id,
    title: project.name,
    completed: project.completed,
    pinned: project.isPinned,
    meta: meta,
    taskCount: taskCount,
    completedTaskCount: completedTaskCount,
    emptyTasksLabel: taskCount == 0 ? 'No tasks yet' : null,
  );

  final endDayLabel = endDate == null
      ? null
      : MaterialLocalizations.of(context).formatShortWeekday(endDate);

  return ProjectAgendaCardModel(
    base: base,
    accentColor: accentColor,
    inProgressStyle: inProgressStyle,
    endDayLabel: endDayLabel,
  );
}

bool _isOverdue(DateTime? deadline, {required bool completed}) {
  if (deadline == null || completed) return false;
  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  return deadlineDay.isBefore(today);
}

bool _isDueToday(DateTime? deadline, {required bool completed}) {
  if (deadline == null || completed) return false;
  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  return deadlineDay.isAtSameMomentAs(today);
}

bool _isDueSoon(DateTime? deadline, {required bool completed}) {
  if (deadline == null || completed) return false;
  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  final daysUntil = deadlineDay.difference(today).inDays;
  return daysUntil > 0 && daysUntil <= 3;
}

Color? _priorityColor(int? p) {
  return switch (p) {
    1 => AppColors.rambutan80,
    2 => AppColors.cempedak80,
    _ => null,
  };
}
