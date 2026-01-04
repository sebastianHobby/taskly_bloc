import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/shared/utils/rrule_display_utils.dart';

/// Task list tile for allocated tasks in My Day view
/// Shows task with compact value icon badges
class AllocatedTaskTile extends StatefulWidget {
  const AllocatedTaskTile({
    required this.allocatedTask,
    required this.onCheckboxChanged,
    this.onTap,
    super.key,
  });

  final AllocatedTask allocatedTask;
  final void Function(Task, bool?) onCheckboxChanged;
  final void Function(Task)? onTap;

  @override
  State<AllocatedTaskTile> createState() => _AllocatedTaskTileState();
}

class _AllocatedTaskTileState extends State<AllocatedTaskTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = widget.allocatedTask.task;

    final isOverdue = _isOverdue(task.deadlineDate);
    final isDueToday = _isDueToday(task.deadlineDate);
    final valueLabels = task.labels
        .where((l) => l.type == LabelType.value)
        .toList();
    final hasMetadata =
        task.deadlineDate != null || task.startDate != null || task.isRepeating;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        key: Key('task-${task.id}'),
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : isOverdue
              ? colorScheme.errorContainer.withValues(alpha: 0.05)
              : null,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          borderRadius: _isHovered
              ? BorderRadius.circular(8)
              : BorderRadius.zero,
        ),
        child: InkWell(
          onTap: () => widget.onTap != null
              ? widget.onTap!(task)
              : Routing.toEntity(context, EntityType.task, task.id),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Checkbox and Task Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox
                    _TaskCheckbox(
                      completed: task.completed,
                      isOverdue: isOverdue,
                      onChanged: (value) =>
                          widget.onCheckboxChanged(task, value),
                    ),
                    const SizedBox(width: 12),
                    // Task name
                    Expanded(
                      child: Text(
                        task.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
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
                  ],
                ),

                // Row 2: Metadata (dates, values, project)
                if (hasMetadata || valueLabels.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // 1. Start Date
                        if (task.startDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '📅',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.startDate!),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 2. Deadline
                        if (task.deadlineDate != null) ...[
                          if (task.startDate != null)
                            Icon(
                              Icons.arrow_forward,
                              size: 10,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isOverdue
                                          ? colorScheme.errorContainer
                                          : isDueToday
                                          ? colorScheme.tertiaryContainer
                                          : colorScheme.secondaryContainer)
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🚩',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDeadline(
                                    task.deadlineDate!,
                                    isOverdue,
                                    isDueToday,
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isOverdue
                                        ? colorScheme.error
                                        : isDueToday
                                        ? colorScheme.tertiary
                                        : colorScheme.secondary,
                                    fontWeight: isOverdue || isDueToday
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 3. Value emojis
                        if (valueLabels.isNotEmpty) ...[
                          if (task.startDate != null ||
                              task.deadlineDate != null)
                            Text(
                              '•',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: valueLabels
                                .take(3)
                                .map(
                                  (label) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Text(
                                      label.iconName ?? '⭐',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],

                        // 4. Recurrence
                        if (task.isRepeating) ...[
                          if (task.startDate != null ||
                              task.deadlineDate != null ||
                              valueLabels.isNotEmpty)
                            Text(
                              '•',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                RruleDisplayUtils.formatRrule(
                                  context,
                                  task.repeatIcalRrule,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 5. Project (flows inline, naturally positions right on wider screens)
                        if (task.project != null) ...[
                          if (task.startDate != null ||
                              task.deadlineDate != null ||
                              valueLabels.isNotEmpty ||
                              task.isRepeating)
                            Text(
                              '•',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.3,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.project!.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDueToday(DateTime? deadlineDate) {
    if (deadlineDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );
    return deadline.isAtSameMomentAs(today);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay.isAtSameMomentAs(today)) return 'Today';

    final tomorrow = today.add(const Duration(days: 1));
    if (dateDay.isAtSameMomentAs(tomorrow)) return 'Tomorrow';

    final yesterday = today.subtract(const Duration(days: 1));
    if (dateDay.isAtSameMomentAs(yesterday)) return 'Yesterday';

    // Within a week (forward or backward)
    final daysAway = dateDay.difference(today).inDays.abs();
    if (daysAway <= 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    }

    // Format as "Jan 15"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDeadline(DateTime deadline, bool isOverdue, bool isDueToday) {
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Today';

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final tomorrowDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    if (deadlineDay.isAtSameMomentAs(tomorrowDay)) return 'Tomorrow';

    // Within a week
    final daysUntil = deadlineDay
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (daysUntil <= 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[deadline.weekday - 1];
    }

    // Format as "Jan 15"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[deadline.month - 1]} ${deadline.day}';
  }

  bool _isOverdue(DateTime? deadlineDate) {
    if (deadlineDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );
    return deadline.isBefore(today);
  }
}

/// Custom checkbox for tasks
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: completed,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: isOverdue ? colorScheme.error : colorScheme.outline,
          width: 2,
        ),
      ),
    );
  }
}
