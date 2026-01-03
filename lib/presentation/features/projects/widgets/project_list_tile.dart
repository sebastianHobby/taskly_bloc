import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';
import 'package:taskly_bloc/presentation/widgets/widgets.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a project.
class ProjectListTile extends StatelessWidget {
  const ProjectListTile({
    required this.project,
    required this.onCheckboxChanged,
    this.onTap,
    this.taskCount,
    this.completedTaskCount,
    super.key,
  });

  final Project project;
  final void Function(Project, bool?) onCheckboxChanged;

  /// Optional tap handler. If null, navigates to project detail via EntityNavigator.
  final void Function(Project)? onTap;

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
            : EntityNavigator.toProject(context, project.id),
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
                projectName: project.name,
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
                                  ? colorScheme.onSurface.withValues(alpha: 0.5)
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
                    LabelsSection(labels: project.labels),

                    // Dates row
                    DatesRow(
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
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom checkbox for projects with folder-style appearance and accessibility.
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
          ? 'Mark "$projectName" as incomplete'
          : 'Mark "$projectName" as complete',
      child: SizedBox(
        width: 28,
        height: 28,
        child: Checkbox(
          value: completed,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onChanged(value);
          },
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
