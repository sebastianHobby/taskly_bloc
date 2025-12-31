import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/tasks_list.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

class TaskOverviewPage extends StatelessWidget {
  const TaskOverviewPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskOverviewBloc>(
      create: (context) => TaskOverviewBloc(
        taskRepository: taskRepository,
        settingsRepository: settingsRepository,
        pageKey: pageKey,
        query: TaskQuery.all(),
      )..add(const TaskOverviewEvent.subscriptionRequested()),
      child: TaskOverviewView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class TaskOverviewView extends StatelessWidget {
  const TaskOverviewView({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
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
              labelRepository: labelRepository,
              taskId: taskId,
            ),
            child: TaskDetailSheet(labelRepository: labelRepository),
          ),
        ),
      ),
    );
  }

  void _onMenuSelected(BuildContext context, _TaskMenuAction action) {
    final bloc = context.read<TaskOverviewBloc>();
    switch (action) {
      case _TaskMenuAction.sortName:
        bloc.add(
          const TaskOverviewEvent.sortChanged(
            preferences: SortPreferences(
              criteria: [
                SortCriterion(field: SortField.name),
                SortCriterion(field: SortField.deadlineDate),
              ],
            ),
          ),
        );
      case _TaskMenuAction.sortDeadline:
        bloc.add(
          const TaskOverviewEvent.sortChanged(
            preferences: SortPreferences(
              criteria: [
                SortCriterion(field: SortField.deadlineDate),
                SortCriterion(field: SortField.name),
              ],
            ),
          ),
        );
    }
  }

  List<PopupMenuEntry<_TaskMenuAction>> _buildMenuItems({
    required AppLocalizations l10n,
    required TaskQuery selectedQuery,
  }) {
    SortField? activePrimaryField;
    if (selectedQuery.sortCriteria.isNotEmpty) {
      activePrimaryField = selectedQuery.sortCriteria.first.field;
    }

    return [
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.sortName,
        checked: activePrimaryField == SortField.name,
        child: Text(l10n.taskSortByName),
      ),
      CheckedPopupMenuItem<_TaskMenuAction>(
        value: _TaskMenuAction.sortDeadline,
        checked: activePrimaryField == SortField.deadlineDate,
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
                orElse: TaskQuery.all,
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
            initial: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            loaded: (tasks, query) => ResponsiveBody(
              child: TasksListView(
                tasks: tasks,
                onTap: (task) => _showTaskDetailSheet(
                  context,
                  taskId: task.id,
                ),
              ),
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
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

enum _TaskMenuAction {
  sortName,
  sortDeadline,
}
