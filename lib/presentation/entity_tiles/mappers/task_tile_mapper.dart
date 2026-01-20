import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

TaskTileModel buildTaskListRowTileModel(
  BuildContext context, {
  required Task task,
  required EntityTileCapabilities tileCapabilities,
  bool showProjectLabel = true,
  bool showDates = true,
  bool showOnlyDeadlineDate = false,
  String? overrideStartDateLabel,
  String? overrideDeadlineDateLabel,
  bool? overrideIsOverdue,
  bool? overrideIsDueToday,
  bool? overrideIsDueSoon,
  bool showPriorityMarkerOnRight = true,
  bool showRepeatIcon = true,
  bool showOverflowEllipsisWhenMetaHidden = false,
}) {
  final isCompleted = task.occurrence?.isCompleted ?? task.completed;

  final effectiveStartDate = task.occurrence?.date ?? task.startDate;
  final effectiveDeadlineDate = task.occurrence?.deadline ?? task.deadlineDate;

  final now = context.read<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = effectiveStartDate;
  final startDateLabel = switch (start) {
    null => null,
    final startDate =>
      !DateTime(startDate.year, startDate.month, startDate.day).isBefore(today)
          ? DateLabelFormatter.format(context, startDate)
          : null,
  };

  final deadlineDateLabel = effectiveDeadlineDate == null
      ? null
      : DateLabelFormatter.format(context, effectiveDeadlineDate);

  final resolvedStartDateLabel = overrideStartDateLabel ?? startDateLabel;
  final resolvedDeadlineDateLabel =
      overrideDeadlineDateLabel ?? deadlineDateLabel;

  final hasExtraSecondaryValues = task.effectiveSecondaryValues.length > 1;

  final shouldShowOverflowEllipsis =
      showOverflowEllipsisWhenMetaHidden &&
      (task.project != null ||
          (resolvedStartDateLabel != null) ||
          (resolvedDeadlineDateLabel != null) ||
          task.isRepeating ||
          task.priority != null ||
          hasExtraSecondaryValues);

  final meta = EntityMetaLineModel(
    projectName: showProjectLabel ? task.project?.name : null,
    showValuesInMetaLine: true,
    primaryValue: task.effectivePrimaryValue?.toChipData(context),
    secondaryValues: task.effectiveSecondaryValues
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
          effectiveDeadlineDate,
          completed: isCompleted,
          today: today,
        ),
    isDueToday:
        overrideIsDueToday ??
        _isDueToday(
          effectiveDeadlineDate,
          completed: isCompleted,
          today: today,
        ),
    isDueSoon:
        overrideIsDueSoon ??
        _isDueSoon(
          effectiveDeadlineDate,
          completed: isCompleted,
          today: today,
        ),
    hasRepeat: showRepeatIcon && task.isRepeating,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: showPriorityMarkerOnRight,
    priority: task.priority,
    priorityColor: _priorityColor(task.priority),
    priorityPillLabel: task.priority == null
        ? null
        : 'Priority P${task.priority}',
  );

  void onTap() {
    final dispatcher = context.read<TileIntentDispatcher>();
    unawaited(
      dispatcher.dispatch(
        context,
        TileIntentOpenEditor(
          entityType: EntityType.task,
          entityId: task.id,
        ),
      ),
    );
  }

  return TaskTileModel(
    id: task.id,
    title: task.name,
    completed: isCompleted,
    onTap: onTap,
    meta: meta,
    checkboxSemanticLabel: isCompleted
        ? 'Mark "${task.name}" as incomplete'
        : 'Mark "${task.name}" as complete',
  );
}

ValueChanged<bool?>? buildTaskToggleCompletionHandler(
  BuildContext context, {
  required Task task,
  required EntityTileCapabilities tileCapabilities,
}) {
  if (!tileCapabilities.canToggleCompletion) return null;

  return (value) {
    final dispatcher = context.read<TileIntentDispatcher>();
    final completed = value ?? false;

    final occurrenceDate = task.occurrence?.date;
    final originalOccurrenceDate =
        task.occurrence?.originalDate ?? occurrenceDate;

    unawaited(
      dispatcher.dispatch(
        context,
        TileIntentSetCompletion(
          entityType: EntityType.task,
          entityId: task.id,
          completed: completed,
          scope: tileCapabilities.completionScope,
          occurrenceDate: occurrenceDate,
          originalOccurrenceDate: originalOccurrenceDate,
        ),
      ),
    );
  };
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

Color? _priorityColor(int? p) {
  return switch (p) {
    1 => AppColors.rambutan80,
    2 => AppColors.cempedak80,
    _ => null,
  };
}
