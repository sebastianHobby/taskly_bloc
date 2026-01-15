import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:taskly_bloc/presentation/field_catalog/field_catalog.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';

enum TaskViewVariant {
  /// Default list-row style used across most list templates.
  list,

  /// Rounded card variant intended for the Scheduled agenda timeline.
  agendaCard,
}

/// The canonical, entity-level task UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class TaskView extends StatelessWidget {
  const TaskView({
    required this.task,
    required this.onCheckboxChanged,
    this.onTap,
    this.compact = false,
    this.onNextActionRemoved,
    this.showNextActionIndicator = true,
    this.isInFocus = false,
    this.showProjectNameInMeta = true,
    this.projectNameIsTertiary = false,
    this.groupedValueId,
    this.showPrimaryValueChip = true,
    this.maxSecondaryValueChips = 1,
    this.excludeValueIdFromChips,
    this.reasonText,
    this.reasonColor,
    this.titlePrefix,
    this.variant = TaskViewVariant.list,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;

  /// Optional tap handler. If null, navigates to task detail via EntityNavigator.
  final void Function(Task)? onTap;

  /// Whether to use a compact (2-row) layout.
  final bool compact;

  /// Callback when user removes the Next Action status from the task.
  /// If null, the indicator won't show the unpin option.
  final void Function(Task)? onNextActionRemoved;

  /// Whether to show the Next Action indicator for pinned tasks.
  final bool showNextActionIndicator;

  /// Whether this task is currently in the user's focus list (My Day).
  ///
  /// Used by screens like Anytime and Scheduled to provide subtle focus cues.
  final bool isInFocus;

  /// Whether to show the project name in the meta line.
  ///
  /// Useful when the task is already displayed under a project header.
  final bool showProjectNameInMeta;

  /// Whether the project name should be rendered with tertiary emphasis.
  ///
  /// This is useful when the project is already implied by the surrounding UI
  /// (e.g., grouped under a project header) but we still want the project name
  /// present as a subtle reminder.
  final bool projectNameIsTertiary;

  /// When set, the task is being rendered under a value grouping.
  ///
  /// Used to (a) render a compact, icon-only primary value chip for the grouped
  /// value and (b) avoid repeating that value among secondary chips.
  final String? groupedValueId;

  /// Whether to show the primary value chip in the meta line.
  ///
  /// Useful when tasks are displayed under a value grouping where the value is
  /// already implied by the section header.
  final bool showPrimaryValueChip;

  /// Maximum number of secondary value chips to show.
  ///
  /// Defaults to 1 to keep list rows compact.
  final int maxSecondaryValueChips;

  /// When set, excludes this value id from any chips shown in the meta line.
  ///
  /// This is typically the current value group id.
  final String? excludeValueIdFromChips;

  /// Optional reason text to display below the task name.
  /// Used for excluded task alerts (e.g., "Overdue by 2 days").
  final String? reasonText;

  /// Custom color for the reason text.
  /// If null, uses onSurfaceVariant.
  final Color? reasonColor;

  /// Optional widget shown inline before the task title.
  ///
  /// Used by some list templates (e.g. Agenda) to display a tag pill like
  /// START/DUE without overlaying the tile content.
  final Widget? titlePrefix;

  /// Visual variant used to align with the Scheduled agenda mock.
  final TaskViewVariant variant;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || task.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 3;
  }

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      TaskViewVariant.list => _buildListRow(context),
      TaskViewVariant.agendaCard => _buildAgendaCard(context),
    };
  }

  Widget _buildListRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    return Material(
      key: Key('task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(task)
            : Routing.toEntity(context, EntityType.task, task.id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isInFocus
                ? colorScheme.primary.withValues(alpha: 0.04)
                : null,
            border: Border(
              left: isInFocus
                  ? BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.65),
                      width: 3,
                    )
                  : BorderSide.none,
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _TaskCheckbox(
                  completed: task.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) => onCheckboxChanged(task, value),
                  taskName: task.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showPrimaryValueChip &&
                            effectivePrimaryValue != null) ...[
                          const SizedBox(width: 12),
                          ValueChip(
                            value: effectivePrimaryValue,
                            variant: ValueChipVariant.solid,
                            iconOnly: false,
                          ),
                        ],
                      ],
                    ),
                    // Explicitly removed subtitle/description logic to align with list view mockup
                    /*
                    if (!compact && subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isReasonSubtitle
                              ? (reasonColor ?? colorScheme.onSurfaceVariant)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isReasonSubtitle ? FontWeight.w500 : null,
                        ),
                        maxLines: isReasonSubtitle ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    */
                    _MetaLine(
                      projectName: showProjectNameInMeta
                          ? task.project?.name
                          : null,
                      projectNameIsTertiary: projectNameIsTertiary,
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: task.repeatIcalRrule != null,
                      secondaryValues: effectiveSecondaryValues,
                      groupedValueId: groupedValueId,
                      maxSecondaryValueChips: maxSecondaryValueChips,
                      excludeValueIdFromChips: excludeValueIdFromChips,
                      isPinned: task.isPinned,
                      priority: task.priority,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePrimaryValue = task.effectivePrimaryValue;
    final effectiveSecondaryValues = task.effectiveSecondaryValues;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    // Keep checkbox interaction (important affordance), but switch the container
    // and hierarchy to a card style that matches the Scheduled mock better.
    return Material(
      key: Key('task-${task.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(task)
            : Routing.toEntity(context, EntityType.task, task.id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: isInFocus
                ? Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.06),
                    colorScheme.surfaceContainerLow,
                  )
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: isInFocus
                ? Border(
                    left: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.55),
                      width: 4,
                    ),
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    right: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  )
                : Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _TaskCheckbox(
                  completed: task.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) => onCheckboxChanged(task, value),
                  taskName: task.name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showPrimaryValueChip &&
                            effectivePrimaryValue != null) ...[
                          const SizedBox(width: 12),
                          ValueChip(
                            value: effectivePrimaryValue,
                            variant: ValueChipVariant.solid,
                            iconOnly: false,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      projectName: showProjectNameInMeta
                          ? task.project?.name
                          : null,
                      projectNameIsTertiary: projectNameIsTertiary,
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: task.repeatIcalRrule != null,
                      secondaryValues: effectiveSecondaryValues,
                      groupedValueId: groupedValueId,
                      maxSecondaryValueChips: maxSecondaryValueChips,
                      excludeValueIdFromChips: excludeValueIdFromChips,
                      isPinned: task.isPinned,
                      priority: task.priority,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.formatDate,
    required this.secondaryValues,
    required this.groupedValueId,
    required this.maxSecondaryValueChips,
    required this.excludeValueIdFromChips,
    required this.isPinned,
    required this.priority,
    this.projectName,
    this.projectNameIsTertiary = false,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
  });

  final String? projectName;
  final bool projectNameIsTertiary;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final String Function(BuildContext, DateTime) formatDate;
  final List<Value> secondaryValues;
  final String? groupedValueId;
  final int maxSecondaryValueChips;
  final String? excludeValueIdFromChips;
  final bool isPinned;
  final int? priority;

  Color _priorityColor(ColorScheme scheme, int p) {
    return switch (p) {
      1 => AppColors.rambutan80,
      2 => AppColors.cempedak80,
      3 => AppColors.blueberry80,
      4 => scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final groupedId = groupedValueId?.trim();
    final isValueGrouped = groupedId != null && groupedId.isNotEmpty;

    final leftChildren = <Widget>[];

    if (maxSecondaryValueChips > 0) {
      final filteredSecondary = secondaryValues
          .where(
            (v) =>
                v.id != excludeValueIdFromChips &&
                (!isValueGrouped || v.id != groupedId),
          )
          .toList(growable: false);

      if (filteredSecondary.isNotEmpty) {
        final visible = filteredSecondary.take(maxSecondaryValueChips).toList();
        for (final v in visible) {
          leftChildren.add(
            Tooltip(
              message: v.name,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: ValueChip(
                  value: v,
                  variant: ValueChipVariant.outlined,
                  iconOnly: isValueGrouped,
                ),
              ),
            ),
          );
        }

        final remaining = filteredSecondary.length - visible.length;
        if (remaining > 0) {
          final allNames = filteredSecondary.map((v) => v.name).join(', ');
          leftChildren.add(
            Tooltip(
              message: allNames,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                constraints: const BoxConstraints(minHeight: 20),
                child: Text(
                  '+$remaining',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    if (hasRepeat) {
      leftChildren.add(
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    if (isPinned) {
      leftChildren.add(
        Tooltip(
          message: 'Pinned',
          child: Icon(
            Icons.push_pin,
            size: 14,
            color: scheme.primary,
          ),
        ),
      );
    }

    final p = priority;
    if (p != null) {
      leftChildren.add(
        Tooltip(
          message: 'Priority P$p',
          child: Icon(
            Icons.flag,
            size: 14,
            color: _priorityColor(scheme, p),
          ),
        ),
      );
    }

    final pName = projectName?.trim();
    if (pName != null && pName.isNotEmpty) {
      leftChildren.add(
        ProjectPill(
          projectName: pName,
          isTertiary: projectNameIsTertiary,
        ),
      );
    }

    final dateTokens = <Widget>[];
    if (startDate != null) {
      dateTokens.add(
        DateChip.startDate(
          context: context,
          label: formatDate(context, startDate!),
        ),
      );
    }
    if (deadlineDate != null) {
      dateTokens.add(
        DateChip.deadline(
          context: context,
          label: formatDate(context, deadlineDate!),
          isOverdue: isOverdue,
          isDueToday: isDueToday,
          isDueSoon: isDueSoon,
        ),
      );
    }

    if (leftChildren.isEmpty && dateTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: leftChildren,
            ),
          ),
          if (dateTokens.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: dateTokens,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
    required this.taskName,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?> onChanged;
  final String taskName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: completed
          ? 'Mark "$taskName" as incomplete'
          : 'Mark "$taskName" as complete',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: completed,
          onChanged: (bool? value) {
            HapticFeedback.lightImpact();
            onChanged(value);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          side: BorderSide(
            color: isOverdue
                ? colorScheme.error
                : completed
                ? colorScheme.primary
                : colorScheme.outline,
            width: 2,
          ),
          activeColor: colorScheme.primary,
          checkColor: colorScheme.onPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
