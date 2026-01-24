import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
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
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/model/anytime_sort.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

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
  void initState() {
    super.initState();
    final dueWindowDays = context
        .read<GlobalSettingsBloc>()
        .state
        .settings
        .myDayDueWindowDays;
    context.read<AnytimeFeedBloc>().add(
      AnytimeFeedDueWindowDaysChanged(days: dueWindowDays),
    );
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
          listenWhen: (prev, next) => prev.searchQuery != next.searchQuery,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedSearchQueryChanged(query: state.searchQuery),
            );
          },
        ),
        BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
          listenWhen: (prev, next) => prev.sortOrder != next.sortOrder,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedSortOrderChanged(order: state.sortOrder),
            );
          },
        ),
        BlocListener<GlobalSettingsBloc, GlobalSettingsState>(
          listenWhen: (prev, next) =>
              prev.settings.myDayDueWindowDays !=
              next.settings.myDayDueWindowDays,
          listener: (context, state) {
            context.read<AnytimeFeedBloc>().add(
              AnytimeFeedDueWindowDaysChanged(
                days: state.settings.myDayDueWindowDays,
              ),
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
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Anytime'),
                              const SizedBox(height: 2),
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
                                  rows: _buildStandardRows(context, rows),
                                ),
                              );
                              return TasklyFeedSpec.content(sections: sections);
                            }(),
                          };

                          return TasklyFeedRenderer(
                            spec: spec,
                            padding: AppSpacing.screenHorizontal,
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
    title: 'No projects yet',
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
      .whereType<ProjectRowUiModel>()
      .map<TasklyRowSpec>((row) {
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

        return TasklyRowSpec.project(
          key: row.rowKey,
          depth: row.depth,
          data: data,
          preset: preset,
          actions: actions,
        );
      })
      .toList(growable: false);
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
    final valueRepository = getIt<ValueRepositoryContract>();
    final screenState = context.watch<AnytimeScreenBloc>().state;

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
            final sorted = values.toList(growable: false)..sort(_compareValues);

            final selectedValue = _findValueById(sorted, selectedValueId);
            final hasValue = selectedValue != null;
            final valueLabel = hasValue ? selectedValue.name : 'All';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Value: $valueLabel',
                        selected: hasValue,
                        onTap: () async {
                          final next = await _showValueFilterSheet(
                            context,
                            sorted,
                            selectedValueId,
                          );
                          if (!context.mounted || next == selectedValueId) {
                            return;
                          }
                          if (next == null) {
                            await GoRouter.of(context).push('/anytime');
                          } else {
                            Routing.pushValueAnytime(context, next);
                          }
                        },
                        backgroundColor: scheme.surface,
                        selectedColor: scheme.surfaceContainerHigh,
                        textColor: scheme.onSurfaceVariant,
                        selectedTextColor: scheme.onSurface,
                        leadingIcon: Icons.expand_more_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _AnytimeSortRow(
                  sortOrder: screenState.sortOrder,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AnytimeSortRow extends StatelessWidget {
  const _AnytimeSortRow({required this.sortOrder});

  final AnytimeSortOrder sortOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chrome = TasklyChromeTheme.of(context);

    return Row(
      children: [
        Text(
          'Sort',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<AnytimeSortOrder>(
            value: sortOrder,
            borderRadius: BorderRadius.circular(chrome.filterPillRadius),
            items: const [
              DropdownMenuItem(
                value: AnytimeSortOrder.dueSoonest,
                child: Text('Due date: Soonest'),
              ),
              DropdownMenuItem(
                value: AnytimeSortOrder.dueLatest,
                child: Text('Due date: Latest'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              context.read<AnytimeScreenBloc>().add(
                AnytimeSortOrderSet(value),
              );
            },
          ),
        ),
      ],
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

Future<String?> _showValueFilterSheet(
  BuildContext context,
  List<Value> values,
  String? selectedValueId,
) {
  return showModalBottomSheet<String?>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.apps_rounded),
            title: const Text('All values'),
            trailing: selectedValueId == null
                ? Icon(Icons.check_rounded, color: scheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(null),
          ),
          const Divider(height: 1),
          for (final value in values)
            Builder(
              builder: (context) {
                final chip = value.toChipData(context);
                return ListTile(
                  leading: Icon(chip.icon, color: chip.color),
                  title: Text(value.name),
                  trailing: selectedValueId == value.id
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(value.id),
                );
              },
            ),
        ],
      );
    },
  );
}
