import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/anytime_scope.dart';
import 'package:taskly_bloc/presentation/features/scope_context/view/scope_header.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui.dart';

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
            allocationSnapshotRepository:
                getIt<AllocationSnapshotRepositoryContract>(),
            dayKeyService: getIt<HomeDayKeyService>(),
            temporalTriggerService: getIt<TemporalTriggerService>(),
            scope: scope,
          ),
        ),
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
            }

            context.read<AnytimeScreenBloc>().add(const AnytimeEffectHandled());
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anytime'),
          actions: [
            if (!isCompact)
              IconButton(
                tooltip: context.l10n.createTaskTooltip,
                onPressed: () => context.read<AnytimeScreenBloc>().add(
                  const AnytimeCreateTaskRequested(),
                ),
                icon: const Icon(Icons.add),
              ),
            BlocBuilder<AnytimeScreenBloc, AnytimeScreenState>(
              buildWhen: (p, n) => p.focusOnly != n.focusOnly,
              builder: (context, state) {
                final enabled = state.focusOnly;
                return IconButton(
                  tooltip: enabled ? 'Focus only: on' : 'Focus only: off',
                  icon: Icon(
                    enabled ? Icons.filter_alt : Icons.filter_alt_off,
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
        floatingActionButton: isCompact
            ? FloatingActionButton(
                tooltip: context.l10n.createTaskTooltip,
                onPressed: () => context.read<AnytimeScreenBloc>().add(
                  const AnytimeCreateTaskRequested(),
                ),
                heroTag: 'create_task_fab_anytime',
                child: const Icon(Icons.add),
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
                          onAction: () => context.read<AnytimeScreenBloc>().add(
                            const AnytimeCreateTaskRequested(),
                          ),
                        ),
                      ),
                    AnytimeFeedLoaded(:final rows) => FeedBody.list(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return KeyedSubtree(
                          key: ValueKey(row.rowKey),
                          child: _AnytimeRow(row: row),
                        );
                      },
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnytimeRow extends StatelessWidget {
  const _AnytimeRow({required this.row});

  final ListRowUiModel row;

  @override
  Widget build(BuildContext context) {
    final leftIndent = 12.0 * row.depth;

    return switch (row) {
      ValueHeaderRowUiModel(:final title) => Padding(
        padding: EdgeInsets.fromLTRB(16 + leftIndent, 16, 16, 8),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(
            context,
          ).extension<TasklyTypography>()?.sectionHeaderHeavy,
        ),
      ),
      ProjectHeaderRowUiModel(
        :final projectRef,
        :final title,
      ) =>
        Padding(
          padding: EdgeInsets.fromLTRB(16 + leftIndent, 12, 16, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              context.read<AnytimeScreenBloc>().add(
                AnytimeProjectHeaderTapped(
                  projectRef: projectRef,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    projectRef.isInbox
                        ? Icons.inbox_outlined
                        : Icons.folder_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(
                        context,
                      ).extension<TasklyTypography>()?.subHeaderCaps,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ),
        ),
      TaskRowUiModel(:final task) => Padding(
        padding: EdgeInsets.only(left: 8 + leftIndent, right: 8),
        child: TaskView(
          task: task,
          tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
          onTap: (_) => context.read<AnytimeScreenBloc>().add(
            AnytimeTaskTapped(taskId: task.id),
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
