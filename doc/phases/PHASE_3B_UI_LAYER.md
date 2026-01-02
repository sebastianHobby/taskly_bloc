# Phase 3B: UI Layer

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones. Leverage existing widgets.

### Phase Goal
Create UI widgets that render section data from SectionBloc. Update ScreenHostPage to use the new section-based rendering instead of the hardcoded switch statement.

### Prerequisites
- Phase 0-2 complete (types, services, models)
- Phase 3A complete (SectionBloc exists)

---

## Task 1: Create Section Renderer Dispatcher

**File**: `lib/presentation/widgets/sections/section_renderer.dart`

**Purpose**: Dispatches to the correct renderer based on section type.

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/sections/data_section_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/support_section_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/navigation_section_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/allocation_section_renderer.dart';

/// Renders a single section based on its type and loaded data.
class SectionRenderer extends StatelessWidget {
  const SectionRenderer({
    required this.loadedSection,
    this.onTaskTap,
    this.onProjectTap,
    this.onLabelTap,
    super.key,
  });

  final LoadedSection loadedSection;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;
  final void Function(String labelId)? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final section = loadedSection.section;
    final data = loadedSection.data;
    final settings = loadedSection.displaySettings;

    return switch (section) {
      DataSection() => DataSectionRenderer(
          section: section,
          data: data,
          displaySettings: settings,
          onTaskTap: onTaskTap,
          onProjectTap: onProjectTap,
          onLabelTap: onLabelTap,
        ),
      SupportSection(:final config) => SupportSectionRenderer(
          config: config,
          data: data,
        ),
      NavigationSection(:final items, :final groupTitle) => 
        NavigationSectionRenderer(
          items: items,
          groupTitle: groupTitle,
          data: data,
        ),
      AllocationSection(:final maxTasks) => AllocationSectionRenderer(
          maxTasks: maxTasks,
          data: data,
          onTaskTap: onTaskTap,
        ),
    };
  }
}

/// Renders multiple sections in a list
class SectionsListView extends StatelessWidget {
  const SectionsListView({
    required this.sections,
    this.onTaskTap,
    this.onProjectTap,
    this.onLabelTap,
    this.padding,
    super.key,
  });

  final List<LoadedSection> sections;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;
  final void Function(String labelId)? onLabelTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final loadedSection = sections[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < sections.length - 1 ? 16 : 0,
          ),
          child: SectionRenderer(
            loadedSection: loadedSection,
            onTaskTap: onTaskTap,
            onProjectTap: onProjectTap,
            onLabelTap: onLabelTap,
          ),
        );
      },
    );
  }
}
```

---

## Task 2: Create Data Section Renderer

**File**: `lib/presentation/widgets/sections/data_section_renderer.dart`

**Pattern Reference**: Look at existing task list widgets in `lib/presentation/features/tasks/`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/widgets/sections/renderers/task_list_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/renderers/project_list_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/renderers/label_list_renderer.dart';
import 'package:taskly_bloc/presentation/widgets/sections/renderers/value_hierarchy_renderer.dart';

/// Renders a DataSection based on its entity type and display settings.
class DataSectionRenderer extends StatelessWidget {
  const DataSectionRenderer({
    required this.section,
    required this.data,
    required this.displaySettings,
    this.onTaskTap,
    this.onProjectTap,
    this.onLabelTap,
    super.key,
  });

  final DataSection section;
  final SectionData data;
  final SectionDisplaySettings displaySettings;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;
  final void Function(String labelId)? onLabelTap;

  @override
  Widget build(BuildContext context) {
    // Optional section title
    final title = section.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          _SectionHeader(title: title),
          const SizedBox(height: 8),
        ],
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (data) {
      TaskSectionData(:final tasks, :final projectsById, :final labelsById) =>
        TaskListRenderer(
          tasks: tasks,
          projectsById: projectsById ?? {},
          labelsById: labelsById ?? {},
          displaySettings: displaySettings,
          onTaskTap: onTaskTap,
        ),
      ProjectSectionData(
        :final projects,
        :final tasksByProjectId,
        :final labelsById,
      ) =>
        ProjectListRenderer(
          projects: projects,
          tasksByProjectId: tasksByProjectId,
          labelsById: labelsById ?? {},
          displaySettings: displaySettings,
          onProjectTap: onProjectTap,
          onTaskTap: onTaskTap,
        ),
      LabelSectionData(
        :final labels,
        :final tasksByLabelId,
        :final projectsByLabelId,
      ) =>
        LabelListRenderer(
          labels: labels.where((l) => l.type != LabelType.value).toList(),
          tasksByLabelId: tasksByLabelId,
          projectsByLabelId: projectsByLabelId,
          displaySettings: displaySettings,
          onLabelTap: onLabelTap,
        ),
      ValueSectionData(
        :final values,
        :final tasksByValueId,
        :final projectsByValueId,
        :final hierarchies,
      ) =>
        // Use hierarchy renderer if available, otherwise simple list
        hierarchies != null && hierarchies.isNotEmpty
            ? ValueHierarchyRenderer(
                hierarchies: hierarchies,
                displaySettings: displaySettings,
                onTaskTap: onTaskTap,
                onProjectTap: onProjectTap,
              )
            : LabelListRenderer(
                labels: values,
                tasksByLabelId: tasksByValueId,
                projectsByLabelId: projectsByValueId,
                displaySettings: displaySettings,
                onLabelTap: onLabelTap,
              ),
      _ => const SizedBox.shrink(), // Allocation, Navigation, Support handled elsewhere
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
```

---

## Task 3: Create Entity List Renderers

### Task List Renderer

**File**: `lib/presentation/widgets/sections/renderers/task_list_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/presentation/widgets/task_tile.dart'; // Reuse existing

/// Renders a list of tasks with optional grouping and related data.
class TaskListRenderer extends StatelessWidget {
  const TaskListRenderer({
    required this.tasks,
    required this.projectsById,
    required this.labelsById,
    required this.displaySettings,
    this.onTaskTap,
    super.key,
  });

  final List<Task> tasks;
  final Map<String, Project> projectsById;
  final Map<String, Label> labelsById;
  final SectionDisplaySettings displaySettings;
  final void Function(String taskId)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyState(message: 'No tasks');
    }

    final grouped = _groupTasks();
    
    if (grouped.length == 1 && grouped.keys.first == null) {
      // No grouping, render flat list
      return _buildTaskList(tasks);
    }

    // Render grouped
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: grouped.entries.map((entry) {
        final groupKey = entry.key;
        final groupTasks = entry.value;
        final isCollapsed = displaySettings.collapsedGroupIds.contains(groupKey);

        return _TaskGroup(
          groupKey: groupKey,
          groupLabel: _getGroupLabel(groupKey),
          tasks: groupTasks,
          isCollapsed: isCollapsed,
          projectsById: projectsById,
          labelsById: labelsById,
          onTaskTap: onTaskTap,
        );
      }).toList(),
    );
  }

  Map<String?, List<Task>> _groupTasks() {
    final groupBy = displaySettings.groupBy;
    
    if (groupBy == null || groupBy == GroupByField.none) {
      return {null: tasks};
    }

    final grouped = <String?, List<Task>>{};
    
    for (final task in tasks) {
      final key = switch (groupBy) {
        GroupByField.project => task.projectId,
        GroupByField.priority => task.priority?.toString(),
        GroupByField.dueDate => _formatDateKey(task.deadlineDate),
        GroupByField.status => task.completed ? 'completed' : 'active',
        _ => null,
      };
      
      grouped.putIfAbsent(key, () => []).add(task);
    }

    return grouped;
  }

  String _getGroupLabel(String? key) {
    if (key == null) return 'Ungrouped';
    
    final groupBy = displaySettings.groupBy;
    
    return switch (groupBy) {
      GroupByField.project => projectsById[key]?.name ?? 'No Project',
      GroupByField.priority => 'Priority $key',
      GroupByField.status => key == 'completed' ? 'Completed' : 'Active',
      _ => key,
    };
  }

  String? _formatDateKey(DateTime? date) {
    if (date == null) return null;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildTaskList(List<Task> taskList) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: taskList.map((task) {
        final project = task.projectId != null 
            ? projectsById[task.projectId] 
            : null;
        
        return TaskTile(
          task: task,
          project: project,
          onTap: onTaskTap != null ? () => onTaskTap!(task.id) : null,
        );
      }).toList(),
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({
    required this.groupKey,
    required this.groupLabel,
    required this.tasks,
    required this.isCollapsed,
    required this.projectsById,
    required this.labelsById,
    this.onTaskTap,
  });

  final String? groupKey;
  final String groupLabel;
  final List<Task> tasks;
  final bool isCollapsed;
  final Map<String, Project> projectsById;
  final Map<String, Label> labelsById;
  final void Function(String taskId)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupHeader(
          label: groupLabel,
          count: tasks.length,
          isCollapsed: isCollapsed,
          onToggle: () {
            // TODO: Dispatch event to SectionBloc
          },
        ),
        if (!isCollapsed)
          ...tasks.map((task) {
            final project = task.projectId != null 
                ? projectsById[task.projectId] 
                : null;
            
            return TaskTile(
              task: task,
              project: project,
              onTap: onTaskTap != null ? () => onTaskTap!(task.id) : null,
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.isCollapsed,
    required this.onToggle,
  });

  final String label;
  final int count;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isCollapsed ? Icons.chevron_right : Icons.expand_more,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            Text(
              '($count)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}
```

### Project List Renderer

**File**: `lib/presentation/widgets/sections/renderers/project_list_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/presentation/widgets/project_tile.dart'; // Reuse if exists

/// Renders a list of projects with optional nested tasks.
class ProjectListRenderer extends StatelessWidget {
  const ProjectListRenderer({
    required this.projects,
    required this.displaySettings,
    this.tasksByProjectId,
    this.labelsById,
    this.onProjectTap,
    this.onTaskTap,
    super.key,
  });

  final List<Project> projects;
  final Map<String, List<Task>>? tasksByProjectId;
  final Map<String, Label> labelsById;
  final SectionDisplaySettings displaySettings;
  final void Function(String projectId)? onProjectTap;
  final void Function(String taskId)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _buildEmptyState(context);
    }

    final relatedMode = displaySettings.relatedDisplayMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: projects.map((project) {
        final tasks = tasksByProjectId?[project.id] ?? [];
        
        return _ProjectItem(
          project: project,
          tasks: tasks,
          relatedMode: relatedMode,
          collapsedGroupIds: displaySettings.collapsedGroupIds,
          onProjectTap: onProjectTap,
          onTaskTap: onTaskTap,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No projects',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  const _ProjectItem({
    required this.project,
    required this.tasks,
    required this.relatedMode,
    required this.collapsedGroupIds,
    this.onProjectTap,
    this.onTaskTap,
  });

  final Project project;
  final List<Task> tasks;
  final RelatedDisplayMode relatedMode;
  final Set<String> collapsedGroupIds;
  final void Function(String projectId)? onProjectTap;
  final void Function(String taskId)? onTaskTap;

  bool get _isCollapsed => collapsedGroupIds.contains(project.id);

  @override
  Widget build(BuildContext context) {
    final showTasks = relatedMode != RelatedDisplayMode.hidden && tasks.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project tile
        ListTile(
          leading: Icon(
            Icons.folder,
            color: project.color != null 
                ? Color(project.color!) 
                : Theme.of(context).colorScheme.primary,
          ),
          title: Text(project.name),
          subtitle: tasks.isNotEmpty 
              ? Text('${tasks.length} tasks')
              : null,
          trailing: showTasks
              ? IconButton(
                  icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
                  onPressed: () {
                    // TODO: Toggle collapse
                  },
                )
              : null,
          onTap: onProjectTap != null ? () => onProjectTap!(project.id) : null,
        ),
        
        // Nested tasks (if mode is nested and not collapsed)
        if (showTasks && relatedMode == RelatedDisplayMode.nested && !_isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tasks.map((task) => ListTile(
                dense: true,
                leading: Checkbox(
                  value: task.completed,
                  onChanged: (_) {
                    // TODO: Toggle completion
                  },
                ),
                title: Text(
                  task.name,
                  style: task.completed
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                onTap: onTaskTap != null ? () => onTaskTap!(task.id) : null,
              )).toList(),
            ),
          ),
        
        const Divider(height: 1),
      ],
    );
  }
}
```

### Label List Renderer

**File**: `lib/presentation/widgets/sections/renderers/label_list_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';

/// Renders a list of labels with optional related tasks/projects.
class LabelListRenderer extends StatelessWidget {
  const LabelListRenderer({
    required this.labels,
    required this.displaySettings,
    this.tasksByLabelId,
    this.projectsByLabelId,
    this.onLabelTap,
    super.key,
  });

  final List<Label> labels;
  final Map<String, List<Task>>? tasksByLabelId;
  final Map<String, List<Project>>? projectsByLabelId;
  final SectionDisplaySettings displaySettings;
  final void Function(String labelId)? onLabelTap;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: labels.map((label) {
        final taskCount = tasksByLabelId?[label.id]?.length ?? 0;
        final projectCount = projectsByLabelId?[label.id]?.length ?? 0;
        
        return _LabelItem(
          label: label,
          taskCount: taskCount,
          projectCount: projectCount,
          onTap: onLabelTap,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No labels',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}

class _LabelItem extends StatelessWidget {
  const _LabelItem({
    required this.label,
    required this.taskCount,
    required this.projectCount,
    this.onTap,
  });

  final Label label;
  final int taskCount;
  final int projectCount;
  final void Function(String labelId)? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (taskCount > 0) subtitle.add('$taskCount tasks');
    if (projectCount > 0) subtitle.add('$projectCount projects');

    return ListTile(
      leading: Icon(
        label.type == LabelType.value ? Icons.star : Icons.label,
        color: label.color != null 
            ? Color(label.color!) 
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(label.name),
      subtitle: subtitle.isNotEmpty ? Text(subtitle.join(' • ')) : null,
      onTap: onTap != null ? () => onTap!(label.id) : null,
    );
  }
}
```

### Value Hierarchy Renderer

**File**: `lib/presentation/widgets/sections/renderers/value_hierarchy_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/models/screens/section_display_settings.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Renders the 3-level Value → Project → Task hierarchy.
class ValueHierarchyRenderer extends StatelessWidget {
  const ValueHierarchyRenderer({
    required this.hierarchies,
    required this.displaySettings,
    this.onTaskTap,
    this.onProjectTap,
    super.key,
  });

  final List<ValueHierarchyResult> hierarchies;
  final SectionDisplaySettings displaySettings;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;

  @override
  Widget build(BuildContext context) {
    if (hierarchies.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hierarchies.map((hierarchy) {
        return _ValueNode(
          hierarchy: hierarchy,
          displaySettings: displaySettings,
          onTaskTap: onTaskTap,
          onProjectTap: onProjectTap,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No values',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}

class _ValueNode extends StatelessWidget {
  const _ValueNode({
    required this.hierarchy,
    required this.displaySettings,
    this.onTaskTap,
    this.onProjectTap,
  });

  final ValueHierarchyResult hierarchy;
  final SectionDisplaySettings displaySettings;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;

  bool get _isCollapsed => 
      displaySettings.collapsedGroupIds.contains(hierarchy.value.id);

  int get _totalTasks {
    var count = hierarchy.directTasks.length;
    for (final p in hierarchy.projects) {
      count += p.allTasks.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final value = hierarchy.value;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Value header (level 1)
        ListTile(
          leading: Icon(
            Icons.star,
            color: value.color != null 
                ? Color(value.color!) 
                : Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            value.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text('$_totalTasks tasks'),
          trailing: IconButton(
            icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
            onPressed: () {
              // TODO: Toggle collapse
            },
          ),
        ),
        
        if (!_isCollapsed) ...[
          // Projects (level 2)
          ...hierarchy.projects.map((projectWithTasks) => Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _ProjectNode(
              projectWithTasks: projectWithTasks,
              displaySettings: displaySettings,
              onTaskTap: onTaskTap,
              onProjectTap: onProjectTap,
            ),
          )),
          
          // Direct tasks (no project)
          if (hierarchy.directTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                'Direct Tasks',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
            ...hierarchy.directTasks.map((task) => Padding(
              padding: const EdgeInsets.only(left: 48),
              child: _TaskTile(task: task, onTap: onTaskTap),
            )),
          ],
        ],
        
        const Divider(),
      ],
    );
  }
}

class _ProjectNode extends StatelessWidget {
  const _ProjectNode({
    required this.projectWithTasks,
    required this.displaySettings,
    this.onTaskTap,
    this.onProjectTap,
  });

  final ProjectWithTasks projectWithTasks;
  final SectionDisplaySettings displaySettings;
  final void Function(String taskId)? onTaskTap;
  final void Function(String projectId)? onProjectTap;

  bool get _isCollapsed => 
      displaySettings.collapsedGroupIds.contains(projectWithTasks.project.id);

  @override
  Widget build(BuildContext context) {
    final project = projectWithTasks.project;
    final allTasks = projectWithTasks.allTasks;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project header (level 2)
        ListTile(
          dense: true,
          leading: Icon(
            Icons.folder_outlined,
            color: project.color != null 
                ? Color(project.color!) 
                : Theme.of(context).colorScheme.secondary,
          ),
          title: Text(project.name),
          subtitle: Text('${allTasks.length} tasks'),
          trailing: allTasks.isNotEmpty
              ? IconButton(
                  icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
                  iconSize: 20,
                  onPressed: () {
                    // TODO: Toggle collapse
                  },
                )
              : null,
          onTap: onProjectTap != null 
              ? () => onProjectTap!(project.id) 
              : null,
        ),
        
        // Tasks (level 3)
        if (!_isCollapsed && allTasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Explicit tasks
                ...projectWithTasks.explicitTasks.map(
                  (task) => _TaskTile(
                    task: task, 
                    onTap: onTaskTap,
                    isInherited: false,
                  ),
                ),
                // Inherited tasks (visually differentiated)
                ...projectWithTasks.inheritedTasks.map(
                  (task) => _TaskTile(
                    task: task, 
                    onTap: onTaskTap,
                    isInherited: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    this.onTap,
    this.isInherited = false,
  });

  final Task task;
  final void Function(String taskId)? onTap;
  final bool isInherited;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) {
          // TODO: Toggle completion
        },
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          fontStyle: isInherited ? FontStyle.italic : null,
          color: isInherited 
              ? Theme.of(context).colorScheme.outline 
              : null,
        ),
      ),
      subtitle: isInherited 
          ? Text(
              'Inherited',
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
      onTap: onTap != null ? () => onTap!(task.id) : null,
    );
  }
}
```

---

## Task 4: Create Support Section Renderer

**File**: `lib/presentation/widgets/sections/support_section_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';

/// Renders support sections (banners, analytics, etc.)
class SupportSectionRenderer extends StatelessWidget {
  const SupportSectionRenderer({
    required this.config,
    required this.data,
    super.key,
  });

  final SupportBlockConfig config;
  final SectionData data;

  @override
  Widget build(BuildContext context) {
    if (data is! SupportSectionData) {
      return const SizedBox.shrink();
    }

    final supportData = (data as SupportSectionData).data;

    return switch (supportData) {
      ReviewBannerData(:final taskCount, :final oldestReviewDate) =>
        _ReviewBanner(taskCount: taskCount, oldestDate: oldestReviewDate),
      ProblemBannerData(:final problemDescriptions) =>
        _ProblemBanner(problems: problemDescriptions),
      AnalyticsBlockData(:final metrics) =>
        _AnalyticsCard(metrics: metrics),
    };
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.taskCount, this.oldestDate});

  final int taskCount;
  final DateTime? oldestDate;

  @override
  Widget build(BuildContext context) {
    if (taskCount == 0) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.rate_review,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$taskCount tasks need review',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.problems});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  '${problems.length} issues detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...problems.map((p) => Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                '• $p',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.metrics});

  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...metrics.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
```

---

## Task 5: Create Navigation & Allocation Renderers

**File**: `lib/presentation/widgets/sections/navigation_section_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';

/// Renders navigation sections (Settings menu style)
class NavigationSectionRenderer extends StatelessWidget {
  const NavigationSectionRenderer({
    required this.items,
    required this.data,
    this.groupTitle,
    super.key,
  });

  final List<NavigationItem> items;
  final String? groupTitle;
  final SectionData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (groupTitle != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              groupTitle!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
        ...items.map((item) => _NavigationTile(item: item)),
      ],
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.item});

  final NavigationItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: item.iconName != null
          ? Icon(_resolveIcon(item.iconName!))
          : null,
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(item.route),
    );
  }

  IconData _resolveIcon(String iconName) {
    // Map string names to IconData
    // This is a simplified version - could use a more complete mapping
    return switch (iconName) {
      'palette' => Icons.palette,
      'language' => Icons.language,
      'tune' => Icons.tune,
      'build' => Icons.build,
      'person' => Icons.person,
      'settings' => Icons.settings,
      'notifications' => Icons.notifications,
      'security' => Icons.security,
      'help' => Icons.help,
      _ => Icons.arrow_forward,
    };
  }
}
```

**File**: `lib/presentation/widgets/sections/allocation_section_renderer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Renders allocation sections (Next Actions)
class AllocationSectionRenderer extends StatelessWidget {
  const AllocationSectionRenderer({
    required this.maxTasks,
    required this.data,
    this.onTaskTap,
    super.key,
  });

  final int maxTasks;
  final SectionData data;
  final void Function(String taskId)? onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (data is! AllocationSectionData) {
      return const SizedBox.shrink();
    }

    final tasks = (data as AllocationSectionData).allocatedTasks;

    if (tasks.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, tasks.length),
        ...tasks.asMap().entries.map((entry) => _AllocationTaskTile(
          index: entry.key + 1,
          task: entry.value,
          onTap: onTaskTap,
        )),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Your Next $count Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks allocated for now',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationTaskTile extends StatelessWidget {
  const _AllocationTaskTile({
    required this.index,
    required this.task,
    this.onTap,
  });

  final int index;
  final Task task;
  final void Function(String taskId)? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$index',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(task.name),
        subtitle: task.projectId != null 
            ? const Text('In project') // TODO: Resolve project name
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            // TODO: Complete task
          },
        ),
        onTap: onTap != null ? () => onTap!(task.id) : null,
      ),
    );
  }
}
```

---

## Task 6: Update ScreenHostPage

**File**: `lib/presentation/features/screens/view/screen_host_page.dart`

**Replace the giant switch statement** with section-based rendering:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_definition_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/section_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/sections/section_renderer.dart';

/// Hosts a screen definition and renders its sections.
class ScreenHostPage extends StatelessWidget {
  const ScreenHostPage({
    required this.screenId,
    this.parentEntityId,
    super.key,
  });

  final String screenId;
  final String? parentEntityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('screen_def_bloc_$screenId'),
      create: (_) => ScreenDefinitionBloc(
        repository: getIt<ScreenDefinitionsRepositoryContract>(),
      )..add(ScreenDefinitionEvent.subscriptionRequested(screenKey: screenId)),
      child: BlocBuilder<ScreenDefinitionBloc, ScreenDefinitionState>(
        builder: (context, state) {
          return state.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            notFound: () => Scaffold(
              appBar: AppBar(title: const Text('Not Found')),
              body: Center(child: Text('Screen not found: $screenId')),
            ),
            error: (error, _) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('Error: $error')),
            ),
            loaded: (screen) => _ScreenContent(
              screen: screen,
              parentEntityId: parentEntityId,
            ),
          );
        },
      ),
    );
  }
}

class _ScreenContent extends StatelessWidget {
  const _ScreenContent({
    required this.screen,
    this.parentEntityId,
  });

  final ScreenDefinition screen;
  final String? parentEntityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('section_bloc_${screen.id}'),
      create: (_) => getIt<SectionBloc>()
        ..add(SectionBlocEvent.started(
          screen: screen,
          parentEntityId: parentEntityId,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: Text(screen.name),
          actions: [
            // TODO: Add screen-specific actions
          ],
        ),
        body: BlocBuilder<SectionBloc, SectionBlocState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (screen, sections, parentId) => _buildSections(
                context,
                sections,
              ),
              partiallyLoaded: (screen, sections, errors, parentId) => 
                _buildSections(context, sections, errors: errors),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    List<LoadedSection> sections, {
    List<SectionError>? errors,
  }) {
    if (sections.isEmpty && (errors == null || errors.isEmpty)) {
      return const Center(child: Text('No content'));
    }

    return SectionsListView(
      sections: sections,
      onTaskTap: (taskId) => context.goNamed(
        AppRouteName.taskDetail,
        pathParameters: {'id': taskId},
      ),
      onProjectTap: (projectId) => context.goNamed(
        AppRouteName.projectDetail,
        pathParameters: {'id': projectId},
      ),
      onLabelTap: (labelId) => context.goNamed(
        AppRouteName.labelDetail,
        pathParameters: {'id': labelId},
      ),
    );
  }
}
```

---

## Task 7: Create Barrel Exports

**File**: `lib/presentation/widgets/sections/sections.dart`

```dart
export 'section_renderer.dart';
export 'data_section_renderer.dart';
export 'support_section_renderer.dart';
export 'navigation_section_renderer.dart';
export 'allocation_section_renderer.dart';
export 'renderers/task_list_renderer.dart';
export 'renderers/project_list_renderer.dart';
export 'renderers/label_list_renderer.dart';
export 'renderers/value_hierarchy_renderer.dart';
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] All renderer widgets compile
3. [ ] ScreenHostPage compiles with new structure
4. [ ] App launches without errors
5. [ ] Navigate to a system screen - verify it renders

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/presentation/widgets/sections/section_renderer.dart` | Main dispatcher |
| `lib/presentation/widgets/sections/data_section_renderer.dart` | Data section handler |
| `lib/presentation/widgets/sections/support_section_renderer.dart` | Support blocks |
| `lib/presentation/widgets/sections/navigation_section_renderer.dart` | Settings menu |
| `lib/presentation/widgets/sections/allocation_section_renderer.dart` | Next Actions |
| `lib/presentation/widgets/sections/renderers/task_list_renderer.dart` | Task lists |
| `lib/presentation/widgets/sections/renderers/project_list_renderer.dart` | Project lists |
| `lib/presentation/widgets/sections/renderers/label_list_renderer.dart` | Label lists |
| `lib/presentation/widgets/sections/renderers/value_hierarchy_renderer.dart` | 3-level tree |
| `lib/presentation/widgets/sections/sections.dart` | Barrel export |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/presentation/features/screens/view/screen_host_page.dart` | Complete rewrite |

---

## Integration Notes

### Reuse Existing Widgets
Before creating new widgets, check for existing ones:
- `TaskTile` - may exist in `lib/presentation/widgets/`
- `ProjectTile` - may exist
- `LabelTile` - may exist

Reuse these in the renderers rather than recreating.

### Navigation
Uses existing `go_router` routes. Verify route names match:
- `AppRouteName.taskDetail`
- `AppRouteName.projectDetail`
- `AppRouteName.labelDetail`

### TODO Items
Several TODOs are acceptable to leave for later:
- Toggle collapse (needs BLoC event dispatch)
- Complete task (needs TaskRepository)
- Resolve project names in allocation view

---

## Next Phase
Proceed to **Phase 4: Workflow Integration** after all validation passes.
