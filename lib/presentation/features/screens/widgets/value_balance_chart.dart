import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class ValueBalanceChart extends StatelessWidget {
  const ValueBalanceChart({
    required this.tasksByValue,
    super.key,
  });

  final Map<String, AllocationValueGroup> tasksByValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalTasks = tasksByValue.values.fold<int>(
      0,
      (sum, group) => sum + group.tasks.length,
    );

    return TasklyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value Balance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (tasksByValue.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No tasks allocated yet',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Column(
              children: tasksByValue.values.map((group) {
                final percentage = totalTasks > 0
                    ? group.tasks.length / totalTasks
                    : 0.0;

                // Parse color string or default to primary
                // Assuming color comes as hex string or similar, but for now using a safe default
                // if parsing logic isn't readily available in this context.
                // Ideally we'd use a helper to parse the color string from the group.
                final color = colorScheme.primary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.valueName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${group.tasks.length} tasks',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
