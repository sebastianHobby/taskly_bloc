import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';

class TaskOverviewPage extends StatelessWidget {
  const TaskOverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final taskRepository = getIt<TaskRepository>();
    return BlocProvider(
      create: (_) =>
          TaskOverviewBloc(taskRepository: taskRepository)
            ..add(const TaskOverviewEvent.subscriptionRequested()),
      child: const TaskOverviewView(),
    );
  }
}

class TaskOverviewView extends StatelessWidget {
  const TaskOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    // Todo: add localization - this is a simple shell for now.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks) => TasksList(tasks, context),
            error: (message, _) => Center(child: Text(message)),
          );
        },
      ),
      floatingActionButton: AddTaskFab(context: context),
    );
  }
}
