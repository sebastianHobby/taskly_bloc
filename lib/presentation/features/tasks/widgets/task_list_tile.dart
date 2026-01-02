import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a task.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onCheckboxChanged,
    required this.onTap,
    this.onNextActionRemoved,
    this.showNextActionIndicator = true,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;
  final void Function(Task) onTap;

  /// Callback when user removes the Next Action status from the task.
  /// If null, the indicator won't show the unpin option.
  final void Function(Task)? onNextActionRemoved;

  /// Whether to show the Next Action indicator for pinned tasks.
  final bool showNextActionIndicator;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final isDueSoon = _isDueSoon(task.deadlineDate);

    return Card(
      key: Key('task-${task.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      color: task.completed
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => onTap(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox with custom styling
              _TaskCheckbox(
                completed: task.completed,
                isOverdue: isOverdue,
                onChanged: (value) => onCheckboxChanged(task, value),
                taskName: task.name,
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with project indicator and next action badge
                    Row(
                      children: [
                        // Next Action indicator (if pinned)
                        if (showNextActionIndicator &&
                            task.labels.hasNextActionLabel) ...[
                          NextActionIndicator(
                            onUnpin: onNextActionRemoved != null
                                ? () => onNextActionRemoved!(task)
                                : null,
                          ),
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
                        if (task.project != null) ...[
                          const SizedBox(width: 8),
                          _ProjectBadge(projectName: task.project!.name),
                        ],
                      ],
                    ),

                    // Description
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Labels section
                    LabelsSection(labels: task.labels),

                    // Dates row
                    DatesRow(
                      startDate: task.startDate,
                      deadlineDate: task.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: _formatRelativeDate,
                      hasRepeat: task.repeatIcalRrule != null,
                    ),
                  ],
                ),
              ),

              // Chevron indicator
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom checkbox with animated states and accessibility support.
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
          onChanged: (value) {
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

/// Badge showing project name.
class _ProjectBadge extends StatelessWidget {
  const _ProjectBadge({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 12,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              projectName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
