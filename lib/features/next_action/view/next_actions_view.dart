import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/core/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/next_action/bloc/next_actions_bloc.dart';
import 'package:taskly_bloc/features/tasks/tasks.dart';
import 'package:taskly_bloc/routing/routes.dart';

/// Full-screen project page showing all projects and filtered list of next
/// action tasks.
class TaskNextActionsPage extends StatelessWidget {
  const TaskNextActionsPage({
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NextActionsBloc>(
      create: (context) => NextActionsBloc(
        taskRepository: taskRepository,
        settingsAdapter: getIt<NextActionsSettingsAdapter>(),
      )..add(const NextActionsSubscriptionRequested()),
      child: TaskNextActionsView(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class TaskNextActionsView extends StatelessWidget {
  const TaskNextActionsView({
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    super.key,
  });

  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;

  void _showTaskDetailSheet(BuildContext context, {required String taskId}) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.nextActionsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed(
              AppRouteName.taskNextActionsSettings,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: BlocBuilder<NextActionsBloc, NextActionsState>(
        builder: (context, state) {
          if (state.status == NextActionsStatus.initial ||
              state.status == NextActionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NextActionsStatus.failure) {
            return Center(
              child: Text(
                friendlyErrorMessageForUi(
                  state.error ?? 'Failed to load next actions',
                  context.l10n,
                ),
              ),
            );
          }

          if (state.groups.isEmpty) {
            return Center(child: Text(context.l10n.taskNotFound));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final group = state.groups[index];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...group.projects.map((projectGroup) {
                    final project = projectGroup.project;
                    final tasksForProject = projectGroup.tasks;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await context.pushNamed(
                                    AppRouteName.projectDetail,
                                    pathParameters: {
                                      'projectId': project.id,
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    project.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              for (final task in tasksForProject) ...[
                                TaskListTile(
                                  task: task,
                                  onCheckboxChanged: (task, isCompleted) {
                                    if (isCompleted == null) return;
                                    context.read<NextActionsBloc>().add(
                                      NextActionsTaskToggled(task),
                                    );
                                  },
                                  onTap: (_) => _showTaskDetailSheet(
                                    context,
                                    taskId: task.id,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
