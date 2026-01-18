import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui.dart';

import 'package:taskly_bloc/presentation/features/inbox/bloc/inbox_feed_bloc.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          InboxFeedBloc(taskRepository: getIt<TaskRepositoryContract>()),
      child: const InboxView(),
    );
  }
}

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  Future<void> _openNewTaskEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openTaskEditor(
      context,
      taskId: null,
      defaultProjectId: null,
      defaultValueIds: null,
      showDragHandle: true,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = WindowSizeClass.of(context).isCompact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: TasklyAppBarActions.withAttentionBell(
          context,
          actions: [
            if (!isCompact)
              EntityAddMenuButton(
                onCreateTask: () => _openNewTaskEditor(context),
                onCreateProject: () => _openNewProjectEditor(context),
              ),
          ],
        ),
      ),
      floatingActionButton: isCompact
          ? EntityAddSpeedDial(
              heroTag: 'add_speed_dial_inbox',
              onCreateTask: () => _openNewTaskEditor(context),
              onCreateProject: () => _openNewProjectEditor(context),
            )
          : null,
      body: BlocBuilder<InboxFeedBloc, InboxFeedState>(
        builder: (context, state) {
          return switch (state) {
            InboxFeedLoading() => const FeedBody.loading(),
            InboxFeedError(:final message) => FeedBody.error(
              message: message,
              retryLabel: context.l10n.retryButton,
              onRetry: () => context.read<InboxFeedBloc>().add(
                const InboxFeedRetryRequested(),
              ),
            ),
            InboxFeedLoaded(:final rows) when rows.isEmpty => FeedBody.empty(
              child: EmptyStateWidget.noTasks(
                title: 'Inbox is empty',
                description: 'Create a task to start capturing things.',
                actionLabel: 'Create task',
                onAction: () => _openNewTaskEditor(context),
              ),
            ),
            InboxFeedLoaded(:final rows) => FeedBody.list(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return KeyedSubtree(
                  key: ValueKey(row.rowKey),
                  child: _InboxRow(row: row),
                );
              },
            ),
          };
        },
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.row});

  final ListRowUiModel row;

  @override
  Widget build(BuildContext context) {
    return switch (row) {
      TaskRowUiModel(:final task) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TaskView(
          task: task,
          tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
          onTap: (_) => Routing.toTaskEdit(context, task.id),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
