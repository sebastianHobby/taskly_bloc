import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_progress.dart';

/// Displays workflow progress with visual indicator
class WorkflowProgressBar extends StatelessWidget {
  const WorkflowProgressBar({
    required this.progress,
    this.showPercentage = true,
    this.showCounts = true,
    super.key,
  });

  final WorkflowProgress progress;
  final bool showPercentage;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workflow Progress',
                  style: theme.textTheme.titleMedium,
                ),
                if (showPercentage)
                  Text(
                    '${progress.percentageReviewed.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.total > 0
                    ? progress.percentageReviewed / 100
                    : 0,
                minHeight: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            ),

            if (showCounts) ...[
              const SizedBox(height: 12),
              // Status counts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatusChip(
                    label: 'Completed',
                    count: progress.completed,
                    color: colorScheme.primary,
                  ),
                  _StatusChip(
                    label: 'Skipped',
                    count: progress.skipped,
                    color: colorScheme.tertiary,
                  ),
                  _StatusChip(
                    label: 'Pending',
                    count: progress.pending,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
