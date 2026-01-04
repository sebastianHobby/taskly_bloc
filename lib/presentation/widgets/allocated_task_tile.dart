import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

/// Task list tile for allocated tasks in My Day view
/// Shows task with compact value icon badges
class AllocatedTaskTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = allocatedTask.task;

    final isOverdue = _isOverdue(task.deadlineDate);

    return Card(
      key: Key('task-${task.id}'),
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
      color: task.completed
          ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => onTap != null
            ? onTap!(task)
            : Routing.toEntity(context, EntityType.task, task.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
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
                    // Task name
                    Text(
                      task.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
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

                    // Value icon badges - compact, icon only
                    if (task.labels.any((l) => l.type == LabelType.value)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: task.labels
                            .where((l) => l.type == LabelType.value)
                            .take(3) // Max 3 icons
                            .map((label) => _CompactValueIcon(label: label))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

/// Compact value icon badge - icon only, no text
class _CompactValueIcon extends StatelessWidget {
  const _CompactValueIcon({required this.label});

  final Label label;

  @override
  Widget build(BuildContext context) {
    final emoji = label.iconName?.isNotEmpty ?? false ? label.iconName! : '⭐';

    return Tooltip(
      message: label.name,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          emoji,
          style: EmojiUtils.emojiTextStyle(fontSize: 14),
        ),
      ),
    );
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
      width: 24,
      height: 24,
      child: Checkbox(
        value: completed,
        onChanged: onChanged,
        shape: const CircleBorder(),
        side: BorderSide(
          color: isOverdue ? colorScheme.error : colorScheme.outline,
          width: 2,
        ),
      ),
    );
  }
}
