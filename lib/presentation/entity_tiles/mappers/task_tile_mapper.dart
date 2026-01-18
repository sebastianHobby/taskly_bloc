import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/formatters/date_label_formatter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui.dart';

TaskTileModel buildTaskListRowTileModel(
  BuildContext context, {
  required Task task,
}) {
  final isCompleted = task.occurrence?.isCompleted ?? task.completed;

  final effectiveStartDate = task.occurrence?.date ?? task.startDate;
  final effectiveDeadlineDate = task.occurrence?.deadline ?? task.deadlineDate;

  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = effectiveStartDate;
  final startDay = start == null
      ? null
      : DateTime(start.year, start.month, start.day);
  final startDateLabel = (startDay != null && startDay.isAfter(today))
      ? DateLabelFormatter.format(context, start)
      : null;

  final deadlineDateLabel = effectiveDeadlineDate == null
      ? null
      : DateLabelFormatter.format(context, effectiveDeadlineDate);

  final meta = EntityMetaLineModel(
    primaryValue: task.effectivePrimaryValue?.toChipData(context),
    secondaryValues: task.effectiveSecondaryValues.isEmpty
        ? const <ValueChipData>[]
        : <ValueChipData>[
            task.effectiveSecondaryValues.first.toChipData(context),
          ],
    secondaryValuePresentation:
        EntitySecondaryValuePresentation.singleOutlinedIconOnly,
    startDateLabel: startDateLabel,
    deadlineDateLabel: deadlineDateLabel,
    isOverdue: _isOverdue(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    isDueToday: _isDueToday(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    isDueSoon: _isDueSoon(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    hasRepeat: task.repeatIcalRrule != null,
    showRepeatOnRight: true,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: true,
    priority: task.priority,
    priorityColor: _priorityColor(task.priority),
    priorityPillLabel: task.priority == null
        ? null
        : 'Priority P${task.priority}',
    enableRightOverflowDemotion: true,
    showOverflowIndicatorOnRight: true,
  );

  return TaskTileModel(
    id: task.id,
    title: task.name,
    completed: isCompleted,
    pinned: task.isPinned,
    meta: meta,
    checkboxSemanticLabel: isCompleted
        ? 'Mark "${task.name}" as incomplete'
        : 'Mark "${task.name}" as complete',
  );
}

TaskAgendaCardModel buildTaskAgendaCardModel(
  BuildContext context, {
  required Task task,
  required bool inProgressStyle,
  required DateTime? endDate,
  Color? accentColor,
  bool backgroundBlendPrimary = false,
  bool showDeadlineChipOnOngoing = true,
}) {
  final isCompleted = task.occurrence?.isCompleted ?? task.completed;

  final effectiveStartDate = task.occurrence?.date ?? task.startDate;
  final effectiveDeadlineDate = task.occurrence?.deadline ?? task.deadlineDate;

  final now = getIt<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = effectiveStartDate;
  final startDay = start == null
      ? null
      : DateTime(start.year, start.month, start.day);
  final startDateLabel =
      (startDay != null && startDay.isAfter(today) && !inProgressStyle)
      ? DateLabelFormatter.format(context, start)
      : null;

  final deadlineDateLabel = effectiveDeadlineDate == null
      ? null
      : DateLabelFormatter.format(context, effectiveDeadlineDate);

  final meta = EntityMetaLineModel(
    primaryValue: task.effectivePrimaryValue?.toChipData(context),
    secondaryValues: task.effectiveSecondaryValues.isEmpty
        ? const <ValueChipData>[]
        : <ValueChipData>[
            task.effectiveSecondaryValues.first.toChipData(context),
          ],
    secondaryValuePresentation:
        EntitySecondaryValuePresentation.singleOutlinedIconOnly,
    startDateLabel: startDateLabel,
    deadlineDateLabel: deadlineDateLabel,
    showDates: !inProgressStyle || showDeadlineChipOnOngoing,
    isOverdue: _isOverdue(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    isDueToday: _isDueToday(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    isDueSoon: _isDueSoon(
      effectiveDeadlineDate,
      completed: isCompleted,
    ),
    hasRepeat: task.repeatIcalRrule != null,
    showRepeatOnRight: true,
    showBothDatesIfPresent: true,
    showPriorityMarkerOnRight: true,
    priority: task.priority,
    priorityColor: _priorityColor(task.priority),
    priorityPillLabel: task.priority == null
        ? null
        : 'Priority P${task.priority}',
    enableRightOverflowDemotion: true,
    showOverflowIndicatorOnRight: true,
  );

  final base = TaskTileModel(
    id: task.id,
    title: task.name,
    completed: isCompleted,
    pinned: task.isPinned,
    meta: meta,
    checkboxSemanticLabel: isCompleted
        ? 'Mark "${task.name}" as incomplete'
        : 'Mark "${task.name}" as complete',
  );

  final endDayLabel = endDate == null
      ? null
      : MaterialLocalizations.of(context).formatShortWeekday(endDate);

  return TaskAgendaCardModel(
    base: base,
    accentColor: accentColor,
    inProgressStyle: inProgressStyle,
    endDayLabel: endDayLabel,
    backgroundBlendPrimary: backgroundBlendPrimary,
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
    );
  };
}

VoidCallback? buildTaskOpenValuesHandler(
  BuildContext context, {
  required Task task,
  required EntityTileCapabilities tileCapabilities,
}) {
  if (!tileCapabilities.canAlignValues) return null;

  return () {
    final dispatcher = context.read<TileIntentDispatcher>();
    dispatcher.dispatch(
      context,
      TileIntentOpenEditor(
        entityType: EntityType.task,
        entityId: task.id,
        openToValues: true,
      ),
    );
  };
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
