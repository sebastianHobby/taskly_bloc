import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/values_footer.dart';

typedef _RowBuilder = Widget Function(BuildContext context);

class AllocationSectionRenderer extends StatefulWidget {
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
  State<AllocationSectionRenderer> createState() =>
      _AllocationSectionRendererState();
}

class _AllocationSectionRendererState extends State<AllocationSectionRenderer> {
  final Set<String> _collapsedProjectIds = <String>{};

  bool _isProjectCollapsed(String projectId) {
    return _collapsedProjectIds.contains(projectId);
  }

  void _toggleProjectCollapsed(String projectId) {
    setState(() {
      if (!_collapsedProjectIds.add(projectId)) {
        _collapsedProjectIds.remove(projectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusMode = widget.data.activeFocusMode ?? FocusMode.sustainable;

    if (widget.data.requiresValueSetup) {
      return SliverToBoxAdapter(child: _buildRequiresValueSetup(context));
    }

    if (widget.data.allocatedTasks.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(context));
    }

    return _buildContent(context, focusMode);
  }

  Widget _buildContent(BuildContext context, FocusMode focusMode) {
    return switch (widget.data.displayMode) {
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

  Widget _buildProjectGroupedList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final groups = <String, List<Task>>{};
    final groupKeys = <String>[];

    for (final task in widget.data.allocatedTasks) {
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
            onCheckboxChanged: (t, val) => widget.onTaskToggle?.call(t.id, val),
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
    if (widget.data.tasksByValue.isEmpty) {
      return _buildFlatList();
    }

    final groups =
        widget.data.tasksByValue.values
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

    final pinnedByValueId = <String, List<AllocatedTask>>{};
    final unassignedPinned = <AllocatedTask>[];

    if (includePinned) {
      for (final pinned in widget.data.pinnedTasks) {
        final valueId = pinned.qualifyingValueId.trim();
        if (valueId.isEmpty) {
          unassignedPinned.add(pinned);
        } else {
          (pinnedByValueId[valueId] ??= []).add(pinned);
        }
      }
    }

    for (final group in groups) {
      if (group.tasks.isEmpty) continue;

      final groupColor = group.color == null
          ? null
          : ColorUtils.fromHexWithThemeFallback(context, group.color);

      rows.add(
        (context) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              if (groupColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: groupColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  group.valueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final pinnedForGroup = pinnedByValueId[group.valueId] ?? const [];
      final allTasksForGroup = <AllocatedTask>[
        ...pinnedForGroup,
        ...group.tasks,
      ];

      final uniqueByTaskId = <String, AllocatedTask>{
        for (final t in allTasksForGroup) t.task.id: t,
      };
      final uniqueTasksForGroup = uniqueByTaskId.values.toList(growable: false);

      final tasksByProjectId = <String, List<AllocatedTask>>{};
      final projectNameById = <String, String>{};
      final projectById = <String, Project?>{};
      const noProjectKey = '__no_project__';

      for (final allocatedTask in uniqueTasksForGroup) {
        final task = allocatedTask.task;
        final project = task.project;
        final projectId = project?.id ?? task.projectId ?? noProjectKey;
        (tasksByProjectId[projectId] ??= []).add(allocatedTask);

        if (projectId == noProjectKey) {
          projectNameById[projectId] = 'No project';
          projectById[projectId] = null;
        } else {
          projectNameById[projectId] = project?.name ?? 'Project';
          projectById[projectId] = project;
        }
      }

      final projectIds = tasksByProjectId.keys.toList(growable: false)
        ..sort((a, b) {
          if (a == noProjectKey && b != noProjectKey) return 1;
          if (b == noProjectKey && a != noProjectKey) return -1;
          final aName = (projectNameById[a] ?? '').toLowerCase();
          final bName = (projectNameById[b] ?? '').toLowerCase();
          return aName.compareTo(bName);
        });

      for (final projectId in projectIds) {
        final projectName = projectNameById[projectId] ?? 'Project';
        final project = projectById[projectId];
        final tasks = tasksByProjectId[projectId] ?? const <AllocatedTask>[];
        if (tasks.isEmpty) continue;

        // Match Someday: small gap before each project block.
        rows.add((context) => const SizedBox(height: 8));

        final canCollapse = projectId != noProjectKey;
        final collapsed = canCollapse && _isProjectCollapsed(projectId);

        final pinnedTaskIds = {
          for (final pinned in pinnedForGroup) pinned.task.id,
        };
        final sortedTasks = tasks.toList(growable: false)
          ..sort((a, b) {
            final aTask = a.task;
            final bTask = b.task;
            final aPinned = pinnedTaskIds.contains(aTask.id);
            final bPinned = pinnedTaskIds.contains(bTask.id);
            if (aPinned != bPinned) return aPinned ? -1 : 1;
            if (aTask.completed != bTask.completed) {
              return aTask.completed ? 1 : -1;
            }
            return aTask.name.toLowerCase().compareTo(bTask.name.toLowerCase());
          });

        rows.add(
          (context) {
            final prefix = canCollapse
                ? _CollapseChevron(
                    collapsed: collapsed,
                    onPressed: () => _toggleProjectCollapsed(projectId),
                  )
                : null;

            if (project != null) {
              final completedCount = tasks
                  .where((t) => t.task.completed)
                  .length;
              return ProjectView(
                project: project,
                compact: true,
                trailing: prefix,
                showTrailingProgressLabel: prefix != null,
                taskCount: tasks.length,
                completedTaskCount: completedCount,
              );
            }

            if (canCollapse) {
              return InkWell(
                onTap: () => Routing.toEntity(
                  context,
                  EntityType.project,
                  projectId,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tasks.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ?prefix,
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (collapsed) {
          rows.add((context) => const SizedBox(height: 8));
          continue;
        }

        // Match Someday: add a small gap between the project header and tasks.
        rows.add((context) => const SizedBox(height: 8));

        for (var i = 0; i < sortedTasks.length; i++) {
          final allocatedTask = sortedTasks[i];
          rows.add(
            (context) => TaskView(
              task: allocatedTask.task,
              onCheckboxChanged: (t, val) =>
                  widget.onTaskToggle?.call(t.id, val),
              showProjectNameInMeta: false,
              showPrimaryValueChip: false,
              maxSecondaryValueChips: 2,
              excludeValueIdFromChips: group.valueId,
            ),
          );
          if (i != sortedTasks.length - 1) {
            rows.add((context) => const Divider(height: 1));
          }
        }

        rows.add((context) => const SizedBox(height: 8));
      }

      rows.add((context) => const SizedBox(height: 8));
    }

    if (unassignedPinned.isNotEmpty) {
      rows.add(
        (context) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            'Pinned (unassigned)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      );

      for (var i = 0; i < unassignedPinned.length; i++) {
        final allocatedTask = unassignedPinned[i];
        rows.add(
          (context) => TaskView(
            task: allocatedTask.task,
            onCheckboxChanged: (t, val) => widget.onTaskToggle?.call(t.id, val),
          ),
        );
        if (i != unassignedPinned.length - 1) {
          rows.add((context) => const Divider(height: 1));
        }
      }
    }

    return _sliverFromBuilders(rows);
  }

  Widget _buildFlatList() {
    final rows = <_RowBuilder>[];
    for (var i = 0; i < widget.data.allocatedTasks.length; i++) {
      final task = widget.data.allocatedTasks[i];
      rows.add(
        (context) => TaskView(
          task: task,
          onCheckboxChanged: (t, val) => widget.onTaskToggle?.call(t.id, val),
        ),
      );
      if (i != widget.data.allocatedTasks.length - 1) {
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

    if (widget.data.totalAvailable == 0) {
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
                  widget.onSetupValues ??
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

class _CollapseChevron extends StatelessWidget {
  const _CollapseChevron({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      tooltip: collapsed ? 'Expand project' : 'Collapse project',
      onPressed: onPressed,
      icon: AnimatedRotation(
        turns: collapsed ? -0.25 : 0,
        duration: const Duration(milliseconds: 160),
        child: Icon(
          Icons.expand_more,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
