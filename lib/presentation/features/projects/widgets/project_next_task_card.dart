import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Card highlighting the recommended next task for a project.
///
/// Shown at the top of project detail view when a recommendation exists.
/// Includes a "Start" button to pin the task to Focus.
class ProjectNextTaskCard extends StatelessWidget {
  const ProjectNextTaskCard({
    required this.task,
    required this.onStartTap,
    required this.onTaskTap,
    super.key,
  });

  /// The recommended task.
  final Task task;

  /// Called when "Start" is tapped - should pin task to Focus.
  final VoidCallback onStartTap;

  /// Called when task name is tapped - navigate to task detail.
  final VoidCallback onTaskTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recommendedNextActionLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onTaskTap,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.deadlineDate != null) ...[
                          const SizedBox(height: 4),
                          _DeadlineChip(
                            deadline: task.deadlineDate!,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onStartTap,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.startLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({
    required this.deadline,
    required this.colorScheme,
  });

  final DateTime deadline;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    final isUrgent = daysUntil <= 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: isUrgent
              ? colorScheme.error
              : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.deadlineFormatDays(daysUntil),
          style: TextStyle(
            fontSize: 12,
            color: isUrgent
                ? colorScheme.error
                : colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
