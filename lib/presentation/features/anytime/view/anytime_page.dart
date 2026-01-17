import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/tile_capabilities/entity_tile_capabilities_resolver.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_screen_bloc.dart';

class AnytimePage extends StatelessWidget {
  const AnytimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AnytimeScreenBloc()),
        BlocProvider(
          create: (_) => AnytimeFeedBloc(
            taskRepository: getIt<TaskRepositoryContract>(),
            allocationSnapshotRepository:
                getIt<AllocationSnapshotRepositoryContract>(),
            dayKeyService: getIt<HomeDayKeyService>(),
            temporalTriggerService: getIt<TemporalTriggerService>(),
          ),
        ),
      ],
      child: const _AnytimeView(),
    );
  }
}

class _AnytimeView extends StatelessWidget {
  const _AnytimeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnytimeScreenBloc, AnytimeScreenState>(
      listenWhen: (prev, next) => prev.focusOnly != next.focusOnly,
      listener: (context, state) {
        context.read<AnytimeFeedBloc>().add(
          AnytimeFeedFocusOnlyChanged(enabled: state.focusOnly),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anytime'),
          actions: [
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
        floatingActionButton: FloatingActionButton(
          tooltip: 'Create task',
          onPressed: () => Routing.toTaskNew(context),
          heroTag: 'create_task_fab_anytime',
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<AnytimeFeedBloc, AnytimeFeedState>(
          builder: (context, state) {
            return switch (state) {
              AnytimeFeedLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AnytimeFeedError(:final message) => ErrorStateWidget(
                message: message,
                onRetry: () => context.read<AnytimeFeedBloc>().add(
                  const AnytimeFeedRetryRequested(),
                ),
              ),
              AnytimeFeedLoaded(:final rows) when rows.isEmpty =>
                EmptyStateWidget.noTasks(
                  title: 'No tasks',
                  description: 'Create a task to start planning.',
                  actionLabel: 'Create task',
                  onAction: () => Routing.toTaskNew(context),
                ),
              AnytimeFeedLoaded(:final rows) => ListView.builder(
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
        :final isInbox,
        :final projectId,
        :final title,
      ) =>
        Padding(
          padding: EdgeInsets.fromLTRB(16 + leftIndent, 12, 16, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (isInbox) {
                Routing.toInbox(context);
                return;
              }
              final id = projectId;
              if (id == null || id.isEmpty) return;
              Routing.toProjectEdit(context, id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    isInbox ? Icons.inbox_outlined : Icons.folder_outlined,
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
          onTap: (_) => Routing.toTaskEdit(context, task.id),
        ),
      ),
    };
  }
}
