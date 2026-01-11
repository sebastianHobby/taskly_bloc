import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a project.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    this.onCheckboxChanged,
    this.onTap,
    this.compact = false,
    this.taskCount,
    this.completedTaskCount,
    this.nextTask,
    this.showNextTask = false,
    this.isInFocus = false,
    this.showPinnedIndicator = true,
    this.showFocusIndicator = true,
    super.key,
  });

  final Project project;

  /// Whether to use a compact (2-row) layout.
  final bool compact;

  /// Optional tap handler. If null, navigates to project detail via EntityNavigator.
  final void Function(Project)? onTap;

  /// Callback when a project's completion checkbox is toggled.
  ///
  /// If null, no checkbox is shown.
  final void Function(Project, bool?)? onCheckboxChanged;

  /// Optional task count to show progress.
  final int? taskCount;

  /// Optional completed task count for progress indicator.
  final int? completedTaskCount;

  /// Optional recommended next task for this project.
  final Task? nextTask;

  /// Whether to display the next task subtitle.
  final bool showNextTask;

  /// Whether this project is part of today's focus allocation.
  ///
  /// If true and the project is not pinned, a focus indicator is shown.
  final bool isInFocus;

  /// Whether to show a pinned indicator when the project is pinned.
  final bool showPinnedIndicator;

  /// Whether to show a focus indicator when [isInFocus] is true.
  final bool showFocusIndicator;

  bool _isOverdue(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  bool _isDueToday(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  bool _isDueSoon(DateTime? deadline) {
    if (deadline == null || project.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= 7;
  }

  String _formatRelativeDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = dateDay.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference < -1 && difference >= -7) return '${-difference} days ago';

    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(date);
  }

  double? get _progressValue {
    if (taskCount == null || taskCount == 0) return null;
    return completedTaskCount != null ? completedTaskCount! / taskCount! : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOverdue = _isOverdue(project.deadlineDate);
    final isDueToday = _isDueToday(project.deadlineDate);
    final isDueSoon = _isDueSoon(project.deadlineDate);

    final hasDescription =
        project.description != null && project.description!.trim().isNotEmpty;
    final canShowNextTask = showNextTask && nextTask != null;
    final subtitle = (!compact && (hasDescription || canShowNextTask))
        ? (hasDescription
              ? project.description!.trim()
              : '${context.l10n.projectNextTaskPrefix} ${nextTask!.name}')
        : null;
    final isNextTaskSubtitle =
        subtitle != null && !hasDescription && canShowNextTask;

    return Card(
      key: Key('project-${project.id}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      color: project.completed
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(project)
            : Routing.toEntity(context, EntityType.project, project.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading widget: optional completion checkbox, else progress ring.
              if (onCheckboxChanged != null)
                _ProjectCheckbox(
                  completed: project.completed,
                  isOverdue: isOverdue,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    onCheckboxChanged?.call(project, value);
                  },
                  projectName: project.name,
                )
              else
                _ProjectProgressRing(
                  value: _progressValue,
                  isOverdue: isOverdue,
                  semanticsLabel: project.name,
                  taskCount: taskCount,
                  completedTaskCount: completedTaskCount,
                ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title + indicators + priority flag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showPinnedIndicator && project.isPinned) ...[
                          const PinnedIndicator(),
                          const SizedBox(width: 8),
                        ] else if (showFocusIndicator && isInFocus) ...[
                          const FocusIndicator(),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            project.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: project.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: project.completed
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityFlag(priority: project.priority),
                        if (!compact &&
                            taskCount != null &&
                            taskCount! > 0) ...[
                          const SizedBox(width: 8),
                          _TaskCountBadge(
                            total: taskCount!,
                            completed: completedTaskCount ?? 0,
                          ),
                        ],
                      ],
                    ),

                    // Row 2 (full only): Description or next task
                    if (!compact && subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isNextTaskSubtitle
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontStyle: isNextTaskSubtitle
                              ? FontStyle.italic
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Meta row: dates + values
                    _MetaChips(
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: _formatRelativeDate,
                      hasRepeat: project.repeatIcalRrule != null,
                      primaryValue: project.primaryValue,
                      secondaryValues: project.secondaryValues,
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

class _ProjectCheckbox extends StatelessWidget {
  const _ProjectCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
    required this.projectName,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?> onChanged;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: completed
          ? 'Mark "$projectName" as active'
          : 'Mark "$projectName" as complete',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: completed,
          onChanged: onChanged,
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

class _ProjectProgressRing extends StatelessWidget {
  const _ProjectProgressRing({
    required this.value,
    required this.isOverdue,
    required this.semanticsLabel,
    this.taskCount,
    this.completedTaskCount,
  });

  final double? value;
  final bool isOverdue;
  final String semanticsLabel;
  final int? taskCount;
  final int? completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ringValue = value;
    final hasValue = ringValue != null;
    final displayValue = (ringValue ?? 0).clamp(0.0, 1.0);

    final color = isOverdue ? scheme.error : scheme.primary;
    final trackColor = scheme.outlineVariant.withValues(alpha: 0.4);

    final semanticsValue = (taskCount != null && completedTaskCount != null)
        ? '$completedTaskCount of $taskCount'
        : hasValue
        ? '${(displayValue * 100).round()}%'
        : 'No tasks';

    return Semantics(
      label: 'Project progress for $semanticsLabel',
      value: semanticsValue,
      child: SizedBox.square(
        dimension: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(trackColor),
            ),
            CircularProgressIndicator(
              value: displayValue,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.formatDate,
    required this.primaryValue,
    required this.secondaryValues,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
  });

  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final bool hasRepeat;
  final String Function(BuildContext, DateTime) formatDate;
  final Value? primaryValue;
  final List<Value> secondaryValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final children = <Widget>[];

    if (primaryValue != null) {
      children.add(
        ValueChip(
          value: primaryValue!,
          variant: ValueChipVariant.solid,
        ),
      );
    }

    for (final value in secondaryValues) {
      children.add(
        ValueChip(
          value: value,
          variant: ValueChipVariant.outlined,
        ),
      );
    }

    if (startDate != null) {
      children.add(
        _InlineMetaItem(
          icon: Icons.calendar_today_rounded,
          label: formatDate(context, startDate!),
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    if (deadlineDate != null) {
      final deadlineColor = isOverdue
          ? scheme.error
          : isDueToday
          ? scheme.tertiary
          : isDueSoon
          ? scheme.secondary
          : scheme.onSurfaceVariant;
      children.add(
        _InlineMetaItem(
          icon: Icons.event_busy_rounded,
          label: formatDate(context, deadlineDate!),
          color: deadlineColor,
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

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _InlineMetaItem extends StatelessWidget {
  const _InlineMetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Badge showing task completion count.
class _TaskCountBadge extends StatelessWidget {
  const _TaskCountBadge({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isComplete = completed == total && total > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isComplete
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.task_alt,
            size: 12,
            color: isComplete
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '$completed/$total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isComplete
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
