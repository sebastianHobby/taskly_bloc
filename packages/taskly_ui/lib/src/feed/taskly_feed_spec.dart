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

  const factory TasklyRowSpec.task({
    required String key,
    required TasklyTaskRowData data,
    required TasklyTaskRowActions actions,
    TasklyTaskRowStyle style,
    int depth,
  }) = TasklyTaskRowSpec;

  const factory TasklyRowSpec.project({
    required String key,
    required TasklyProjectRowData data,
    required TasklyProjectRowActions actions,
    TasklyProjectRowPreset preset,
    int depth,
  }) = TasklyProjectRowSpec;

  const factory TasklyRowSpec.value({
    required String key,
    required TasklyValueRowData data,
    required TasklyValueRowActions actions,
    TasklyValueRowPreset preset,
  }) = TasklyValueRowSpec;

  const factory TasklyRowSpec.routine({
    required String key,
    required TasklyRoutineRowData data,
    required TasklyRoutineRowActions actions,
    int depth,
  }) = TasklyRoutineRowSpec;
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

final class TasklyTaskRowSpec extends TasklyRowSpec {
  const TasklyTaskRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.style = const TasklyTaskRowStyle.standard(),
    this.depth = 0,
  });

  final String key;
  final TasklyTaskRowData data;
  final TasklyTaskRowActions actions;
  final TasklyTaskRowStyle style;
  final int depth;
}

final class TasklyProjectRowSpec extends TasklyRowSpec {
  const TasklyProjectRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.preset = const TasklyProjectRowPreset.standard(),
    this.depth = 0,
  });

  final String key;
  final TasklyProjectRowData data;
  final TasklyProjectRowActions actions;
  final TasklyProjectRowPreset preset;
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

  const factory TasklyTaskRowStyle.bulkSelection({
    required bool selected,
  }) = TasklyTaskRowStyleBulkSelection;

  const factory TasklyTaskRowStyle.planPick({
    required bool selected,
  }) = TasklyTaskRowStylePlanPick;
}

final class TasklyTaskRowStyleStandard extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleStandard();
}

final class TasklyTaskRowStyleBulkSelection extends TasklyTaskRowStyle {
  const TasklyTaskRowStyleBulkSelection({required this.selected});

  final bool selected;
}

final class TasklyTaskRowStylePlanPick extends TasklyTaskRowStyle {
  const TasklyTaskRowStylePlanPick({required this.selected});

  final bool selected;
}

@immutable
final class TasklyTaskRowActions {
  const TasklyTaskRowActions({
    this.onTap,
    this.onToggleCompletion,
    this.onToggleSelected,
    this.onSnoozeRequested,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final VoidCallback? onToggleSelected;
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
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
  });

  final String? pinnedSemanticLabel;
  final String? snoozeTooltip;
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
    this.taskCount,
    this.completedTaskCount,
    this.dueSoonCount,
    this.leadingChip,
    this.subtitle,
    this.deemphasized = false,
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
}

@immutable
final class TasklyRoutineRowData {
  const TasklyRoutineRowData({
    required this.id,
    required this.title,
    required this.targetLabel,
    required this.remainingLabel,
    required this.windowLabel,
    this.progress,
    this.scheduleRow,
    this.valueChip,
    this.selected = false,
    this.completed = false,
    this.highlightCompleted = true,
    this.badges = const <TasklyBadgeData>[],
    this.labels,
  });

  final String id;
  final String title;
  final String targetLabel;
  final String remainingLabel;
  final String windowLabel;
  final TasklyRoutineProgressData? progress;
  final TasklyRoutineScheduleRowData? scheduleRow;
  final ValueChipData? valueChip;
  final bool selected;
  final bool completed;
  final bool highlightCompleted;
  final List<TasklyBadgeData> badges;
  final TasklyRoutineRowLabels? labels;
}

enum TasklyRoutineScheduleIcon {
  loggedScheduled,
  loggedUnscheduled,
  missedScheduled,
}

@immutable
final class TasklyRoutineProgressData {
  const TasklyRoutineProgressData({
    required this.completedCount,
    required this.targetCount,
    required this.windowLabel,
  });

  final int completedCount;
  final int targetCount;
  final String windowLabel;

  double get progressRatio {
    if (targetCount <= 0) return 0;
    return completedCount.clamp(0, targetCount) / targetCount;
  }
}

@immutable
final class TasklyRoutineScheduleDay {
  const TasklyRoutineScheduleDay({
    required this.label,
    required this.isScheduled,
    required this.isToday,
  });

  final String label;
  final bool isScheduled;
  final bool isToday;
}

@immutable
final class TasklyRoutineScheduleRowData {
  const TasklyRoutineScheduleRowData({
    required this.icons,
    required this.days,
  });

  final List<TasklyRoutineScheduleIcon> icons;
  final List<TasklyRoutineScheduleDay> days;
}

@immutable
final class TasklyRoutineRowLabels {
  const TasklyRoutineRowLabels({
    this.primaryActionLabel,
  });

  final String? primaryActionLabel;
}

@immutable
final class TasklyRoutineRowActions {
  const TasklyRoutineRowActions({
    this.onTap,
    this.onPrimaryAction,
  });

  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
}

final class TasklyRoutineRowSpec extends TasklyRowSpec {
  const TasklyRoutineRowSpec({
    required this.key,
    required this.data,
    required this.actions,
    this.depth = 0,
  });

  final String key;
  final TasklyRoutineRowData data;
  final TasklyRoutineRowActions actions;
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
