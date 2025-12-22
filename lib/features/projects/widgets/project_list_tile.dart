import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/shared/widgets/truncated_label_chips.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a project.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    required this.onCheckboxChanged,
    required this.onTap,
    this.taskCount,
    this.completedTaskCount,
    super.key,
  });

  final Project project;
  final void Function(Project, bool?) onCheckboxChanged;
  final void Function(Project) onTap;

  /// Optional task count to show progress.
  final int? taskCount;

  /// Optional completed task count for progress indicator.
  final int? completedTaskCount;

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

    return Card(
      key: Key('project-${project.id}'),
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
      color: project.completed
          ? colorScheme.surfaceContainerLowest.withOpacity(0.5)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => onTap(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project icon/checkbox area
              _ProjectCheckbox(
                completed: project.completed,
                isOverdue: isOverdue,
                onChanged: (value) => onCheckboxChanged(project, value),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: project.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: project.completed
                                  ? colorScheme.onSurface.withOpacity(0.5)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Task count badge
                        if (taskCount != null && taskCount! > 0) ...[
                          const SizedBox(width: 8),
                          _TaskCountBadge(
                            total: taskCount!,
                            completed: completedTaskCount ?? 0,
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        project.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Progress bar
                    if (_progressValue != null) ...[
                      const SizedBox(height: 8),
                      _ProgressBar(
                        progress: _progressValue!,
                        isCompleted: project.completed,
                      ),
                    ],

                    // Labels section
                    _LabelsSection(labels: project.labels),

                    // Dates row
                    _DatesRow(
                      startDate: project.startDate,
                      deadlineDate: project.deadlineDate,
                      isOverdue: isOverdue,
                      isDueToday: isDueToday,
                      isDueSoon: isDueSoon,
                      formatDate: _formatRelativeDate,
                      hasRepeat: project.repeatIcalRrule != null,
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

/// Custom checkbox for projects with folder-style appearance.
class _ProjectCheckbox extends StatelessWidget {
  const _ProjectCheckbox({
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
      width: 28,
      height: 28,
      child: Checkbox(
        value: completed,
        onChanged: onChanged,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
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
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
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

/// Progress bar for project completion.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.isCompleted,
  });

  final double progress;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          isCompleted ? colorScheme.primary : colorScheme.secondary,
        ),
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
