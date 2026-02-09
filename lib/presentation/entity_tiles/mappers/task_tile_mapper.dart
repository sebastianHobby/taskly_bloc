import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/feature_flags.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

TasklyTaskRowData buildTaskRowData(
  BuildContext context, {
  required Task task,
  required EntityTileCapabilities tileCapabilities,
  String? overrideStartDateLabel,
  String? overrideDeadlineDateLabel,
  bool? overrideIsOverdue,
  bool? overrideIsDueToday,
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

  // Only show a due label when there is a concrete deadline date.
  // This intentionally suppresses non-date concepts like “Daily/Flexible/No Date”.
  final effectiveResolvedDeadlineDateLabel = effectiveDeadlineDate == null
      ? null
      : resolvedDeadlineDateLabel;

  final primaryValueData = task.effectivePrimaryValue?.toChipData(context);
  final secondaryValueData = TasklyFeatureFlags.taskSecondaryValuesEnabled
      ? task.effectiveSecondaryValues
            .map((value) => value.toChipData(context))
            .toList(growable: false)
      : const <ValueChipData>[];

  final meta = TasklyEntityMetaData(
    startDateLabel: resolvedStartDateLabel,
    deadlineDateLabel: effectiveResolvedDeadlineDateLabel,
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
    priority: task.priority,
  );

  return TasklyTaskRowData(
    id: task.id,
    title: task.name,
    completed: isCompleted,
    meta: meta,
    leadingChip: primaryValueData,
    secondaryChips: secondaryValueData,
    checkboxSemanticLabel: isCompleted
        ? context.l10n.markIncompleteSemanticLabel(task.name)
        : context.l10n.markCompleteSemanticLabel(task.name),
    pinned: false,
  );
}

VoidCallback buildTaskOpenEditorHandler(
  BuildContext context, {
  required Task task,
}) {
  return () {
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
  };
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
