import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/app_log.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/app_bar_action.dart';
import 'package:taskly_bloc/domain/models/screens/fab_operation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/focus_mode_banner.dart';

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
      child: const _UnifiedScreenScaffold(),
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
      child: const _UnifiedScreenScaffold(),
    );
  }
}

class _UnifiedScreenScaffold extends StatelessWidget {
  const _UnifiedScreenScaffold();

  static const _fullScreenTemplateIds = <String>{
    SectionTemplateId.settingsMenu,
    SectionTemplateId.screenManagement,
    SectionTemplateId.trackerManagement,
    SectionTemplateId.statisticsDashboard,
    SectionTemplateId.wellbeingDashboard,
    SectionTemplateId.allocationSettings,
    SectionTemplateId.navigationSettings,
    SectionTemplateId.attentionRules,
    SectionTemplateId.focusSetupWizard,
    SectionTemplateId.myDayFocusModeRequired,
    SectionTemplateId.browseHub,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenBloc, ScreenState>(
      builder: (context, state) {
        // Extract data from state if loaded
        final data = switch (state) {
          ScreenLoadedState(:final data) => data,
          _ => null,
        };

        // Extract title/definition info
        final title = switch (state) {
          ScreenLoadingState(:final definition) => definition?.name,
          ScreenLoadedState(:final data) => data.definition.name,
          ScreenErrorState(:final definition) => definition?.name,
          _ => null,
        };

        // Some sections represent full-screen legacy pages (with their own
        // Scaffold/AppBar/FAB). In those cases, render the section directly
        // to avoid nested scaffolds and duplicated chrome.
        final fullScreenSection = switch (state) {
          ScreenLoadedState(:final data)
              when data.sections.length == 1 &&
                  _fullScreenTemplateIds.contains(
                    data.sections.first.templateId,
                  ) =>
            data.sections.first,
          _ => null,
        };

        if (fullScreenSection != null) {
          return SectionWidget(section: fullScreenSection);
        }

        // Scheduled uses a single agenda section that needs to own scrolling
        // to support date-chip ↔ timeline scroll synchronization.
        final singleAgendaSection = switch (state) {
          ScreenLoadedState(:final data)
              when data.sections.length == 1 &&
                  data.sections.first.templateId == SectionTemplateId.agenda =>
            data.sections.first,
          _ => null,
        };

        // Build body based on state
        final body = switch (state) {
          ScreenInitialState() || ScreenLoadingState() => const Center(
            child: CircularProgressIndicator(),
          ),
          ScreenLoadedState() when singleAgendaSection != null => SectionWidget(
            section: singleAgendaSection,
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
                await getIt<EntityActionService>().completeTask(task.id);
              } else {
                await getIt<EntityActionService>().uncompleteTask(task.id);
              }
            },
            onProjectCheckboxChanged: (project, value) async {
              if (value ?? false) {
                await getIt<EntityActionService>().completeProject(project.id);
              } else {
                await getIt<EntityActionService>().uncompleteProject(
                  project.id,
                );
              }
            },
          ),
          ScreenLoadedState(:final data) => _ScreenContent(
            data: data,
            entityActionService: getIt<EntityActionService>(),
          ),
          ScreenErrorState(:final message) => _ErrorContent(message: message),
        };

        final isSystemScheduled = switch (state) {
          ScreenLoadedState(:final data) => data.definition.id == 'scheduled',
          ScreenLoadingState(:final definition) =>
            definition?.id == 'scheduled',
          ScreenErrorState(:final definition) => definition?.id == 'scheduled',
          _ => false,
        };

        // Build FAB only when loaded (returns null otherwise)
        final fab = data != null ? _buildFab(context, data) : null;

        // Build app bar actions only when loaded
        final appBarActions = data != null
            ? _buildAppBarActions(context, data.definition)
            : <Widget>[];

        final theme = Theme.of(context);

        // Use Scaffold here - this is the inner content page scaffold.
        // The shell navigation scaffold wraps this but doesn't have a FAB slot,
        // so this Scaffold's FAB is the primary one for the screen.
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: isSystemScheduled
              ? null
              : AppBar(
                  title: Text(title ?? 'Loading...'),
                  actions: appBarActions,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                ),
          body: isSystemScheduled
              ? SafeArea(top: true, bottom: false, child: body)
              : body,
          // Use AnimatedSwitcher to smoothly transition FAB and avoid layout race
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: fab ?? const SizedBox.shrink(key: ValueKey('no-fab')),
          ),
        );
      },
    );
  }

  /// Builds FAB based on screen definition's fabOperations.
  Widget? _buildFab(BuildContext context, ScreenData data) {
    final operations = data.definition.chrome.fabOperations;

    // No FAB if no operations defined
    if (operations.isEmpty) return null;

    // Single operation = single FAB
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
        tooltip: context.l10n.createLabelTooltip,
        heroTag: 'create_value_fab',
      ),
    };
  }

  /// Builds AppBar actions based on screen definition's appBarActions.
  List<Widget> _buildAppBarActions(
    BuildContext context,
    ScreenDefinition definition,
  ) {
    return definition.chrome.appBarActions.map((action) {
      return switch (action) {
        AppBarAction.settingsLink => IconButton(
          icon: const Icon(Icons.tune),
          tooltip: context.l10n.settingsTitle,
          onPressed: definition.chrome.settingsRoute != null
              ? () => Routing.toScreenKey(
                  context,
                  definition.chrome.settingsRoute!,
                )
              : null,
        ),
        AppBarAction.help => IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
          onPressed: () => _showHelpDialog(context, definition.name),
        ),
      };
    }).toList();
  }

  void _showHelpDialog(BuildContext context, String screenName) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About $screenName'),
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
    // Infer focus screen from presence of Allocation template
    final isFocusScreen = data.definition.sections.any(
      (s) => s.templateId == SectionTemplateId.allocation,
    );

    if (isFocusScreen) {
      return StreamBuilder<AllocationConfig>(
        stream: getIt<SettingsRepositoryContract>().watch(
          SettingsKey.allocation,
        ),
        builder: (context, configSnapshot) {
          final config = configSnapshot.data ?? const AllocationConfig();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sections.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (config.hasSelectedFocusMode) {
                  return FocusModeBanner(
                    focusMode: config.focusMode,
                    onTap: () =>
                        context.push(Routing.screenPath('focus_setup')),
                  );
                }

                return const SizedBox.shrink();
              }

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
                  AppLog.routine(
                    'ui.unified_screen',
                    'Task checkbox changed: ${task.id} -> $value',
                  );
                  if (value ?? false) {
                    await entityActionService.completeTask(task.id);
                  } else {
                    await entityActionService.uncompleteTask(task.id);
                  }
                },
              );
            },
          );
        },
      );
    }

    if (sections.isEmpty && !isFocusScreen) {
      return const Center(
        child: Text('No sections configured'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sections.length,
      itemBuilder: (context, index) {
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
            AppLog.routine(
              'ui.unified_screen',
              'CHECKBOX: task=${task.id}, newValue=$value, '
                  'task.completed=${task.completed}',
            );
            if (value ?? false) {
              await entityActionService.completeTask(task.id);
            } else {
              await entityActionService.uncompleteTask(task.id);
            }
            AppLog.routine(
              'ui.unified_screen',
              'CHECKBOX: action complete, data will update automatically',
            );
          },
          onProjectCheckboxChanged: (project, value) async {
            if (value ?? false) {
              await entityActionService.completeProject(project.id);
            } else {
              await entityActionService.uncompleteProject(project.id);
            }
          },
        );
      },
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
                // Navigate back or reload screen
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
