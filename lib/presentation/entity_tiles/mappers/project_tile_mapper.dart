import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

ProjectTileModel buildProjectListRowTileModel(
  BuildContext context, {
  required Project project,
  int? taskCount,
  int? completedTaskCount,
  bool showTrailingProgressLabel = false,
  bool showDates = true,
  bool showOnlyDeadlineDate = false,
  bool showPrimaryValueOnTitleLine = false,
  bool showValuesInMetaLine = true,
  bool showSecondaryValues = true,
  String? overrideStartDateLabel,
  String? overrideDeadlineDateLabel,
  bool? overrideIsOverdue,
  bool? overrideIsDueToday,
  bool? overrideIsDueSoon,
  bool showPriorityMarkerOnRight = true,
  bool showRepeatIcon = true,
  bool showOverflowEllipsisWhenMetaHidden = false,
}) {
  final now = context.read<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = project.startDate;
  final startDateLabel = switch (start) {
    null => null,
    final startDate =>
      !DateTime(startDate.year, startDate.month, startDate.day).isBefore(today)
          ? _formatMonthDay(context, startDate)
          : null,
  };

  final deadlineDateLabel = project.deadlineDate == null
      ? null
      : _formatMonthDay(context, project.deadlineDate!);

  final resolvedStartDateLabel = overrideStartDateLabel ?? startDateLabel;
  final resolvedDeadlineDateLabel =
      overrideDeadlineDateLabel ?? deadlineDateLabel;

  final hasExtraSecondaryValues = project.secondaryValues.length > 1;

  final shouldShowOverflowEllipsis =
      showOverflowEllipsisWhenMetaHidden &&
      ((resolvedStartDateLabel != null) ||
          (resolvedDeadlineDateLabel != null) ||
          project.isRepeating ||
          project.priority != null ||
          hasExtraSecondaryValues);

  final primaryValueData = project.primaryValue?.toChipData(context);

  final meta = EntityMetaLineModel(
    showValuesInMetaLine: showValuesInMetaLine,
    primaryValue: primaryValueData,
    secondaryValues: !showSecondaryValues
        ? const []
        : project.secondaryValues
              .take(1)
              .map((v) => v.toChipData(context))
              .toList(growable: false),
    showOverflowEllipsis: shouldShowOverflowEllipsis,
    showDates: showDates,
    showOnlyDeadlineDate: showOnlyDeadlineDate,
    startDateLabel: resolvedStartDateLabel,
    deadlineDateLabel: resolvedDeadlineDateLabel,
    isOverdue:
        overrideIsOverdue ??
        _isOverdue(
          project.deadlineDate,
          completed: project.completed,
          today: today,
        ),
    isDueToday:
        overrideIsDueToday ??
        _isDueToday(
          project.deadlineDate,
          completed: project.completed,
          today: today,
        ),
    isDueSoon:
        overrideIsDueSoon ??
        _isDueSoon(
          project.deadlineDate,
          completed: project.completed,
          today: today,
        ),
    hasRepeat: showRepeatIcon && project.isRepeating,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: showPriorityMarkerOnRight,
    priority: project.priority,
    priorityColor: _priorityColor(project.priority),
    priorityPillLabel: project.priority == null
        ? null
        : 'Priority P${project.priority}',
  );

  return ProjectTileModel(
    id: project.id,
    title: project.name,
    completed: project.completed,
    pinned: project.isPinned,
    meta: meta,
    titlePrimaryValue: showPrimaryValueOnTitleLine ? primaryValueData : null,
    taskCount: taskCount,
    completedTaskCount: completedTaskCount,
    emptyTasksLabel: taskCount == 0 ? 'No tasks yet' : null,
    showTrailingProgressLabel: showTrailingProgressLabel,
  );
}

bool _isOverdue(
  DateTime? deadline, {
  required bool completed,
  required DateTime today,
}) {
  if (deadline == null || completed) return false;
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  return deadlineDay.isBefore(today);
}

bool _isDueToday(
  DateTime? deadline, {
  required bool completed,
  required DateTime today,
}) {
  if (deadline == null || completed) return false;
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  return deadlineDay.isAtSameMomentAs(today);
}

bool _isDueSoon(
  DateTime? deadline, {
  required bool completed,
  required DateTime today,
}) {
  if (deadline == null || completed) return false;
  final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
  final daysUntil = deadlineDay.difference(today).inDays;
  return daysUntil > 0 && daysUntil <= 3;
}

String _formatMonthDay(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  return DateFormat.MMMd(locale.toLanguageTag()).format(date);
}

Color? _priorityColor(int? p) {
  return switch (p) {
    1 => AppColors.rambutan80,
    2 => AppColors.cempedak80,
    _ => null,
  };
}
