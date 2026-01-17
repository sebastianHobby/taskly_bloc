import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/domain/entity_views/tile_capabilities/entity_tile_capabilities_resolver.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/model/scheduled_scope.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui.dart';

class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key, this.scope = const GlobalScheduledScope()});

  final ScheduledScope scope;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduledFeedBloc(
        agendaDataService: getIt(),
        homeDayService: getIt(),
        scope: scope,
      ),
      child: const _ScheduledView(),
    );
  }
}

class _ScheduledView extends StatelessWidget {
  const _ScheduledView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scheduled')),
      body: BlocBuilder<ScheduledFeedBloc, ScheduledFeedState>(
        builder: (context, state) {
          return switch (state) {
            ScheduledFeedLoading() => const FeedBody.loading(),
            ScheduledFeedError(:final message) => FeedBody.error(
              message: message,
              onRetry: () => context.read<ScheduledFeedBloc>().add(
                const ScheduledFeedRetryRequested(),
              ),
            ),
            ScheduledFeedLoaded(:final rows) when rows.isEmpty =>
              FeedBody.empty(
                child: EmptyStateWidget.noTasks(
                  title: 'Nothing scheduled',
                  description:
                      'Add start dates or deadlines to see items here.',
                ),
              ),
            ScheduledFeedLoaded(:final rows) => FeedBody.list(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return KeyedSubtree(
                  key: ValueKey(row.rowKey),
                  child: _ScheduledRow(row: row),
                );
              },
            ),
          };
        },
      ),
    );
  }
}

class _ScheduledRow extends StatelessWidget {
  const _ScheduledRow({required this.row});

  final ListRowUiModel row;

  @override
  Widget build(BuildContext context) {
    return switch (row) {
      BucketHeaderRowUiModel(:final title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      DateHeaderRowUiModel(:final title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      EmptyDayRowUiModel() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'No items',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      AgendaEntityRowUiModel(:final item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _AgendaEntityTile(item: item),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _AgendaEntityTile extends StatelessWidget {
  const _AgendaEntityTile({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final isInProgress = item.tag == AgendaDateTag.inProgress;

    if (item.isTask && item.task != null) {
      final task = item.task!;
      return TaskView(
        task: task,
        tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
        variant: TaskViewVariant.agendaCard,
        agendaInProgressStyle: isInProgress,
        endDate: task.deadlineDate,
        onTap: (_) => Routing.toTaskEdit(context, task.id),
      );
    }

    if (item.isProject && item.project != null) {
      final project = item.project!;
      return ProjectView(
        project: project,
        tileCapabilities: EntityTileCapabilitiesResolver.forProject(project),
        variant: ProjectViewVariant.agendaCard,
        agendaInProgressStyle: isInProgress,
        endDate: project.deadlineDate,
        onTap: (_) => Routing.toProjectEdit(context, project.id),
      );
    }

    return const SizedBox.shrink();
  }
}
