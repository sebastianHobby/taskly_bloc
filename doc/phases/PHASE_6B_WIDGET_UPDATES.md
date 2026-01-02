# Phase 6B: Widget Updates

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Update entity widgets to use default onTap navigation from EntityNavigator.

**Decisions Implemented**: DR-007 (Default onTap navigation)

---

## Prerequisites

- Phase 6A complete (EntityNavigator exists)

---

## Task 1: Update TaskListItem Widget

**File**: `lib/presentation/widgets/task_list_item.dart` (or similar)

Add default navigation if not already present:

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final bool showProject;
  final bool showLabels;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap, // Optional - uses default navigation if null
    this.onComplete,
    this.showProject = true,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: _buildSubtitle(context),
      leading: _buildCheckbox(context),
      trailing: _buildTrailing(context),
      onTap: onTap ?? () => EntityNavigator.toTask(context, task.id),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    // Existing subtitle implementation
    return null;
  }

  Widget _buildCheckbox(BuildContext context) {
    return Checkbox(
      value: task.isCompleted,
      onChanged: (_) => onComplete?.call(),
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    // Existing trailing implementation
    return null;
  }
}
```

---

## Task 2: Update ProjectListItem Widget

**File**: `lib/presentation/widgets/project_list_item.dart` (or similar)

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';

class ProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final int? taskCount;

  const ProjectListItem({
    super.key,
    required this.project,
    this.onTap, // Optional - uses default navigation if null
    this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(context),
      title: Text(project.name),
      subtitle: project.description != null 
          ? Text(project.description!) 
          : null,
      trailing: taskCount != null 
          ? Text('$taskCount tasks')
          : null,
      onTap: onTap ?? () => EntityNavigator.toProject(context, project.id),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final color = project.color != null
        ? Color(int.parse(project.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      backgroundColor: color,
      radius: 16,
      child: Text(
        project.name.isNotEmpty ? project.name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
```

---

## Task 3: Update LabelChip Widget

**File**: `lib/presentation/widgets/label_chip.dart` (or similar)

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';

class LabelChip extends StatelessWidget {
  final Label label;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const LabelChip({
    super.key,
    required this.label,
    this.onTap, // Optional - uses default navigation if null
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = label.color != null
        ? Color(int.parse(label.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.secondary;

    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
      label: Text(label.name),
      onPressed: onTap ?? () => _navigate(context),
    );
  }

  void _navigate(BuildContext context) {
    if (label.type == LabelType.value) {
      EntityNavigator.toValue(context, label.id);
    } else {
      EntityNavigator.toLabel(context, label.id);
    }
  }
}
```

---

## Task 4: Create Generic EntityCard Widget

**File**: `lib/presentation/widgets/entity_card.dart`

A reusable card for any entity type:

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';
import 'package:taskly_bloc/presentation/widgets/entity_tap_handler.dart';

/// Generic card widget for displaying any entity type
class EntityCard extends StatelessWidget with EntityTapHandler {
  final String entityId;
  final String entityType;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const EntityCard({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: buildTapCallback(
          context,
          entityId: entityId,
          entityType: entityType,
          customOnTap: onTap,
        ),
      ),
    );
  }
}
```

---

## Task 5: Create SectionWidget

**File**: `lib/presentation/widgets/section_widget.dart`

Widget for rendering a section from ScreenBloc state:

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/widgets/task_list_item.dart';
import 'package:taskly_bloc/presentation/widgets/project_list_item.dart';
import 'package:taskly_bloc/presentation/widgets/label_chip.dart';

/// Widget that renders a section from screen data
class SectionWidget extends StatelessWidget {
  final SectionData section;
  final Function(String entityId, String entityType)? onEntityTap;
  final Function(String taskId)? onTaskComplete;

  const SectionWidget({
    super.key,
    required this.section,
    this.onEntityTap,
    this.onTaskComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) _buildHeader(context),
        if (section.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (section.error != null)
          _buildError(context)
        else
          _buildContent(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        section.title!,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Error: ${section.error}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return switch (section.data) {
      DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
          _buildDataSection(context, primaryEntities, primaryEntityType),
      AllocationSectionResult(:final allocatedTasks) =>
          _buildTaskList(context, allocatedTasks),
      AgendaSectionResult(:final groupedTasks, :final groupOrder) =>
          _buildAgendaSection(context, groupedTasks, groupOrder),
    };
  }

  Widget _buildDataSection(
    BuildContext context,
    List<dynamic> entities,
    String entityType,
  ) {
    return switch (entityType) {
      'task' => _buildTaskList(context, entities.cast<Task>()),
      'project' => _buildProjectList(context, entities.cast<Project>()),
      'label' || 'value' => _buildLabelList(context, entities.cast<Label>()),
      _ => const Text('Unknown entity type'),
    };
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskListItem(
          task: task,
          onTap: onEntityTap != null
              ? () => onEntityTap!(task.id, 'task')
              : null,
          onComplete: onTaskComplete != null
              ? () => onTaskComplete!(task.id)
              : null,
        );
      },
    );
  }

  Widget _buildProjectList(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No projects'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectListItem(
          project: project,
          onTap: onEntityTap != null
              ? () => onEntityTap!(project.id, 'project')
              : null,
        );
      },
    );
  }

  Widget _buildLabelList(BuildContext context, List<Label> labels) {
    if (labels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No labels'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: labels.map((label) {
          return LabelChip(
            label: label,
            onTap: onEntityTap != null
                ? () => onEntityTap!(label.id, label.type == LabelType.value ? 'value' : 'label')
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAgendaSection(
    BuildContext context,
    Map<String, List<Task>> groupedTasks,
    List<String> groupOrder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupOrder.map((group) {
        final tasks = groupedTasks[group] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _buildTaskList(context, tasks),
          ],
        );
      }).toList(),
    );
  }
}
```

---

## Task 6: Update Widgets Barrel Export

**File**: `lib/presentation/widgets/widgets.dart`

Add new exports:

```dart
export 'entity_card.dart';
export 'entity_tap_handler.dart';
export 'section_widget.dart';
// ... existing exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `TaskListItem` has default onTap navigation
- [ ] `ProjectListItem` has default onTap navigation
- [ ] `LabelChip` has default onTap navigation
- [ ] `EntityCard` uses EntityTapHandler mixin
- [ ] `SectionWidget` renders all section types

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/presentation/widgets/entity_card.dart` | Generic entity card |
| `lib/presentation/widgets/section_widget.dart` | Section renderer |

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/widgets/task_list_item.dart` | Add default navigation |
| `lib/presentation/widgets/project_list_item.dart` | Add default navigation |
| `lib/presentation/widgets/label_chip.dart` | Add default navigation |
| `lib/presentation/widgets/widgets.dart` | Add new exports |

---

## Next Phase

Proceed to **Phase 7A: Workflow Model Update** after validation passes.
