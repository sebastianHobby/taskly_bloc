import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/add_label_fab.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

/// Unified page for rendering all screen types.
///
/// This is the single rendering path for both system screens (Inbox, Today)
/// and user-created screens via ScreenBuilder.
class UnifiedScreenPage extends StatelessWidget {
  const UnifiedScreenPage({
    required this.definition,
    super.key,
  });

  /// The screen definition to render.
  final ScreenDefinition definition;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: const _UnifiedScreenView(),
    );
  }
}

/// Alternative constructor for loading by screen ID.
class UnifiedScreenPageById extends StatelessWidget {
  const UnifiedScreenPageById({
    required this.screenId,
    super.key,
  });

  final String screenId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.loadById(screenId: screenId)),
      child: const _UnifiedScreenView(),
    );
  }
}

class _UnifiedScreenView extends StatelessWidget {
  const _UnifiedScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenBloc, ScreenState>(
      builder: (context, state) {
        return switch (state) {
          ScreenInitialState() => const _LoadingView(),
          ScreenLoadingState(:final definition) => _LoadingView(
            title: definition?.name,
          ),
          ScreenLoadedState(:final data, :final isRefreshing) => _LoadedView(
            data: data,
            isRefreshing: isRefreshing,
          ),
          ScreenErrorState(:final message, :final definition) => _ErrorView(
            message: message,
            definition: definition,
          ),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.data,
    required this.isRefreshing,
  });

  final ScreenData data;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final entityActionService = getIt<EntityActionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(data.definition.name),
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ScreenBloc>().add(const ScreenEvent.refresh());
          // Wait a bit for the refresh to complete
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: _ScreenContent(
          data: data,
          entityActionService: entityActionService,
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  /// Builds FAB based on screen definition's fabOperations.
  Widget? _buildFab(BuildContext context) {
    final operations = data.definition.fabOperations;

    // No FAB if no operations defined
    if (operations.isEmpty) return null;

    // Single operation = single FAB
    // TODO: Support multiple operations with SpeedDial in future
    return _buildSingleFab(context, operations.first);
  }

  Widget _buildSingleFab(BuildContext context, FabOperation operation) {
    return switch (operation) {
      FabOperation.createTask => AddTaskFab(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
      ),
      FabOperation.createProject => AddProjectFab(
        projectRepository: getIt<ProjectRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
      ),
      FabOperation.createLabel => AddLabelFab(
        labelRepository: getIt<LabelRepositoryContract>(),
        initialType: LabelType.label,
        lockType: false,
        tooltip: context.l10n.createLabelTooltip,
        heroTag: 'create_label_fab',
      ),
      FabOperation.createValue => AddLabelFab(
        labelRepository: getIt<LabelRepositoryContract>(),
        initialType: LabelType.value,
        lockType: true,
        tooltip: context.l10n.createValueTooltip,
        heroTag: 'create_value_fab',
      ),
    };
  }
}

class _ScreenContent extends StatelessWidget {
  const _ScreenContent({
    required this.data,
    required this.entityActionService,
  });

  final ScreenData data;
  final EntityActionService entityActionService;

  @override
  Widget build(BuildContext context) {
    if (data.sections.isEmpty) {
      return const Center(
        child: Text('No sections configured'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: data.sections.length,
      itemBuilder: (context, index) {
        final section = data.sections[index];
        return SectionWidget(
          section: section,
          onEntityTap: (entityId, entityType) {
            Routing.toEntity(
              context,
              EntityType.fromString(entityType),
              entityId,
            );
          },
          onTaskCheckboxChanged: (task, value) async {
            developer.log(
              'CHECKBOX: task=${task.id}, newValue=$value, task.completed=${task.completed}',
              name: 'UnifiedScreenPage',
            );
            if (value ?? false) {
              await entityActionService.completeTask(task.id);
            } else {
              await entityActionService.uncompleteTask(task.id);
            }
            developer.log(
              'CHECKBOX: action complete, triggering refresh',
              name: 'UnifiedScreenPage',
            );
            // Refresh data after action
            if (context.mounted) {
              context.read<ScreenBloc>().add(const ScreenEvent.refresh());
            }
          },
          onProjectCheckboxChanged: (project, value) async {
            if (value ?? false) {
              await entityActionService.completeProject(project.id);
            } else {
              await entityActionService.uncompleteProject(project.id);
            }
            // Refresh data after action
            if (context.mounted) {
              context.read<ScreenBloc>().add(const ScreenEvent.refresh());
            }
          },
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    this.definition,
  });

  final String message;
  final ScreenDefinition? definition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(definition?.name ?? 'Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load screen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context.read<ScreenBloc>().add(const ScreenEvent.refresh());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
