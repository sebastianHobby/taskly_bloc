import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/features/projects/view/project_detail_view.dart';
import 'package:taskly_bloc/features/tasks/tasks.dart';

/// Full-screen project page showing the project details and its related tasks.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    required this.projectRepository,
    required this.taskRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final String projectId;
  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectDetailBloc>(
          create: (_) => ProjectDetailBloc(
            projectRepository: projectRepository,
            valueRepository: valueRepository,
            labelRepository: labelRepository,
          )..add(ProjectDetailEvent.get(projectId: projectId)),
        ),
        BlocProvider<TaskOverviewBloc>(
          create: (_) => TaskOverviewBloc(
            taskRepository: taskRepository,
            initialQuery: TaskListQuery(projectId: projectId),
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
      ],
      child: ProjectDetailPageView(
        projectId: projectId,
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        valueRepository: valueRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class ProjectDetailPageView extends StatelessWidget {
  const ProjectDetailPageView({
    required this.projectId,
    required this.projectRepository,
    required this.taskRepository,
    required this.valueRepository,
    required this.labelRepository,
    super.key,
  });

  final String projectId;
  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final ValueRepositoryContract valueRepository;
  final LabelRepositoryContract labelRepository;

  void _showEditProjectSheet(BuildContext context) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: projectRepository,
          valueRepository: valueRepository,
          labelRepository: labelRepository,
          onSuccess: (message) {
            Navigator.of(modalSheetContext).pop();
            context.read<ProjectDetailBloc>().add(
              ProjectDetailEvent.get(projectId: projectId),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          onError: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        ),
        showDragHandle: true,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailBloc, ProjectDetailState>(
      builder: (context, state) {
        return state.when(
          initial: () => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          loadInProgress: () => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          initialDataLoadSuccess: (_, _) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          loadSuccess: (_, _, project) => Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.projectsTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProjectSheet(context),
                ),
              ],
            ),
            body: Column(
              children: [
                _ProjectHeader(project: project),
                const Divider(height: 1),
                Expanded(
                  child: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
                    builder: (context, state) {
                      return state.when(
                        initial: () =>
                            const Center(child: CircularProgressIndicator()),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        loaded: (tasks, _) => TasksListView(
                          tasks: tasks,
                          onTap: (task) =>
                              _showTaskDetailSheet(context, taskId: task.id),
                        ),
                        error: (error, _) => Center(
                          child: Text(
                            friendlyErrorMessageForUi(error, context.l10n),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          operationSuccess: (_) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          operationFailure: (details) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: Center(
              child: Text(
                friendlyErrorMessageForUi(details.error, context.l10n),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    String formatDate(DateTime value) => localizations.formatShortDate(value);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                project.completed
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.name,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (project.values.isNotEmpty || project.labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...project.values.map(
                  (v) => Chip(
                    label: Text(v.name),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                ...project.labels.map(
                  (l) => Chip(
                    label: Text(l.name),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
          if (project.description != null &&
              project.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                project.description!.trim(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (project.startDate != null || project.deadlineDate != null) ...[
            const SizedBox(height: 12),
            if (project.startDate != null)
              Row(
                children: [
                  const Icon(Icons.play_arrow_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatDate(project.startDate!),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (project.deadlineDate != null)
              Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formatDate(project.deadlineDate!),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
          if (project.repeatIcalRrule != null &&
              project.repeatIcalRrule!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.repeatIcalRrule!.trim(),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
