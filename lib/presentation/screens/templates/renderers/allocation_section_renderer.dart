import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';

typedef _RowBuilder = Widget Function(BuildContext context);

class AllocationSectionRenderer extends StatelessWidget {
  const AllocationSectionRenderer({
    required this.data,
    super.key,
    this.onTaskToggle,
    this.onSetupValues,
  });
  final AllocationSectionResult data;
  final void Function(String, bool?)? onTaskToggle;
  final VoidCallback? onSetupValues;

  @override
  Widget build(BuildContext context) {
    final focusMode = data.activeFocusMode ?? FocusMode.sustainable;

    if (data.requiresValueSetup) {
      return SliverToBoxAdapter(child: _buildRequiresValueSetup(context));
    }

    if (data.allocatedTasks.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }

    return _buildContent(context, focusMode);
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

  void _appendPinnedTasks(BuildContext context, List<_RowBuilder> rows) {
    if (data.pinnedTasks.isEmpty) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    rows.add(
      (context) => Padding(
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
    );

    for (var i = 0; i < data.pinnedTasks.length; i++) {
      final allocatedTask = data.pinnedTasks[i];
      rows.add(
        (context) => TaskView(
          task: allocatedTask.task,
          onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        ),
      );

      if (i != data.pinnedTasks.length - 1) {
        rows.add((context) => const Divider(height: 1));
      }
    }

    rows.add((context) => const SizedBox(height: 16));
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

    final rows = <_RowBuilder>[];

    for (final key in groupKeys) {
      final tasks = groups[key] ?? const <Task>[];
      if (tasks.isEmpty) continue;

      final Project? project = tasks
          .map((t) => t.project)
          .cast<Project?>()
          .firstWhere(
            (p) => p != null,
            orElse: () => null,
          );

      rows.add(
        (context) => Padding(
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
      );

      if (project != null &&
          (project.primaryValue != null ||
              project.secondaryValues.isNotEmpty)) {
        rows.add(
          (context) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ValuesFooter(
              primaryValue: project.primaryValue,
              secondaryValues: project.secondaryValues,
            ),
          ),
        );
      }

      for (var i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        rows.add(
          (context) => TaskView(
            task: task,
            onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
          ),
        );
        if (i != tasks.length - 1) {
          rows.add((context) => const Divider(height: 1));
        }
      }

      rows.add((context) => const SizedBox(height: 16));
    }

    return _sliverFromBuilders(rows);
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

    final rows = <_RowBuilder>[];

    if (includePinned) {
      _appendPinnedTasks(context, rows);
    }

    for (final group in groups) {
      if (group.tasks.isEmpty) continue;

      rows.add(
        (context) => Padding(
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
      );

      for (var i = 0; i < group.tasks.length; i++) {
        final allocatedTask = group.tasks[i];
        rows.add(
          (context) => TaskView(
            task: allocatedTask.task,
            onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
          ),
        );
        if (i != group.tasks.length - 1) {
          rows.add((context) => const Divider(height: 1));
        }
      }

      rows.add((context) => const SizedBox(height: 16));
    }

    return _sliverFromBuilders(rows);
  }

  Widget _buildFlatList() {
    final rows = <_RowBuilder>[];
    for (var i = 0; i < data.allocatedTasks.length; i++) {
      final task = data.allocatedTasks[i];
      rows.add(
        (context) => TaskView(
          task: task,
          onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        ),
      );
      if (i != data.allocatedTasks.length - 1) {
        rows.add((context) => const Divider(height: 1));
      }
    }
    return _sliverFromBuilders(rows);
  }

  Widget _sliverFromBuilders(List<_RowBuilder> rows) {
    if (rows.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => rows[index](context),
        childCount: rows.length,
      ),
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
                final launcher = EditorLauncher.fromGetIt();
                await launcher.openTaskEditor(context);
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

  Widget _buildRequiresValueSetup(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set up values to use focus mode',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Focus allocation needs at least one value so it can prioritize '
              'your tasks. Add a value, then come back here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  onSetupValues ??
                  () {
                    Routing.toScreenKey(context, 'focus_setup');
                  },
              icon: const Icon(Icons.tune),
              label: const Text('Set up focus'),
            ),
          ],
        ),
      ),
    );
  }
}
