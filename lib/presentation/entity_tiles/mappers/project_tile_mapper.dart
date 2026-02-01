import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/utils/rich_text_utils.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

TasklyProjectRowData buildProjectRowData(
  BuildContext context, {
  required Project project,
  int? taskCount,
  int? completedTaskCount,
  int? dueSoonCount,
  bool showOnlyDeadlineDate = false,
  String? overrideStartDateLabel,
  String? overrideDeadlineDateLabel,
  bool? overrideIsOverdue,
  bool? overrideIsDueToday,
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

  final primaryValueData = project.primaryValue?.toChipData(context);

  final subtitle = richTextPreview(project.description);

  final effectiveTaskCount = taskCount ?? project.taskCount;
  final effectiveCompletedTaskCount =
      completedTaskCount ?? project.completedTaskCount;

  final meta = TasklyEntityMetaData(
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
    priority: project.priority,
  );

  return TasklyProjectRowData(
    id: project.id,
    title: project.name,
    completed: project.completed,
    pinned: false,
    meta: meta,
    leadingChip: primaryValueData,
    subtitle: subtitle,
    taskCount: effectiveTaskCount,
    completedTaskCount: effectiveCompletedTaskCount,
    dueSoonCount: dueSoonCount,
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

String _formatMonthDay(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context);
  return DateFormat.MMMd(locale.toLanguageTag()).format(date);
}
