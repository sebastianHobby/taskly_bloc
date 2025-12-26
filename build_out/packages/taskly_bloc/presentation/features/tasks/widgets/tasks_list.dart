import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

class TasksListView extends StatefulWidget {
  const TasksListView({
    required this.tasks,
    required this.onTap,
    this.displaySettings = const PageDisplaySettings(),
    this.onDisplaySettingsChanged,
    this.shrinkWrap = false,
    this.physics,
    this.enableSwipeToDelete = true,
    super.key,
  });

  final List<Task> tasks;
  final ValueChanged<Task> onTap;
  final PageDisplaySettings displaySettings;
  final ValueChanged<PageDisplaySettings>? onDisplaySettingsChanged;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool enableSwipeToDelete;

  @override
  State<TasksListView> createState() => _TasksListViewState();
}

class _TasksListViewState extends State<TasksListView> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskOverviewBloc>();

    // Separate tasks into active and completed
    final activeTasks = <Task>[];
    final completedTasks = <Task>[];

    for (final task in widget.tasks) {
      if (task.completed) {
        completedTasks.add(task);
      } else {
        activeTasks.add(task);
      }
    }

    // If hiding completed, only show active tasks
    if (widget.displaySettings.hideCompleted) {
      return _buildTasksList(context, activeTasks, bloc);
    }

    // Show both active and completed sections
    return ListView(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      children: [
        // Active tasks
        ...activeTasks.map((task) => _buildTaskItem(context, task, bloc)),

        // Completed section
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              initiallyExpanded:
                  !widget.displaySettings.completedSectionCollapsed,
              onExpansionChanged: (expanded) {
                widget.onDisplaySettingsChanged?.call(
                  widget.displaySettings.copyWith(
                    completedSectionCollapsed: !expanded,
                  ),
                );
              },
              leading: Icon(
                Icons.check_circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
              title: Text(
                'Completed (${completedTasks.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: completedTasks
                  .map((task) => _buildTaskItem(context, task, bloc))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTasksList(
    BuildContext context,
    List<Task> tasks,
    TaskOverviewBloc bloc,
  ) {
    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task, bloc);
      },
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Task task,
    TaskOverviewBloc bloc,
  ) {
    return SwipeToDelete(
      itemKey: ValueKey(task.id),
      enabled: widget.enableSwipeToDelete,
      confirmDismiss: () => showDeleteConfirmationDialog(
        context: context,
        title: 'Delete Task',
        itemName: task.name,
        description: 'This action cannot be undone.',
      ),
      onDismissed: () {
        bloc.add(TaskOverviewEvent.deleteTask(task: task));
        showDeleteSnackBar(
          context: context,
          message: 'Task deleted',
        );
      },
      child: TaskListTile(
        task: task,
        onCheckboxChanged: (task, isCompleted) {
          if (isCompleted != null) {
            bloc.add(
              TaskOverviewEvent.toggleTaskCompletion(
                task: task,
              ),
            );
          }
        },
        onTap: widget.onTap,
      ),
    );
  }
}
