import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/bloc/scope_context_bloc.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/anytime/widgets/anytime_scope_picker_sheet.dart';

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
                    title: _isSearching
                        ? TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search tasks and projects',
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
                            onPressed: () => _setSearchActive(true),
                          )
                        else
                          IconButton(
                            tooltip: 'Close search',
                            icon: const Icon(Icons.close),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: (scope == null)
                      ? _AnytimeScopeAndFiltersRow(
                          scope: scope,
                          onPickScope: () async {
                            final selected = await AnytimeScopePickerSheet.show(
                              context,
                              scope,
                            );
                            if (!context.mounted) return;
                            if (selected == null && scope == null) return;

                            switch (selected) {
                              case null:
                                await GoRouter.of(context).push('/anytime');
                              case AnytimeProjectScope(:final projectId):
                                Routing.pushProjectAnytime(context, projectId);
                              case AnytimeValueScope(:final valueId):
                                Routing.pushValueAnytime(context, valueId);
                            }
                          },
                        )
                      : BlocProvider(
                          create: (_) => ScopeContextBloc(
                            scope: scope!,
                            taskRepository: getIt<TaskRepositoryContract>(),
                            projectRepository:
                                getIt<ProjectRepositoryContract>(),
                            valueRepository: getIt<ValueRepositoryContract>(),
                          ),
                          child: _AnytimeScopeAndFiltersRow(
                            scope: scope,
                            onPickScope: () async {
                              final selected =
                                  await AnytimeScopePickerSheet.show(
                                    context,
                                    scope,
                                  );
                              if (!context.mounted) return;
                              if (selected == null && scope == null) return;

                              switch (selected) {
                                case null:
                                  await GoRouter.of(context).push('/anytime');
                                case AnytimeProjectScope(:final projectId):
                                  Routing.pushProjectAnytime(
                                    context,
                                    projectId,
                                  );
                                case AnytimeValueScope(:final valueId):
                                  Routing.pushValueAnytime(context, valueId);
                              }
                            },
                          ),
                        ),
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
      actionLabel: 'Create task',
      onAction: () => context.read<AnytimeScreenBloc>().add(
        const AnytimeCreateTaskRequested(),
      ),
    );
  }

  return TasklyEmptyStateSpec(
    icon: Icons.inbox_outlined,
    title: 'No backlog items yet',
    description: 'Create a task to start planning.',
    actionLabel: 'Create task',
    onAction: () => context.read<AnytimeScreenBloc>().add(
      const AnytimeCreateTaskRequested(),
    ),
  );
}

class _AnytimeScopeAndFiltersRow extends StatelessWidget {
  const _AnytimeScopeAndFiltersRow({
    required this.scope,
    required this.onPickScope,
  });

  final AnytimeScope? scope;
  final VoidCallback onPickScope;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
      buildWhen: (p, n) => p.showStartLaterItems != n.showStartLaterItems,
      builder: (context, state) {
        final showStartLater = state.showStartLaterItems;
        final label = showStartLater
            ? 'Start later: Shown'
            : 'Start later: Hidden';

        final scopeLabel = (scope == null) ? 'Scope: All' : null;

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPickScope,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: (scopeLabel != null)
                      ? Text(
                          scopeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : BlocBuilder<ScopeContextBloc, ScopeContextState>(
                          buildWhen: (p, n) => p.runtimeType != n.runtimeType,
                          builder: (context, scopeState) {
                            final title = switch (scopeState) {
                              ScopeContextLoaded(title: final title) => title,
                              _ => 'Scope',
                            };

                            return Text(
                              'Scope: $title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilterChip(
              label: Text(label),
              selected: showStartLater,
              onSelected: (selected) {
                context.read<AnytimeScreenBloc>().add(
                  AnytimeShowStartLaterSet(selected),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

List<TasklyRowSpec> _buildStandardRows(
  BuildContext context,
  List<ListRowUiModel> rows,
) {
  final selection = context.read<SelectionCubit>();

  selection.updateVisibleEntities(
    rows
        .whereType<TaskRowUiModel>()
        .map(
          (r) => SelectionEntityMeta(
            key: SelectionKey(entityType: EntityType.task, entityId: r.task.id),
            displayName: r.task.name,
            canDelete: true,
            completed: r.task.completed,
            pinned: r.task.isPinned,
            canCompleteSeries: r.task.isRepeating && !r.task.seriesEnded,
          ),
        )
        .toList(growable: false),
  );

  return rows
      .map<TasklyRowSpec>((row) {
        return switch (row) {
          ValueHeaderRowUiModel(:final title) => TasklyRowSpec.header(
            key: row.rowKey,
            depth: row.depth,
            title: title,
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
              intent: TasklyProjectRowIntent.groupHeader(expanded: expanded),
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
              showProjectLabel: false,
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
              intent: selectionMode
                  ? TasklyTaskRowIntent.bulkSelection(selected: isSelected)
                  : const TasklyTaskRowIntent.standard(),
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
        };
      })
      .toList(growable: false);
}
