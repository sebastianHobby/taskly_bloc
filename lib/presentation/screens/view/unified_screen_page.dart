import 'package:flutter/widgets.dart';

/// Deprecated legacy screen rendering page.
///
/// The app uses typed screen specs rendered via `UnifiedScreenPageFromSpec`.
@Deprecated('Legacy UnifiedScreenPage. Use UnifiedScreenPageFromSpec instead.')
class UnifiedScreenPage extends StatelessWidget {
  @Deprecated(
    'Legacy UnifiedScreenPage. Use UnifiedScreenPageFromSpec instead.',
  )
  const UnifiedScreenPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/*
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
      ),
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

          final focusBannerSliver = config.hasSelectedFocusMode
              ? SliverToBoxAdapter(
                  child: FocusModeBanner(
                    focusMode: config.focusMode,
                    onTap: () =>
                        context.push(Routing.screenPath('focus_setup')),
                  ),
                )
              : null;

          return CustomScrollView(
            slivers: [
              ?focusBannerSliver,
              for (final section in sections)
                SectionWidget(
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
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      );
    }

    if (sections.isEmpty && !isFocusScreen) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No sections configured')),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        for (final section in sections)
          SectionWidget(
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
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }
}

class _AgendaBody extends StatelessWidget {
  const _AgendaBody({required this.section});

  final SectionVm section;

  @override
  Widget build(BuildContext context) {
    final agendaResult = section.data;
    if (agendaResult is! AgendaSectionResult) {
      return const Center(child: Text('Agenda data not available'));
    }

    final sectionParams = section.params;
    if (sectionParams is! AgendaSectionParamsV2) {
      return const Center(child: Text('Agenda params not available'));
    }

    return AgendaSectionRenderer(
      data: agendaResult,
      showTagPills: sectionParams.enrichment.items.any(
        (i) => i.maybeWhen(agendaTags: (_) => true, orElse: () => false),
      ),
      onTaskToggle: (taskId, val) async {
        final task = agendaResult.agendaData.groups
            .expand((g) => g.items)
            .where((item) => item.isTask && item.task?.id == taskId)
            .map((item) => item.task)
            .whereType<Task>()
            .first;
        final entityActionService = getIt<EntityActionService>();
        if (val ?? false) {
          await entityActionService.completeTask(task.id);
        } else {
          await entityActionService.uncompleteTask(task.id);
        }
      },
      onTaskTap: (task) => Routing.toEntity(context, EntityType.task, task.id),
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

*/
