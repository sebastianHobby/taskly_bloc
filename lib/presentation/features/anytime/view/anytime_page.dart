import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_models.dart';

import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';

class AnytimePage extends StatelessWidget {
  const AnytimePage({
    this.scope,
    super.key,
  });

  final AnytimeScope? scope;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AnytimeScreenBloc(scope: scope)),
        BlocProvider(
          create: (_) => AnytimeFeedBloc(
            queryService: getIt<AnytimeSessionQueryService>(),
            scope: scope,
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: _AnytimeView(scope: scope),
    );
  }
}

class _AnytimeView extends StatefulWidget {
  const _AnytimeView({required this.scope});

  final AnytimeScope? scope;

  @override
  State<_AnytimeView> createState() => _AnytimeViewState();
}

class _AnytimeViewState extends State<_AnytimeView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  AnytimeScope? get scope => widget.scope;

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
      context.read<AnytimeScreenBloc>().add(
        const AnytimeSearchQueryChanged(''),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    String? defaultProjectId,
    String? defaultValueId,
  }) {
    return EditorLauncher.fromGetIt().openTaskEditor(
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
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      openToValues: openToValues,
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = WindowSizeClass.of(context).isCompact;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chrome = TasklyChromeTheme.of(context);
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
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) => prev.focusOnly != next.focusOnly,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedFocusOnlyChanged(enabled: state.focusOnly),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) =>
              prev.showStartLaterItems != next.showStartLaterItems,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedShowStartLaterItemsChanged(
                enabled: state.showStartLaterItems,
              ),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) => prev.searchQuery != next.searchQuery,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedSearchQueryChanged(query: state.searchQuery),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) =>
              prev.inboxCollapsed != next.inboxCollapsed,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedInboxCollapsedChanged(collapsed: state.inboxCollapsed),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) =>
              !_sameSet(prev.collapsedValueIds, next.collapsedValueIds),
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedValueCollapsedChanged(
                collapsedValueIds: state.collapsedValueIds,
              ),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) => prev.effect != next.effect,
          listener: (context, state) {
            final effect = state.effect;
            if (effect == null) return;

            switch (effect) {
              case AnytimeNavigateToProjectAnytime(:final projectId):
                Routing.pushProjectAnytime(context, projectId);
              case AnytimeNavigateToTaskEdit(:final taskId):
                Routing.toTaskEdit(context, taskId);
              case AnytimeNavigateToTaskNew(
                :final defaultProjectId,
                :final defaultValueId,
              ):
                _openNewTaskEditor(
                  context,
                  defaultProjectId: defaultProjectId,
                  defaultValueId: defaultValueId,
                );
              case AnytimeOpenProjectNew(:final openToValues):
                _openNewProjectEditor(context, openToValues: openToValues);
            }

            context.read<AnytimeScreenBloc>().add(const AnytimeEffectHandled());
          },
        ),
      ],
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, selectionState) {
          return Scaffold(
            appBar: selectionState.isSelectionMode
                ? const SelectionAppBar(baseTitle: 'Anytime', onExit: _noop)
                : AppBar(
                    centerTitle: true,
                    toolbarHeight: chrome.anytimeAppBarHeight,
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search projects',
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              context.read<AnytimeScreenBloc>().add(
                                AnytimeSearchQueryChanged(value),
                              );
                            },
                          )
                        : const Text('Anytime'),
                    actions: TasklyAppBarActions.withAttentionBell(
                      context,
                      actions: [
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
                        if (!isCompact)
                          EntityAddMenuButton(
                            onCreateTask: () =>
                                context.read<AnytimeScreenBloc>().add(
                                  const AnytimeCreateTaskRequested(),
                                ),
                            onCreateProject: () =>
                                context.read<AnytimeScreenBloc>().add(
                                  const AnytimeCreateProjectRequested(),
                                ),
                          ),
                        BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
                          buildWhen: (p, n) => p.focusOnly != n.focusOnly,
                          builder: (context, state) {
                            final enabled = state.focusOnly;
                            return IconButton(
                              tooltip: enabled
                                  ? 'Focus only: on'
                                  : 'Focus only: off',
                              icon: Icon(
                                enabled
                                    ? Icons.filter_alt
                                    : Icons.filter_alt_off,
                              ),
                              style: iconButtonStyle,
                              onPressed: () {
                                context.read<AnytimeScreenBloc>().add(
                                  const AnytimeFocusOnlyToggled(),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
            floatingActionButton: isCompact
                ? EntityAddSpeedDial(
                    heroTag: 'add_speed_dial_anytime',
                    onCreateTask: () => context.read<AnytimeScreenBloc>().add(
                      const AnytimeCreateTaskRequested(),
                    ),
                    onCreateProject: () =>
                        context.read<AnytimeScreenBloc>().add(
                          const AnytimeCreateProjectRequested(),
                        ),
                  )
                : null,
            body: Column(
              children: [
                Padding(
                  padding: chrome.anytimeHeaderPadding,
                  child: _AnytimeValuesAndFiltersRow(scope: scope),
                ),
                Expanded(
                  child: BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
                    buildWhen: (p, n) =>
                        p.searchQuery != n.searchQuery ||
                        p.showStartLaterItems != n.showStartLaterItems,
                    builder: (context, screenState) {
                      return BlocBuilder<AnytimeFeedBloc, AnytimeFeedState>(
                        builder: (context, state) {
                          final spec = switch (state) {
                            AnytimeFeedLoading() => const TasklyFeedSpec.loading(),
                            AnytimeFeedError(:final message) => TasklyFeedSpec.error(
                              message: message,
                              retryLabel: context.l10n.retryButton,
                              onRetry: () =>
                                  context.read<AnytimeFeedBloc>().add(
                                    const AnytimeFeedRetryRequested(),
                                  ),
                            ),
                            AnytimeFeedLoaded(:final rows) when rows.isEmpty =>
                              TasklyFeedSpec.empty(
                                empty: _buildEmptySpec(
                                  context,
                                  scope,
                                  screenState,
                                ),
                              ),
                            AnytimeFeedLoaded(:final rows) => TasklyFeedSpec.content(
                              sections: [
                                TasklySectionSpec.standardList(
                                  id: 'anytime',
                                  rows: _buildStandardRows(context, rows),
                                ),
                              ],
                            ),
                          };

                          return TasklyFeedRenderer(spec: spec);
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

TasklyEmptyStateSpec _buildEmptySpec(
  BuildContext context,
  AnytimeScope? scope,
  AnytimeScreenState screenState,
) {
  final query = screenState.searchQuery.trim();
  if (query.isNotEmpty) {
    return TasklyEmptyStateSpec(
      icon: Icons.search,
      title: 'No matches',
      description: 'Try a different keyword.',
      actionLabel: 'Clear search',
      onAction: () {
        context.read<AnytimeScreenBloc>().add(
          const AnytimeSearchQueryChanged(''),
        );
      },
    );
  }

  if (scope != null) {
    return TasklyEmptyStateSpec(
      icon: Icons.inbox_outlined,
      title: 'Nothing in this scope yet',
      description: "Try a different scope or show 'Start later' items.",
      actionLabel: 'Create project',
      onAction: () => context.read<AnytimeScreenBloc>().add(
        const AnytimeCreateProjectRequested(),
      ),
    );
  }

  return TasklyEmptyStateSpec(
    icon: Icons.inbox_outlined,
    title: 'No backlog items yet',
    description: 'Create a project to start planning.',
    actionLabel: 'Create project',
    onAction: () => context.read<AnytimeScreenBloc>().add(
      const AnytimeCreateProjectRequested(),
    ),
  );
}

List<TasklyRowSpec> _buildStandardRows(
  BuildContext context,
  List<ListRowUiModel> rows,
) {
  final selection = context.read<SelectionCubit>();

  selection.updateVisibleEntities(
    [
      ...rows.whereType<TaskRowUiModel>().map(
        (r) => SelectionEntityMeta(
          key: SelectionKey(entityType: EntityType.task, entityId: r.task.id),
          displayName: r.task.name,
          canDelete: true,
          completed: r.task.completed,
          pinned: r.task.isPinned,
          canCompleteSeries: r.task.isRepeating && !r.task.seriesEnded,
        ),
      ),
      ...rows.whereType<ProjectRowUiModel>().map(
        (r) => SelectionEntityMeta(
          key: SelectionKey(
            entityType: EntityType.project,
            entityId: r.project?.id ?? r.rowKey,
          ),
          displayName: r.project?.name ?? 'Inbox',
          canDelete: r.project != null,
          completed: r.project?.completed ?? false,
          pinned: r.project?.isPinned ?? false,
        ),
      ),
    ].toList(growable: false),
  );

  return rows
      .map<TasklyRowSpec>((row) {
        return switch (row) {
          ValueHeaderRowUiModel(
            :final title,
            :final valueId,
            :final value,
            :final activeCount,
            :final isCollapsed
          ) =>
            TasklyRowSpec.valueHeader(
              key: row.rowKey,
              depth: row.depth,
              title: title,
              leadingChip: value?.toChipData(context),
              trailingLabel: _activeCountLabel(activeCount),
              isCollapsed: isCollapsed,
              onToggleCollapsed: () => context.read<AnytimeScreenBloc>().add(
                    AnytimeValueHeaderToggled(
                      valueKey: valueId ?? '__none__',
                    ),
                  ),
            ),
          ProjectHeaderRowUiModel(:final projectRef, :final title) => () {
            final expandable = row.isCollapsed != null;
            final expanded = !(row.isCollapsed ?? true);
            return TasklyRowSpec.project(
              key: row.rowKey,
              depth: row.depth,
              data: TasklyProjectRowData(
                id: projectRef.stableKey,
                title: title,
                completed: false,
                pinned: false,
                meta: const TasklyEntityMetaData(),
                groupLeadingIcon: projectRef.isInbox
                    ? Icons.inbox_outlined
                    : Icons.folder_outlined,
                groupTrailingLabel: row.trailingLabel,
              ),
              preset: TasklyProjectRowPreset.groupHeader(expanded: expanded),
              actions: TasklyProjectRowActions(
                onTap: () => context.read<AnytimeScreenBloc>().add(
                  AnytimeProjectHeaderTapped(projectRef: projectRef),
                ),
                onToggleExpanded: expandable
                    ? () => context.read<AnytimeScreenBloc>().add(
                          AnytimeProjectHeaderTapped(projectRef: projectRef),
                        )
                    : null,
              ),
            );
          }(),
          TaskRowUiModel(:final task) => () {
            final tileCapabilities = EntityTileCapabilitiesResolver.forTask(
              task,
            );

            final key = SelectionKey(
              entityType: EntityType.task,
              entityId: task.id,
            );

            final data = buildTaskRowData(
              context,
              task: task,
              tileCapabilities: tileCapabilities,
            );

            final openEditor = buildTaskOpenEditorHandler(
              context,
              task: task,
            );

            final isSelected = selection.isSelected(key);
            final selectionMode = selection.isSelectionMode;

            return TasklyRowSpec.task(
              key: row.rowKey,
              depth: row.depth,
              data: data,
              markers: TasklyTaskRowMarkers(pinned: task.isPinned),
              preset: selectionMode
                  ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
                  : const TasklyTaskRowPreset.standard(),
              actions: TasklyTaskRowActions(
                onTap: () {
                  if (selection.shouldInterceptTapAsSelection()) {
                    selection.handleEntityTap(key);
                    return;
                  }
                  openEditor();
                },
                onLongPress: () {
                  selection.enterSelectionMode(initialSelection: key);
                },
                onToggleSelected: () =>
                    selection.toggleSelection(key, extendRange: false),
                onToggleCompletion: buildTaskToggleCompletionHandler(
                  context,
                  task: task,
                  tileCapabilities: tileCapabilities,
                ),
              ),
            );
          }(),
          ProjectRowUiModel(
            :final project,
            :final taskCount,
            :final completedTaskCount
          ) =>
            () {
              final data = project == null
                  ? TasklyProjectRowData(
                      id: 'inbox',
                      title: 'Inbox',
                      completed: false,
                      pinned: false,
                      meta: const TasklyEntityMetaData(),
                      taskCount: taskCount,
                      completedTaskCount: completedTaskCount,
                    )
                  : _stripProjectValueChip(
                      buildProjectRowData(
                        context,
                        project: project,
                        taskCount: taskCount,
                        completedTaskCount: completedTaskCount,
                      ),
                    );

              return TasklyRowSpec.project(
                key: row.rowKey,
                depth: row.depth,
                data: data,
                preset: const TasklyProjectRowPreset.standard(),
                actions: TasklyProjectRowActions(
                  onTap: project == null
                      ? null
                      : () => Routing.toProjectEdit(context, project.id),
                ),
              );
            }(),
        };
      })
      .toList(growable: false);
}

TasklyProjectRowData _stripProjectValueChip(TasklyProjectRowData data) {
  return TasklyProjectRowData(
    id: data.id,
    title: data.title,
    completed: data.completed,
    pinned: data.pinned,
    meta: data.meta,
    taskCount: data.taskCount,
    completedTaskCount: data.completedTaskCount,
    leadingChip: null,
    subtitle: data.subtitle,
    deemphasized: data.deemphasized,
    groupLeadingIcon: data.groupLeadingIcon,
    groupTrailingLabel: data.groupTrailingLabel,
  );
}

String _activeCountLabel(int count) {
  if (count <= 0) return '0 Active';
  return count == 1 ? '1 Active' : '$count Active';
}

bool _sameSet(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}

class _AnytimeValuesAndFiltersRow extends StatelessWidget {
  const _AnytimeValuesAndFiltersRow({required this.scope});

  final AnytimeScope? scope;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = TasklyChromeTheme.of(context);
    final valueRepository = getIt<ValueRepositoryContract>();

    final selectedValueId = switch (scope) {
      AnytimeValueScope(:final valueId) => valueId,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<Value>>(
          stream: valueRepository.watchAll(),
          builder: (context, snapshot) {
            final values = snapshot.data ?? const <Value>[];
            final sorted = values.toList(growable: false)
              ..sort(_compareValues);

            final allChip = ValueChipData(
              label: 'All',
              icon: Icons.apps_rounded,
              color: scheme.primary,
              semanticLabel: 'All values',
            );

            return SizedBox(
              height: chrome.valueRowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final data = isAll
                      ? allChip
                      : sorted[index - 1].toChipData(context);
                  final isSelected = isAll
                      ? selectedValueId == null
                      : sorted[index - 1].id == selectedValueId;

                  return _ValueIconButton(
                    data: data,
                    selected: isSelected,
                    onTap: () async {
                      if (isSelected) return;
                      if (isAll) {
                        await GoRouter.of(context).push('/anytime');
                      } else {
                        Routing.pushValueAnytime(
                          context,
                          sorted[index - 1].id,
                        );
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) =>
                    SizedBox(width: chrome.valueItemSpacing),
                itemCount: sorted.length + 1,
              ),
            );
          },
        ),
        SizedBox(height: chrome.filterRowSpacing),
        BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
          buildWhen: (p, n) => p.showStartLaterItems != n.showStartLaterItems,
          builder: (context, state) {
            final showStartLater = state.showStartLaterItems;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Filters',
                    selected: false,
                    onTap: () {},
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onSurface,
                    leadingIcon: Icons.tune_rounded,
                  ),
                  _FilterPill(
                    label: showStartLater ? 'Start later' : 'Start later',
                    selected: showStartLater,
                    onTap: () => context.read<AnytimeScreenBloc>().add(
                          AnytimeShowStartLaterSet(!showStartLater),
                        ),
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onSurface,
                    leadingIcon: Icons.schedule,
                  ),
                  _FilterPill(
                    label: 'Due Soon',
                    selected: false,
                    onTap: () {},
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onSurface,
                  ),
                  _FilterPill(
                    label: 'Overdue',
                    selected: false,
                    onTap: () {},
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.errorContainer,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onErrorContainer,
                  ),
                  _FilterPill(
                    label: 'P1 Priority',
                    selected: false,
                    onTap: () {},
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onSurface,
                  ),
                  _FilterPill(
                    label: 'Stalled',
                    selected: false,
                    onTap: () {},
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurfaceVariant,
                    selectedTextColor: scheme.onSurface,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ValueIconButton extends StatelessWidget {
  const _ValueIconButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final ValueChipData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = TasklyChromeTheme.of(context);
    final isDark = scheme.brightness == Brightness.dark;
    final fg = data.color.withValues(alpha: selected ? 1.0 : 0.7);
    final bg = data.color.withValues(alpha: selected ? 0.24 : 0.12);
    final labelColor = selected ? fg : scheme.onSurfaceVariant;
    final borderColor = selected
        ? data.color.withValues(alpha: 0.8)
        : scheme.outlineVariant.withValues(alpha: 0.5);

    return InkWell(
      borderRadius: BorderRadius.circular(chrome.valueIconRadius),
      onTap: onTap,
      child: SizedBox(
        width: chrome.valueItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: chrome.valueIconBoxSize,
              height: chrome.valueIconBoxSize,
              decoration: BoxDecoration(
                color: isDark ? bg.withValues(alpha: 0.3) : bg,
                borderRadius: BorderRadius.circular(chrome.valueIconRadius),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: data.color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                data.icon,
                color: fg,
                size: chrome.valueIconSize,
              ),
            ),
            SizedBox(height: chrome.valueLabelSpacing),
            Text(
              data.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: (selected
                      ? chrome.valueLabelSelectedStyle
                      : chrome.valueLabelStyle)
                  .copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.backgroundColor,
    required this.selectedColor,
    required this.textColor,
    required this.selectedTextColor,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color selectedColor;
  final Color textColor;
  final Color selectedTextColor;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final chrome = TasklyChromeTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? selectedTextColor : textColor;
    final bg = selected ? selectedColor : backgroundColor;

    return Padding(
      padding: EdgeInsets.only(right: chrome.filterRowSpacing),
      child: InkWell(
        borderRadius: BorderRadius.circular(chrome.filterPillRadius),
        onTap: onTap,
        child: Container(
          padding: chrome.filterPillPadding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(chrome.filterPillRadius),
            border: Border.all(
              color: selected
                  ? scheme.surface.withValues(alpha: 0)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: chrome.filterPillIconSize, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: chrome.filterPillTextStyle.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _compareValues(Value a, Value b) {
  final ap = a.priority ?? ValuePriority.medium;
  final bp = b.priority ?? ValuePriority.medium;
  final byPriority = _priorityRank(ap).compareTo(_priorityRank(bp));
  if (byPriority != 0) return byPriority;

  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

int _priorityRank(ValuePriority priority) {
  return switch (priority) {
    ValuePriority.high => 0,
    ValuePriority.medium => 1,
    ValuePriority.low => 2,
  };
}
