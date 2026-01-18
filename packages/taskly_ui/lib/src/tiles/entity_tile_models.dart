import 'package:flutter/material.dart';

import 'package:taskly_ui/src/primitives/value_chip.dart';

enum EntitySecondaryValuePresentation {
  dotsCluster,
  singleOutlinedIconOnly,
}

/// UI-only meta-line input.
///
/// All formatting and domain semantics should be computed in the app layer and
/// passed in as plain fields.
class EntityMetaLineModel {
  const EntityMetaLineModel({
    this.primaryValue,
    this.secondaryValues = const <ValueChipData>[],
    this.secondaryValuePresentation =
        EntitySecondaryValuePresentation.singleOutlinedIconOnly,
    this.primaryValueIconOnly = false,
    this.maxSecondaryValues = 2,
    this.collapseSecondaryValuesToCount = false,
    this.showDates = true,
    this.showOnlyDeadlineDate = false,
    this.showBothDatesIfPresent = false,
    this.startDateLabel,
    this.deadlineDateLabel,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.showRepeatOnRight = true,
    this.priority,
    this.priorityPillLabel,
    this.priorityColor,
    this.showPriorityMarkerOnRight = false,
    this.enableRightOverflowDemotion = false,
    this.showOverflowIndicatorOnRight = false,
    this.onTapValues,
  });

  final ValueChipData? primaryValue;
  final List<ValueChipData> secondaryValues;
  final EntitySecondaryValuePresentation secondaryValuePresentation;
  final bool primaryValueIconOnly;
  final int maxSecondaryValues;
  final bool collapseSecondaryValuesToCount;

  /// When false, no date chips are rendered.
  final bool showDates;

  /// When true, only the deadline chip is shown (start date suppressed).
  final bool showOnlyDeadlineDate;

  /// If true, show both start and deadline when both are present.
  ///
  /// If false, start date is shown only when there is no deadline, or when the
  /// layout has enough horizontal space.
  final bool showBothDatesIfPresent;

  /// Pre-formatted labels (app-owned).
  final String? startDateLabel;
  final String? deadlineDateLabel;

  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;

  final bool hasRepeat;
  final bool showRepeatOnRight;

  final int? priority;

  /// Optional label for a priority pill when using an explicit pill encoding.
  final String? priorityPillLabel;

  /// App-resolved priority accent color.
  final Color? priorityColor;

  /// Shows a small marker on the right (typically only P1/P2).
  final bool showPriorityMarkerOnRight;

  /// If true, on narrow widths status tokens are demoted first.
  final bool enableRightOverflowDemotion;

  /// If true and tokens are demoted, show a subtle overflow indicator (…).
  final bool showOverflowIndicatorOnRight;

  final VoidCallback? onTapValues;
}

class TaskTileModel {
  const TaskTileModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.pinned,
    required this.meta,
    this.checkboxSemanticLabel,
  });

  final String id;
  final String title;
  final bool completed;
  final bool pinned;
  final EntityMetaLineModel meta;

  /// Optional semantics label for the completion toggle (app-owned).
  final String? checkboxSemanticLabel;
}

class ProjectTileModel {
  const ProjectTileModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.pinned,
    required this.meta,
    this.taskCount,
    this.completedTaskCount,
    this.emptyTasksLabel,
    this.showTrailingProgressLabel = false,
  });

  final String id;
  final String title;
  final bool completed;
  final bool pinned;
  final EntityMetaLineModel meta;

  final int? taskCount;
  final int? completedTaskCount;

  /// Optional empty hint when taskCount == 0 (app-owned text).
  final String? emptyTasksLabel;

  /// Mirrors legacy behavior: show a small done/total label under actions.
  final bool showTrailingProgressLabel;
}
