import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/theme/allocation_theme.dart';

/// Hero card showing focus strategy and overall progress.
///
/// Displays current allocation strategy, total task count, and progress.
/// Can be tapped to expand and show configuration hint.
class FocusHeroCard extends StatefulWidget {
  const FocusHeroCard({
    required this.result,
    this.userName,
    super.key,
  });

  final AllocationSectionResult result;
  final String? userName;

  @override
  State<FocusHeroCard> createState() => _FocusHeroCardState();
}

class _FocusHeroCardState extends State<FocusHeroCard> {
  bool _isExpanded = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? '🌅 Good Morning'
        : hour < 17
        ? '🌤️ Good Afternoon'
        : '🌙 Good Evening';

    final name = widget.userName;
    return name != null && name.isNotEmpty
        ? '$timeGreeting, $name'
        : timeGreeting;
  }

  String _getIntentionPrompt() {
    final totalCount = _getTotalTaskCount();
    final valueCount = widget.result.tasksByValue.length;

    return 'Your focus today:\n$totalCount tasks across $valueCount values';
  }

  int _getTotalTaskCount() {
    final allTasks = [
      ...widget.result.pinnedTasks,
      ...widget.result.tasksByValue.values.expand((g) => g.tasks),
    ];
    return allTasks.length;
  }

  int _getCompletedCount() {
    final allTasks = [
      ...widget.result.pinnedTasks,
      ...widget.result.tasksByValue.values.expand((g) => g.tasks),
    ];
    return allTasks.where((at) => at.task.completed).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allocationTheme =
        theme.extension<AllocationTheme>() ??
        AllocationTheme.light(colorScheme);

    final completedCount = _getCompletedCount();
    final totalCount = _getTotalTaskCount();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shadowColor: colorScheme.primary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Part 1: Greeting (Option B)
              Text(
                _getGreeting(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getIntentionPrompt(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '💭 What matters most?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: completedCount == totalCount
                          ? allocationTheme.completionGreen.withValues(
                              alpha: 0.1,
                            )
                          : colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: completedCount == totalCount
                            ? allocationTheme.completionGreen
                            : colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$completedCount/$totalCount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: completedCount == totalCount
                            ? allocationTheme.completionGreen
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Expanded configuration panel
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Quick adjust hint
                Text(
                  'Quick Adjust',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAdjustHint(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAdjustHint(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap settings to adjust allocation strategy and value weights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
