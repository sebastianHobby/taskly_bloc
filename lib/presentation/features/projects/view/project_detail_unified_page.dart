import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/allocation/project_next_task_resolver.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_next_task_card.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

/// Unified project detail page using the screen model.
///
/// Fetches the project first, then creates a dynamic ScreenDefinition
/// and renders using the unified pattern.
class ProjectDetailUnifiedPage extends StatelessWidget {
  const ProjectDetailUnifiedPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectDetailBloc>(
      create: (_) => ProjectDetailBloc(
        projectRepository: getIt<ProjectRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
      )..add(ProjectDetailEvent.loadById(projectId: projectId)),
      child: _ProjectDetailContent(projectId: projectId),
    );
  }
}

class _ProjectDetailContent extends StatelessWidget {
  const _ProjectDetailContent({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailBloc, ProjectDetailState>(
      builder: (context, state) {
        return switch (state) {
          ProjectDetailInitial() ||
          ProjectDetailLoadInProgress() => const _LoadingScaffold(),
          ProjectDetailLoadSuccess(:final project) => _ProjectScreenWithData(
            project: project,
          ),
          ProjectDetailOperationFailure(:final errorDetails) => _ErrorScaffold(
            message: friendlyErrorMessageForUi(
              errorDetails.error,
              context.l10n,
            ),
            onRetry: () => context.read<ProjectDetailBloc>().add(
              ProjectDetailEvent.loadById(projectId: projectId),
            ),
          ),
          _ => const _LoadingScaffold(),
        };
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading...')),
      body: const LoadingStateWidget(),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: ErrorStateWidget(message: message, onRetry: onRetry),
    );
  }
}

/// Main content view when project is loaded
class _ProjectScreenWithData extends StatelessWidget {
  const _ProjectScreenWithData({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    // Create dynamic screen definition for this project
    final definition = SystemScreenDefinitions.forProject(
      projectId: project.id,
      projectName: project.name,
    );

    return BlocProvider<ScreenBloc>(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: _ProjectScreenView(project: project),
    );
  }
}

class _ProjectScreenView extends StatelessWidget {
  const _ProjectScreenView({required this.project});

  final Project project;

  void _showEditProjectSheet(BuildContext context) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => ProjectEditSheetPage(
          projectId: project.id,
          projectRepository: getIt<ProjectRepositoryContract>(),
          labelRepository: getIt<LabelRepositoryContract>(),
          onSaved: (savedProjectId) {
            // Refresh the project details after edit
            context.read<ProjectDetailBloc>().add(
              ProjectDetailEvent.loadById(projectId: savedProjectId),
            );
          },
        ),
        showDragHandle: true,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProjectAction),
        content: Text(
          'Are you sure you want to delete "${project.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<ProjectDetailBloc>().add(
        ProjectDetailEvent.delete(id: project.id),
      );
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'delete':
        unawaited(_showDeleteConfirmation(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entityActionService = getIt<EntityActionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.editLabel,
            onPressed: () => _showEditProjectSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deleteLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Entity header
          EntityHeader.project(
            project: project,
            onTap: () => _showEditProjectSheet(context),
            onCheckboxChanged: (value) {
              context.read<ProjectDetailBloc>().add(
                ProjectDetailEvent.update(
                  id: project.id,
                  name: project.name,
                  completed: value ?? !project.completed,
                ),
              );
            },
          ),

          // Task list via ScreenBloc
          Expanded(
            child: StreamBuilder<AllocationConfig>(
              stream: getIt<SettingsRepositoryContract>().watch(
                SettingsKey.allocation,
              ),
              builder: (context, configSnapshot) {
                final allocationConfig =
                    configSnapshot.data ?? const AllocationConfig();

                return BlocBuilder<ScreenBloc, ScreenState>(
                  builder: (context, state) {
                    return switch (state) {
                      ScreenInitialState() ||
                      ScreenLoadingState() => const LoadingStateWidget(),
                      ScreenLoadedState(:final data) => _buildTaskList(
                        context,
                        data,
                        entityActionService,
                        allocationConfig,
                      ),
                      ScreenErrorState(:final message) => ErrorStateWidget(
                        message: message,
                        onRetry: () => context.read<ScreenBloc>().add(
                          const ScreenEvent.refresh(),
                        ),
                      ),
                    };
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTaskFab(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
        defaultProjectId: project.id,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    ScreenData data,
    EntityActionService entityActionService,
    AllocationConfig allocationConfig,
  ) {
    final l10n = context.l10n;

    // Extract all incomplete tasks from sections for next task resolution
    final allTasks = <Task>[];
    for (final section in data.sections) {
      allTasks.addAll(section.result.allTasks);
    }
    final incompleteTasks = allTasks.where((t) => !t.completed).toList();

    // Resolve next task if enabled
    Task? nextTask;
    if (allocationConfig.displaySettings.showProjectNextTask &&
        incompleteTasks.isNotEmpty) {
      const resolver = ProjectNextTaskResolver();
      nextTask = resolver.getNextTask(
        project: project,
        projectTasks: incompleteTasks,
        focusTaskIds: const {}, // TODO: Could wire to actual focus tasks
        config: allocationConfig,
      );
    }

    if (data.sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: l10n.emptyTasksTitle,
        description: l10n.projectDetailEmptyTasksDescription,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ScreenBloc>().add(const ScreenEvent.refresh());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Next task recommendation card
          if (nextTask != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ProjectNextTaskCard(
                  task: nextTask,
                  onStartTap: () => _pinToFocus(context, nextTask!),
                  onTaskTap: () =>
                      Routing.toEntity(context, EntityType.task, nextTask!.id),
                ),
              ),
            ),
          // Task sections
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = data.sections[index];
                return SectionWidget(
                  section: section,
                  displayConfig: section.displayConfig,
                  onEntityTap: (entityId, entityType) {
                    Routing.toEntity(
                      context,
                      EntityType.fromString(entityType),
                      entityId,
                    );
                  },
                  onTaskCheckboxChanged: (task, value) async {
                    if (value ?? false) {
                      await entityActionService.completeTask(task.id);
                    } else {
                      await entityActionService.uncompleteTask(task.id);
                    }
                    if (context.mounted) {
                      context.read<ScreenBloc>().add(
                        const ScreenEvent.refresh(),
                      );
                    }
                  },
                  onTaskDelete: (task) async {
                    await entityActionService.deleteTask(task.id);
                    if (context.mounted) {
                      context.read<ScreenBloc>().add(
                        const ScreenEvent.refresh(),
                      );
                    }
                  },
                );
              },
              childCount: data.sections.length,
            ),
          ),
          // Bottom padding for FAB
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Future<void> _pinToFocus(BuildContext context, Task task) async {
    final entityActionService = getIt<EntityActionService>();
    await entityActionService.pinTask(task.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.taskPinnedToFocus(task.name))),
      );
      // Refresh to update the UI
      context.read<ScreenBloc>().add(const ScreenEvent.refresh());
    }
  }
}
