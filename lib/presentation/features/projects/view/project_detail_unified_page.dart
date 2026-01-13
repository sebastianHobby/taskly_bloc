import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_spec_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
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
        header: [
          ScreenModuleSpec.entityHeader(
            params: EntityHeaderSectionParams(
              entityType: 'project',
              entityId: project.id,
              showCheckbox: true,
              showMetadata: true,
            ),
          ),
        ],
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
      body: BlocBuilder<ScreenSpecBloc, ScreenSpecState>(
        builder: (context, state) {
          return switch (state) {
            ScreenSpecInitialState() ||
            ScreenSpecLoadingState() => const LoadingStateWidget(),
            ScreenSpecLoadedState(:final data) => _buildBody(
              context,
              data,
              entityActionService,
            ),
            ScreenSpecErrorState(:final message) => ErrorStateWidget(
              message: message,
              onRetry: () => Navigator.of(context).pop(),
            ),
          };
        },
      ),
      floatingActionButton: AddTaskFab(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        defaultProjectId: project.id,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScreenSpecData data,
    EntityActionService entityActionService,
  ) {
    final l10n = context.l10n;

    final sections = [
      ...data.sections.header,
      ...data.sections.primary,
    ];

    if (sections.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: l10n.emptyTasksTitle,
        description: l10n.projectDetailEmptyTasksDescription,
      );
    }

    return CustomScrollView(
      slivers: [
        for (final section in sections)
          SectionWidget(
            section: section,
            displayConfig: section.displayConfig,
            onEntityHeaderTap: () => _showEditProjectSheet(context),
            onEntityTap: (entity) {
              if (entity is Task) {
                Routing.toEntity(context, EntityType.task, entity.id);
              } else if (entity is Project) {
                Routing.toEntity(context, EntityType.project, entity.id);
              }
            },
            onProjectCheckboxChanged: (project, value) {
              if (value ?? false) {
                unawaited(entityActionService.completeProject(project.id));
              } else {
                unawaited(entityActionService.uncompleteProject(project.id));
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
            onProjectDelete: (project) {
              unawaited(entityActionService.deleteProject(project.id));
            },
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}
