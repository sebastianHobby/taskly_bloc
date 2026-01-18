import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui.dart';

ProjectTileModel buildProjectListRowTileModel(
  BuildContext context, {
  required Project project,
  required EntityTileCapabilities tileCapabilities,
  int? taskCount,
  int? completedTaskCount,
  bool showTrailingProgressLabel = false,
}) {
  final now = context.read<NowService>().nowLocal();
  final today = DateTime(now.year, now.month, now.day);

  final start = project.startDate;
  final startDateLabel = switch (start) {
    null => null,
    final startDate =>
      DateTime(startDate.year, startDate.month, startDate.day).isAfter(today)
          ? _formatMonthDay(context, startDate)
          : null,
  };

  final deadlineDateLabel = project.deadlineDate == null
      ? null
      : _formatMonthDay(context, project.deadlineDate!);

  final meta = EntityMetaLineModel(
    primaryValue: project.primaryValue?.toChipData(context),
    secondaryValues: project.secondaryValues
        .take(1)
        .map((v) => v.toChipData(context))
        .toList(growable: false),
    secondaryValuePresentation: EntitySecondaryValuePresentation.dotsCluster,
    maxSecondaryValues: 1,
    startDateLabel: startDateLabel,
    deadlineDateLabel: deadlineDateLabel,
    isOverdue: _isOverdue(
      project.deadlineDate,
      completed: project.completed,
      today: today,
    ),
    isDueToday: _isDueToday(
      project.deadlineDate,
      completed: project.completed,
      today: today,
    ),
    isDueSoon: _isDueSoon(
      project.deadlineDate,
      completed: project.completed,
      today: today,
    ),
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
    onTapValues: buildProjectOpenValuesHandler(
      context,
      project: project,
      tileCapabilities: tileCapabilities,
    ),
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

VoidCallback? buildProjectOpenValuesHandler(
  BuildContext context, {
  required Project project,
  required EntityTileCapabilities tileCapabilities,
}) {
  if (!tileCapabilities.canAlignValues) return null;

  return () {
    final dispatcher = context.read<TileIntentDispatcher>();
    unawaited(
      dispatcher.dispatch(
        context,
        TileIntentOpenEditor(
          entityType: EntityType.project,
          entityId: project.id,
          openToValues: true,
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
