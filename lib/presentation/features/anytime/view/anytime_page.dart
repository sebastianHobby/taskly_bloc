import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
          create: (context) => AnytimeFeedBloc(
            queryService: context.read<AnytimeSessionQueryService>(),
            scope: scope,
          ),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chrome = TasklyTokens.of(context);
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
      child: BlocBuilder<SelectionBloc, SelectionState>(
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
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Anytime'),
                              SizedBox(
                                height: TasklyTokens.of(context).spaceSm,
                              ),
                              Text(
                                "Plan what's next",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
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
                      ],
                    ),
                  ),
            floatingActionButton: selectionState.isSelectionMode
                ? null
                : EntityAddSpeedDial(
                    heroTag: 'add_speed_dial_anytime',
                    onCreateTask: () => context.read<AnytimeScreenBloc>().add(
                      const AnytimeCreateTaskRequested(),
                    ),
                    onCreateProject: () =>
                        context.read<AnytimeScreenBloc>().add(
                          const AnytimeCreateProjectRequested(),
                        ),
                  ),
            body: Column(
              children: [
                Padding(
                  padding: chrome.anytimeHeaderPadding,
                  child: _AnytimeValuesAndFiltersRow(scope: scope),
                ),
                Expanded(
                  child: BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
                    buildWhen: (p, n) => p.searchQuery != n.searchQuery,
                    builder: (context, screenState) {
                      return BlocBuilder<AnytimeFeedBloc, AnytimeFeedState>(
                        builder: (context, state) {
                          final spec = switch (state) {
                            AnytimeFeedLoading() =>
                              const TasklyFeedSpec.loading(),
                            AnytimeFeedError(:final message) =>
                              TasklyFeedSpec.error(
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
                            AnytimeFeedLoaded(:final rows) => () {
                              final sections = <TasklySectionSpec>[];
                              sections.add(
                                TasklySectionSpec.standardList(
                                  id: 'anytime',
                                  rows: _buildStandardRows(
                                    context,
                                    rows,
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
    title: 'Add your first task or project',
    description:
        "This is your project backlog. My Day pulls today's plan from here.",
    actionLabel: 'Add task',
    onAction: () => context.read<AnytimeScreenBloc>().add(
      const AnytimeCreateTaskRequested(),
    ),
  );
}

List<TasklyRowSpec> _buildStandardRows(
  BuildContext context,
  List<ListRowUiModel> rows,
) {
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
          pinned: r.project?.isPinned ?? false,
        ),
      ),
    ].toList(growable: false),
  );

  final specs = <TasklyRowSpec>[];

  for (final row in rows) {
    if (row is! ProjectRowUiModel) continue;

    final data = row.project == null
        ? TasklyProjectRowData(
            id: 'inbox',
            title: 'Inbox',
            completed: false,
            pinned: false,
            meta: const TasklyEntityMetaData(),
            taskCount: row.taskCount,
          )
        : buildProjectRowData(
            context,
            project: row.project!,
            taskCount: row.taskCount,
            completedTaskCount: row.completedTaskCount,
            dueSoonCount: row.dueSoonCount,
          );

    final preset = row.project == null
        ? const TasklyProjectRowPreset.inbox()
        : const TasklyProjectRowPreset.standard();

    final actions = TasklyProjectRowActions(
      onTap: row.project == null
          ? () => Routing.pushInboxProjectDetail(context)
          : () => Routing.pushProjectAnytime(context, row.project!.id),
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

class _AnytimeValuesAndFiltersRow extends StatefulWidget {
  const _AnytimeValuesAndFiltersRow({required this.scope});

  final AnytimeScope? scope;

  @override
  State<_AnytimeValuesAndFiltersRow> createState() =>
      _AnytimeValuesAndFiltersRowState();
}

class _AnytimeValuesAndFiltersRowState
    extends State<_AnytimeValuesAndFiltersRow> {
  final ScrollController _valueScrollController = ScrollController();

  @override
  void dispose() {
    _valueScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    final selectedValueId = switch (widget.scope) {
      AnytimeValueScope(:final valueId) => valueId,
      _ => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<AnytimeFeedBloc, AnytimeFeedState>(
          buildWhen: (prev, next) =>
              prev is! AnytimeFeedLoaded ||
              next is! AnytimeFeedLoaded ||
              prev.values != next.values,
          builder: (context, state) {
            final values = switch (state) {
              AnytimeFeedLoaded(:final values) => values,
              _ => const <Value>[],
            };
            final rows = switch (state) {
              AnytimeFeedLoaded(:final rows) => rows,
              _ => const <ListRowUiModel>[],
            };
            final sorted = values.toList(growable: false)..sort(_compareValues);

            final counts = _countProjectsByValue(rows);
            final selectedValue = _findValueById(sorted, selectedValueId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown,
                    },
                  ),
                  child: Listener(
                    onPointerSignal: (signal) {
                      if (signal is! PointerScrollEvent) return;
                      if (!_valueScrollController.hasClients) return;
                      final target =
                          (_valueScrollController.offset +
                                  signal.scrollDelta.dy)
                              .clamp(
                                0.0,
                                _valueScrollController.position.maxScrollExtent,
                              );
                      _valueScrollController.jumpTo(target);
                    },
                    child: SingleChildScrollView(
                      controller: _valueScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceXs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ValueFilterChip(
                              label: 'All',
                              count: counts.total,
                              selected: selectedValue == null,
                              icon: Icons.filter_list_rounded,
                              iconColor: scheme.onSurfaceVariant,
                              onTap: () async {
                                if (selectedValueId == null) return;
                                unawaited(HapticFeedback.lightImpact());
                                await GoRouter.of(context).push('/anytime');
                              },
                            ),
                            for (final value in sorted) ...[
                              SizedBox(width: tokens.filterRowSpacing),
                              Builder(
                                builder: (context) {
                                  final chip = value.toChipData(context);
                                  return _ValueFilterChip(
                                    label: chip.label,
                                    count: counts.byValueId[value.id],
                                    selected: value.id == selectedValueId,
                                    icon: chip.icon,
                                    iconColor: chip.color,
                                    tintColor: chip.color,
                                    onTap: () async {
                                      if (value.id == selectedValueId) return;
                                      unawaited(HapticFeedback.lightImpact());
                                      Routing.pushValueAnytime(
                                        context,
                                        value.id,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            );
          },
        ),
      ],
    );
  }
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

int _compareValues(Value a, Value b) {
  final ap = a.priority;
  final bp = b.priority;
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

Value? _findValueById(List<Value> values, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final value in values) {
    if (value.id == id) return value;
  }
  return null;
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
