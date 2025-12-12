import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/tasks_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_item.dart';

import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

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
        create: (_) => TasksBloc(taskRepository: taskRepository),
        child: const TasksView(),
      ),
      floatingActionButton: const FloatingActionButton(
        tooltip: 'Add', // used by assistive technologies
        onPressed: null,
        child: Icon(Icons.add),
      ),
    );
  }
}

class TasksView extends StatelessWidget {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    //Todo add localization - just a shell so easy to add in future
    //final l10n = context.l10n;

    // Send event to request data stream subscription
    return BlocBuilder<TasksBloc, TasksState>(
      builder: (context, state) {
        switch (state) {
          case TasksInitial():
            context.read<TasksBloc>().add(
              const TasksSubscriptionRequested(),
            );

          case TasksLoading():
            return const Center(child: CircularProgressIndicator());
          case TasksLoaded():
            if (state.tasks.isEmpty) {
              return const Center(child: Text('No tasks found.'));
            }
            return ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks[index];
                return TaskListTile(task: task, key: super.key);
                //return TaskItem(task: task, key: super.key);
              },
            );
          case TasksError():
        }

        return const SizedBox();
      },
    );
  }
}
