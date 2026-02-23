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
    required List<TasklyRowSpec> rows,
    required String Function(int remaining, int total) showMoreLabelBuilder,
    required String emptyLabel,
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
    String? addLabel,
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
    required this.rows,
    required this.showMoreLabelBuilder,
    required this.emptyLabel,
    this.actionLabel,
    this.actionTooltip,
    this.onActionPressed,
  });

  final String id;
  final String title;
  final String countLabel;
  final List<TasklyRowSpec> rows;
  final String Function(int remaining, int total) showMoreLabelBuilder;
  final String emptyLabel;
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
    this.addLabel,
  });

  final String id;
  final DateTime day;
  final String title;
  final bool isToday;
  final List<TasklyRowSpec> rows;
  final String? countLabel;
  final String? emptyLabel;
  final VoidCallback? onAddRequested;
  final String? addLabel;
}

sealed class TasklyRowSpec {
  const TasklyRowSpec();

  const factory TasklyRowSpec.header({
    required String key,
    required String title,
    IconData? leadingIcon,
    Color? leadingIconColor,
    String? subtitle,
    String? trailingLabel,
    IconData? trailingIcon,
    IconData? trailingActionIcon,
    String? trailingActionTooltip,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onTrailingAction,
    double? dividerOpacity,
    Key? anchorKey,
    int depth,
  }) = TasklyHeaderRowSpec;

  const factory TasklyRowSpec.subheader({
    required String key,
    required String title,
    Key? anchorKey,
    int depth,
  }) = TasklySubheaderRowSpec;

  const factory TasklyRowSpec.divider({
    required String key,
    Key? anchorKey,
    int depth,
  }) = TasklyDividerRowSpec;

  const factory TasklyRowSpec.inlineAction({
    required String key,
    required String label,
    required VoidCallback onTap,
    Key? anchorKey,
    int depth,
  }) = TasklyInlineActionRowSpec;

  const factory TasklyRowSpec.task({
    required String key,
    required TasklyTaskRowData data,
    required TasklyTaskRowActions actions,
    Key? anchorKey,
    TasklyTaskRowStyle style,
    int depth,
  }) = TasklyTaskRowSpec;

  const factory TasklyRowSpec.project({
    required String key,
    required TasklyProjectRowData data,
    required TasklyProjectRowActions actions,
    Key? anchorKey,
    TasklyProjectRowPreset preset,
    int depth,
  }) = TasklyProjectRowSpec;

  const factory TasklyRowSpec.value({
    required String key,
    required TasklyValueRowData data,
    required TasklyValueRowActions actions,
    Key? anchorKey,
    TasklyValueRowPreset preset,
  }) = TasklyValueRowSpec;

  const factory TasklyRowSpec.routine({
    required String key,
    required TasklyRoutineRowData data,
    required TasklyRoutineRowActions actions,
    Key? anchorKey,
    TasklyRoutineRowStyle? style,
    int depth,
  }) = TasklyRoutineRowSpec;
}

final class TasklyHeaderRowSpec extends TasklyRowSpec {
  const TasklyHeaderRowSpec({
    required this.key,
    required this.title,
    this.leadingIcon,
    this.leadingIconColor,
    this.subtitle,
    this.trailingLabel,
    this.trailingIcon,
    this.trailingActionIcon,
    this.trailingActionTooltip,
    this.onTap,
    this.onLongPress,
    this.onTrailingAction,
    this.dividerOpacity,
    this.anchorKey,
    this.depth = 0,
  });

  final String key;
  final String title;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final String? subtitle;
  final String? trailingLabel;
  final IconData? trailingIcon;
  final IconData? trailingActionIcon;
  final String? trailingActionTooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTrailingAction;
  final double? dividerOpacity;
  final Key? anchorKey;
  final int depth;
}

final class TasklySubheaderRowSpec extends TasklyRowSpec {
  const TasklySubheaderRowSpec({
    required this.key,
    required this.title,
    this.anchorKey,
    this.depth = 0,
  });

  final String key;
  final String title;
  final Key? anchorKey;
  final int depth;
}

final class TasklyDividerRowSpec extends TasklyRowSpec {
  const TasklyDividerRowSpec({
    required this.key,
    this.anchorKey,
    this.depth = 0,
  });

  final String key;
  final Key? anchorKey;
  final int depth;
}

final class TasklyInlineActionRowSpec extends TasklyRowSpec {
  const TasklyInlineActionRowSpec({
    required this.key,
    required this.label,
    required this.onTap,
    this.anchorKey,
    this.depth = 0,
  });

  final String key;
  final String label;
  final VoidCallback onTap;
  final Key? anchorKey;
  final int depth;
}

final class TasklyTaskRowSpec extends TasklyRowSpec {
  const TasklyTaskRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.anchorKey,
    this.style = const TasklyTaskRowStyle.standard(),
    this.depth = 0,
  });

  final String key;
  final TasklyTaskRowData data;
  final TasklyTaskRowActions actions;
  final Key? anchorKey;
  final TasklyTaskRowStyle style;
  final int depth;
}

final class TasklyProjectRowSpec extends TasklyRowSpec {
  const TasklyProjectRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.anchorKey,
    this.preset = const TasklyProjectRowPreset.standard(),
    this.depth = 0,
  });

  final String key;
  final TasklyProjectRowData data;
  final TasklyProjectRowActions actions;
  final Key? anchorKey;
  final TasklyProjectRowPreset preset;
  final int depth;
}

final class TasklyValueRowSpec extends TasklyRowSpec {
  const TasklyValueRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.anchorKey,
    this.preset = const TasklyValueRowPreset.standard(),
  });

  final String key;
  final TasklyValueRowData data;
  final TasklyValueRowActions actions;
  final Key? anchorKey;
  final TasklyValueRowPreset preset;
}

enum TasklyBadgeTone { solid, outline, soft }

@immutable
final class TasklyBadgeData {
  const TasklyBadgeData({
    required this.label,
    required this.color,
    this.icon,
    this.tone = TasklyBadgeTone.solid,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final TasklyBadgeTone tone;
}

sealed class TasklyTaskRowStyle {
  const TasklyTaskRowStyle();

  const factory TasklyTaskRowStyle.standard() = TasklyTaskRowStyleStandard;

  const factory TasklyTaskRowStyle.compact() = TasklyTaskRowStyleCompact;

  const factory TasklyTaskRowStyle.bulkSelection({
    required bool selected,
  }) = TasklyTaskRowStyleBulkSelection;

  const factory TasklyTaskRowStyle.bulkSelectionCompact({
    required bool selected,
  }) = TasklyTaskRowStyleBulkSelectionCompact;

  const factory TasklyTaskRowStyle.planPick({
    required bool selected,
  }) = TasklyTaskRowStylePlanPick;
}

final class TasklyTaskRowStyleStandard extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleStandard();
}

final class TasklyTaskRowStyleCompact extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleCompact();
}

final class TasklyTaskRowStyleBulkSelection extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStyleBulkSelectionCompact extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleBulkSelectionCompact({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePlanPick extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePlanPick({required this.selected});

  final bool selected;
}

sealed class TasklyRoutineRowStyle {
  const TasklyRoutineRowStyle();

  const factory TasklyRoutineRowStyle.standard() =
      TasklyRoutineRowStyleStandard;

  const factory TasklyRoutineRowStyle.bulkSelection() =
      TasklyRoutineRowStyleBulkSelection;

  const factory TasklyRoutineRowStyle.planPick() =
      TasklyRoutineRowStylePlanPick;
}

final class TasklyRoutineRowStyleStandard extends TasklyRoutineRowStyle {
  const TasklyRoutineRowStyleStandard();
}

final class TasklyRoutineRowStyleBulkSelection extends TasklyRoutineRowStyle {
  const TasklyRoutineRowStyleBulkSelection();
}

final class TasklyRoutineRowStylePlanPick extends TasklyRoutineRowStyle {
  const TasklyRoutineRowStylePlanPick();
}

@immutable
final class TasklyTaskRowActions {
  const TasklyTaskRowActions({
    this.onTap,
    this.onToggleCompletion,
    this.onToggleSelected,
    this.onSnoozeRequested,
    this.onSwapRequested,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onSnoozeRequested;
  final VoidCallback? onSwapRequested;
  final VoidCallback? onLongPress;
}

sealed class TasklyProjectRowPreset {
  const TasklyProjectRowPreset();

  const factory TasklyProjectRowPreset.standard() =
      TasklyProjectRowPresetStandard;

  const factory TasklyProjectRowPreset.compact() =
      TasklyProjectRowPresetCompact;

  const factory TasklyProjectRowPreset.inbox() = TasklyProjectRowPresetInbox;

  const factory TasklyProjectRowPreset.bulkSelection({
    required bool selected,
  }) = TasklyProjectRowPresetBulkSelection;

  const factory TasklyProjectRowPreset.bulkSelectionCompact({
    required bool selected,
  }) = TasklyProjectRowPresetBulkSelectionCompact;
}

final class TasklyProjectRowPresetStandard extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetStandard();
}

final class TasklyProjectRowPresetCompact extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetCompact();
}

final class TasklyProjectRowPresetInbox extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetInbox();
}

final class TasklyProjectRowPresetBulkSelection extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyProjectRowPresetBulkSelectionCompact
    extends TasklyProjectRowPreset {
  const TasklyProjectRowPresetBulkSelectionCompact({required this.selected});

  final bool selected;
}

@immutable
final class TasklyProjectRowActions {
  const TasklyProjectRowActions({
    this.onTap,
    this.onToggleSelected,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
}

sealed class TasklyValueRowPreset {
  const TasklyValueRowPreset();

  const factory TasklyValueRowPreset.standard() = TasklyValueRowPresetStandard;

  const factory TasklyValueRowPreset.hero() = TasklyValueRowPresetHero;

  const factory TasklyValueRowPreset.heroSelection({
    required bool selected,
  }) = TasklyValueRowPresetHeroSelection;

  const factory TasklyValueRowPreset.bulkSelection({
    required bool selected,
  }) = TasklyValueRowPresetBulkSelection;
}

final class TasklyValueRowPresetStandard extends TasklyValueRowPreset {
  const TasklyValueRowPresetStandard();
}

final class TasklyValueRowPresetHero extends TasklyValueRowPreset {
  const TasklyValueRowPresetHero();
}

final class TasklyValueRowPresetHeroSelection extends TasklyValueRowPreset {
  const TasklyValueRowPresetHeroSelection({required this.selected});

  final bool selected;
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
    this.startDateLabel,
    this.deadlineDateLabel,
    this.showOnlyDeadlineDate = false,
    this.isOverdue = false,
    this.isDueToday = false,
    this.priority,
  });

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
    this.badges = const <TasklyBadgeData>[],
    this.deemphasized = false,
    this.checkboxSemanticLabel,
    this.labels,
    this.pinned = false,
  });

  final String id;
  final String title;
  final bool completed;
  final TasklyEntityMetaData meta;
  final ValueChipData? leadingChip;
  final List<ValueChipData> secondaryChips;
  final List<TasklyBadgeData> badges;
  final bool deemphasized;
  final String? checkboxSemanticLabel;
  final TasklyTaskRowLabels? labels;
  final bool pinned;
}

@immutable
final class TasklyTaskRowLabels {
  const TasklyTaskRowLabels({
    this.pinnedSemanticLabel,
    this.snoozeTooltip,
    this.swapTooltip,
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
  });

  final String? pinnedSemanticLabel;
  final String? snoozeTooltip;
  final String? swapTooltip;
  final String? selectionPillLabel;
  final String? selectionPillSelectedLabel;
}

@immutable
final class TasklyProjectRowData {
  const TasklyProjectRowData({
    required this.id,
    required this.title,
    required this.completed,
    required this.pinned,
    required this.meta,
    this.statusBadge,
    this.taskCount,
    this.completedTaskCount,
    this.dueSoonCount,
    this.leadingChip,
    this.accentColor,
    this.subtitle,
    this.deemphasized = false,
  });

  final String id;
  final String title;
  final bool completed;
  final bool pinned;
  final TasklyEntityMetaData meta;
  final TasklyBadgeData? statusBadge;
  final int? taskCount;
  final int? completedTaskCount;
  final int? dueSoonCount;
  final ValueChipData? leadingChip;
  final Color? accentColor;
  final String? subtitle;
  final bool deemphasized;
}

@immutable
final class TasklyRoutineRowData {
  const TasklyRoutineRowData({
    required this.id,
    required this.title,
    this.actionLineText,
    this.dotRow,
    this.scheduleRow,
    this.leadingIcon,
    this.selected = false,
    this.completed = false,
    this.highlightCompleted = false,
    this.badges = const <TasklyBadgeData>[],
    this.labels,
  });

  final String id;
  final String title;
  final String? actionLineText;
  final TasklyRoutineDotRowData? dotRow;
  final TasklyRoutineScheduleRowData? scheduleRow;
  final ValueChipData? leadingIcon;
  final bool selected;
  final bool completed;
  final bool highlightCompleted;
  final List<TasklyBadgeData> badges;
  final TasklyRoutineRowLabels? labels;
}

enum TasklyRoutineScheduleDayState {
  none,
  scheduled,
  loggedScheduled,
  loggedUnscheduled,
  skippedScheduled,
  missedScheduled,
}

@immutable
final class TasklyRoutineDotRowData {
  const TasklyRoutineDotRowData({
    required this.completedCount,
    required this.targetCount,
    required this.label,
  });

  final int completedCount;
  final int targetCount;
  final String label;
}

@immutable
final class TasklyRoutineScheduleDay {
  const TasklyRoutineScheduleDay({
    required this.label,
    required this.isToday,
    required this.state,
  });

  final String label;
  final bool isToday;
  final TasklyRoutineScheduleDayState state;
}

@immutable
final class TasklyRoutineScheduleRowData {
  const TasklyRoutineScheduleRowData({
    required this.days,
  });

  final List<TasklyRoutineScheduleDay> days;
}

@immutable
final class TasklyRoutineRowLabels {
  const TasklyRoutineRowLabels({
    this.primaryActionLabel,
    this.selectionTooltipLabel,
    this.selectionTooltipSelectedLabel,
  });

  final String? primaryActionLabel;
  final String? selectionTooltipLabel;
  final String? selectionTooltipSelectedLabel;
}

@immutable
final class TasklyRoutineRowActions {
  const TasklyRoutineRowActions({
    this.onTap,
    this.onPrimaryAction,
    this.onToggleSelected,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
}

final class TasklyRoutineRowSpec extends TasklyRowSpec {
  const TasklyRoutineRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.anchorKey,
    TasklyRoutineRowStyle? style,
    this.depth = 0,
  }) : style = style ?? const TasklyRoutineRowStyle.standard();

  final String key;
  final TasklyRoutineRowData data;
  final TasklyRoutineRowActions actions;
  final Key? anchorKey;
  final TasklyRoutineRowStyle style;
  final int depth;
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
    this.priorityLabel,
    this.priorityDotColor,
    this.primaryStatLabel,
    this.primaryStatSubLabel,
    this.emptyStatTitle,
    this.emptyStatSubtitle,
    this.metrics = const <TasklyValueRowMetric>[],
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accentColor;
  final String? priorityLabel;
  final Color? priorityDotColor;
  final String? primaryStatLabel;
  final String? primaryStatSubLabel;
  final String? emptyStatTitle;
  final String? emptyStatSubtitle;
  final List<TasklyValueRowMetric> metrics;
}

@immutable
final class TasklyValueRowMetric {
  const TasklyValueRowMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
