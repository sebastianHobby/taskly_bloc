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

  const factory TasklySectionSpec.valueDistribution({
    required String id,
    required String title,
    required String totalLabel,
    required List<TasklyValueDistributionEntry> entries,
  }) = TasklyValueDistributionSectionSpec;

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

final class TasklyValueDistributionSectionSpec extends TasklySectionSpec {
  const TasklyValueDistributionSectionSpec({
    required this.id,
    required this.title,
    required this.totalLabel,
    required this.entries,
  });

  final String id;
  final String title;
  final String totalLabel;
  final List<TasklyValueDistributionEntry> entries;
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

  const factory TasklyRowSpec.subheader({
    required String key,
    required String title,
    int depth,
  }) = TasklySubheaderRowSpec;

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

  const factory TasklyRowSpec.valueHeader({
    required String key,
    required String title,
    required ValueChipData? leadingChip,
    required String? trailingLabel,
    required bool isCollapsed,
    required VoidCallback onToggleCollapsed,
    String? priorityLabel,
    int depth,
  }) = TasklyValueHeaderRowSpec;

  const factory TasklyRowSpec.task({
    required String key,
    required TasklyTaskRowData data,
    required TasklyTaskRowActions actions,
    TasklyTaskRowStyle style,
    TasklyRowEmphasis emphasis,
    int depth,
  }) = TasklyTaskRowSpec;

  const factory TasklyRowSpec.project({
    required String key,
    required TasklyProjectRowData data,
    required TasklyProjectRowActions actions,
    TasklyProjectRowPreset preset,
    TasklyRowEmphasis emphasis,
    int depth,
  }) = TasklyProjectRowSpec;

  const factory TasklyRowSpec.value({
    required String key,
    required TasklyValueRowData data,
    required TasklyValueRowActions actions,
    TasklyValueRowPreset preset,
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

final class TasklySubheaderRowSpec extends TasklyRowSpec {
  const TasklySubheaderRowSpec({
    required this.key,
    required this.title,
    this.depth = 0,
  });

  final String key;
  final String title;
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

final class TasklyValueHeaderRowSpec extends TasklyRowSpec {
  const TasklyValueHeaderRowSpec({
    required this.key,
    required this.title,
    required this.leadingChip,
    required this.trailingLabel,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    this.priorityLabel,
    this.depth = 0,
  });

  final String key;
  final String title;
  final ValueChipData? leadingChip;
  final String? trailingLabel;
  final String? priorityLabel;
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;
  final int depth;
}

final class TasklyTaskRowSpec extends TasklyRowSpec {
  const TasklyTaskRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.style = const TasklyTaskRowStyle.standard(),
    this.emphasis = TasklyRowEmphasis.none,
    this.depth = 0,
  });

  final String key;
  final TasklyTaskRowData data;
  final TasklyTaskRowActions actions;
  final TasklyTaskRowStyle style;
  final TasklyRowEmphasis emphasis;
  final int depth;
}

final class TasklyProjectRowSpec extends TasklyRowSpec {
  const TasklyProjectRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.preset = const TasklyProjectRowPreset.standard(),
    this.emphasis = TasklyRowEmphasis.none,
    this.depth = 0,
  });

  final String key;
  final TasklyProjectRowData data;
  final TasklyProjectRowActions actions;
  final TasklyProjectRowPreset preset;
  final TasklyRowEmphasis emphasis;
  final int depth;
}

final class TasklyValueRowSpec extends TasklyRowSpec {
  const TasklyValueRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.preset = const TasklyValueRowPreset.standard(),
  });

  final String key;
  final TasklyValueRowData data;
  final TasklyValueRowActions actions;
  final TasklyValueRowPreset preset;
}

enum TasklyRowEmphasis { none, overdue }

sealed class TasklyTaskRowStyle {
  const TasklyTaskRowStyle();

  const factory TasklyTaskRowStyle.standard() = TasklyTaskRowStyleStandard;

  const factory TasklyTaskRowStyle.bulkSelection({
    required bool selected,
  }) = TasklyTaskRowStyleBulkSelection;

  const factory TasklyTaskRowStyle.picker({
    required bool selected,
  }) = TasklyTaskRowStylePicker;

  const factory TasklyTaskRowStyle.pickerAction({
    required bool selected,
  }) = TasklyTaskRowStylePickerAction;

  const factory TasklyTaskRowStyle.planPick({
    required bool selected,
  }) = TasklyTaskRowStylePlanPick;

  const factory TasklyTaskRowStyle.pinnedToggle() =
      TasklyTaskRowStylePinnedToggle;
}

final class TasklyTaskRowStyleStandard extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleStandard();
}

final class TasklyTaskRowStyleBulkSelection extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePicker extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePicker({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePickerAction extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePickerAction({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePlanPick extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePlanPick({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePinnedToggle extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePinnedToggle();
}

@immutable
final class TasklyTaskRowActions {
  const TasklyTaskRowActions({
    this.onTap,
    this.onToggleCompletion,
    this.onToggleSelected,
    this.onTogglePinned,
    this.onSnoozeRequested,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final VoidCallback? onToggleSelected;
  final ValueChanged<bool>? onTogglePinned;
  final VoidCallback? onSnoozeRequested;
  final VoidCallback? onLongPress;
}

sealed class TasklyProjectRowPreset {
  const TasklyProjectRowPreset();

  const factory TasklyProjectRowPreset.standard() =
      TasklyProjectRowPresetStandard;

  const factory TasklyProjectRowPreset.inbox() = TasklyProjectRowPresetInbox;

  const factory TasklyProjectRowPreset.bulkSelection({
    required bool selected,
  }) = TasklyProjectRowPresetBulkSelection;

  const factory TasklyProjectRowPreset.groupHeader({
    required bool expanded,
  }) = TasklyProjectRowPresetGroupHeader;
}

final class TasklyProjectRowPresetStandard extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetStandard();
}

final class TasklyProjectRowPresetInbox extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetInbox();
}

final class TasklyProjectRowPresetBulkSelection extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyProjectRowPresetGroupHeader extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetGroupHeader({required this.expanded});

  final bool expanded;
}

@immutable
final class TasklyProjectRowActions {
  const TasklyProjectRowActions({
    this.onTap,
    this.onToggleSelected,
    this.onLongPress,
    this.onToggleExpanded,
  });

  final VoidCallback? onTap;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleExpanded;
}

sealed class TasklyValueRowPreset {
  const TasklyValueRowPreset();

  const factory TasklyValueRowPreset.standard() = TasklyValueRowPresetStandard;

  const factory TasklyValueRowPreset.bulkSelection({
    required bool selected,
  }) = TasklyValueRowPresetBulkSelection;
}

final class TasklyValueRowPresetStandard extends TasklyValueRowPreset {
  const TasklyValueRowPresetStandard();
}

final class TasklyValueRowPresetBulkSelection extends TasklyValueRowPreset {
  const TasklyValueRowPresetBulkSelection({required this.selected});

  final bool selected;
}

@immutable
final class TasklyValueRowActions {
  const TasklyValueRowActions({
    this.onTap,
    this.onToggleSelected,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
}

@immutable
final class TasklyEntityMetaData {
  const TasklyEntityMetaData({
    this.primaryValue,
    this.startDateLabel,
    this.deadlineDateLabel,
    this.showOnlyDeadlineDate = false,
    this.isOverdue = false,
    this.isDueToday = false,
    this.priority,
  });

  final ValueChipData? primaryValue;

  final String? startDateLabel;
  final String? deadlineDateLabel;

  final bool showOnlyDeadlineDate;

  final bool isOverdue;
  final bool isDueToday;

  final int? priority;
}

@immutable
final class TasklyTaskRowData {
  const TasklyTaskRowData({
    required this.id,
    required this.title,
    required this.completed,
    required this.meta,
    this.leadingChip,
    this.secondaryChips = const <ValueChipData>[],
    this.deemphasized = false,
    this.checkboxSemanticLabel,
    this.labels,
    this.pinned = false,
    this.primaryValueIconOnly = false,
  });

  final String id;
  final String title;
  final bool completed;
  final TasklyEntityMetaData meta;
  final ValueChipData? leadingChip;
  final List<ValueChipData> secondaryChips;
  final bool deemphasized;
  final String? checkboxSemanticLabel;
  final TasklyTaskRowLabels? labels;
  final bool pinned;
  final bool primaryValueIconOnly;
}

@immutable
final class TasklyTaskRowLabels {
  const TasklyTaskRowLabels({
    this.completedStatusLabel,
    this.pinnedSemanticLabel,
    this.snoozeTooltip,
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
    this.pinLabel,
    this.pinnedLabel,
    this.bulkSelectTooltip,
    this.bulkDeselectTooltip,
  });

  final String? completedStatusLabel;
  final String? pinnedSemanticLabel;
  final String? snoozeTooltip;
  final String? selectionPillLabel;
  final String? selectionPillSelectedLabel;
  final String? pinLabel;
  final String? pinnedLabel;
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
    this.taskCount,
    this.completedTaskCount,
    this.dueSoonCount,
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
  final int? taskCount;
  final int? completedTaskCount;
  final int? dueSoonCount;
  final ValueChipData? leadingChip;
  final String? subtitle;
  final bool deemphasized;
  final IconData? groupLeadingIcon;
  final String? groupTrailingLabel;
}

@immutable
final class TasklyValueDistributionEntry {
  const TasklyValueDistributionEntry({
    required this.value,
    required this.count,
  });

  final ValueChipData value;
  final int count;

  String get stableId => value.label.toLowerCase();
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
