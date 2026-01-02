import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/presentation/features/workflow/bloc/workflow_run_bloc.dart';

/// Page for running a multi-step workflow
class WorkflowRunPage extends StatelessWidget {
  const WorkflowRunPage({
    required this.definition,
    this.existingWorkflow,
    super.key,
  });

  /// The workflow definition to run
  final WorkflowDefinition definition;

  /// An existing workflow to resume (optional)
  final Workflow? existingWorkflow;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = WorkflowRunBloc(
          workflowRepository: getIt<WorkflowRepositoryContract>(),
          taskRepository: getIt<TaskRepositoryContract>(),
          queryBuilder: getIt<ScreenQueryBuilder>(),
        );

        if (existingWorkflow != null) {
          bloc.add(
            WorkflowRunEvent.resumed(
              workflow: existingWorkflow!,
              definition: definition,
            ),
          );
        } else {
          bloc.add(WorkflowRunEvent.started(definition: definition));
        }

        return bloc;
      },
      child: const _WorkflowRunView(),
    );
  }
}

class _WorkflowRunView extends StatelessWidget {
  const _WorkflowRunView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkflowRunBloc, WorkflowRunState>(
      listener: (context, state) {
        if (state is WorkflowCompleted) {
          _showCompletionDialog(context, state);
        } else if (state is WorkflowAbandoned) {
          context.pop();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: _buildBody(context, state),
          bottomNavigationBar: _buildBottomBar(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WorkflowRunState state,
  ) {
    final title = switch (state) {
      WorkflowRunning(:final definition, :final currentStepIndex) =>
        '${definition.name} - Step ${currentStepIndex + 1}/${definition.steps.length}',
      WorkflowCompleted(:final definition) => '${definition.name} - Complete',
      WorkflowStepComplete(:final definition, :final completedStepIndex) =>
        '${definition.name} - Step ${completedStepIndex + 1} Complete',
      _ => 'Workflow',
    };

    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _confirmAbandon(context),
      ),
      actions: [
        if (state is WorkflowRunning)
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Skip to next step',
            onPressed: () {
              context.read<WorkflowRunBloc>().add(
                const WorkflowRunEvent.nextStep(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WorkflowRunState state) {
    return switch (state) {
      WorkflowInitial() => const Center(child: Text('Initializing...')),
      WorkflowLoading() => const Center(child: CircularProgressIndicator()),
      WorkflowRunning() => _WorkflowRunningView(state: state),
      WorkflowStepComplete() => _StepCompleteView(state: state),
      WorkflowCompleted() => _CompletedView(state: state),
      WorkflowAbandoned() => const Center(child: Text('Workflow abandoned')),
      WorkflowError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    };
  }

  Widget? _buildBottomBar(BuildContext context, WorkflowRunState state) {
    if (state is! WorkflowRunning) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final currentItem =
                      state.currentStepItems[state.currentItemIndex];
                  context.read<WorkflowRunBloc>().add(
                    WorkflowRunEvent.itemSkipped(entityId: currentItem.id),
                  );
                  _moveToNextItem(context, state);
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () {
                  final currentItem =
                      state.currentStepItems[state.currentItemIndex];
                  context.read<WorkflowRunBloc>().add(
                    WorkflowRunEvent.itemReviewed(entityId: currentItem.id),
                  );
                  _moveToNextItem(context, state);
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark Reviewed'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveToNextItem(BuildContext context, WorkflowRunning state) {
    final bloc = context.read<WorkflowRunBloc>();

    if (state.currentItemIndex < state.currentStepItems.length - 1) {
      bloc.add(const WorkflowRunEvent.nextItem());
    } else {
      // End of current step
      if (state.currentStepIndex < state.definition.steps.length - 1) {
        bloc.add(const WorkflowRunEvent.nextStep());
      } else {
        bloc.add(const WorkflowRunEvent.completed());
      }
    }
  }

  void _confirmAbandon(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandon Workflow?'),
        content: const Text(
          'Your progress will be saved, but the workflow will be marked as abandoned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
              context.read<WorkflowRunBloc>().add(
                const WorkflowRunEvent.abandoned(),
              );
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, WorkflowCompleted state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Workflow Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You completed ${state.definition.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _ProgressSummary(progress: state.progress),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _WorkflowRunningView extends StatelessWidget {
  const _WorkflowRunningView({required this.state});

  final WorkflowRunning state;

  @override
  Widget build(BuildContext context) {
    final currentStep = state.definition.steps[state.currentStepIndex];
    final currentItem = state.currentStepItems.isNotEmpty
        ? state.currentStepItems[state.currentItemIndex]
        : null;

    return Column(
      children: [
        // Progress indicator
        _WorkflowProgressBar(progress: state.progress),

        // Step info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            currentStep.stepName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // Item navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: state.currentItemIndex > 0
                    ? () => context.read<WorkflowRunBloc>().add(
                        const WorkflowRunEvent.previousItem(),
                      )
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                'Item ${state.currentItemIndex + 1} of ${state.currentStepItems.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed:
                    state.currentItemIndex < state.currentStepItems.length - 1
                    ? () => context.read<WorkflowRunBloc>().add(
                        const WorkflowRunEvent.nextItem(),
                      )
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Current item
        Expanded(
          child: currentItem != null
              ? _TaskItemView(task: currentItem, state: state)
              : const Center(child: Text('No items in this step')),
        ),
      ],
    );
  }
}

class _TaskItemView extends StatelessWidget {
  const _TaskItemView({required this.task, required this.state});

  final Task task;
  final WorkflowRunning state;

  @override
  Widget build(BuildContext context) {
    final stepState = state.workflow.stepStates[state.currentStepIndex];
    final isReviewed = stepState.reviewedEntityIds.contains(task.id);
    final isSkipped = stepState.skippedEntityIds.contains(task.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isReviewed)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else if (isSkipped)
                    const Icon(Icons.skip_next, color: Colors.orange)
                  else
                    const Icon(Icons.radio_button_unchecked),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (task.deadlineDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(task.deadlineDate!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (task.project != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.folder, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      task.project!.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StepCompleteView extends StatelessWidget {
  const _StepCompleteView({required this.state});

  final WorkflowStepComplete state;

  @override
  Widget build(BuildContext context) {
    final completedStep = state.definition.steps[state.completedStepIndex];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Step Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            completedStep.stepName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          if (state.completedStepIndex < state.definition.steps.length - 1)
            FilledButton.icon(
              onPressed: () {
                context.read<WorkflowRunBloc>().add(
                  const WorkflowRunEvent.nextStep(),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                'Continue to ${state.definition.steps[state.completedStepIndex + 1].stepName}',
              ),
            )
          else
            FilledButton.icon(
              onPressed: () {
                context.read<WorkflowRunBloc>().add(
                  const WorkflowRunEvent.completed(),
                );
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Complete Workflow'),
            ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.state});

  final WorkflowCompleted state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Workflow Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _ProgressSummary(progress: state.progress),
        ],
      ),
    );
  }
}

class _WorkflowProgressBar extends StatelessWidget {
  const _WorkflowProgressBar({required this.progress});

  final WorkflowProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                '${(progress.overallPercentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.overallPercentage,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${progress.currentStepIndex + 1}/${progress.totalSteps}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '${progress.currentStepProgress.completedItems}/${progress.currentStepProgress.totalItems} items',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.progress});

  final WorkflowProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: 'Steps',
                  value: '${progress.completedSteps}/${progress.totalSteps}',
                ),
                _StatColumn(
                  label: 'Items Reviewed',
                  value: '${progress.currentStepProgress.reviewedItems}',
                ),
                _StatColumn(
                  label: 'Items Skipped',
                  value: '${progress.currentStepProgress.skippedItems}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
