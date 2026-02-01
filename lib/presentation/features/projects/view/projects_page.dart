import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/bloc/display_density_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

import 'package:taskly_bloc/presentation/features/projects/bloc/projects_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/projects_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/services/projects_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/projects/model/projects_sort.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({
    this.scope,
    super.key,
  });

  final ProjectsScope? scope;

  @override
  Widget build(BuildContext context) {
    final isCompactScreen = Breakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProjectsScreenBloc(scope: scope)),
        BlocProvider(
          create: (context) => ProjectsFeedBloc(
            queryService: context.read<ProjectsSessionQueryService>(),
            scope: scope,
          ),
        ),
        BlocProvider(
          create: (context) => DisplayDensityBloc(
            settingsRepository: context.read<SettingsRepositoryContract>(),
            pageKey: PageKey.projectOverview,
            defaultDensity: isCompactScreen
                ? DisplayDensity.compact
                : DisplayDensity.standard,
          )..add(const DisplayDensityStarted()),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: _ProjectsView(scope: scope),
    );
  }
}

class _ProjectsView extends StatefulWidget {
  const _ProjectsView({required this.scope});

  final ProjectsScope? scope;

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showCompleted = false;
  ProjectsSortOrder _sortOrder = ProjectsSortOrder.recentlyUpdated;
  final Set<String> _selectedValueIds = <String>{};

  ProjectsScope? get scope => widget.scope;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setSearchActive(bool active) {
    if (_isSearching == active) return;
    setState(() => _isSearching = active);

    if (!active) {
      _searchController.clear();
      context.read<ProjectsScreenBloc>().add(
        const ProjectsSearchQueryChanged(''),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  void _updateSortOrder(ProjectsSortOrder order) {
    if (_sortOrder == order) return;
    setState(() => _sortOrder = order);
    context.read<ProjectsFeedBloc>().add(
      ProjectsFeedSortOrderChanged(sortOrder: order),
    );
  }

  void _toggleShowCompleted() {
    setState(() => _showCompleted = !_showCompleted);
  }

  void _toggleValueFilter(String valueId) {
    setState(() {
      if (_selectedValueIds.contains(valueId)) {
        _selectedValueIds.remove(valueId);
      } else {
        _selectedValueIds.add(valueId);
      }
    });
  }

  void _clearValueFilters() {
    if (_selectedValueIds.isEmpty) return;
    setState(_selectedValueIds.clear);
  }

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    String? defaultProjectId,
    String? defaultValueId,
  }) {
    return context.read<EditorLauncher>().openTaskEditor(
      context,
      taskId: null,
      defaultProjectId: defaultProjectId,
      defaultValueIds: defaultValueId == null ? null : [defaultValueId],
      showDragHandle: true,
    );
  }

  Future<void> _openNewProjectEditor(
    BuildContext context, {
    required bool openToValues,
  }) {
    return context.read<EditorLauncher>().openProjectEditor(
      context,
      projectId: null,
      openToValues: openToValues,
      showDragHandle: true,
    );
  }

  Future<void> _showFilterSheet({
    required List<Value> values,
    required List<ListRowUiModel> rows,
  }) async {
    final countRows = _filterProjectsRows(
      rows: rows,
      selectedValueIds: const <String>{},
      showCompleted: _showCompleted,
      scope: scope,
    );
    final counts = _countProjectsByValue(countRows);
    final hasScopedValue = scope is ProjectsValueScope;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TasklyTokens.of(sheetContext).spaceLg,
              TasklyTokens.of(sheetContext).spaceSm,
              TasklyTokens.of(sheetContext).spaceLg,
              TasklyTokens.of(sheetContext).spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & sort',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                SizedBox(height: TasklyTokens.of(sheetContext).spaceSm),
                Text(
                  'Sort',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final order in ProjectsSortOrder.values)
                  RadioListTile<ProjectsSortOrder>(
                    value: order,
                    groupValue: _sortOrder,
                    title: Text(order.label),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateSortOrder(value);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                SizedBox(height: TasklyTokens.of(sheetContext).spaceSm),
                Text(
                  'Values',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(sheetContext).spaceSm),
                if (hasScopedValue)
                  Text(
                    'Value filters are disabled for scoped views.',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: TasklyTokens.of(sheetContext).spaceSm,
                    runSpacing: TasklyTokens.of(sheetContext).spaceSm,
                    children: [
                      _ValueFilterChip(
                        label: 'All values',
                        count: counts.total,
                        selected: _selectedValueIds.isEmpty,
                        icon: Icons.filter_list_rounded,
                        iconColor: Theme.of(
                          sheetContext,
                        ).colorScheme.onSurfaceVariant,
                        onTap: _clearValueFilters,
                      ),
                      for (final value in values) ...[
                        _ValueFilterChip(
                          label: value.name,
                          count: counts.byValueId[value.id],
                          selected: _selectedValueIds.contains(value.id),
                          icon: value.toChipData(sheetContext).icon,
                          iconColor: value.toChipData(sheetContext).color,
                          tintColor: value.toChipData(sheetContext).color,
                          onTap: () => _toggleValueFilter(value.id),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chrome = TasklyTokens.of(context);
    final density = context.select(
      (DisplayDensityBloc bloc) => bloc.state.density,
    );
    final iconButtonStyle = IconButton.styleFrom(
      backgroundColor: scheme.surfaceContainerHighest.withValues(
        alpha: chrome.iconButtonBackgroundAlpha,
      ),
      foregroundColor: scheme.onSurface,
      shape: const CircleBorder(),
      minimumSize: Size.square(chrome.iconButtonMinSize),
      padding: chrome.iconButtonPadding,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<ProjectsScreenBloc, ProjectsScreenState>(
          listenWhen: (prev, next) => prev.searchQuery != next.searchQuery,
          listener: (context, state) {
            context.read<ProjectsFeedBloc>().add(
              ProjectsFeedSearchQueryChanged(query: state.searchQuery),
            );
          },
        ),
        BlocListener<ProjectsScreenBloc, ProjectsScreenState>(
          listenWhen: (prev, next) =>
              prev.inboxCollapsed != next.inboxCollapsed,
          listener: (context, state) {
            context.read<ProjectsFeedBloc>().add(
              ProjectsFeedInboxCollapsedChanged(
                collapsed: state.inboxCollapsed,
              ),
            );
          },
        ),
        BlocListener<ProjectsScreenBloc, ProjectsScreenState>(
          listenWhen: (prev, next) => prev.effect != next.effect,
          listener: (context, state) {
            final effect = state.effect;
            if (effect == null) return;

            switch (effect) {
              case ProjectsNavigateToProjectDetail(:final projectId):
                Routing.pushProjectDetail(context, projectId);
              case ProjectsNavigateToTaskEdit(:final taskId):
                Routing.toTaskEdit(context, taskId);
              case ProjectsNavigateToTaskNew(
                :final defaultProjectId,
                :final defaultValueId,
              ):
                _openNewTaskEditor(
                  context,
                  defaultProjectId: defaultProjectId,
                  defaultValueId: defaultValueId,
                );
              case ProjectsOpenProjectNew(:final openToValues):
                _openNewProjectEditor(context, openToValues: openToValues);
            }

            context.read<ProjectsScreenBloc>().add(
              const ProjectsEffectHandled(),
            );
          },
        ),
      ],
      child: BlocBuilder<SelectionBloc, SelectionState>(
        builder: (context, selectionState) {
          return Scaffold(
            appBar: selectionState.isSelectionMode
                ? const SelectionAppBar(baseTitle: 'Projects', onExit: _noop)
                : AppBar(
                    centerTitle: true,
                    toolbarHeight: chrome.projectsAppBarHeight,
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search your project list',
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              context.read<ProjectsScreenBloc>().add(
                                ProjectsSearchQueryChanged(value),
                              );
                            },
                          )
                        : null,
                    actions: TasklyAppBarActions.withAttentionBell(
                      context,
                      actions: [
                        IconButton(
                          tooltip: 'Filter & sort',
                          icon: const Icon(Icons.tune_rounded),
                          style: iconButtonStyle,
                          onPressed: () {
                            final state = context
                                .read<ProjectsFeedBloc>()
                                .state;
                            if (state is! ProjectsFeedLoaded) return;
                            _showFilterSheet(
                              values: state.values,
                              rows: state.rows,
                            );
                          },
                        ),
                        if (!_isSearching)
                          IconButton(
                            tooltip: 'Search',
                            icon: const Icon(Icons.search),
                            style: iconButtonStyle,
                            onPressed: () => _setSearchActive(true),
                          )
                        else
                          IconButton(
                            tooltip: 'Close search',
                            icon: const Icon(Icons.close),
                            style: iconButtonStyle,
                            onPressed: () => _setSearchActive(false),
                          ),
                        BlocBuilder<DisplayDensityBloc, DisplayDensityState>(
                          builder: (context, densityState) {
                            final isCompact =
                                densityState.density == DisplayDensity.compact;
                            return IconButton(
                              tooltip: 'Row density',
                              icon: Icon(
                                isCompact
                                    ? Icons.view_agenda_rounded
                                    : Icons.view_week_rounded,
                              ),
                              style: iconButtonStyle,
                              onPressed: () => context
                                  .read<DisplayDensityBloc>()
                                  .add(const DisplayDensityToggled()),
                            );
                          },
                        ),
                        TasklyOverflowMenuButton<_ProjectsMenuAction>(
                          tooltip: 'More',
                          icon: Icons.more_vert,
                          style: iconButtonStyle,
                          itemsBuilder: (context) => [
                            CheckedPopupMenuItem(
                              value: _ProjectsMenuAction.showCompleted,
                              checked: _showCompleted,
                              child: const TasklyMenuItemLabel(
                                'Show completed',
                              ),
                            ),
                            const PopupMenuItem(
                              value: _ProjectsMenuAction.selectMultiple,
                              child: TasklyMenuItemLabel('Select multiple'),
                            ),
                          ],
                          onSelected: (action) {
                            switch (action) {
                              case _ProjectsMenuAction.showCompleted:
                                _toggleShowCompleted();
                              case _ProjectsMenuAction.selectMultiple:
                                context
                                    .read<SelectionBloc>()
                                    .enterSelectionMode();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
            floatingActionButton: selectionState.isSelectionMode
                ? null
                : SizedBox(
                    key: GuidedTourAnchors.projectsCreateProject,
                    child: EntityAddSpeedDial(
                      heroTag: 'add_speed_dial_projects',
                      onCreateTask: () =>
                          context.read<ProjectsScreenBloc>().add(
                            const ProjectsCreateTaskRequested(),
                          ),
                      onCreateProject: () =>
                          context.read<ProjectsScreenBloc>().add(
                            const ProjectsCreateProjectRequested(),
                          ),
                    ),
                  ),
            body: Column(
              children: [
                const _ProjectsTitleHeader(),
                Expanded(
                  child: BlocBuilder<ProjectsScreenBloc, ProjectsScreenState>(
                    buildWhen: (p, n) => p.searchQuery != n.searchQuery,
                    builder: (context, screenState) {
                      return BlocBuilder<ProjectsFeedBloc, ProjectsFeedState>(
                        builder: (context, state) {
                          final spec = switch (state) {
                            ProjectsFeedLoading() =>
                              const TasklyFeedSpec.loading(),
                            ProjectsFeedError(:final message) =>
                              TasklyFeedSpec.error(
                                message: message,
                                retryLabel: context.l10n.retryButton,
                                onRetry: () =>
                                    context.read<ProjectsFeedBloc>().add(
                                      const ProjectsFeedRetryRequested(),
                                    ),
                              ),
                            ProjectsFeedLoaded(:final rows) when rows.isEmpty =>
                              TasklyFeedSpec.empty(
                                empty: _buildEmptySpec(
                                  context,
                                  scope,
                                  screenState,
                                ),
                              ),
                            ProjectsFeedLoaded(:final rows) => () {
                              final visibleRows = _filterProjectsRows(
                                rows: rows,
                                selectedValueIds: _selectedValueIds,
                                showCompleted: _showCompleted,
                                scope: scope,
                              );
                              if (visibleRows.isEmpty) {
                                return TasklyFeedSpec.empty(
                                  empty: _buildEmptySpec(
                                    context,
                                    scope,
                                    screenState,
                                  ),
                                );
                              }
                              final sections = <TasklySectionSpec>[];
                              sections.add(
                                TasklySectionSpec.standardList(
                                  id: 'projects',
                                  rows: _buildStandardRows(
                                    context,
                                    visibleRows,
                                    density: density,
                                  ),
                                ),
                              );
                              return TasklyFeedSpec.content(sections: sections);
                            }(),
                          };

                          return TasklyFeedRenderer(
                            spec: spec,
                            padding: EdgeInsets.symmetric(
                              horizontal: chrome.spaceLg,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _noop() {}

enum _ProjectsMenuAction {
  showCompleted,
  selectMultiple,
}

TasklyEmptyStateSpec _buildEmptySpec(
  BuildContext context,
  ProjectsScope? scope,
  ProjectsScreenState screenState,
) {
  final query = screenState.searchQuery.trim();
  if (query.isNotEmpty) {
    return TasklyEmptyStateSpec(
      icon: Icons.search,
      title: 'No matches',
      description: 'Try a different keyword.',
      actionLabel: 'Clear search',
      onAction: () {
        context.read<ProjectsScreenBloc>().add(
          const ProjectsSearchQueryChanged(''),
        );
      },
    );
  }

  if (scope != null) {
    return TasklyEmptyStateSpec(
      icon: Icons.inbox_outlined,
      title: switch (scope) {
        ProjectsValueScope() => 'No projects for this value yet',
        ProjectsProjectScope() => 'No tasks in this project yet',
      },
      description: switch (scope) {
        ProjectsValueScope() =>
          'Add a project or assign this value to get started.',
        ProjectsProjectScope() =>
          'Add tasks so My Day can pull from this project.',
      },
      actionLabel: 'Create project',
      onAction: () => context.read<ProjectsScreenBloc>().add(
        const ProjectsCreateProjectRequested(),
      ),
    );
  }

  return TasklyEmptyStateSpec(
    icon: Icons.inbox_outlined,
    title: 'Build your project list',
    description: 'My Day is filled from here - add a project to get started.',
    actionLabel: 'Add project',
    onAction: () => context.read<ProjectsScreenBloc>().add(
      const ProjectsCreateProjectRequested(),
    ),
  );
}

List<TasklyRowSpec> _buildStandardRows(
  BuildContext context,
  List<ListRowUiModel> rows, {
  required DisplayDensity density,
}) {
  final selection = context.read<SelectionBloc>();

  final projectRowCache = rows.whereType<ProjectRowUiModel>().toList(
    growable: false,
  );
  selection.updateVisibleEntities(
    [
      ...projectRowCache.map(
        (r) => SelectionEntityMeta(
          key: SelectionKey(
            entityType: EntityType.project,
            entityId: r.project?.id ?? r.rowKey,
          ),
          displayName: r.project?.name ?? 'Inbox',
          canDelete: r.project != null,
          completed: r.project?.completed ?? false,
        ),
      ),
    ].toList(growable: false),
  );

  final specs = <TasklyRowSpec>[];

  for (final row in rows) {
    if (row is! ProjectRowUiModel) continue;
    if (row.project == null) continue;

    final data = buildProjectRowData(
      context,
      project: row.project!,
      taskCount: row.taskCount,
      completedTaskCount: row.completedTaskCount,
      dueSoonCount: row.dueSoonCount,
    );

    final preset = density == DisplayDensity.compact
        ? const TasklyProjectRowPreset.compact()
        : const TasklyProjectRowPreset.standard();

    final actions = TasklyProjectRowActions(
      onTap: () => Routing.toProject(context, row.project!),
    );

    specs.add(
      TasklyRowSpec.project(
        key: row.rowKey,
        depth: row.depth,
        data: data,
        preset: preset,
        actions: actions,
      ),
    );
  }

  return specs;
}

class _ValueFilterChip extends StatelessWidget {
  const _ValueFilterChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.tintColor,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final Color? tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    final baseBg = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerLow;
    final tintAlpha = selected ? 0.16 : 0.12;
    final bg = tintColor == null
        ? baseBg
        : Color.alphaBlend(tintColor!.withValues(alpha: tintAlpha), baseBg);
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final border = selected
        ? scheme.primary.withValues(alpha: 0.28)
        : scheme.outlineVariant.withValues(alpha: 0.7);

    final textStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12);
    const visualHeight = 30.0;

    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radiusPill),
      onTap: onTap,
      child: SizedBox(
        height: tokens.minTapTargetSize,
        child: Center(
          child: Container(
            height: visualHeight,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: tokens.filterPillIconSize - 2,
                  color: iconColor,
                ),
                SizedBox(width: tokens.spaceXxs2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
                      if (count != null && count! > 0)
                        TextSpan(
                          text: ' \u00b7 $count',
                          style: textStyle.copyWith(
                            color: fg.withValues(alpha: 0.7),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (selected) ...[
                  SizedBox(width: tokens.spaceXxs2),
                  Icon(Icons.check_rounded, size: 12, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<ListRowUiModel> _filterProjectsRows({
  required List<ListRowUiModel> rows,
  required Set<String> selectedValueIds,
  required bool showCompleted,
  required ProjectsScope? scope,
}) {
  final filtered = <ListRowUiModel>[];
  for (final row in rows) {
    if (row is! ProjectRowUiModel) {
      filtered.add(row);
      continue;
    }

    final project = row.project;
    final isCompleted = project?.completed ?? false;
    if (!showCompleted && isCompleted) continue;

    if (scope is ProjectsValueScope) {
      filtered.add(row);
      continue;
    }

    if (selectedValueIds.isEmpty) {
      filtered.add(row);
      continue;
    }

    final valueId = project?.primaryValueId;
    if (valueId != null && selectedValueIds.contains(valueId)) {
      filtered.add(row);
    }
  }

  final incomplete = <ProjectRowUiModel>[];
  final completed = <ProjectRowUiModel>[];
  for (final row in filtered) {
    if (row is! ProjectRowUiModel) continue;
    final isCompleted = row.project?.completed ?? false;
    if (isCompleted) {
      completed.add(row);
    } else {
      incomplete.add(row);
    }
  }

  return [
    ...incomplete,
    if (showCompleted) ...completed,
  ];
}

_ValueProjectCounts _countProjectsByValue(List<ListRowUiModel> rows) {
  var total = 0;
  final byValueId = <String, int>{};
  for (final row in rows) {
    if (row is! ProjectRowUiModel) continue;
    final project = row.project;
    if (project == null) continue;
    total += 1;
    final valueId = project.primaryValue?.id;
    if (valueId == null) continue;
    byValueId[valueId] = (byValueId[valueId] ?? 0) + 1;
  }
  return _ValueProjectCounts(total: total, byValueId: byValueId);
}

class _ValueProjectCounts {
  const _ValueProjectCounts({required this.total, required this.byValueId});

  final int total;
  final Map<String, int> byValueId;
}

class _ProjectsTitleHeader extends StatelessWidget {
  const _ProjectsTitleHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'projects',
      iconName: null,
    );

    return Padding(
      padding: tokens.projectsHeaderPadding,
      child: Row(
        children: [
          Icon(
            iconSet.selectedIcon,
            color: scheme.primary,
            size: tokens.spaceLg3,
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projects',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Source for today's plan",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
