import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';

sealed class TasklyFeedSpec {
  const TasklyFeedSpec();

  const factory TasklyFeedSpec.loading({String? message}) = TasklyFeedLoading;

  const factory TasklyFeedSpec.error({
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
  }) = TasklyFeedError;

  const factory TasklyFeedSpec.empty({
    required TasklyEmptyStateSpec empty,
  }) = TasklyFeedEmpty;

  const factory TasklyFeedSpec.content({
    required List<TasklySectionSpec> sections,
  }) = TasklyFeedContent;
}

final class TasklyFeedLoading extends TasklyFeedSpec {
  const TasklyFeedLoading({this.message});

  final String? message;
}

final class TasklyFeedError extends TasklyFeedSpec {
  const TasklyFeedError({
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
}

final class TasklyFeedEmpty extends TasklyFeedSpec {
  const TasklyFeedEmpty({required this.empty});

  final TasklyEmptyStateSpec empty;
}

final class TasklyFeedContent extends TasklyFeedSpec {
  const TasklyFeedContent({required this.sections});

  final List<TasklySectionSpec> sections;
}

@immutable
final class TasklyEmptyStateSpec {
  const TasklyEmptyStateSpec({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
}

sealed class TasklySectionSpec {
  const TasklySectionSpec();

  const factory TasklySectionSpec.standardList({
    required String id,
    required List<TasklyRowSpec> rows,
  }) = TasklyStandardListSectionSpec;

  const factory TasklySectionSpec.scheduledOverdue({
    required String id,
    required String title,
    required String countLabel,
    required bool isCollapsed,
    required VoidCallback? onToggleCollapsed,
    required List<TasklyRowSpec> rows,
    String? actionLabel,
    String? actionTooltip,
    VoidCallback? onActionPressed,
  }) = TasklyScheduledOverdueSectionSpec;

  const factory TasklySectionSpec.scheduledDay({
    required String id,
    required DateTime day,
    required String title,
    required bool isToday,
    required List<TasklyRowSpec> rows,
    String? countLabel,
    String? emptyLabel,
    VoidCallback? onAddRequested,
  }) = TasklyScheduledDaySectionSpec;
}

final class TasklyStandardListSectionSpec extends TasklySectionSpec {
  const TasklyStandardListSectionSpec({
    required this.id,
    required this.rows,
  });

  final String id;
  final List<TasklyRowSpec> rows;
}

final class TasklyScheduledOverdueSectionSpec extends TasklySectionSpec {
  const TasklyScheduledOverdueSectionSpec({
    required this.id,
    required this.title,
    required this.countLabel,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    required this.rows,
    this.actionLabel,
    this.actionTooltip,
    this.onActionPressed,
  });

  final String id;
  final String title;
  final String countLabel;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;
  final List<TasklyRowSpec> rows;
  final String? actionLabel;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;
}

final class TasklyScheduledDaySectionSpec extends TasklySectionSpec {
  const TasklyScheduledDaySectionSpec({
    required this.id,
    required this.day,
    required this.title,
    required this.isToday,
    required this.rows,
    this.countLabel,
    this.emptyLabel,
    this.onAddRequested,
  });

  final String id;
  final DateTime day;
  final String title;
  final bool isToday;
  final List<TasklyRowSpec> rows;
  final String? countLabel;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;
}

sealed class TasklyRowSpec {
  const TasklyRowSpec();

  const factory TasklyRowSpec.header({
    required String key,
    required String title,
    IconData? leadingIcon,
    String? trailingLabel,
    IconData? trailingIcon,
    VoidCallback? onTap,
    int depth,
  }) = TasklyHeaderRowSpec;

  const factory TasklyRowSpec.divider({
    required String key,
    int depth,
  }) = TasklyDividerRowSpec;

  const factory TasklyRowSpec.inlineAction({
    required String key,
    required String label,
    required VoidCallback onTap,
    int depth,
  }) = TasklyInlineActionRowSpec;

  const factory TasklyRowSpec.task({
    required String key,
    required TasklyTaskRowData data,
    required TasklyTaskRowActions actions,
    TasklyTaskRowIntent intent,
    TasklyTaskRowMarkers markers,
    TasklyRowEmphasis emphasis,
    int depth,
  }) = TasklyTaskRowSpec;

  const factory TasklyRowSpec.project({
    required String key,
    required TasklyProjectRowData data,
    required TasklyProjectRowActions actions,
    TasklyProjectRowIntent intent,
    TasklyRowEmphasis emphasis,
    int depth,
  }) = TasklyProjectRowSpec;

  const factory TasklyRowSpec.value({
    required String key,
    required TasklyValueRowData data,
    required TasklyValueRowActions actions,
    TasklyValueRowIntent intent,
  }) = TasklyValueRowSpec;
}

final class TasklyHeaderRowSpec extends TasklyRowSpec {
  const TasklyHeaderRowSpec({
    required this.key,
    required this.title,
    this.leadingIcon,
    this.trailingLabel,
    this.trailingIcon,
    this.onTap,
    this.depth = 0,
  });

  final String key;
  final String title;
  final IconData? leadingIcon;
  final String? trailingLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final int depth;
}

final class TasklyDividerRowSpec extends TasklyRowSpec {
  const TasklyDividerRowSpec({required this.key, this.depth = 0});

  final String key;
  final int depth;
}

final class TasklyInlineActionRowSpec extends TasklyRowSpec {
  const TasklyInlineActionRowSpec({
    required this.key,
    required this.label,
    required this.onTap,
    this.depth = 0,
  });

  final String key;
  final String label;
  final VoidCallback onTap;
  final int depth;
}

final class TasklyTaskRowSpec extends TasklyRowSpec {
  const TasklyTaskRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.intent = const TasklyTaskRowIntent.standard(),
    this.markers = const TasklyTaskRowMarkers(),
    this.emphasis = TasklyRowEmphasis.none,
    this.depth = 0,
  });

  final String key;
  final TasklyTaskRowData data;
  final TasklyTaskRowActions actions;
  final TasklyTaskRowIntent intent;
  final TasklyTaskRowMarkers markers;
  final TasklyRowEmphasis emphasis;
  final int depth;
}

final class TasklyProjectRowSpec extends TasklyRowSpec {
  const TasklyProjectRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.intent = const TasklyProjectRowIntent.standard(),
    this.emphasis = TasklyRowEmphasis.none,
    this.depth = 0,
  });

  final String key;
  final TasklyProjectRowData data;
  final TasklyProjectRowActions actions;
  final TasklyProjectRowIntent intent;
  final TasklyRowEmphasis emphasis;
  final int depth;
}

final class TasklyValueRowSpec extends TasklyRowSpec {
  const TasklyValueRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.intent = const TasklyValueRowIntent.standard(),
  });

  final String key;
  final TasklyValueRowData data;
  final TasklyValueRowActions actions;
  final TasklyValueRowIntent intent;
}

enum TasklyRowEmphasis { none, overdue }

sealed class TasklyTaskRowIntent {
  const TasklyTaskRowIntent();

  const factory TasklyTaskRowIntent.standard() = TasklyTaskRowIntentStandard;

  const factory TasklyTaskRowIntent.bulkSelection({required bool selected}) =
      TasklyTaskRowIntentBulkSelection;

  const factory TasklyTaskRowIntent.selectionPicker({required bool selected}) =
      TasklyTaskRowIntentSelectionPicker;
}

final class TasklyTaskRowIntentStandard extends TasklyTaskRowIntent {
  const TasklyTaskRowIntentStandard();
}

final class TasklyTaskRowIntentBulkSelection extends TasklyTaskRowIntent {
  const TasklyTaskRowIntentBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyTaskRowIntentSelectionPicker extends TasklyTaskRowIntent {
  const TasklyTaskRowIntentSelectionPicker({required this.selected});

  final bool selected;
}

@immutable
final class TasklyTaskRowMarkers {
  const TasklyTaskRowMarkers({this.pinned = false});

  final bool pinned;
}

@immutable
final class TasklyTaskRowActions {
  const TasklyTaskRowActions({
    this.onTap,
    this.onToggleCompletion,
    this.onOverflowMenuRequestedAt,
    this.onToggleSelected,
    this.onSnoozeRequested,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onSnoozeRequested;
  final VoidCallback? onLongPress;
}

sealed class TasklyProjectRowIntent {
  const TasklyProjectRowIntent();

  const factory TasklyProjectRowIntent.standard() =
      TasklyProjectRowIntentStandard;

  const factory TasklyProjectRowIntent.bulkSelection({required bool selected}) =
      TasklyProjectRowIntentBulkSelection;

  const factory TasklyProjectRowIntent.groupHeader({
    required bool expanded,
  }) = TasklyProjectRowIntentGroupHeader;
}

final class TasklyProjectRowIntentStandard extends TasklyProjectRowIntent {
  const TasklyProjectRowIntentStandard();
}

final class TasklyProjectRowIntentBulkSelection extends TasklyProjectRowIntent {
  const TasklyProjectRowIntentBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyProjectRowIntentGroupHeader extends TasklyProjectRowIntent {
  const TasklyProjectRowIntentGroupHeader({required this.expanded});

  final bool expanded;
}

@immutable
final class TasklyProjectRowActions {
  const TasklyProjectRowActions({
    this.onTap,
    this.onOverflowMenuRequestedAt,
    this.onToggleSelected,
    this.onLongPress,
    this.onToggleExpanded,
  });

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleExpanded;
}

sealed class TasklyValueRowIntent {
  const TasklyValueRowIntent();

  const factory TasklyValueRowIntent.standard() = TasklyValueRowIntentStandard;

  const factory TasklyValueRowIntent.bulkSelection({required bool selected}) =
      TasklyValueRowIntentBulkSelection;
}

final class TasklyValueRowIntentStandard extends TasklyValueRowIntent {
  const TasklyValueRowIntentStandard();
}

final class TasklyValueRowIntentBulkSelection extends TasklyValueRowIntent {
  const TasklyValueRowIntentBulkSelection({required this.selected});

  final bool selected;
}

@immutable
final class TasklyValueRowActions {
  const TasklyValueRowActions({
    this.onTap,
    this.onOverflowMenuRequestedAt,
    this.onToggleSelected,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onOverflowMenuRequestedAt;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
}

@immutable
final class TasklyEntityMetaData {
  const TasklyEntityMetaData({
    this.projectName,
    this.primaryValue,
    this.secondaryValues = const <ValueChipData>[],
    this.startDateLabel,
    this.deadlineDateLabel,
    this.showDates = true,
    this.showOnlyDeadlineDate = false,
    this.showBothDatesIfPresent = false,
    this.showDeadlineChipOnTitleLine = false,
    this.showOverflowEllipsis = false,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.priority,
    this.priorityPillLabel,
    this.priorityColor,
    this.showPriorityMarkerOnRight = false,
  });

  final String? projectName;
  final ValueChipData? primaryValue;
  final List<ValueChipData> secondaryValues;

  final String? startDateLabel;
  final String? deadlineDateLabel;

  final bool showDates;
  final bool showOnlyDeadlineDate;
  final bool showBothDatesIfPresent;
  final bool showDeadlineChipOnTitleLine;
  final bool showOverflowEllipsis;

  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;

  final int? priority;
  final String? priorityPillLabel;
  final Color? priorityColor;
  final bool showPriorityMarkerOnRight;
}

@immutable
final class TasklyTaskRowData {
  const TasklyTaskRowData({
    required this.id,
    required this.title,
    required this.completed,
    required this.meta,
    this.titlePrimaryValue,
    this.leadingChip,
    this.supportingText,
    this.supportingTooltipText,
    this.deemphasized = false,
    this.checkboxSemanticLabel,
    this.labels,
  });

  final String id;
  final String title;
  final bool completed;
  final TasklyEntityMetaData meta;
  final ValueChipData? titlePrimaryValue;
  final ValueChipData? leadingChip;
  final String? supportingText;
  final String? supportingTooltipText;
  final bool deemphasized;
  final String? checkboxSemanticLabel;
  final TasklyTaskRowLabels? labels;
}

@immutable
final class TasklyTaskRowLabels {
  const TasklyTaskRowLabels({
    this.completedStatusLabel,
    this.pinnedSemanticLabel,
    this.supportingTooltipSemanticLabel,
    this.snoozeTooltip,
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
    this.bulkSelectTooltip,
    this.bulkDeselectTooltip,
  });

  final String? completedStatusLabel;
  final String? pinnedSemanticLabel;
  final String? supportingTooltipSemanticLabel;
  final String? snoozeTooltip;
  final String? selectionPillLabel;
  final String? selectionPillSelectedLabel;
  final String? bulkSelectTooltip;
  final String? bulkDeselectTooltip;
}

@immutable
final class TasklyProjectRowData {
  const TasklyProjectRowData({
    required this.id,
    required this.title,
    required this.completed,
    required this.pinned,
    required this.meta,
    this.titlePrimaryValue,
    this.taskCount,
    this.completedTaskCount,
    this.leadingChip,
    this.subtitle,
    this.deemphasized = false,
    this.groupLeadingIcon,
    this.groupTrailingLabel,
  });

  final String id;
  final String title;
  final bool completed;
  final bool pinned;
  final TasklyEntityMetaData meta;
  final ValueChipData? titlePrimaryValue;
  final int? taskCount;
  final int? completedTaskCount;
  final ValueChipData? leadingChip;
  final String? subtitle;
  final bool deemphasized;
  final IconData? groupLeadingIcon;
  final String? groupTrailingLabel;
}

@immutable
final class TasklyValueRowData {
  const TasklyValueRowData({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.firstLineLabel,
    this.firstLineValue,
    this.secondLineLabel,
    this.secondLineValue,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? firstLineLabel;
  final String? firstLineValue;
  final String? secondLineLabel;
  final String? secondLineValue;
}
