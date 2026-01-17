import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/language/models/app_bar_action.dart';
import 'package:taskly_bloc/domain/screens/language/models/fab_operation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/view/focus_setup_wizard_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_add_fab.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/add_value_fab.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/screens/identity/section_persistence_key.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_focus_mode_required_page.dart';
import 'package:taskly_bloc/presentation/screens/templates/widgets/task_status_filter_bar.dart';
import 'package:taskly_bloc/presentation/screens/templates/widgets/attention_app_bar_accessory.dart';
import 'package:taskly_bloc/presentation/features/attention/widgets/attention_bell_icon_button.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/model/attention_session_banner_vm.dart';
import 'package:taskly_bloc/presentation/features/attention/widgets/attention_session_banner.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import 'package:taskly_core/logging.dart';

/// Switchboard for rendering a typed [ScreenTemplateSpec].
class ScreenTemplateWidget extends StatelessWidget {
  const ScreenTemplateWidget({
    required this.data,
    required this.attentionSessionBanner,
    super.key,
  });

  final ScreenSpecData data;
  final AttentionSessionBannerVm? attentionSessionBanner;

  @override
  Widget build(BuildContext context) {
    Widget buildFocusSetupWizard() {
      FocusSetupWizardStep? parseInitialStep() {
        final step = GoRouterState.of(context).uri.queryParameters['step'];
        return switch (step) {
          'select_focus_mode' => FocusSetupWizardStep.selectFocusMode,
          _ => null,
        };
      }

      return BlocProvider(
        create: (_) => FocusSetupBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          valueRepository: getIt(),
        )..add(FocusSetupEvent.started(initialStep: parseInitialStep())),
        child: const FocusSetupWizardPage(),
      );
    }

    return data.template.when(
      standardScaffoldV1: () => _StandardScaffoldV1Template(
        data: data,
        attentionSessionBanner: attentionSessionBanner,
      ),
      entityDetailScaffoldV1: () => _EntityDetailScaffoldV1Template(data: data),
      settingsMenu: () => const SettingsScreen(),
      trackerManagement: () => const _PlaceholderTemplate(
        title: 'Trackers',
        message: 'Tracker management is being rebuilt.',
      ),
      statisticsDashboard: () => const _StatisticsDashboardPlaceholder(),
      journalHub: () => const JournalHubPage(),
      attentionRules: () => const _PlaceholderTemplate(
        title: 'Attention Rules',
        message: 'Attention rules UI is being rebuilt.',
      ),
      focusSetupWizard: buildFocusSetupWizard,
      myDayFocusModeRequired: () => const MyDayFocusModeRequiredPage(),
    );
  }
}

class _StatisticsDashboardPlaceholder extends StatelessWidget {
  const _StatisticsDashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            tooltip: 'Attention',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Statistics dashboard not implemented yet.'),
      ),
    );
  }
}

class _EntityDetailScaffoldV1Template extends StatefulWidget {
  const _EntityDetailScaffoldV1Template({required this.data});

  final ScreenSpecData data;

  @override
  State<_EntityDetailScaffoldV1Template> createState() =>
      _EntityDetailScaffoldV1TemplateState();
}

class _EntityDetailScaffoldV1TemplateState
    extends State<_EntityDetailScaffoldV1Template> {
  TaskCompletionFilter _projectTasksFilter = TaskCompletionFilter.open;
  bool _restoredFilter = false;

  String? get _projectTasksFilterStorageKey {
    final entity = _entityFromHeader(widget.data.sections.header);
    if (entity.entityType != EntityType.project) return null;
    final entityId = entity.entityId;
    if (entityId == null || entityId.isEmpty) return null;
    return '${widget.data.spec.screenKey}:$entityId:projectTasksFilter';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restoredFilter) return;
    final storageKey = _projectTasksFilterStorageKey;
    if (storageKey == null) {
      _restoredFilter = true;
      return;
    }

    final bucket = PageStorage.of(context);
    final stored = bucket.readState(context, identifier: storageKey);
    if (stored is String) {
      final restored = switch (stored) {
        'all' => TaskCompletionFilter.all,
        'open' => TaskCompletionFilter.open,
        'completed' => TaskCompletionFilter.completed,
        _ => null,
      };
      if (restored != null) _projectTasksFilter = restored;
    }
    _restoredFilter = true;
  }

  void _persistProjectTasksFilter() {
    final storageKey = _projectTasksFilterStorageKey;
    if (storageKey == null) return;
    final stored = switch (_projectTasksFilter) {
      TaskCompletionFilter.all => 'all',
      TaskCompletionFilter.open => 'open',
      TaskCompletionFilter.completed => 'completed',
    };

    PageStorage.of(context).writeState(
      context,
      stored,
      identifier: storageKey,
    );
  }

  ({EntityType? entityType, String? entityId, String? entityName})
  _entityFromHeader(
    List<SectionVm> header,
  ) {
    for (final section in header) {
      final result = section.data;
      switch (result) {
        case null:
          continue;
        case EntityHeaderProjectSectionResult(:final project):
          return (
            entityType: EntityType.project,
            entityId: project.id,
            entityName: project.name,
          );
        case EntityHeaderValueSectionResult(:final value):
          return (
            entityType: EntityType.value,
            entityId: value.id,
            entityName: value.name,
          );
        default:
          continue;
      }
    }

    return (entityType: null, entityId: null, entityName: null);
  }

  Future<void> _openEditor(BuildContext context) async {
    final launcher = EditorLauncher.fromGetIt();
    final entity = _entityFromHeader(widget.data.sections.header);
    final entityType = entity.entityType;
    final entityId = entity.entityId;
    if (entityType == null || entityId == null) return;

    switch (entityType) {
      case EntityType.project:
        await launcher.openProjectEditor(context, projectId: entityId);
      case EntityType.value:
        await launcher.openValueEditor(context, valueId: entityId);
      case EntityType.task:
        return;
    }
  }

  Future<void> _deleteEntityFromOverflow(BuildContext context) async {
    final dispatcher = context.read<TileIntentDispatcher>();
    final (entityType: entityType, entityId: entityId, entityName: entityName) =
        _entityFromHeader(widget.data.sections.header);

    if (entityType == null || entityId == null || entityName == null) return;

    final actions = TileOverflowActionCatalog.forEntityDetail(
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
    );
    final action = actions.first;

    AppLog.routineThrottledStructured(
      'entity_detail_overflow.${entityType.name}.delete.$entityId',
      const Duration(seconds: 2),
      'tile_overflow',
      'selected',
      fields: {
        'entityType': entityType.name,
        'entityId': entityId,
        'action': action.id.name,
      },
    );

    await dispatcher.dispatch(context, action.intent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = widget.data.spec;
    final l10n = context.l10n;
    final (entityType: entityType, entityId: entityId, entityName: entityName) =
        _entityFromHeader(widget.data.sections.header);

    final title = (entityName != null && entityName.trim().isNotEmpty)
        ? entityName
        : spec.name;

    final hasProjectTaskFilter = entityType == EntityType.project;

    final headerSections = widget.data.sections.header;
    final primarySections = widget.data.sections.primary;

    final allPrimaryTasks = <Task>[];
    for (final section in primarySections) {
      final result = section.data;
      if (result is SectionDataResult) {
        allPrimaryTasks.addAll(result.allTasks);
      }
    }

    final hasAnyTasks = allPrimaryTasks.isNotEmpty;

    final filteredPrimarySections = hasProjectTaskFilter
        ? _filterPrimarySectionsByCompletion(primarySections)
        : primarySections;

    final filteredPrimaryTasks = <Task>[];
    for (final section in filteredPrimarySections) {
      final result = section.data;
      if (result is SectionDataResult) {
        filteredPrimaryTasks.addAll(result.allTasks);
      }
    }

    final hasFilteredTasks = filteredPrimaryTasks.isNotEmpty;

    final slivers = <Widget>[
      for (final section in headerSections)
        _EntityDetailModuleSliver(
          section: section,
          screenKey: spec.screenKey,
          onEntityHeaderTap: () => _openEditor(context),
        ),

      if (hasProjectTaskFilter && hasAnyTasks)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: TaskStatusFilterBar(
              filter: _projectTasksFilter,
              allLabel: l10n.projectDetailTasksFilterAll,
              openLabel: l10n.projectDetailTasksFilterOpen,
              completedLabel: l10n.projectDetailTasksFilterCompleted,
              onChanged: (next) {
                setState(() => _projectTasksFilter = next);
                _persistProjectTasksFilter();
              },
            ),
          ),
        ),
    ];

    if (!hasAnyTasks) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget.noTasks(
            title: l10n.emptyTasksTitle,
            description: l10n.emptyTasksDescription,
            actionLabel: l10n.createTaskTooltip,
            onAction: () {
              final launcher = EditorLauncher.fromGetIt();

              launcher.openTaskEditor(
                context,
                defaultProjectId: entityType == EntityType.project
                    ? entityId
                    : null,
                defaultValueIds:
                    entityType == EntityType.value && entityId != null
                    ? [entityId]
                    : null,
              );
            },
          ),
        ),
      );
    } else if (hasProjectTaskFilter && !hasFilteredTasks) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget.noTasks(
            title: l10n.projectDetailNoMatchingTasksTitle,
            description: l10n.projectDetailNoMatchingTasksDescription,
          ),
        ),
      );
    } else {
      for (final section in filteredPrimarySections) {
        slivers.add(
          _EntityDetailModuleSliver(
            section: section,
            screenKey: spec.screenKey,
            onEntityHeaderTap: () => _openEditor(context),
          ),
        );
      }
    }

    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 80)));

    final fab = switch (entityType) {
      EntityType.project =>
        entityId == null
            ? null
            : AddTaskFab(
                taskRepository: getIt(),
                projectRepository: getIt(),
                valueRepository: getIt(),
                defaultProjectId: entityId,
              ),
      EntityType.value =>
        entityId == null
            ? null
            : AddTaskFab(
                taskRepository: getIt(),
                projectRepository: getIt(),
                valueRepository: getIt(),
                defaultValueIds: [entityId],
              ),
      _ => null,
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (entityType == EntityType.project ||
              entityType == EntityType.value)
            IconButton(
              tooltip: l10n.editLabel,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(context),
            ),
          IconButton(
            tooltip: 'Attention',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
          ),
          if ((entityType == EntityType.project ||
                  entityType == EntityType.value) &&
              entityId != null)
            PopupMenuButton<TileOverflowActionId>(
              onSelected: (value) {
                if (value == TileOverflowActionId.delete) {
                  _deleteEntityFromOverflow(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<TileOverflowActionId>(
                  value: TileOverflowActionId.delete,
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
      body: CustomScrollView(
        slivers: [
          SliverContentConstraint(
            maxWidth: 840,
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }

  List<SectionVm> _filterPrimarySectionsByCompletion(List<SectionVm> sections) {
    if (_projectTasksFilter == TaskCompletionFilter.all) return sections;

    return sections
        .map((section) {
          final result = section.data;
          if (result is! DataV2SectionResult) return section;

          final filteredItems = result.items
              .where((item) {
                if (item is! ScreenItemTask) return true;
                return switch (_projectTasksFilter) {
                  TaskCompletionFilter.open => !item.task.completed,
                  TaskCompletionFilter.completed => item.task.completed,
                  TaskCompletionFilter.all => true,
                };
              })
              .toList(growable: false);

          return section.copyWith(
            data: result.copyWith(items: filteredItems),
          );
        })
        .toList(growable: false);
  }
}

class _EntityDetailModuleSliver extends StatelessWidget {
  const _EntityDetailModuleSliver({
    required this.section,
    required this.screenKey,
    required this.onEntityHeaderTap,
  });

  final SectionVm section;
  final String screenKey;
  final VoidCallback onEntityHeaderTap;

  @override
  Widget build(BuildContext context) {
    final persistenceKey = SectionPersistenceKey.fromParts(
      screenKey: screenKey,
      sectionTemplateId: section.templateId,
      sectionIndex: section.index,
    ).value;
    return SectionWidget(
      section: section,
      persistenceKey: persistenceKey,
      displayConfig: section.displayConfig,
      onEntityHeaderTap: onEntityHeaderTap,
      onEntityTap: (entity) {
        if (entity is Task) {
          Routing.toEntity(context, EntityType.task, entity.id);
        } else if (entity is Project) {
          Routing.toEntity(context, EntityType.project, entity.id);
        } else if (entity is Value) {
          Routing.toEntity(context, EntityType.value, entity.id);
        }
      },
    );
  }
}

class _PlaceholderTemplate extends StatelessWidget {
  const _PlaceholderTemplate({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _StandardScaffoldV1Template extends StatelessWidget {
  const _StandardScaffoldV1Template({
    required this.data,
    required this.attentionSessionBanner,
  });

  final ScreenSpecData data;
  final AttentionSessionBannerVm? attentionSessionBanner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = data.spec;

    final description = spec.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    final headerSections = data.sections.header;

    SectionVm? attentionHeader;
    for (final section in headerSections) {
      if (section.templateId == SectionTemplateId.attentionBannerV2) {
        attentionHeader = section;
        break;
      }
    }

    final showHeaderAccessoryInAppBar = spec.chrome.showHeaderAccessoryInAppBar;

    final showAttentionInAppBar =
        showHeaderAccessoryInAppBar && attentionHeader != null;

    final attentionBannerResult = showAttentionInAppBar
        ? attentionHeader.data
        : null;
    final attentionBannerData =
        attentionBannerResult is AttentionBannerV2SectionResult
        ? attentionBannerResult
        : null;

    final appBarActions = <Widget>[..._buildAppBarActions(context, spec)];
    final fab = _buildFab(spec);

    final slivers = <Widget>[
      if (attentionSessionBanner != null)
        SliverToBoxAdapter(
          child: AttentionSessionBanner(
            vm: attentionSessionBanner!,
            onReview: () => Routing.toScreenKey(context, 'review_inbox'),
            onDismiss: () {
              getIt<AttentionBannerSessionCubit>().dismissForScreenKey(
                spec.screenKey,
              );
            },
          ),
        ),
      ...headerSections
          .where((s) => !(showAttentionInAppBar && s == attentionHeader))
          .map((s) => _ModuleSliver(section: s, screenKey: spec.screenKey)),
      ..._buildPrimarySlivers(context),
    ];

    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: hasDescription ? 72 : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spec.name),
            if (hasDescription)
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: appBarActions,
        bottom: showAttentionInAppBar
            ? PreferredSize(
                preferredSize: Size.fromHeight(
                  AttentionAppBarAccessory.preferredHeight(
                    showProgressRail:
                        (attentionBannerData?.totalCount ?? 0) > 0,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    if (attentionBannerData == null) {
                      return const SizedBox.shrink();
                    }
                    return AttentionAppBarAccessory(
                      result: attentionBannerData,
                    );
                  },
                ),
              )
            : null,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: CustomScrollView(slivers: slivers),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: fab ?? const SizedBox.shrink(key: ValueKey('no-fab')),
      ),
    );

    return scaffold;
  }

  List<Widget> _buildPrimarySlivers(BuildContext context) {
    final spec = data.spec;
    final primary = data.sections.primary;
    return primary
        .map((s) => _ModuleSliver(section: s, screenKey: spec.screenKey))
        .toList(growable: false);
  }

  List<Widget> _buildAppBarActions(BuildContext context, ScreenSpec spec) {
    final actions = <Widget>[
      ...spec.chrome.appBarActions.map((action) {
        return switch (action) {
          AppBarAction.settingsLink => IconButton(
            icon: const Icon(Icons.tune),
            onPressed: spec.chrome.settingsRoute != null
                ? () => Routing.toScreenKey(context, spec.chrome.settingsRoute!)
                : null,
          ),
          AppBarAction.help => const SizedBox.shrink(),
          AppBarAction.createValue => IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create value',
            onPressed: () async {
              await EditorLauncher.fromGetIt().openValueEditor(context);
            },
          ),
          AppBarAction.journalManageTrackers => IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Manage trackers',
            onPressed: () {
              Routing.pushScreenKey(context, 'journal_manage_trackers');
            },
          ),
        };
      }),
    ];

    // Global entrypoint (bell → Attention inbox).
    // Suppress on the inbox itself to avoid self-navigation.
    if (spec.screenKey != 'review_inbox') {
      actions.add(
        AttentionBellIconButton(
          onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
        ),
      );
    }

    return actions;
  }

  Widget? _buildFab(ScreenSpec spec) {
    final operations = spec.chrome.fabOperations;
    if (operations.isEmpty) return null;

    final operation = operations.first;

    return switch (operation) {
      FabOperation.createTask => AddTaskFab(
        taskRepository: getIt(),
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createProject => AddProjectFab(
        projectRepository: getIt(),
        valueRepository: getIt(),
      ),
      FabOperation.createValue => AddValueFab(
        valueRepository: getIt(),
        tooltip: 'Create value',
        heroTag: 'create_value_fab',
      ),
    };
  }
}

class _ModuleSliver extends StatelessWidget {
  const _ModuleSliver({required this.section, required this.screenKey});

  final SectionVm section;
  final String screenKey;

  @override
  Widget build(BuildContext context) {
    final persistenceKey = SectionPersistenceKey.fromParts(
      screenKey: screenKey,
      sectionTemplateId: section.templateId,
      sectionIndex: section.index,
    ).value;
    return SectionWidget(
      section: section,
      persistenceKey: persistenceKey,
      onEntityTap: (entity) {
        if (entity is Task) {
          Routing.toEntity(context, EntityType.task, entity.id);
        } else if (entity is Project) {
          Routing.toEntity(context, EntityType.project, entity.id);
        } else if (entity is Value) {
          Routing.toEntity(context, EntityType.value, entity.id);
        }
      },
    );
  }
}
