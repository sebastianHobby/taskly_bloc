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
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/widgets/display_density_sheet.dart';
import 'package:taskly_bloc/presentation/shared/widgets/filter_sort_sheet.dart';
import 'package:taskly_bloc/presentation/shared/bloc/display_density_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/time.dart';
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
            defaultDensity: DisplayDensity.compact,
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
  ProjectsValueSortOrder _valueSortOrder =
      ProjectsValueSortOrder.lowestAverageRating;
  final Set<String> _selectedValueIds = <String>{};
  final Set<String> _collapsedValueIds = <String>{};
  Set<String> _lastVisibleValueIds = const <String>{};

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

  void _updateValueSortOrder(ProjectsValueSortOrder order) {
    if (_valueSortOrder == order) return;
    setState(() => _valueSortOrder = order);
  }

  void _toggleShowCompleted([bool? value]) {
    setState(() => _showCompleted = value ?? !_showCompleted);
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

  void _toggleValueCollapsed(String valueId) {
    setState(() {
      if (_collapsedValueIds.contains(valueId)) {
        _collapsedValueIds.remove(valueId);
      } else {
        _collapsedValueIds.add(valueId);
      }
    });
  }

  void _collapseAllValues() {
    if (_lastVisibleValueIds.isEmpty) return;
    setState(() => _collapsedValueIds.addAll(_lastVisibleValueIds));
  }

  void _expandAllValues() {
    if (_collapsedValueIds.isEmpty) return;
    setState(_collapsedValueIds.clear);
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
    final l10n = context.l10n;
    final countRows = _filterProjectsRows(
      rows: rows,
      selectedValueIds: const <String>{},
      showCompleted: _showCompleted,
      scope: scope,
    );
    final counts = _countProjectsByValue(countRows);
    final hasScopedValue = scope is ProjectsValueScope;
    await showFilterSortSheet(
      context: context,
      sortGroups: [
        FilterSortRadioGroup(
          title: l10n.projectsSortProjectsOrderTitle,
          options: [
            for (final order in ProjectsSortOrder.values)
              FilterSortRadioOption(
                value: order,
                label: order.label(l10n),
              ),
          ],
          selectedValue: _sortOrder,
          onSelected: (value) {
            if (value is! ProjectsSortOrder) return;
            _updateSortOrder(value);
          },
        ),
        FilterSortRadioGroup(
          title: l10n.projectsSortValuesOrderTitle,
          options: [
            for (final order in ProjectsValueSortOrder.values)
              FilterSortRadioOption(
                value: order,
                label: order.label(l10n),
              ),
          ],
          selectedValue: _valueSortOrder,
          onSelected: (value) {
            if (value is! ProjectsValueSortOrder) return;
            _updateValueSortOrder(value);
          },
        ),
      ],
      sections: [
        FilterSortSection(
          title: l10n.valuesLabel,
          child: Builder(
            builder: (sheetContext) {
              if (hasScopedValue) {
                return Text(
                  l10n.projectsValueFiltersDisabled,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                );
              }
              return Column(
                children: [
                  _ValueFilterRow(
                    label: l10n.allValuesLabel,
                    count: counts.total,
                    selected: _selectedValueIds.isEmpty,
                    icon: Icons.filter_list_rounded,
                    iconColor: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurfaceVariant,
                    onTap: _clearValueFilters,
                  ),
                  for (final value in values) ...[
                    _ValueFilterRow(
                      label: value.name,
                      count: counts.byValueId[value.id],
                      selected: _selectedValueIds.contains(value.id),
                      icon: value.toChipData(sheetContext).icon,
                      iconColor: value.toChipData(sheetContext).color,
                      onTap: () => _toggleValueFilter(value.id),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
      toggles: [
        FilterSortToggle(
          title: context.l10n.showCompletedLabel,
          value: _showCompleted,
          onChanged: _toggleShowCompleted,
        ),
      ],
    );
  }

  Future<void> _showDensitySheet(DisplayDensity density) async {
    await showDisplayDensitySheet(
      context: context,
      density: density,
      onChanged: (next) {
        context.read<DisplayDensityBloc>().add(DisplayDensitySet(next));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chrome = TasklyTokens.of(context);
    final density = context.select<DisplayDensityBloc, DisplayDensity>(
      (bloc) => bloc.state.density,
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
                ? SelectionAppBar(
                    baseTitle: context.l10n.projectsTitle,
                    onExit: _noop,
                  )
                : AppBar(
                    centerTitle: true,
                    toolbarHeight: chrome.projectsAppBarHeight,
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: context.l10n.searchProjectsHint,
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
                    actions: [
                      IconButton(
                        tooltip: context.l10n.filterSortTooltip,
                        icon: const Icon(Icons.tune_rounded),
                        style: iconButtonStyle,
                        onPressed: () {
                          final state = context.read<ProjectsFeedBloc>().state;
                          if (state is! ProjectsFeedLoaded) return;
                          _showFilterSheet(
                            values: state.values,
                            rows: state.rows,
                          );
                        },
                      ),
                      if (!_isSearching)
                        IconButton(
                          tooltip: context.l10n.searchLabel,
                          icon: const Icon(Icons.search),
                          style: iconButtonStyle,
                          onPressed: () => _setSearchActive(true),
                        )
                      else
                        IconButton(
                          tooltip: context.l10n.closeSearchLabel,
                          icon: const Icon(Icons.close),
                          style: iconButtonStyle,
                          onPressed: () => _setSearchActive(false),
                        ),
                      TasklyOverflowMenuButton<_ProjectsMenuAction>(
                        tooltip: context.l10n.moreLabel,
                        icon: Icons.more_vert,
                        style: iconButtonStyle,
                        itemsBuilder: (context) => [
                          PopupMenuItem(
                            value: _ProjectsMenuAction.density,
                            child: TasklyMenuItemLabel(
                              context.l10n.displayDensityTitle,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ProjectsMenuAction.expandAll,
                            child: TasklyMenuItemLabel(
                              context.l10n.projectsExpandAllLabel,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ProjectsMenuAction.collapseAll,
                            child: TasklyMenuItemLabel(
                              context.l10n.projectsCollapseAllLabel,
                            ),
                          ),
                          PopupMenuItem(
                            value: _ProjectsMenuAction.selectMultiple,
                            child: TasklyMenuItemLabel(
                              context.l10n.selectMultipleLabel,
                            ),
                          ),
                        ],
                        onSelected: (action) {
                          switch (action) {
                            case _ProjectsMenuAction.density:
                              _showDensitySheet(density);
                            case _ProjectsMenuAction.expandAll:
                              _expandAllValues();
                            case _ProjectsMenuAction.collapseAll:
                              _collapseAllValues();
                            case _ProjectsMenuAction.selectMultiple:
                              context
                                  .read<SelectionBloc>()
                                  .enterSelectionMode();
                          }
                        },
                      ),
                    ],
                  ),
            floatingActionButton: selectionState.isSelectionMode
                ? null
                : SizedBox(
                    key: GuidedTourAnchors.projectsCreateProject,
                    child: EntityAddFab(
                      heroTag: 'add_speed_dial_projects',
                      tooltip: context.l10n.addProjectAction,
                      onPressed: () => context.read<ProjectsScreenBloc>().add(
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
                          final shouldShowInboxTile =
                              scope == null &&
                              screenState.searchQuery.trim().isEmpty;
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
                            ProjectsFeedLoaded(
                              :final rows,
                            )
                                when rows.isEmpty && !shouldShowInboxTile =>
                              TasklyFeedSpec.empty(
                                empty: _buildEmptySpec(
                                  context,
                                  scope,
                                  screenState,
                                  showCompleted: _showCompleted,
                                  completionCounts: _countProjectsByCompletion(
                                    rows,
                                  ),
                                ),
                              ),
                            ProjectsFeedLoaded(:final rows) => () {
                              final visibleRows = _filterProjectsRows(
                                rows: rows,
                                selectedValueIds: _selectedValueIds,
                                showCompleted: _showCompleted,
                                scope: scope,
                              );
                              _lastVisibleValueIds = _extractVisibleValueIds(
                                visibleRows,
                              );
                              if (visibleRows.isEmpty && !shouldShowInboxTile) {
                                return TasklyFeedSpec.empty(
                                  empty: _buildEmptySpec(
                                    context,
                                    scope,
                                    screenState,
                                    showCompleted: _showCompleted,
                                    completionCounts:
                                        _countProjectsByCompletion(rows),
                                  ),
                                );
                              }
                              final sections = <TasklySectionSpec>[];
                              sections.add(
                                TasklySectionSpec.standardList(
                                  id: 'projects',
                                  rows: _buildGroupedRows(
                                    context,
                                    visibleRows,
                                    values: state.values,
                                    ratings: state.ratings,
                                    density: density,
                                    selectionState: selectionState,
                                    includeInboxTile: shouldShowInboxTile,
                                    inboxTaskCount: state.inboxTaskCount,
                                    valueSortOrder: _valueSortOrder,
                                    showCompleted: _showCompleted,
                                    collapsedValueIds: _collapsedValueIds,
                                    onToggleCollapsed: _toggleValueCollapsed,
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
  density,
  expandAll,
  collapseAll,
  selectMultiple,
}

TasklyEmptyStateSpec _buildEmptySpec(
  BuildContext context,
  ProjectsScope? scope,
  ProjectsScreenState screenState, {
  required bool showCompleted,
  required _ProjectCompletionCounts completionCounts,
}) {
  final query = screenState.searchQuery.trim();
  if (query.isNotEmpty) {
    return TasklyEmptyStateSpec(
      icon: Icons.search,
      title: context.l10n.projectsSearchNoMatchesTitle,
      description: context.l10n.projectsSearchNoMatchesDescription,
      actionLabel: context.l10n.clearSearchLabel,
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
        ProjectsValueScope() => context.l10n.projectsValueScopeEmptyTitle,
        ProjectsProjectScope() => context.l10n.projectsProjectScopeEmptyTitle,
      },
      description: switch (scope) {
        ProjectsValueScope() => context.l10n.projectsValueScopeEmptyDescription,
        ProjectsProjectScope() =>
          context.l10n.projectsProjectScopeEmptyDescription,
      },
      actionLabel: context.l10n.addProjectAction,
      onAction: () => context.read<ProjectsScreenBloc>().add(
        const ProjectsCreateProjectRequested(),
      ),
    );
  }

  if (completionCounts.total == 0 ||
      (!showCompleted && completionCounts.active == 0) ||
      (showCompleted && completionCounts.completed == 0)) {
    final l10n = context.l10n;
    final title = showCompleted
        ? l10n.projectsEmptyCompletedTitle
        : l10n.projectsEmptyActiveTitle;
    final description = showCompleted
        ? l10n.projectsEmptyCompletedDescription
        : l10n.projectsEmptyActiveDescription;
    return TasklyEmptyStateSpec(
      icon: Icons.inbox_outlined,
      title: title,
      description: description,
      actionLabel: showCompleted ? null : l10n.addProjectAction,
      onAction: showCompleted
          ? null
          : () => context.read<ProjectsScreenBloc>().add(
              const ProjectsCreateProjectRequested(),
            ),
    );
  }

  return TasklyEmptyStateSpec(
    icon: Icons.inbox_outlined,
    title: context.l10n.projectsEmptyBuildTitle,
    description: context.l10n.projectsEmptyBuildDescription,
    actionLabel: context.l10n.addProjectAction,
    onAction: () => context.read<ProjectsScreenBloc>().add(
      const ProjectsCreateProjectRequested(),
    ),
  );
}

_ProjectCompletionCounts _countProjectsByCompletion(List<ListRowUiModel> rows) {
  var total = 0;
  var completed = 0;
  for (final row in rows) {
    if (row is! ProjectRowUiModel) continue;
    final project = row.project;
    if (project == null) continue;
    total += 1;
    if (project.completed) completed += 1;
  }
  return _ProjectCompletionCounts(total: total, completed: completed);
}

class _ProjectCompletionCounts {
  const _ProjectCompletionCounts({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  int get active => total - completed;
}

List<TasklyRowSpec> _buildGroupedRows(
  BuildContext context,
  List<ListRowUiModel> rows, {
  required List<Value> values,
  required List<ValueWeeklyRating> ratings,
  required DisplayDensity density,
  required SelectionState selectionState,
  required bool includeInboxTile,
  required int inboxTaskCount,
  required ProjectsValueSortOrder valueSortOrder,
  required bool showCompleted,
  required Set<String> collapsedValueIds,
  required void Function(String valueId) onToggleCollapsed,
}) {
  final selection = context.read<SelectionBloc>();
  final selectionMode = selectionState.isSelectionMode;

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
          displayName: r.project?.name ?? context.l10n.inboxLabel,
          canDelete: r.project != null,
          completed: r.project?.completed ?? false,
        ),
      ),
    ].toList(growable: false),
  );

  final specs = <TasklyRowSpec>[];
  if (includeInboxTile) {
    specs.add(
      TasklyRowSpec.project(
        key: RowKey.v1(
          screen: 'projects',
          rowType: 'inbox',
        ),
        depth: 0,
        data: buildInboxProjectRowData(
          context,
          taskCount: inboxTaskCount,
        ),
        preset: const TasklyProjectRowPreset.inbox(),
        actions: TasklyProjectRowActions(
          onTap: selectionMode
              ? null
              : () => Routing.toScreenKey(context, 'inbox'),
        ),
      ),
    );
  }

  final nowUtc = context.read<NowService>().nowUtc();
  final summaries = _buildValueRatingSummaries(
    values: values,
    ratings: ratings,
    nowUtc: nowUtc,
  );

  final grouped = _groupProjectRowsByValue(
    rows: projectRowCache,
    values: values,
    summaries: summaries,
    sortOrder: valueSortOrder,
    collapsedValueIds: collapsedValueIds,
    onToggleCollapsed: onToggleCollapsed,
  );

  for (var index = 0; index < grouped.length; index += 1) {
    final group = grouped[index];
    final summary = summaries[group.value.id];
    final expanded = !group.collapsed;
    final visibleCount = showCompleted
        ? group.projectRows.length
        : group.projectRows
              .where((row) => !(row.project?.completed ?? false))
              .length;
    specs.add(
      TasklyRowSpec.header(
        key: 'value-header-${group.value.id}',
        title: group.value.name,
        leadingIcon: group.value.toChipData(context).icon,
        leadingIconColor: group.value.toChipData(context).color,
        subtitle: expanded
            ? _buildValueHeaderSubtitle(
                context,
                summary: summary,
                nowUtc: nowUtc,
              )
            : null,
        trailingLabel: _buildValueHeaderTrailingLabel(
          context,
          summary: summary,
          projectCount: visibleCount,
          expanded: expanded,
        ),
        trailingIcon: expanded
            ? Icons.expand_less_rounded
            : Icons.expand_more_rounded,
        onTap: group.onToggleCollapsed,
        dividerOpacity: expanded ? null : 0.25,
      ),
    );

    if (expanded) {
      specs.addAll(
        _buildProjectRowSpecs(
          context,
          group.projectRows,
          density: density,
          selectionState: selectionState,
          selectionMode: selectionMode,
          selection: selection,
          showCompleted: showCompleted,
        ),
      );
    }

    final isLast = index == grouped.length - 1;
    if (!isLast && expanded) {
      specs.add(
        TasklyRowSpec.divider(
          key: 'value-divider-${group.value.id}',
        ),
      );
    }
  }

  return specs;
}

List<TasklyRowSpec> _buildProjectRowSpecs(
  BuildContext context,
  List<ProjectRowUiModel> rows, {
  required DisplayDensity density,
  required SelectionState selectionState,
  required bool selectionMode,
  required SelectionBloc selection,
  required bool showCompleted,
}) {
  final visible = showCompleted
      ? _orderProjectsByCompletion(rows)
      : rows.where((row) => !(row.project?.completed ?? false)).toList();

  final specs = <TasklyRowSpec>[];
  for (final row in visible) {
    final project = row.project;
    if (project == null) continue;

    final valueChip = project.primaryValue?.toChipData(context);
    final data = buildProjectRowData(
      context,
      project: project,
      taskCount: row.taskCount,
      completedTaskCount: row.completedTaskCount,
      dueSoonCount: row.dueSoonCount,
      valueChipOverride: valueChip,
      includeValueIcon: false,
      accentColor: valueChip?.color,
    );

    final key = SelectionKey(
      entityType: EntityType.project,
      entityId: project.id,
    );
    final isSelected = selectionState.selected.contains(key);

    final preset = selectionMode
        ? (density == DisplayDensity.compact
              ? TasklyProjectRowPreset.bulkSelectionCompact(
                  selected: isSelected,
                )
              : TasklyProjectRowPreset.bulkSelection(selected: isSelected))
        : (density == DisplayDensity.compact
              ? const TasklyProjectRowPreset.compact()
              : const TasklyProjectRowPreset.standard());
    void handleLongPress() =>
        selection.enterSelectionMode(initialSelection: key);

    final actions = TasklyProjectRowActions(
      onTap: () {
        if (selection.shouldInterceptTapAsSelection()) {
          selection.handleEntityTap(key);
          return;
        }
        Routing.toProject(context, project);
      },
      onLongPress: handleLongPress,
      onToggleSelected: selectionMode
          ? () => selection.toggleSelection(key, extendRange: false)
          : null,
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

List<ProjectRowUiModel> _orderProjectsByCompletion(
  List<ProjectRowUiModel> rows,
) {
  final incomplete = <ProjectRowUiModel>[];
  final completed = <ProjectRowUiModel>[];
  for (final row in rows) {
    final isCompleted = row.project?.completed ?? false;
    if (isCompleted) {
      completed.add(row);
    } else {
      incomplete.add(row);
    }
  }
  return [...incomplete, ...completed];
}

Set<String> _extractVisibleValueIds(List<ListRowUiModel> rows) {
  final ids = <String>{};
  for (final row in rows) {
    if (row is! ProjectRowUiModel) continue;
    final valueId = row.project?.primaryValueId;
    if (valueId != null) {
      ids.add(valueId);
    }
  }
  return ids;
}

final class _ProjectsValueRatingSummary {
  const _ProjectsValueRatingSummary({
    required this.valueId,
    required this.averageRating,
    required this.trendDelta,
    required this.lastRatingWeekStartUtc,
    required this.lastRatingValue,
  });

  final String valueId;
  final double? averageRating;
  final double? trendDelta;
  final DateTime? lastRatingWeekStartUtc;
  final int? lastRatingValue;
}

final class _ProjectsValueGroup {
  const _ProjectsValueGroup({
    required this.value,
    required this.projectRows,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final Value value;
  final List<ProjectRowUiModel> projectRows;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
}

Map<String, _ProjectsValueRatingSummary> _buildValueRatingSummaries({
  required List<Value> values,
  required List<ValueWeeklyRating> ratings,
  required DateTime nowUtc,
}) {
  if (values.isEmpty) return const {};

  final ratingsByValue = <String, Map<DateTime, int>>{};
  final lastRatingByValue = <String, DateTime>{};
  for (final rating in ratings) {
    final weekStart = _weekStartFor(rating.weekStartUtc);
    (ratingsByValue[rating.valueId] ??= {})[weekStart] = rating.rating.clamp(
      1,
      10,
    );
    final last = lastRatingByValue[rating.valueId];
    if (last == null || weekStart.isAfter(last)) {
      lastRatingByValue[rating.valueId] = weekStart;
    }
  }

  final nowWeekStart = _weekStartFor(nowUtc);
  final recentWeeks = <DateTime>[
    for (var i = _ratingsWindowWeeks - 1; i >= 0; i -= 1)
      nowWeekStart.subtract(Duration(days: i * 7)),
  ];
  final priorWeeks = <DateTime>[
    for (
      var i = (_ratingsWindowWeeks * 2) - 1;
      i >= _ratingsWindowWeeks;
      i -= 1
    )
      nowWeekStart.subtract(Duration(days: i * 7)),
  ];

  final summaries = <String, _ProjectsValueRatingSummary>{};
  for (final value in values) {
    final valueId = value.id;
    final perWeek = ratingsByValue[valueId] ?? const {};
    final recentRatings = <int>[
      for (final week in recentWeeks)
        if (perWeek[week] != null) perWeek[week]!,
    ];
    final priorRatings = <int>[
      for (final week in priorWeeks)
        if (perWeek[week] != null) perWeek[week]!,
    ];

    final averageRating = recentRatings.isEmpty
        ? null
        : recentRatings.fold<int>(0, (sum, v) => sum + v) /
              recentRatings.length;
    final priorAverage = priorRatings.isEmpty
        ? null
        : priorRatings.fold<int>(0, (sum, v) => sum + v) / priorRatings.length;
    final trendDelta = (averageRating != null && priorAverage != null)
        ? averageRating - priorAverage
        : null;

    final lastWeekStart = lastRatingByValue[valueId];
    final lastRatingValue = lastWeekStart == null
        ? null
        : perWeek[lastWeekStart];

    summaries[valueId] = _ProjectsValueRatingSummary(
      valueId: valueId,
      averageRating: averageRating,
      trendDelta: trendDelta,
      lastRatingWeekStartUtc: lastWeekStart,
      lastRatingValue: lastRatingValue,
    );
  }

  return summaries;
}

List<_ProjectsValueGroup> _groupProjectRowsByValue({
  required List<ProjectRowUiModel> rows,
  required List<Value> values,
  required Map<String, _ProjectsValueRatingSummary> summaries,
  required ProjectsValueSortOrder sortOrder,
  required Set<String> collapsedValueIds,
  required void Function(String valueId) onToggleCollapsed,
}) {
  final rowsByValueId = <String, List<ProjectRowUiModel>>{};
  for (final row in rows) {
    final valueId = row.project?.primaryValueId;
    if (valueId == null) continue;
    (rowsByValueId[valueId] ??= <ProjectRowUiModel>[]).add(row);
  }

  final valueMap = {for (final value in values) value.id: value};
  final valueList = <Value>[
    for (final entry in rowsByValueId.entries)
      if (valueMap.containsKey(entry.key)) valueMap[entry.key]!,
  ];

  valueList.sort(
    (a, b) => _compareValues(
      a,
      b,
      summaries: summaries,
      sortOrder: sortOrder,
    ),
  );

  return [
    for (final value in valueList)
      _ProjectsValueGroup(
        value: value,
        projectRows: rowsByValueId[value.id] ?? const <ProjectRowUiModel>[],
        collapsed: collapsedValueIds.contains(value.id),
        onToggleCollapsed: () => onToggleCollapsed(value.id),
      ),
  ];
}

int _compareValues(
  Value a,
  Value b, {
  required Map<String, _ProjectsValueRatingSummary> summaries,
  required ProjectsValueSortOrder sortOrder,
}) {
  final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (sortOrder == ProjectsValueSortOrder.alphabetical) return nameCompare;

  final summaryA = summaries[a.id];
  final summaryB = summaries[b.id];
  final avgA = summaryA?.averageRating;
  final avgB = summaryB?.averageRating;
  final trendA = summaryA?.trendDelta;
  final trendB = summaryB?.trendDelta;

  if (avgA == null || avgB == null) {
    return nameCompare;
  }

  switch (sortOrder) {
    case ProjectsValueSortOrder.lowestAverageRating:
      final byAvg = avgA.compareTo(avgB);
      if (byAvg != 0) return byAvg;
      final byTrend = (trendA ?? double.infinity).compareTo(
        trendB ?? double.infinity,
      );
      if (byTrend != 0) return byTrend;
      return nameCompare;
    case ProjectsValueSortOrder.ratingTrendingDown:
      final byTrend = (trendA ?? double.infinity).compareTo(
        trendB ?? double.infinity,
      );
      if (byTrend != 0) return byTrend;
      final byAvg = avgA.compareTo(avgB);
      if (byAvg != 0) return byAvg;
      return nameCompare;
    case ProjectsValueSortOrder.alphabetical:
      return nameCompare;
  }
}

String _buildValueHeaderTrailingLabel(
  BuildContext context, {
  required _ProjectsValueRatingSummary? summary,
  required int projectCount,
  required bool expanded,
}) {
  final l10n = context.l10n;
  return l10n.projectsValueProjectCountLabel(projectCount);
}

String? _buildValueHeaderSubtitle(
  BuildContext context, {
  required _ProjectsValueRatingSummary? summary,
  required DateTime nowUtc,
}) {
  final l10n = context.l10n;
  final lastRatingDate = summary?.lastRatingWeekStartUtc;
  if (lastRatingDate == null) {
    return null;
  }
  final averageValue = summary?.averageRating?.toStringAsFixed(1);
  final averageLabel = averageValue == null
      ? null
      : l10n.projectsAverageRatingLabel(averageValue);
  final lastRatingValue = summary?.lastRatingValue;
  final ratingLabel = lastRatingValue == null
      ? null
      : l10n.projectsRatingLabel(lastRatingValue.toDouble().toStringAsFixed(1));
  final lastRatedLabel = l10n.projectsAverageRatingLastRatedLabel(
    l10n.dateDaysAgo(
      dateOnly(
        nowUtc,
      ).difference(dateOnly(lastRatingDate)).inDays.clamp(0, 9999),
    ),
  );
  final primaryLabel = averageLabel ?? ratingLabel;
  return primaryLabel == null
      ? lastRatedLabel
      : [primaryLabel, lastRatedLabel].join(l10n.projectsValueHeaderSeparator);
}

DateTime _weekStartFor(DateTime dateUtc) {
  final date = dateOnly(dateUtc.toUtc());
  return DateTime.utc(date.year, date.month, date.day);
}

const int _ratingsWindowWeeks = 4;

class _ValueFilterRow extends StatelessWidget {
  const _ValueFilterRow({
    required this.label,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final countLabel = count == null ? null : '$count';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: fg,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countLabel != null)
            Text(
              countLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, size: 18, color: scheme.primary),
          ],
        ],
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
  return filtered;
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
                  context.l10n.projectsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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
