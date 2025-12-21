import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';
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
      ],
      child: TaskOverviewView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class TaskOverviewView extends StatelessWidget {
  const TaskOverviewView({
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

  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              valueRepository: valueRepository,
              labelRepository: labelRepository,
              taskId: taskId,
            ),
            child: const TaskDetailSheet(),
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(BuildContext context, _TaskMenuAction action) {
    final bloc = context.read<TaskOverviewBloc>();
    final currentQuery = bloc.state.maybeWhen(
      loaded: (_, query) => query,
      orElse: () => TaskListQuery.all,
    );
    switch (action) {
      case _TaskMenuAction.filterAll:
        bloc.add(
          TaskOverviewEvent.queryChanged(
            query: currentQuery.copyWith(completion: TaskCompletionFilter.all),
          ),
        );
      case _TaskMenuAction.filterActive:
        bloc.add(
          TaskOverviewEvent.queryChanged(
            query: currentQuery.copyWith(
              completion: TaskCompletionFilter.active,
            ),
          ),
        );
      case _TaskMenuAction.filterCompleted:
        bloc.add(
          TaskOverviewEvent.queryChanged(
            query: currentQuery.copyWith(
              completion: TaskCompletionFilter.completed,
            ),
          ),
        );
      case _TaskMenuAction.sortName:
        bloc.add(
          TaskOverviewEvent.queryChanged(
            query: currentQuery.copyWith(sort: TaskSort.name),
          ),
        );
      case _TaskMenuAction.sortDeadline:
        bloc.add(
          TaskOverviewEvent.queryChanged(
            query: currentQuery.copyWith(sort: TaskSort.deadline),
          ),
        );
    }
  }

  List<PopupMenuEntry<_TaskMenuAction>> _buildMenuItems({
    required AppLocalizations l10n,
    required TaskListQuery selectedQuery,
  }) {
    return [
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.filterAll,
        checked: selectedQuery.completion == TaskCompletionFilter.all,
        child: Text(l10n.taskFilterAll),
      ),
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.filterActive,
        checked: selectedQuery.completion == TaskCompletionFilter.active,
        child: Text(l10n.taskFilterActive),
      ),
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.filterCompleted,
        checked: selectedQuery.completion == TaskCompletionFilter.completed,
        child: Text(l10n.taskFilterCompleted),
      ),
      const PopupMenuDivider(),
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.sortName,
        checked: selectedQuery.sort == TaskSort.name,
        child: Text(l10n.taskSortByName),
      ),
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.sortDeadline,
        checked: selectedQuery.sort == TaskSort.deadline,
        child: Text(l10n.taskSortByDeadline),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasksTitle),
        actions: [
          BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
            buildWhen: (previous, current) {
              final previousSelection = previous.maybeWhen(
                loaded: (_, query) => query,
                orElse: () => null,
              );
              final currentSelection = current.maybeWhen(
                loaded: (_, query) => query,
                orElse: () => null,
              );
              return previousSelection != currentSelection;
            },
            builder: (context, state) {
              final selectedQuery = state.maybeWhen(
                loaded: (_, query) => query,
                orElse: () => TaskListQuery.all,
              );
              return PopupMenuButton<_TaskMenuAction>(
                onSelected: (action) => _onMenuSelected(context, action),
                itemBuilder: (_) => _buildMenuItems(
                  l10n: context.l10n,
                  selectedQuery: selectedQuery,
                ),
                icon: const Icon(Icons.tune),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (tasks, query) => TasksListView(
              tasks: tasks,
              onTap: (task) => _showTaskDetailSheet(context, taskId: task.id),
            ),
            error: (error, _) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        onPressed: () => _showTaskDetailSheet(context),
      ),
    );
  }
}

enum _TaskMenuAction {
  filterAll,
  filterActive,
  filterCompleted,
  sortName,
  sortDeadline,
}
