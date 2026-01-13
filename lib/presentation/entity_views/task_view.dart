import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';
import 'package:taskly_bloc/presentation/field_catalog/field_catalog.dart';
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

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateChip? _buildStrictDateToken(
    BuildContext context, {
    required DateTime? startDate,
    required DateTime? deadlineDate,
    required bool isOverdue,
    required bool isDueToday,
    required bool isDueSoon,
    required String Function(BuildContext, DateTime) formatDate,
  }) {
    if (deadlineDate != null) {
      return DateChip.deadline(
        context: context,
        label: formatDate(context, deadlineDate),
        isOverdue: isOverdue,
        isDueToday: isDueToday,
        isDueSoon: isDueSoon,
      );
    }

    if (startDate != null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      if (!startDay.isBefore(_today())) {
        return DateChip.startDate(
          context: context,
          label: formatDate(context, startDate),
        );
      }
    }

    return null;
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
            border: Border(
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
                        if (showNextActionIndicator && task.isPinned) ...[
                          NextActionIndicator(
                            onUnpin: onNextActionRemoved != null
                                ? () => onNextActionRemoved!(task)
                                : null,
                          ),
                          const SizedBox(width: 8),
                        ],
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
                        const SizedBox(width: 8),
                        PriorityFlag(priority: task.priority),
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
                      projectName: task.project?.name,
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: task.repeatIcalRrule != null,
                      primaryValue: effectivePrimaryValue,
                      secondaryValues: effectiveSecondaryValues,
                      buildDateToken: (context) => _buildStrictDateToken(
                        context,
                        startDate: task.startDate,
                        deadlineDate: task.deadlineDate,
                        isOverdue: isOverdue,
                        isDueToday: isDueToday,
                        isDueSoon: isDueSoon,
                        formatDate: DateLabelFormatter.format,
                      ),
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
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      projectName: task.project?.name,
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: DateLabelFormatter.format,
                      hasRepeat: task.repeatIcalRrule != null,
                      primaryValue: effectivePrimaryValue,
                      secondaryValues: effectiveSecondaryValues,
                      buildDateToken: (context) => _buildStrictDateToken(
                        context,
                        startDate: task.startDate,
                        deadlineDate: task.deadlineDate,
                        isOverdue: isOverdue,
                        isDueToday: isDueToday,
                        isDueSoon: isDueSoon,
                        formatDate: DateLabelFormatter.format,
                      ),
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
    required this.primaryValue,
    required this.secondaryValues,
    required this.buildDateToken,
    this.projectName,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
  });

  final String? projectName;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final String Function(BuildContext, DateTime) formatDate;
  final Value? primaryValue;
  final List<Value> secondaryValues;
  final DateChip? Function(BuildContext context) buildDateToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final primary = primaryValue;

    final dateToken = buildDateToken(context);

    final children = <Widget>[];

    if (primary != null) {
      children.add(
        ValueChip(
          value: primary,
          variant: ValueChipVariant.solid,
        ),
      );
    }

    if (secondaryValues.isNotEmpty) {
      children.add(
        ValueChip(
          value: secondaryValues.first,
          variant: ValueChipVariant.outlined,
        ),
      );
    }

    if (hasRepeat) {
      children.add(
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    final pName = projectName?.trim();
    if (pName != null && pName.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(
          Container(
            height: 14,
            width: 1,
            color: scheme.outlineVariant,
          ),
        );
      }
      children.add(
        Text(
          'Project: $pName',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: scheme.primary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (children.isEmpty && dateToken == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...children,
          ?dateToken,
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
