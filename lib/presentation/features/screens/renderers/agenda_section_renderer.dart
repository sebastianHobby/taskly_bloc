import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

class AgendaSectionRenderer extends StatelessWidget {
  const AgendaSectionRenderer({
    required this.data,
    this.onTaskToggle,
    this.onTaskTap,
    super.key,
  });

  final AgendaSectionResult data;
  final void Function(String taskId, bool? value)? onTaskToggle;
  final void Function(Task task)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (data.groupOrder.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No scheduled tasks'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.groupOrder.length,
      itemBuilder: (context, index) {
        final groupKey = data.groupOrder[index];
        final tasks = data.groupedTasks[groupKey] ?? [];

        if (tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, groupKey),
            ...tasks.map(
              (task) => TaskListTile(
                task: task,
                onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
                onTap: (t) => onTaskTap?.call(t),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
