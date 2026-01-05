import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/app_bar_action.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/presentation/features/persona_wizard/view/persona_selection_page.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/persona_selector.dart';

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
          ScreenLoadedState(:final data) => _LoadedView(data: data),
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
  });

  final ScreenData data;

  @override
  Widget build(BuildContext context) {
    final entityActionService = getIt<EntityActionService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(data.definition.name),
        actions: _buildAppBarActions(context),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _ScreenContent(
        data: data,
        entityActionService: entityActionService,
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  /// Builds AppBar actions based on screen definition's appBarActions.
  List<Widget> _buildAppBarActions(BuildContext context) {
    final definition = data.definition;

    return definition.appBarActions.map((action) {
      return switch (action) {
        AppBarAction.settingsLink => IconButton(
          icon: const Icon(Icons.tune),
          tooltip: context.l10n.settingsTitle,
          onPressed: definition.settingsRoute != null
              ? () => Routing.toScreenKey(context, definition.settingsRoute!)
              : null,
        ),
        AppBarAction.help => IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpDialog(context),
        ),
      };
    }).toList();
  }

  /// Shows a help dialog for the current screen.
  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About ${data.definition.name}'),
        content: const Text('Help content for this screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
      FabOperation.createProject => AddProjectFab(
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
      FabOperation.createValue => AddValueFab(
        valueRepository: getIt<ValueRepositoryContract>(),
        tooltip: context.l10n.createLabelTooltip, // TODO: Update l10n
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
    final sections = data.sections;
    final isFocusScreen = data.definition.screenType == ScreenType.focus;

    if (sections.isEmpty && !isFocusScreen) {
      return const Center(
        child: Text('No sections configured'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sections.length + (isFocusScreen ? 1 : 0),
      itemBuilder: (context, index) {
        if (isFocusScreen) {
          if (index == 0) {
            // Find active persona from allocation section
            AllocationPersona? activePersona;
            for (final section in sections) {
              if (section.result is AllocationSectionResult) {
                activePersona =
                    (section.result as AllocationSectionResult).activePersona;
                break;
              }
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PersonaSelector(
                    currentPersona: activePersona ?? AllocationPersona.realist,
                    onPersonaSelected: (p) async {
                      final settingsRepo = getIt<SettingsRepositoryContract>();
                      final currentConfig = await settingsRepo.load(
                        SettingsKey.allocation,
                      );
                      await settingsRepo.save(
                        SettingsKey.allocation,
                        currentConfig.copyWith(persona: p),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PersonaSelectionPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('Configure Focus Style'),
                  ),
                ),
              ],
            );
          }
          // Adjust index for sections
          final section = sections[index - 1];
          return SectionWidget(
            section: section,
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
              developer.log(
                'Task checkbox changed: ${task.id} -> $value',
                name: 'UnifiedScreenPage',
              );
              if (value ?? false) {
                await entityActionService.completeTask(task.id);
              } else {
                await entityActionService.uncompleteTask(task.id);
              }
              if (context.mounted) {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              }
            },
          );
        }

        final section = sections[index];
        return SectionWidget(
          section: section,
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
