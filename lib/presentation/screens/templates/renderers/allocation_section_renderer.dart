import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';

class AllocationSectionRenderer extends StatelessWidget {
  const AllocationSectionRenderer({
    required this.data,
    super.key,
    this.onTaskToggle,
  });
  final AllocationSectionResult data;
  final void Function(String, bool?)? onTaskToggle;

  @override
  Widget build(BuildContext context) {
    final focusMode = data.activeFocusMode ?? FocusMode.sustainable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content based on Focus Mode
        if (data.allocatedTasks.isEmpty)
          _buildEmptyState(context)
        else
          _buildContent(context, focusMode),
      ],
    );
  }

  Widget _buildContent(BuildContext context, FocusMode focusMode) {
    return switch (data.displayMode) {
      AllocationDisplayMode.groupedByProject => _buildProjectGroupedList(
        context,
      ),
      AllocationDisplayMode.flat => _buildFlatList(),
      AllocationDisplayMode.groupedByValue => _buildValueGroupedList(
        context,
        includePinned: true,
      ),
      AllocationDisplayMode.pinnedFirst => _buildValueGroupedList(
        context,
        includePinned: true,
      ),
    };
  }

  int _priorityRank(ValuePriority p) {
    // Lower rank = higher priority.
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  Widget _buildPinnedTasks(BuildContext context) {
    if (data.pinnedTasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                'PINNED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${data.pinnedTasks.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.pinnedTasks.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final allocatedTask = data.pinnedTasks[index];
            return TaskView(
              task: allocatedTask.task,
              onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProjectGroupedList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final groups = <String, List<Task>>{};
    final groupKeys = <String>[];

    for (final task in data.allocatedTasks) {
      final key = _projectGroupKey(task);
      final existing = groups[key];
      if (existing == null) {
        groups[key] = [task];
        groupKeys.add(key);
      } else {
        existing.add(task);
      }
    }

    // Sort tasks and groups deterministically.
    for (final entry in groups.entries) {
      entry.value.sort((a, b) => a.name.compareTo(b.name));
    }

    groupKeys.sort((a, b) {
      final aTasks = groups[a] ?? const <Task>[];
      final bTasks = groups[b] ?? const <Task>[];

      final aHasUrgent = aTasks.any(_isProjectGroupUrgent);
      final bHasUrgent = bTasks.any(_isProjectGroupUrgent);

      if (aHasUrgent != bHasUrgent) return aHasUrgent ? -1 : 1;
      return a.compareTo(b);
    });

    return Column(
      children: groupKeys.map((key) {
        final tasks = groups[key] ?? const <Task>[];
        if (tasks.isEmpty) return const SizedBox.shrink();

        final Project? project = tasks
            .map((t) => t.project)
            .cast<Project?>()
            .firstWhere(
              (p) => p != null,
              orElse: () => null,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (project != null &&
                (project.primaryValue != null ||
                    project.secondaryValues.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ValuesFooter(
                  primaryValue: project.primaryValue,
                  secondaryValues: project.secondaryValues,
                ),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskView(
                  task: task,
                  onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  String _projectGroupKey(Task task) {
    final projectName = task.project?.name.trim();
    if (projectName != null && projectName.isNotEmpty) return projectName;
    if (task.projectId != null) return 'Project';
    return 'No Project';
  }

  bool _isProjectGroupUrgent(Task task) {
    if (task.completed) return false;
    final deadline = task.deadlineDate;
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(tomorrow);
  }

  Widget _buildValueGroupedList(
    BuildContext context, {
    required bool includePinned,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use tasksByValue if available, otherwise fallback to flat list
    if (data.tasksByValue.isEmpty) {
      return _buildFlatList();
    }

    final groups =
        data.tasksByValue.values
            .where((g) => g.tasks.isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) {
            final byPriority = _priorityRank(
              a.valuePriority,
            ).compareTo(_priorityRank(b.valuePriority));
            if (byPriority != 0) return byPriority;
            return a.valueName.toLowerCase().compareTo(
              b.valueName.toLowerCase(),
            );
          });

    return Column(
      children: [
        if (includePinned) _buildPinnedTasks(context),
        ...groups.map((group) {
          if (group.tasks.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      group.valueName.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${group.tasks.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final allocatedTask = group.tasks[index];
                  return TaskView(
                    task: allocatedTask.task,
                    onCheckboxChanged: (t, val) =>
                        onTaskToggle?.call(t.id, val),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFlatList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.allocatedTasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = data.allocatedTasks[index];
        return TaskView(
          task: task,
          onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    if (data.totalAvailable == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No tasks yet.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first task to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await showDetailModal<void>(
                  context: context,
                  childBuilder: (modalSheetContext) => BlocProvider(
                    create: (_) => TaskDetailBloc(
                      taskRepository: getIt<TaskRepositoryContract>(),
                      projectRepository: getIt<ProjectRepositoryContract>(),
                      valueRepository: getIt<ValueRepositoryContract>(),
                    ),
                    child: const TaskDetailSheet(),
                  ),
                );
              },
              child: const Text('Add First Task'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'No tasks allocated for today.',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
