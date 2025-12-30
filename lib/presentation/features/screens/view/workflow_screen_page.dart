import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_session.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/workflow_run_bloc.dart';

class WorkflowScreenPage extends StatelessWidget {
  const WorkflowScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkflowRunBloc, WorkflowRunState>(
      builder: (context, state) {
        return state.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Workflow')),
            body: Center(child: Text('Workflow error: $error')),
          ),
          completed: (screen, session) => _ResultScaffold(
            title: screen.name,
            statusText: 'Completed',
            session: session,
          ),
          abandoned: (screen, session) => _ResultScaffold(
            title: screen.name,
            statusText: 'Abandoned',
            session: session,
          ),
          running: (screen, session, items, actionByEntityId) {
            final completedCount = actionByEntityId.length;
            final total = session.totalItems;
            final progress = total == 0 ? 0.0 : (completedCount / total);

            return Scaffold(
              appBar: AppBar(
                title: Text(screen.name),
                actions: [
                  IconButton(
                    tooltip: 'Abandon session',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => context.read<WorkflowRunBloc>().add(
                      const WorkflowRunEvent.abandonRequested(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Complete session',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: completedCount >= total
                        ? () => context.read<WorkflowRunBloc>().add(
                            const WorkflowRunEvent.completeRequested(),
                          )
                        : null,
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (total > 0)
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text('$completedCount / $total'),
                        const Spacer(),
                        Text(
                          'Reviewed: ${session.itemsReviewed}  Skipped: ${session.itemsSkipped}',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final action = actionByEntityId[item.entityId];

                        return ListTile(
                          title: Text(item.title),
                          subtitle: action == null
                              ? null
                              : Text(
                                  action == WorkflowAction.reviewed
                                      ? 'Reviewed'
                                      : 'Skipped',
                                ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: action == null
                                    ? () => context.read<WorkflowRunBloc>().add(
                                        WorkflowRunEvent.itemActionRequested(
                                          entityId: item.entityId,
                                          entityType: item.entityType,
                                          action: WorkflowAction.skipped,
                                        ),
                                      )
                                    : null,
                                child: const Text('Skip'),
                              ),
                              FilledButton(
                                onPressed: action == null
                                    ? () => context.read<WorkflowRunBloc>().add(
                                        WorkflowRunEvent.itemActionRequested(
                                          entityId: item.entityId,
                                          entityType: item.entityType,
                                          action: WorkflowAction.reviewed,
                                        ),
                                      )
                                    : null,
                                child: const Text('Reviewed'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({
    required this.title,
    required this.statusText,
    required this.session,
  });

  final String title;
  final String statusText;
  final WorkflowSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Reviewed: ${session.itemsReviewed}, Skipped: ${session.itemsSkipped}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
