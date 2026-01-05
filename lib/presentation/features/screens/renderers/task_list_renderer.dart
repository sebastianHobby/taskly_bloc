import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

class TaskListRenderer extends StatelessWidget {
  const TaskListRenderer({
    required this.data,
    super.key,
    this.title,
    this.onTaskToggle,
  });
  final DataSectionResult data;
  final String? title;
  final void Function(String, bool?)? onTaskToggle;

  @override
  Widget build(BuildContext context) {
    // Cast primaryEntities to List<Task> safely
    final tasks = data.primaryEntities.whereType<Task>().toList();

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TasklyHeader(title: title!),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskListTile(
              task: task,
              onCheckboxChanged: (t, val) {
                onTaskToggle?.call(t.id, val);
              },
            );
          },
        ),
      ],
    );
  }
}
