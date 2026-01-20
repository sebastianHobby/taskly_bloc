import 'package:flutter/material.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';

/// UI-only meta-line input.
///
/// All formatting and domain semantics should be computed in the app layer and
/// passed in as plain fields.
class EntityMetaLineModel {
  const EntityMetaLineModel({
    this.projectName,
    this.showValuesInMetaLine = false,
    this.primaryValue,
    this.secondaryValues = const <ValueChipData>[],
    this.showOverflowEllipsis = false,
    this.showDates = true,
    this.showOnlyDeadlineDate = false,
    this.showBothDatesIfPresent = false,
    this.startDateLabel,
    this.deadlineDateLabel,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.priority,
    this.priorityPillLabel,
    this.priorityColor,
    this.showPriorityMarkerOnRight = false,
  });

  final ValueChipData? primaryValue;
  final List<ValueChipData> secondaryValues;

  /// Optional project name to render inline on the meta line.
  final String? projectName;

  /// When true, value icons render at the start of the meta line.
  final bool showValuesInMetaLine;

  /// When true, shows a non-numeric overflow indicator ("…") to signal that
  /// additional metadata exists but is intentionally hidden by the caller.
  final bool showOverflowEllipsis;

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

  final int? priority;

  /// Optional label for a priority pill when using an explicit pill encoding.
  final String? priorityPillLabel;

  /// App-resolved priority accent color.
  final Color? priorityColor;

  /// Shows a small marker on the right (typically only P1/P2).
  final bool showPriorityMarkerOnRight;
}

class TaskTileModel {
  const TaskTileModel({
    required this.id,
    required this.title,
    required this.completed,
    required this.onTap,
    required this.meta,
    this.checkboxSemanticLabel,
  });

  final String id;
  final String title;
  final bool completed;
  final VoidCallback onTap;
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

/// Curated visual variants for value tiles.
enum ValueTileVariant {
  /// A standard list-row variant for the Values list.
  standard,

  /// Screenshot-style card variant used on the system “My Values” screen.
  myValuesCardV1,
}

/// UI-only value tile input.
///
/// All formatting and user-facing strings must be computed in the app layer
/// and passed in as plain fields.
class ValueTileModel {
  const ValueTileModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.loadingLabel,
    this.firstLineLabel,
    this.firstLineValue,
    this.secondLineLabel,
    this.secondLineValue,
  });

  final String id;
  final String title;

  final IconData icon;
  final Color accentColor;

  /// Rendered when stats lines are not available (app-owned).
  final String? loadingLabel;

  /// Optional stat lines (app-owned strings).
  final String? firstLineLabel;
  final String? firstLineValue;
  final String? secondLineLabel;
  final String? secondLineValue;
}
