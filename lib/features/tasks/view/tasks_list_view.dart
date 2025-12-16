import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/routing/routes.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});
  @override
  Widget build(BuildContext context) {
    final taskRepository = getIt<TaskRepository>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: BlocProvider(
        create: (_) => TaskListBloc(taskRepository: taskRepository),
        child: const TasksListView(),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        onPressed: () async {
          await context.push(
            Routes.editTaskModal,
          );
        }, // used by assistive technologies
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TasksListView extends StatelessWidget {
  const TasksListView({super.key});

  @override
  Widget build(BuildContext context) {
    //Todo add localization - just a shell so easy to add in future
    //final l10n = context.l10n;

    // Send event to request data stream subscription
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        return state.when(
          initial: () {
            context.read<TaskListBloc>().add(
              const TaskListEvent.subscriptionRequested(),
            );
            return const Center(child: CircularProgressIndicator());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (tasks) {
            if (tasks.isEmpty) {
              return const Center(child: Text('No tasks found.'));
            }
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskListTile(
                  task: task,
                  onCheckboxChanged: (task, _) {
                    context.read<TaskListBloc>().add(
                      TaskListEvent.toggleTaskCompletion(taskData: task),
                    );
                  },
                  onTap: (task) async {
                    await context.push(Routes.editTaskModal, extra: task);
                  },
                );
              },
            );
          },
          error: (message, stacktrace) => Center(child: Text(message)),
        );
      },
    );
  }
}
