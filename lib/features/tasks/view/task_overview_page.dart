import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/data/repositories/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';

class TaskOverviewPage extends StatelessWidget {
  const TaskOverviewPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskOverviewBloc>(
          create: (context) => TaskOverviewBloc(
            taskRepository: taskRepository,
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
        BlocProvider<TaskDetailBloc>(
          create: (context) => TaskDetailBloc(
            taskRepository: taskRepository,
            projectRepository: projectRepository,
            valueRepository: valueRepository,
            labelRepository: labelRepository,
          ),
        ),
      ],
      child: const TaskOverviewView(),
    );
  }
}

class TaskOverviewView extends StatelessWidget {
  const TaskOverviewView({
    super.key,
  });

  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    showDetailModal<void>(
      context: context,
      childBuilder: (modalSheetContext) => SafeArea(
        top: false,
        child: BlocProvider.value(
          value: context.read<TaskDetailBloc>(),
          child: TaskDetailSheet(taskId: taskId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks) => TasksListView(
              tasks: tasks,
              onTap: (task) => _showTaskDetailSheet(context, taskId: task.id),
            ),
            error: (message, _) => Center(child: Text(message)),
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        onPressed: () => _showTaskDetailSheet(context),
      ),
    );
  }
}
