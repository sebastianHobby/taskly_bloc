import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    required this.completedTaskCount,
    required this.totalTaskCount,
    super.key,
    this.nextActionTitle,
  });

  final Project project;
  final int completedTaskCount;
  final int totalTaskCount;
  final String? nextActionTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine color
    final primaryValue = project.primaryValue;
    final progressColor = primaryValue != null
        ? ColorUtils.fromHexWithThemeFallback(context, primaryValue.color)
        : colorScheme.primary;

    final progress = totalTaskCount > 0
        ? completedTaskCount / totalTaskCount
        : 0.0;

    return TasklyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Body
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  color: progressColor,
                  strokeWidth: 5,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 16),
              // Stats and Next Action
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedTaskCount/$totalTaskCount Tasks',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (nextActionTitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next: $nextActionTitle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Footer
          if (project.primaryValue != null ||
              project.secondaryValues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ValuesFooter(
              primaryValue: project.primaryValue,
              secondaryValues: project.secondaryValues,
            ),
          ],
        ],
      ),
    );
  }
}
