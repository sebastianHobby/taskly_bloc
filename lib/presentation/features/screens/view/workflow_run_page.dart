import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/screens/models/workflow_screen.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';
import 'package:taskly_bloc/domain/interfaces/problem_acknowledgments_repository_contract.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/workflow_run/workflow_run_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/workflow_progress_bar.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/workflow_item_card.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/support_block_renderer.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';

/// Page for running a workflow screen with item-by-item review
class WorkflowRunPage extends StatelessWidget {
  const WorkflowRunPage({
    required this.screen,
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.problemAcknowledgmentsRepository,
    required this.queryBuilder,
    required this.supportBlockComputer,
    this.problemDetector = const ProblemDetector(),
    super.key,
  });

  final WorkflowScreen screen;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final ProblemAcknowledgmentsRepositoryContract
  problemAcknowledgmentsRepository;
  final ScreenQueryBuilder queryBuilder;
  final SupportBlockComputer supportBlockComputer;
  final ProblemDetector problemDetector;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkflowRunBloc(
        screen: screen,
        taskRepository: taskRepository,
        settingsRepository: settingsRepository,
        problemAcknowledgmentsRepository: problemAcknowledgmentsRepository,
        problemDetector: problemDetector,
        queryBuilder: queryBuilder,
        supportBlockComputer: supportBlockComputer,
      )..add(const WorkflowRunEvent.started()),
      child: WorkflowRunView(
        screen: screen,
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
        supportBlockComputer: supportBlockComputer,
      ),
    );
  }
}

class WorkflowRunView extends StatelessWidget {
  const WorkflowRunView({
    required this.screen,
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.supportBlockComputer,
    super.key,
  });

  final WorkflowScreen screen;
  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SupportBlockComputer supportBlockComputer;

  List<SupportBlock> get _defaultBlocks => const [
    SupportBlock.workflowProgress(),
    SupportBlock.taskStats(statType: TaskStatType.completedCount),
    SupportBlock.breakdown(
      statType: TaskStatType.totalCount,
      dimension: BreakdownDimension.project,
      maxItems: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkflowRunBloc, WorkflowRunState<Task>>(
      listener: (context, state) {
        if (state.status == WorkflowRunStatus.completed) {
          // Show completion dialog
          _showCompletionDialog(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(screen.name),
            actions: [
              // Complete workflow button
              if (state.status == WorkflowRunStatus.running &&
                  state.progress != null)
                TextButton.icon(
                  onPressed: () {
                    context.read<WorkflowRunBloc>().add(
                      const WorkflowRunEvent.workflowCompleted(),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WorkflowRunState<Task> state) {
    return switch (state.status) {
      WorkflowRunStatus.initial || WorkflowRunStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      WorkflowRunStatus.error => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load workflow',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      WorkflowRunStatus.running => _buildWorkflowContent(context, state),
      WorkflowRunStatus.completed => _buildCompletedView(context, state),
    };
  }

  Widget _buildWorkflowContent(
    BuildContext context,
    WorkflowRunState<Task> state,
  ) {
    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'No items to review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _SoftGatesPanel(
          problems: state.problems,
          onAcknowledge: (problem) {
            context.read<WorkflowRunBloc>().add(
              WorkflowRunEvent.problemAcknowledged(
                problemType: problem.type,
                entityType: problem.entityType,
                entityId: problem.entityId,
              ),
            );
          },
          onSnooze: (problem) {
            context.read<WorkflowRunBloc>().add(
              WorkflowRunEvent.problemSnoozed(
                problemType: problem.type,
                entityType: problem.entityType,
                entityId: problem.entityId,
              ),
            );
          },
          onDismiss: (problem) {
            context.read<WorkflowRunBloc>().add(
              WorkflowRunEvent.problemDismissed(
                problemType: problem.type,
                entityType: problem.entityType,
                entityId: problem.entityId,
              ),
            );
          },
        ),

        // Progress bar
        if (state.progress != null)
          WorkflowProgressBar(progress: state.progress!),

        const SizedBox(height: 8),

        // Current item indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${state.currentIndex + 1} of ${state.items.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: state.hasPrevious
                        ? () => context.read<WorkflowRunBloc>().add(
                            const WorkflowRunEvent.previousItemRequested(),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: state.hasNext
                        ? () => context.read<WorkflowRunBloc>().add(
                            const WorkflowRunEvent.nextItemRequested(),
                          )
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Current item card
        Expanded(
          child: state.currentItem != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      WorkflowItemCard(
                        item: state.currentItem!,
                        onMarkReviewed: () => _markReviewed(context, state),
                        onSkip: () => _skipItem(context, state),
                        onTap: () => _showTaskDetail(context, state),
                        showNotes: true,
                      ),
                      const SizedBox(height: 16),
                      SupportBlocksSection(
                        blocks: _defaultBlocks,
                        items: state.items,
                        supportBlockComputer: supportBlockComputer,
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    WorkflowRunState<Task> state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Workflow Complete!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (state.progress != null)
            Text(
              'Reviewed ${state.progress!.completed} items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _markReviewed(BuildContext context, WorkflowRunState<Task> state) {
    if (state.currentItem == null) return;

    final bloc = context.read<WorkflowRunBloc>();

    // Note: Notes can be added via task detail screen
    bloc.add(
      WorkflowRunEvent.itemMarkedReviewed(
        entityId: state.currentItem!.entityId,
      ),
    );

    // Auto-advance to next item
    if (state.hasNext) {
      Future.delayed(const Duration(milliseconds: 300), () {
        bloc.add(const WorkflowRunEvent.nextItemRequested());
      });
    }
  }

  void _skipItem(BuildContext context, WorkflowRunState<Task> state) {
    if (state.currentItem == null) return;

    final bloc = context.read<WorkflowRunBloc>();

    bloc.add(
      WorkflowRunEvent.itemSkipped(
        entityId: state.currentItem!.entityId,
      ),
    );

    // Auto-advance to next item
    if (state.hasNext) {
      Future.delayed(const Duration(milliseconds: 300), () {
        bloc.add(const WorkflowRunEvent.nextItemRequested());
      });
    }
  }

  void _showTaskDetail(BuildContext context, WorkflowRunState<Task> state) {
    if (state.currentItem == null) return;

    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              taskId: state.currentItem!.entity.id,
            ),
            child: TaskDetailSheet(labelRepository: labelRepository),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.celebration),
          title: const Text('Workflow Complete'),
          content: const Text(
            'You have reviewed all items in this workflow.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftGatesPanel extends StatelessWidget {
  const _SoftGatesPanel({
    required this.problems,
    required this.onAcknowledge,
    required this.onSnooze,
    required this.onDismiss,
  });

  final List<DetectedProblem> problems;
  final ValueChanged<DetectedProblem> onAcknowledge;
  final ValueChanged<DetectedProblem> onSnooze;
  final ValueChanged<DetectedProblem> onDismiss;

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Soft gates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...problems.map(
                (p) => _SoftGateProblemTile(
                  problem: p,
                  onAcknowledge: () => onAcknowledge(p),
                  onSnooze: () => onSnooze(p),
                  onDismiss: () => onDismiss(p),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftGateProblemTile extends StatelessWidget {
  const _SoftGateProblemTile({
    required this.problem,
    required this.onAcknowledge,
    required this.onSnooze,
    required this.onDismiss,
  });

  final DetectedProblem problem;
  final VoidCallback onAcknowledge;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            problem.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            problem.suggestedAction,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: onAcknowledge,
                child: const Text('Acknowledge'),
              ),
              TextButton(
                onPressed: onSnooze,
                child: const Text('Snooze 7 days'),
              ),
              TextButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
