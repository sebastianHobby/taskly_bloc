import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/screens/tiles/screen_item_tile_registry.dart';
import 'package:taskly_bloc/presentation/widgets/taskly/widgets.dart';

enum _SomedaySortMode {
  updatedAt,
  priority,
}

class SomedayBacklogRenderer extends StatefulWidget {
  const SomedayBacklogRenderer({
    required this.data,
    super.key,
    this.onTaskToggle,
    this.onProjectToggle,
    this.onEntityTap,
  });

  final DataSectionResult data;
  final void Function(String, bool?)? onTaskToggle;
  final void Function(String, bool?)? onProjectToggle;
  final void Function(Object entity)? onEntityTap;

  @override
  State<SomedayBacklogRenderer> createState() => _SomedayBacklogRendererState();
}

class _SomedayBacklogRendererState extends State<SomedayBacklogRenderer> {
  static const _tileRegistry = ScreenItemTileRegistry();

  _SomedaySortMode _sortMode = _SomedaySortMode.updatedAt;
  bool _projectsOnly = false;
  String? _selectedValueId; // null means "All Values"

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final focusTaskIds =
        widget.data.relatedEntities['focusTaskIds']
            ?.whereType<String>()
            .toSet() ??
        const <String>{};
    final focusProjectIds =
        widget.data.relatedEntities['focusProjectIds']
            ?.whereType<String>()
            .toSet() ??
        const <String>{};

    final allTasks = widget.data.items.whereType<ScreenItemTask>().toList();
    final allProjects = widget.data.items
        .whereType<ScreenItemProject>()
        .toList();

    final availableValues = _collectValues(allTasks, allProjects)
      ..sort(_compareValuesByPriorityThenName);

    final filteredTasks = _applyFiltersToTasks(allTasks);
    final filteredProjects = _applyFiltersToProjects(allProjects);

    if (filteredTasks.isEmpty && filteredProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No items',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final groups = _buildGroups(
      tasks: filteredTasks,
      projects: filteredProjects,
      values: availableValues,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _FilterBar(
          sortMode: _sortMode,
          projectsOnly: _projectsOnly,
          selectedValueId: _selectedValueId,
          values: availableValues,
          onSortModeChanged: (m) => setState(() => _sortMode = m),
          onProjectsOnlyChanged: (v) => setState(() => _projectsOnly = v),
          onSelectedValueChanged: (v) => setState(() => _selectedValueId = v),
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          _GroupHeader(
            title: group.title,
            badgeText: group.badgeText,
          ),
          const SizedBox(height: 12),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _tileRegistry.build(
                context,
                item: item,
                focusTaskIds: focusTaskIds,
                focusProjectIds: focusProjectIds,
                onTaskToggle: widget.onTaskToggle,
                onProjectToggle: widget.onProjectToggle,
                onTap: () {
                  switch (item) {
                    case ScreenItemTask(:final task):
                      widget.onEntityTap?.call(task);
                    case ScreenItemProject(:final project):
                      widget.onEntityTap?.call(project);
                    default:
                      // Ignore structural items.
                      break;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  List<Value> _collectValues(
    List<ScreenItemTask> tasks,
    List<ScreenItemProject> projects,
  ) {
    final byId = <String, Value>{};

    for (final t in tasks) {
      for (final v in t.task.values) {
        byId[v.id] = v;
      }
    }

    for (final p in projects) {
      for (final v in p.project.values) {
        byId[v.id] = v;
      }
    }

    return byId.values.toList(growable: false);
  }

  int _compareValuesByPriorityThenName(Value a, Value b) {
    final ap = _priorityRank(a.priority);
    final bp = _priorityRank(b.priority);
    final byP = ap.compareTo(bp);
    if (byP != 0) return byP;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _priorityRank(ValuePriority p) {
    // Lower rank = higher priority.
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  List<ScreenItemTask> _applyFiltersToTasks(List<ScreenItemTask> tasks) {
    return tasks
        .where((t) {
          final task = t.task;

          if (_projectsOnly && task.projectId == null) {
            return false;
          }

          if (_selectedValueId == null) return true;

          final primary = task.primaryValue;
          final primaryId = primary?.id;
          if (primaryId != null) return primaryId == _selectedValueId;

          // If no primary, fall back to any value.
          return task.values.any((v) => v.id == _selectedValueId);
        })
        .toList(growable: false);
  }

  List<ScreenItemProject> _applyFiltersToProjects(
    List<ScreenItemProject> projects,
  ) {
    return projects
        .where((p) {
          if (_selectedValueId == null) return true;
          return p.project.values.any((v) => v.id == _selectedValueId);
        })
        .toList(growable: false);
  }

  List<_SomedayGroup> _buildGroups({
    required List<ScreenItemTask> tasks,
    required List<ScreenItemProject> projects,
    required List<Value> values,
  }) {
    final noValueTasks = <Task>[];
    final noValueProjects = <Project>[];

    final tasksByValueId = <String, List<Task>>{};
    final projectsByValueId = <String, List<Project>>{};

    for (final t in tasks) {
      final task = t.task;
      final value =
          task.primaryValue ?? (task.values.isEmpty ? null : task.values.first);

      if (value == null) {
        noValueTasks.add(task);
      } else {
        tasksByValueId.putIfAbsent(value.id, () => []).add(task);
      }
    }

    for (final p in projects) {
      final project = p.project;
      // Choose a single value for grouping: highest priority, then name.
      final value = project.values.isEmpty
          ? null
          : (project.values.toList()..sort(_compareValuesByPriorityThenName))
                .first;

      if (value == null) {
        noValueProjects.add(project);
      } else {
        projectsByValueId.putIfAbsent(value.id, () => []).add(project);
      }
    }

    final groups = <_SomedayGroup>[];

    // 1) No value assigned (top)
    final noValueItems = <ScreenItem>[];
    noValueProjects.sort(_compareProjects);
    noValueTasks.sort(_compareTasks);

    noValueItems.addAll(noValueProjects.map(ScreenItem.project));
    noValueItems.addAll(noValueTasks.map(ScreenItem.task));

    if (noValueItems.isNotEmpty) {
      groups.add(
        _SomedayGroup(
          title: 'NO VALUE ASSIGNED (Inbox)',
          badgeText: null,
          items: noValueItems,
        ),
      );
    }

    // 2) Value groups (ordered by value priority)
    for (final value in values) {
      final valueTasks = tasksByValueId[value.id] ?? const <Task>[];
      final valueProjects = projectsByValueId[value.id] ?? const <Project>[];

      if (valueTasks.isEmpty && valueProjects.isEmpty) continue;

      final items = <ScreenItem>[];

      // Projects first (each project tile + its tasks)
      final sortedProjects = valueProjects.toList()..sort(_compareProjects);
      for (final project in sortedProjects) {
        items.add(ScreenItem.header('PROJECT: ${project.name.toUpperCase()}'));
        items.add(ScreenItem.project(project));

        final projectTasks =
            valueTasks
                .where((t) => t.projectId == project.id)
                .toList(growable: false)
              ..sort(_compareTasks);

        for (final task in projectTasks) {
          items.add(ScreenItem.task(task));
        }
      }

      // Inbox tasks for this value (no project)
      final inboxTasks =
          valueTasks.where((t) => t.projectId == null).toList(growable: false)
            ..sort(_compareTasks);

      if (inboxTasks.isNotEmpty) {
        items.add(ScreenItem.header('INBOX (${value.name.toUpperCase()})'));
        for (final task in inboxTasks) {
          items.add(ScreenItem.task(task));
        }
      }

      final badge = _valuePriorityLabel(value.priority);

      groups.add(
        _SomedayGroup(
          title: value.name,
          badgeText: badge,
          items: items,
        ),
      );
    }

    return groups;
  }

  int _compareTasks(Task a, Task b) {
    if (_sortMode == _SomedaySortMode.priority) {
      final ap = a.priority;
      final bp = b.priority;

      if (ap == null && bp != null) return 1;
      if (ap != null && bp == null) return -1;
      if (ap != null && bp != null) {
        final byP = ap.compareTo(bp);
        if (byP != 0) return byP;
      }
    }

    // Default: updatedAt desc
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    return a.id.compareTo(b.id);
  }

  int _compareProjects(Project a, Project b) {
    // Projects don't have an intrinsic priority; always updatedAt desc.
    final byUpdated = b.updatedAt.compareTo(a.updatedAt);
    if (byUpdated != 0) return byUpdated;
    return a.id.compareTo(b.id);
  }

  String _valuePriorityLabel(ValuePriority p) {
    return switch (p) {
      ValuePriority.high => 'HIGH PRIORITY VALUE',
      ValuePriority.medium => 'PRIORITY VALUE',
      ValuePriority.low => 'STANDARD VALUE',
    };
  }
}

class _SomedayGroup {
  const _SomedayGroup({
    required this.title,
    required this.items,
    this.badgeText,
  });

  final String title;
  final String? badgeText;
  final List<ScreenItem> items;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.sortMode,
    required this.projectsOnly,
    required this.selectedValueId,
    required this.values,
    required this.onSortModeChanged,
    required this.onProjectsOnlyChanged,
    required this.onSelectedValueChanged,
  });

  final _SomedaySortMode sortMode;
  final bool projectsOnly;
  final String? selectedValueId;
  final List<Value> values;
  final ValueChanged<_SomedaySortMode> onSortModeChanged;
  final ValueChanged<bool> onProjectsOnlyChanged;
  final ValueChanged<String?> onSelectedValueChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SortButton(sortMode: sortMode, onChanged: onSortModeChanged),
        _ValueDropdown(
          selectedValueId: selectedValueId,
          values: values,
          onChanged: onSelectedValueChanged,
        ),
        FilterChip(
          label: const Text('Projects Only'),
          selected: projectsOnly,
          onSelected: onProjectsOnlyChanged,
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sortMode, required this.onChanged});

  final _SomedaySortMode sortMode;
  final ValueChanged<_SomedaySortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = switch (sortMode) {
      _SomedaySortMode.updatedAt => 'Sort: Recent',
      _SomedaySortMode.priority => 'Sort: Priority',
    };

    return OutlinedButton.icon(
      onPressed: () {
        onChanged(
          sortMode == _SomedaySortMode.updatedAt
              ? _SomedaySortMode.priority
              : _SomedaySortMode.updatedAt,
        );
      },
      icon: const Icon(Icons.sort),
      label: Text(label),
    );
  }
}

class _ValueDropdown extends StatelessWidget {
  const _ValueDropdown({
    required this.selectedValueId,
    required this.values,
    required this.onChanged,
  });

  final String? selectedValueId;
  final List<Value> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedValueId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Values'),
              ),
              ...values.map(
                (v) => DropdownMenuItem<String?>(
                  value: v.id,
                  child: Text(v.name),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.badgeText});

  final String title;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: TasklyHeader(
            title: title,
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              badgeText!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
