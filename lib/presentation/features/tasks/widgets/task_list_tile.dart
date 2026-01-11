import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';

/// Legacy name retained temporarily.
///
/// Prefer using `TaskView` directly.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    required this.task,
    required this.onCheckboxChanged,
    this.onTap,
    this.compact = false,
    this.onNextActionRemoved,
    this.showNextActionIndicator = true,
    this.reasonText,
    this.reasonColor,
    super.key,
  });

  final Task task;
  final void Function(Task, bool?) onCheckboxChanged;
  final void Function(Task)? onTap;
  final bool compact;
  final void Function(Task)? onNextActionRemoved;
  final bool showNextActionIndicator;
  final String? reasonText;
  final Color? reasonColor;

  @override
  Widget build(BuildContext context) {
    return TaskView(
      task: task,
      onCheckboxChanged: onCheckboxChanged,
      onTap: onTap,
      compact: compact,
      onNextActionRemoved: onNextActionRemoved,
      showNextActionIndicator: showNextActionIndicator,
      reasonText: reasonText,
      reasonColor: reasonColor,
    );
  }
}
