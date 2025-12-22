import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/shared/widgets/truncated_label_chips.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a task.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onCheckboxChanged,
    required this.onTap,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;
  final void Function(Task) onTap;

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
              ? colorScheme.error.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      color: task.completed
          ? colorScheme.surfaceContainerLowest.withOpacity(0.5)
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
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with project indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed
                                  ? colorScheme.onSurface.withOpacity(0.5)
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
                    _LabelsSection(labels: task.labels),

                    // Dates row
                    _DatesRow(
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
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom checkbox with animated states.
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
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
        color: colorScheme.tertiaryContainer.withOpacity(0.5),
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

/// Section displaying labels and values.
class _LabelsSection extends StatelessWidget {
  const _LabelsSection({required this.labels});

  final List<Label> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final valueLabels = labels.where((l) => l.type == LabelType.value).toList();
    final typeLabels = labels.where((l) => l.type == LabelType.label).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (valueLabels.isNotEmpty) TruncatedLabelChips(labels: valueLabels),
          if (valueLabels.isNotEmpty && typeLabels.isNotEmpty)
            const SizedBox(height: 4),
          if (typeLabels.isNotEmpty) TruncatedLabelChips(labels: typeLabels),
        ],
      ),
    );
  }
}

/// Row displaying dates with visual indicators.
class _DatesRow extends StatelessWidget {
  const _DatesRow({
    required this.startDate,
    required this.deadlineDate,
    required this.isOverdue,
    required this.isDueToday,
    required this.isDueSoon,
    required this.formatDate,
    required this.hasRepeat,
  });

  final DateTime? startDate;
  final DateTime? deadlineDate;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;
  final String Function(BuildContext, DateTime) formatDate;
  final bool hasRepeat;

  @override
  Widget build(BuildContext context) {
    if (startDate == null && deadlineDate == null && !hasRepeat) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          // Start date
          if (startDate != null)
            _DateChip(
              icon: Icons.play_arrow_rounded,
              label: formatDate(context, startDate!),
              color: colorScheme.onSurfaceVariant,
            ),

          // Deadline date with status color
          if (deadlineDate != null)
            _DateChip(
              icon: Icons.flag_rounded,
              label: formatDate(context, deadlineDate!),
              color: isOverdue
                  ? colorScheme.error
                  : isDueToday
                  ? colorScheme.tertiary
                  : isDueSoon
                  ? colorScheme.secondary
                  : colorScheme.onSurfaceVariant,
              backgroundColor: isOverdue
                  ? colorScheme.errorContainer.withOpacity(0.3)
                  : isDueToday
                  ? colorScheme.tertiaryContainer.withOpacity(0.3)
                  : null,
            ),

          // Repeat indicator
          if (hasRepeat)
            _DateChip(
              icon: Icons.repeat_rounded,
              label: 'Repeats',
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

/// A compact chip showing a date or indicator.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.icon,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.zero,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
