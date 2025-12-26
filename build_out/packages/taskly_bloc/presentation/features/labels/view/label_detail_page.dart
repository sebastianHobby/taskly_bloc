import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/section_header.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/labels/view/label_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/tasks.dart';
import 'package:taskly_bloc/core/routing/routes.dart';

class LabelDetailPage extends StatelessWidget {
  const LabelDetailPage({
    required this.labelId,
    required this.labelRepository,
    required this.taskRepository,
    required this.projectRepository,
    super.key,
  });

  final String labelId;
  final LabelRepositoryContract labelRepository;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LabelDetailBloc>(
          create: (_) => LabelDetailBloc(
            labelRepository: labelRepository,
            labelId: labelId,
          ),
        ),
        BlocProvider<TaskOverviewBloc>(
          create: (_) => TaskOverviewBloc(
            taskRepository: taskRepository,
            query: TaskQuery.forLabel(
              labelId: labelId,
            ),
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
      ],
      child: _LabelDetailView(
        labelId: labelId,
        labelRepository: labelRepository,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
      ),
    );
  }
}

enum _MenuAction { edit }

class _LabelDetailView extends StatelessWidget {
  const _LabelDetailView({
    required this.labelId,
    required this.labelRepository,
    required this.taskRepository,
    required this.projectRepository,
  });

  final String labelId;
  final LabelRepositoryContract labelRepository;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;

  void _showEditLabelSheet(BuildContext context) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: LabelDetailSheetPage(
            labelId: labelId,
            labelRepository: labelRepository,
            onSaved: (savedLabelId) {
              // Refresh the label details after edit
              context.read<LabelDetailBloc>().add(
                LabelDetailEvent.get(labelId: savedLabelId),
              );
            },
          ),
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
              labelRepository: labelRepository,
              taskId: taskId,
            ),
            child: TaskDetailSheet(labelRepository: labelRepository),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LabelDetailBloc, LabelDetailState>(
      builder: (context, state) {
        return state.when(
          initial: () => Scaffold(
            appBar: AppBar(title: Text(context.l10n.labelsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          loadInProgress: () => Scaffold(
            appBar: AppBar(title: Text(context.l10n.labelsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          loadSuccess: (label) => Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.labelsTitle),
              actions: [
                PopupMenuButton<_MenuAction>(
                  onSelected: (value) {
                    switch (value) {
                      case _MenuAction.edit:
                        _showEditLabelSheet(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _MenuAction.edit,
                      child: Text(context.l10n.actionUpdate),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                _Header(
                  title: label.name,
                  onTap: () => _showEditLabelSheet(context),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _RelatedLists(
                    labelId: labelId,
                    projectRepository: projectRepository,
                    onTapTask: (task) => _showTaskDetailSheet(
                      context,
                      taskId: task.id,
                    ),
                    onTapProject: (project) async {
                      await context.pushNamed(
                        AppRouteName.projectDetail,
                        pathParameters: {'projectId': project.id},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          operationSuccess: (_) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.labelsTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          operationFailure: (details) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.labelsTitle)),
            body: Center(
              child: Text(
                friendlyErrorMessageForUi(
                  details.error,
                  context.l10n,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.label_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tap to edit',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelatedLists extends StatelessWidget {
  const _RelatedLists({
    required this.labelId,
    required this.projectRepository,
    required this.onTapTask,
    required this.onTapProject,
  });

  final String labelId;
  final ProjectRepositoryContract projectRepository;
  final ValueChanged<Task> onTapTask;
  final ValueChanged<Project> onTapProject;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
      builder: (context, tasksState) {
        return tasksState.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              friendlyErrorMessageForUi(error, context.l10n),
            ),
          ),
          loaded: (tasks, _) {
            final taskBloc = context.read<TaskOverviewBloc>();

            return StreamBuilder<List<Project>>(
              stream: projectRepository.watchAll(withRelated: true),
              builder: (context, snapshot) {
                final projects = (snapshot.data ?? const <Project>[])
                    .where((p) => p.labels.any((l) => l.id == labelId))
                    .toList(growable: false);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      if (tasks.isNotEmpty)
                        SectionHeader.simple(title: context.l10n.tasksTitle),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskListTile(
                            task: task,
                            onCheckboxChanged: (task, isCompleted) {
                              if (isCompleted != null) {
                                taskBloc.add(
                                  TaskOverviewEvent.toggleTaskCompletion(
                                    task: task,
                                  ),
                                );
                              }
                            },
                            onTap: onTapTask,
                          );
                        },
                      ),
                      if (projects.isNotEmpty)
                        SectionHeader.simple(title: context.l10n.projectsTitle),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return ListTile(
                            title: Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => onTapProject(project),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
