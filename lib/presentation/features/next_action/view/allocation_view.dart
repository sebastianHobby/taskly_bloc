import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/allocation_bloc.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/pinned_section.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/allocated_group_widget.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/excluded_urgent_banner.dart';

/// Main view for task allocation screen
class NextActionsView extends StatelessWidget {
  const NextActionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.nextActionsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed(
              AppRouteName.taskNextActionsSettings,
            ),
            tooltip: context.l10n.settings,
          ),
        ],
      ),
      body: BlocBuilder<AllocationBloc, AllocationState>(
        builder: (context, state) {
          if (state.status == AllocationStatus.initial ||
              state.status == AllocationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AllocationStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    friendlyErrorMessageForUi(
                      state.errorMessage ?? 'Failed to load allocations',
                      context.l10n,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<AllocationBloc>().add(
                        const AllocationRefreshRequested(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (state.isEmpty && state.unrankedCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noTasksToFocusOn,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All caught up!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Has unranked but no allocated
          if (state.isEmpty && state.unrankedCount > 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rank your values',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${state.unrankedCount} unranked value(s). '
                      'Rank them to see task recommendations.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.pushNamed(
                        AppRouteName.taskNextActionsSettings,
                      ),
                      icon: const Icon(Icons.settings),
                      label: const Text('Rank Values'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Success with content
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AllocationBloc>().add(
                const AllocationRefreshRequested(),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Excluded urgent warning banner
                if (state.showExcludedWarning && state.hasExcludedUrgent) ...[
                  ExcludedUrgentBanner(
                    count: state.excludedUrgent.length,
                    onReview: () {
                      // Show modal with excluded tasks
                      _showExcludedTasksSheet(context, state);
                    },
                    onDismiss: () {
                      context.read<AllocationBloc>().add(
                        const AllocationExcludedDismissed(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Pinned section
                if (state.pinnedTasks.isNotEmpty) ...[
                  PinnedSection(
                    pinnedTasks: state.pinnedTasks,
                    onUnpin: (taskId) {
                      context.read<AllocationBloc>().add(
                        AllocationTaskUnpinned(taskId),
                      );
                    },
                    onTaskTap: (taskId) {
                      context.pushNamed(
                        AppRouteName.taskDetail,
                        pathParameters: {'taskId': taskId},
                      );
                    },
                    onToggleComplete: (taskId) {
                      context.read<AllocationBloc>().add(
                        AllocationTaskCompletionToggled(taskId),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Allocated groups by value
                ...state.tasksByValue.entries.map((entry) {
                  final group = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AllocatedGroupWidget(
                      group: group,
                      onPin: (taskId) {
                        context.read<AllocationBloc>().add(
                          AllocationTaskPinned(taskId),
                        );
                      },
                      onTaskTap: (taskId) {
                        context.pushNamed(
                          AppRouteName.taskDetail,
                          pathParameters: {'taskId': taskId},
                        );
                      },
                      onToggleComplete: (taskId) {
                        context.read<AllocationBloc>().add(
                          AllocationTaskCompletionToggled(taskId),
                        );
                      },
                    ),
                  );
                }),

                // "Get More Tasks" button - only when ALL tasks completed
                // and there are more tasks available to allocate
                if (state.isEmpty && state.hasMoreTasksAvailable) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.celebration_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Great work! All tasks completed.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<AllocationBloc>().add(
                              const AllocationRefreshRequested(),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'Get More Tasks (${state.excludedCount} available)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExcludedTasksSheet(BuildContext context, AllocationState state) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Excluded Urgent Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "These tasks are approaching their deadline but weren't included "
              "in today's allocation due to daily task limits.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...state.excludedUrgent.map((excludedTask) {
              final task = excludedTask.task;
              return ListTile(
                title: Text(task.name),
                subtitle: task.deadlineDate != null
                    ? Text('Due: ${task.deadlineDate}')
                    : null,
                trailing: FilledButton.tonal(
                  onPressed: () {
                    context.read<AllocationBloc>().add(
                      AllocationTaskPinned(task.id),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Pin'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
