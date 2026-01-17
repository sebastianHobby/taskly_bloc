import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/tile_capabilities/entity_tile_capabilities_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_domain/contracts.dart';

import 'package:taskly_bloc/presentation/features/inbox/bloc/inbox_bloc.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InboxBloc(taskRepository: getIt<TaskRepositoryContract>()),
      child: const InboxView(),
    );
  }
}

class InboxView extends StatelessWidget {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      floatingActionButton: FloatingActionButton(
        tooltip: context.l10n.createTaskTooltip,
        onPressed: () => Routing.toTaskNew(context),
        heroTag: 'create_task_fab_inbox',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<InboxBloc, InboxState>(
        builder: (context, state) {
          return switch (state) {
            InboxLoading() => const Center(child: CircularProgressIndicator()),
            InboxError(:final message) => ErrorStateWidget(
              message: message,
            ),
            InboxLoaded(:final tasks) when tasks.isEmpty =>
              EmptyStateWidget.noTasks(
                title: 'Inbox is empty',
                description: 'Create a task to start capturing things.',
                actionLabel: 'Create task',
                onAction: () => Routing.toTaskNew(context),
              ),
            InboxLoaded(:final tasks) => ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final tileCapabilities = EntityTileCapabilitiesResolver.forTask(
                  task,
                );

                return TaskView(
                  task: task,
                  tileCapabilities: tileCapabilities,
                  onTap: (_) => Routing.toTaskEdit(context, task.id),
                );
              },
            ),
          };
        },
      ),
    );
  }
}
