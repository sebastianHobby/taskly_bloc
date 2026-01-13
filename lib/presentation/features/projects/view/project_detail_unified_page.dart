import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/allocation/engine/project_next_task_resolver.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_next_task_card.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/entity_header.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

/// Unified project detail page using the screen model.
///
/// Fetches the project first, then creates a typed [ScreenSpec]
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
        valueRepository: getIt<ValueRepositoryContract>(),
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
    final spec = ScreenSpec(
      id: 'project_${project.id}',
      screenKey: 'project_detail',
      name: project.name,
      template: const ScreenTemplateSpec.standardScaffoldV1(),
      modules: SlottedModules(
        primary: [
          ScreenModuleSpec.taskListV2(
            title: 'Tasks',
            params: ListSectionParamsV2(
              config: DataConfig.task(
                query: TaskQuery.forProject(projectId: project.id),
              ),
              pack: StylePackV2.standard,
              layout: const SectionLayoutSpecV2.flatList(
                separator: ListSeparatorV2.divider,
              ),
            ),
          ),
        ],
      ),
    );

    return BlocProvider<ScreenSpecBloc>(
      create: (_) => ScreenSpecBloc(
        interpreter: getIt(),
      )..add(ScreenSpecLoadEvent(spec: spec)),
      child: BlocListener<ScreenSpecBloc, ScreenSpecState>(
        listenWhen: (previous, current) {
          return previous is! ScreenSpecLoadedState &&
              current is ScreenSpecLoadedState;
        },
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            getIt<PerformanceLogger>().markFirstPaint();
          });
        },
        child: _ProjectScreenView(project: project),
      ),
    );
  }
}

class _ProjectScreenView extends StatelessWidget {
  const _ProjectScreenView({required this.project});

  final Project project;

  void _showEditProjectSheet(BuildContext context) {
    final launcher = EditorLauncher.fromGetIt();
    unawaited(
      launcher.openProjectEditor(
        context,
        projectId: project.id,
        onSaved: (savedProjectId) {
          // Refresh the project details after edit
          context.read<ProjectDetailBloc>().add(
            ProjectDetailEvent.loadById(projectId: savedProjectId),
          );
        },
        showDragHandle: true,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: l10n.deleteProjectAction,
      itemName: project.name,
      description: l10n.deleteProjectCascadeDescription,
    );

    if (confirmed && context.mounted) {
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

                return BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
                  builder: (context, state) {
                    return switch (state) {
                      ScreenSpecInitialState() ||
                      ScreenSpecLoadingState() => const LoadingStateWidget(),
                      ScreenSpecLoadedState(:final data) => _buildTaskList(
                        context,
                        data,
                        entityActionService,
                        allocationConfig,
                      ),
                      ScreenSpecErrorState(:final message) => ErrorStateWidget(
                        message: message,
                        onRetry: () => Navigator.of(context).pop(),
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
        valueRepository: getIt<ValueRepositoryContract>(),
        defaultProjectId: project.id,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    ScreenSpecData data,
    EntityActionService entityActionService,
    AllocationConfig allocationConfig,
  ) {
    final l10n = context.l10n;

    final sections = [
      ...data.sections.header,
      ...data.sections.primary,
    ];

    // Extract all incomplete tasks from sections for next task resolution
    final allTasks = <Task>[];
    for (final section in sections) {
      final result = section.data;
      if (result is SectionDataResult) {
        allTasks.addAll(result.allTasks);
      }
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

    if (sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: l10n.emptyTasksTitle,
        description: l10n.projectDetailEmptyTasksDescription,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Data updates automatically via reactive streams
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Next task recommendation card
          if (nextTask != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ProjectNextTaskCard(
                  task: nextTask,
                  onStartTap: () {
                    final task = nextTask;
                    if (task == null) return;
                    _pinToFocus(context, task);
                  },
                  onTaskTap: () {
                    final task = nextTask;
                    if (task == null) return;
                    Routing.toEntity(context, EntityType.task, task.id);
                  },
                ),
              ),
            ),
          // Task sections
          for (final section in sections)
            SectionWidget(
              section: section,
              displayConfig: section.displayConfig,
              onEntityTap: (entity) {
                if (entity is Task) {
                  Routing.toEntity(
                    context,
                    EntityType.task,
                    entity.id,
                  );
                } else if (entity is Project) {
                  Routing.toEntity(
                    context,
                    EntityType.project,
                    entity.id,
                  );
                }
              },
              onTaskCheckboxChanged: (task, value) async {
                if (value ?? false) {
                  await entityActionService.completeTask(task.id);
                } else {
                  await entityActionService.uncompleteTask(task.id);
                }
              },
              onTaskDelete: (task) async {
                await entityActionService.deleteTask(task.id);
              },
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
    }
  }
}
