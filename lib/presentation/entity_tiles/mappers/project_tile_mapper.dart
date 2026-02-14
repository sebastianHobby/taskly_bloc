import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
  String? overrideDeadlineDateLabel,
  bool? overrideIsOverdue,
  bool? overrideIsDueToday,
  ValueChipData? valueChipOverride,
  bool includeValueIcon = true,
  Color? accentColor,
}) {
  final scheme = Theme.of(context).colorScheme;
  final now = context.read<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final deadlineDateLabel = project.deadlineDate == null
      ? null
      : _formatMonthDay(context, project.deadlineDate!);

  final resolvedDeadlineDateLabel =
      overrideDeadlineDateLabel ?? deadlineDateLabel;

  final primaryValueData =
      valueChipOverride ?? project.primaryValue?.toChipData(context);
  final leadingChip = includeValueIcon ? primaryValueData : null;

  final subtitle = richTextPreview(project.description);

  final effectiveTaskCount = taskCount ?? project.taskCount;
  final effectiveCompletedTaskCount =
      completedTaskCount ?? project.completedTaskCount;

  final statusBadge = project.completed
      ? TasklyBadgeData(
          label: context.l10n.projectStatusCompleted,
          color: scheme.secondary,
          icon: Icons.check_rounded,
          tone: TasklyBadgeTone.soft,
        )
      : null;

  final meta = TasklyEntityMetaData(
    showOnlyDeadlineDate: showOnlyDeadlineDate,
    startDateLabel: null,
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
    leadingChip: leadingChip,
    accentColor: accentColor,
    subtitle: subtitle,
    taskCount: effectiveTaskCount,
    completedTaskCount: effectiveCompletedTaskCount,
    dueSoonCount: dueSoonCount,
    statusBadge: statusBadge,
    deemphasized: project.completed,
  );
}

TasklyProjectRowData buildInboxProjectRowData(
  BuildContext context, {
  required int taskCount,
}) {
  final safeCount = taskCount < 0 ? 0 : taskCount;
  return TasklyProjectRowData(
    id: ProjectGroupingRef.inbox().stableKey,
    title: context.l10n.inboxLabel,
    completed: false,
    pinned: false,
    meta: const TasklyEntityMetaData(),
    taskCount: safeCount,
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
