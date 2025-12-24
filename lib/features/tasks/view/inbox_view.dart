import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/widgets/sort_bottom_sheet.dart';
import 'package:taskly_bloc/features/tasks/widgets/tasks_list.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/core/shared/widgets/empty_state_widget.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.sortAdapter,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final PageSortAdapter sortAdapter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskOverviewBloc>(
      create: (context) => TaskOverviewBloc(
        taskRepository: taskRepository,
        initialConfig: TaskSelector.inbox(),
        withRelated: true,
        sortAdapter: sortAdapter,
      )..add(const TaskOverviewEvent.subscriptionRequested()),
      child: InboxView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class InboxView extends StatefulWidget {
  const InboxView({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.inboxTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: context.l10n.sortMenuTitle,
            onPressed: _openGroupSortSheet,
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
            loaded: (tasks, query) {
              if (tasks.isEmpty) {
                return EmptyStateWidget.inbox(
                  title: context.l10n.emptyInboxTitle,
                  description: context.l10n.emptyInboxDescription,
                );
              }
              return TasksListView(
                tasks: tasks,
                onTap: (task) => _showTaskDetailSheet(
                  context,
                  taskId: task.id,
                ),
              );
            },
            error: (error, _) => Center(
              child: Text(
                friendlyErrorMessageForUi(error, context.l10n),
              ),
            ),
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        taskRepository: widget.taskRepository,
        projectRepository: widget.projectRepository,
        labelRepository: widget.labelRepository,
      ),
    );
  }

  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: widget.taskRepository,
              projectRepository: widget.projectRepository,
              labelRepository: widget.labelRepository,
              taskId: taskId,
            ),
            child: TaskDetailSheet(labelRepository: widget.labelRepository),
          ),
        ),
      ),
    );
  }

  Future<void> _openGroupSortSheet() async {
    final bloc = context.read<TaskOverviewBloc>();
    final currentQuery = bloc.state.maybeWhen(
      loaded: (_, config) => config,
      orElse: TaskSelector.all,
    );

    await showSortBottomSheet(
      context: context,
      current: SortPreferences(criteria: currentQuery.sortCriteria),
      availableSortFields: const [
        SortField.deadlineDate,
        SortField.startDate,
        SortField.name,
      ],
      onChanged: (updated) {
        bloc.add(
          TaskOverviewEvent.sortChanged(preferences: updated),
        );
      },
    );
  }
}
