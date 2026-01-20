import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/features/scope_context/view/scope_header.dart';
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
import 'package:taskly_ui/taskly_ui_entities.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_screen_bloc.dart';

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
            taskRepository: getIt<TaskRepositoryContract>(),
            myDayRepository: getIt<MyDayRepositoryContract>(),
            dayKeyService: getIt<HomeDayKeyService>(),
            temporalTriggerService: getIt<TemporalTriggerService>(),
            scope: scope,
          ),
        ),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: _AnytimeView(scope: scope),
    );
  }
}

class _AnytimeView extends StatelessWidget {
  const _AnytimeView({required this.scope});

  final AnytimeScope? scope;

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
          listenWhen: (prev, next) => prev.effect != next.effect,
          listener: (context, state) {
            final effect = state.effect;
            if (effect == null) return;

            switch (effect) {
              case AnytimeNavigateToInbox():
                Routing.toInbox(context);
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
                    title: const Text('Anytime'),
                    actions: TasklyAppBarActions.withAttentionBell(
                      context,
                      actions: [
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
                if (scope != null) ScopeHeader(scope: scope!),
                Expanded(
                  child: BlocBuilder<AnytimeFeedBloc, AnytimeFeedState>(
                    builder: (context, state) {
                      return switch (state) {
                        AnytimeFeedLoading() => const FeedBody.loading(),
                        AnytimeFeedError(:final message) => FeedBody.error(
                          message: message,
                          retryLabel: context.l10n.retryButton,
                          onRetry: () => context.read<AnytimeFeedBloc>().add(
                            const AnytimeFeedRetryRequested(),
                          ),
                        ),
                        AnytimeFeedLoaded(:final rows) when rows.isEmpty =>
                          FeedBody.empty(
                            child: EmptyStateWidget.noTasks(
                              title: 'No tasks',
                              description: 'Create a task to start planning.',
                              actionLabel: 'Create task',
                              onAction: () =>
                                  context.read<AnytimeScreenBloc>().add(
                                    const AnytimeCreateTaskRequested(),
                                  ),
                            ),
                          ),
                        AnytimeFeedLoaded(:final rows) => FeedBody.child(
                          child: TasklyStandardTileListSection(
                            rows: _buildStandardRows(context, rows),
                          ),
                        ),
                      };
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

List<TasklyStandardTileListRowModel> _buildStandardRows(
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
      .map<TasklyStandardTileListRowModel?>((row) {
        return switch (row) {
          ValueHeaderRowUiModel(:final title) =>
            TasklyStandardTileListHeaderRowModel(
              key: row.rowKey,
              depth: row.depth,
              title: title,
            ),
          ProjectHeaderRowUiModel(:final projectRef, :final title) =>
            TasklyStandardTileListIconHeaderRowModel(
              key: row.rowKey,
              depth: row.depth,
              title: title,
              leadingIcon: projectRef.isInbox
                  ? Icons.inbox_outlined
                  : Icons.folder_outlined,
              onTap: () => context.read<AnytimeScreenBloc>().add(
                AnytimeProjectHeaderTapped(projectRef: projectRef),
              ),
            ),
          TaskRowUiModel(:final task, :final showProjectLabel) => () {
            final tileCapabilities = EntityTileCapabilitiesResolver.forTask(
              task,
            );

            final key = SelectionKey(
              entityType: EntityType.task,
              entityId: task.id,
            );

            final model = buildTaskListRowTileModel(
              context,
              task: task,
              tileCapabilities: tileCapabilities,
              showProjectLabel: showProjectLabel,
            );

            final isSelected = selection.isSelected(key);
            final selectionMode = selection.isSelectionMode;

            return TasklyStandardTileListTaskRowModel(
              key: row.rowKey,
              depth: row.depth,
              entityId: task.id,
              model: model,
              markers: TaskTileMarkers(pinned: task.isPinned),
              intent: selectionMode
                  ? TaskTileIntent.bulkSelection(selected: isSelected)
                  : const TaskTileIntent.standardList(),
              actions: TaskTileActions(
                onTap: () {
                  if (selection.shouldInterceptTapAsSelection()) {
                    selection.handleEntityTap(key);
                    return;
                  }
                  model.onTap();
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
                onOverflowMenuRequestedAt: null,
              ),
            );
          }(),
          _ => null,
        };
      })
      .whereType<TasklyStandardTileListRowModel>()
      .toList(growable: false);
}
