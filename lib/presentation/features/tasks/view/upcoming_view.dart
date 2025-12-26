import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/upcoming_tasks_grouper.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_add_fab.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

/// The Upcoming page displaying tasks organized by date in agenda format.
class UpcomingPage extends StatelessWidget {
  const UpcomingPage({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    required this.settingsRepository,
    required this.pageKey,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;
  final SettingsRepositoryContract settingsRepository;
  final PageKey pageKey;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TaskOverviewBloc>(
      create: (context) => TaskOverviewBloc(
        taskRepository: taskRepository,
        query: TaskQuery.upcoming(),
        settingsRepository: settingsRepository,
        pageKey: pageKey,
      )..add(const TaskOverviewEvent.subscriptionRequested()),
      child: UpcomingView(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

/// The main upcoming view displaying tasks grouped by date in agenda format.
class UpcomingView extends StatefulWidget {
  const UpcomingView({
    required this.taskRepository,
    required this.projectRepository,
    required this.labelRepository,
    super.key,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final LabelRepositoryContract labelRepository;

  @override
  State<UpcomingView> createState() => _UpcomingViewState();
}

class _UpcomingViewState extends State<UpcomingView> {
  void _showTaskDetailSheet(BuildContext context, {String? taskId}) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: widget.taskRepository,
              projectRepository: widget.projectRepository,
              labelRepository: widget.labelRepository,
              taskId: taskId,
            ),
            child: TaskDetailSheet(labelRepository: widget.labelRepository),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.upcomingTitle),
      ),
      body: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(friendlyErrorMessageForUi(error, context.l10n)),
            ),
            loaded: (tasks, _) {
              if (tasks.isEmpty) {
                return EmptyStateWidget.upcoming(
                  title: context.l10n.emptyUpcomingTitle,
                  description: context.l10n.emptyUpcomingDescription,
                );
              }

              final now = DateTime.now();
              // Use large number to get all future tasks
              final groupedTasks = UpcomingTasksGrouper.groupByDate(
                tasks: tasks,
                now: now,
                daysAhead: 3650, // ~10 years to capture all future tasks
              );

              // Filter to show only dates with tasks (agenda view)
              final sortedDates = groupedTasks.keys.toList()..sort();
              final datesWithTasks = sortedDates
                  .where((date) => groupedTasks[date]!.isNotEmpty)
                  .toList();

              if (datesWithTasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All clear!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming tasks with deadlines',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  for (int index = 0; index < datesWithTasks.length; index++)
                    ..._buildDateSectionSlivers(
                      context,
                      date: datesWithTasks[index],
                      entries: groupedTasks[datesWithTasks[index]]!,
                      now: now,
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: AddTaskFab(
        taskRepository: widget.taskRepository,
        projectRepository: widget.projectRepository,
        labelRepository: widget.labelRepository,
      ),
    );
  }

  List<Widget> _buildDateSectionSlivers(
    BuildContext context, {
    required DateTime date,
    required List<TaskDateEntry> entries,
    required DateTime now,
  }) {
    final dateFormatter = DateFormat.MMMEd(); // Shorter format: "Dec 25, Wed"
    final dateString = dateFormatter.format(date);

    // Calculate relative day label
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String? relativeDayLabel;
    if (dateOnly == today) {
      relativeDayLabel = 'Today';
    } else if (dateOnly == tomorrow) {
      relativeDayLabel = 'Tomorrow';
    } else {
      final daysAway = dateOnly.difference(today).inDays;
      if (daysAway <= 7) {
        relativeDayLabel = 'in $daysAway days';
      }
    }

    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _DateHeaderDelegate(
          dateString: dateString,
          relativeDayLabel: relativeDayLabel,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTaskEntry(context, entries[index]),
            childCount: entries.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildTaskEntry(BuildContext context, TaskDateEntry entry) {
    return TaskListTile(
      task: entry.task,
      onTap: (task) => _showTaskDetailSheet(context, taskId: task.id),
      onCheckboxChanged: (task, _) {
        context.read<TaskOverviewBloc>().add(
          TaskOverviewEvent.toggleTaskCompletion(task: task),
        );
      },
    );
  }
}

/// Sticky header delegate for date sections
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateHeaderDelegate({
    required this.dateString,
    this.relativeDayLabel,
  });

  final String dateString;
  final String? relativeDayLabel;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (relativeDayLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                relativeDayLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            dateString,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) {
    return oldDelegate.dateString != dateString ||
        oldDelegate.relativeDayLabel != relativeDayLabel;
  }
}
