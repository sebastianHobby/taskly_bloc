import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/theme/app_colors.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    required this.progress,
    super.key,
    this.nextActionTitle,
  });
  final Project project;
  final double progress; // 0.0 to 1.0
  final String? nextActionTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TasklyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (nextActionTitle != null) ...[
            Text(
              'Next: $nextActionTitle',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
