# Phase 2: UnifiedScreenPage

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Create the single page widget that renders ALL screens (system and user-created) through a unified path.

**Design Decisions Implemented**:
- D4: Widget routes directly via `EntityNavigator`
- D7: Edit action handled by widget directly

---

## Prerequisites

- Phase 0 complete (domain services exist)
- Phase 1 complete (thin `ScreenBloc` exists)
- Existing `SectionWidget` at `lib/presentation/features/screens/widgets/`

---

## Task 2.1: Create EntityNavigator

**File**: `lib/presentation/features/navigation/services/entity_navigator.dart`

This service handles navigation to entity detail pages.

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';

/// Service for navigating to entity detail pages.
///
/// Used by widgets to navigate without coupling to routing implementation.
class EntityNavigator {
  const EntityNavigator();

  /// Navigate to task detail page.
  void navigateToTask(BuildContext context, String taskId) {
    talker.serviceLog('EntityNavigator', 'navigateToTask: $taskId');
    context.push('${AppRoutePath.taskDetail}/$taskId');
  }

  /// Navigate to project detail page.
  void navigateToProject(BuildContext context, String projectId) {
    talker.serviceLog('EntityNavigator', 'navigateToProject: $projectId');
    context.push('${AppRoutePath.projectDetail}/$projectId');
  }

  /// Navigate to label detail page.
  void navigateToLabel(BuildContext context, String labelId) {
    talker.serviceLog('EntityNavigator', 'navigateToLabel: $labelId');
    context.push('${AppRoutePath.labelDetail}/$labelId');
  }

  /// Navigate to entity by type.
  void navigateToEntity(
    BuildContext context, {
    required String entityId,
    required String entityType,
  }) {
    talker.serviceLog(
      'EntityNavigator',
      'navigateToEntity: $entityType/$entityId',
    );

    switch (entityType) {
      case 'task':
        navigateToTask(context, entityId);
      case 'project':
        navigateToProject(context, entityId);
      case 'label':
        navigateToLabel(context, entityId);
      default:
        talker.warning('EntityNavigator: Unknown entity type: $entityType');
    }
  }
}
```

---

## Task 2.2: Create UnifiedScreenPage

**File**: `lib/presentation/features/screens/view/unified_screen_page.dart`

The single page that renders all screens.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/entity_navigator.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/screens/widgets/section_list_widget.dart';

/// Unified page for rendering all screen types.
///
/// This is the single rendering path for both system screens (Inbox, Today)
/// and user-created screens via ScreenBuilder.
class UnifiedScreenPage extends StatelessWidget {
  const UnifiedScreenPage({
    required this.definition,
    super.key,
  });

  /// The screen definition to render.
  final ScreenDefinition definition;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: const _UnifiedScreenView(),
    );
  }
}

/// Alternative constructor for loading by screen ID.
class UnifiedScreenPageById extends StatelessWidget {
  const UnifiedScreenPageById({
    required this.screenId,
    super.key,
  });

  final String screenId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.loadById(screenId: screenId)),
      child: const _UnifiedScreenView(),
    );
  }
}

class _UnifiedScreenView extends StatelessWidget {
  const _UnifiedScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenBloc, ScreenState>(
      builder: (context, state) {
        return switch (state) {
          ScreenInitialState() => const _LoadingView(),
          ScreenLoadingState() => _LoadingView(
              title: state.definition?.name,
            ),
          ScreenLoadedState(:final data, :final isRefreshing) =>
            _LoadedView(data: data, isRefreshing: isRefreshing),
          ScreenErrorState(:final message, :final definition) =>
            _ErrorView(message: message, definition: definition),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Loading...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.data,
    required this.isRefreshing,
  });

  final ScreenData data;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final entityNavigator = const EntityNavigator();
    final entityActionService = getIt<EntityActionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(data.definition.name),
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<ScreenBloc>().add(const ScreenEvent.refresh());
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ScreenBloc>().add(const ScreenEvent.refresh());
          // Wait a bit for the refresh to complete
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: _ScreenContent(
          data: data,
          entityNavigator: entityNavigator,
          entityActionService: entityActionService,
        ),
      ),
    );
  }
}

class _ScreenContent extends StatelessWidget {
  const _ScreenContent({
    required this.data,
    required this.entityNavigator,
    required this.entityActionService,
  });

  final ScreenData data;
  final EntityNavigator entityNavigator;
  final EntityActionService entityActionService;

  @override
  Widget build(BuildContext context) {
    if (data.sections.isEmpty) {
      return const Center(
        child: Text('No sections configured'),
      );
    }

    return ListView.builder(
      itemCount: data.sections.length,
      itemBuilder: (context, index) {
        final section = data.sections[index];

        if (section.error != null) {
          return _SectionErrorWidget(
            title: section.title,
            error: section.error!,
          );
        }

        return SectionListWidget(
          title: section.title,
          result: section.result,
          onEntityTap: (entityId, entityType) {
            entityNavigator.navigateToEntity(
              context,
              entityId: entityId,
              entityType: entityType,
            );
          },
          onEntityAction: (entityId, entityType, action, params) async {
            await entityActionService.performAction(
              entityId: entityId,
              entityType: entityType,
              action: action,
              params: params,
            );
          },
        );
      },
    );
  }
}

class _SectionErrorWidget extends StatelessWidget {
  const _SectionErrorWidget({
    required this.title,
    required this.error,
  });

  final String? title;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    this.definition,
  });

  final String message;
  final ScreenDefinition? definition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(definition?.name ?? 'Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ScreenBloc>().add(const ScreenEvent.refresh());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Task 2.3: Create SectionListWidget

**File**: `lib/presentation/features/screens/widgets/section_list_widget.dart`

Widget that renders a section's data. This may already exist - check and extend if needed.

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

/// Callback for entity tap.
typedef EntityTapCallback = void Function(String entityId, String entityType);

/// Callback for entity action.
typedef EntityActionCallback = Future<void> Function(
  String entityId,
  String entityType,
  EntityActionType action,
  Map<String, dynamic>? params,
);

/// Widget that renders a section's data.
class SectionListWidget extends StatelessWidget {
  const SectionListWidget({
    required this.result,
    required this.onEntityTap,
    required this.onEntityAction,
    this.title,
    super.key,
  });

  final String? title;
  final SectionDataResult result;
  final EntityTapCallback onEntityTap;
  final EntityActionCallback onEntityAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        switch (result) {
          DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
            _DataSectionContent(
              entities: primaryEntities,
              entityType: primaryEntityType,
              onEntityTap: onEntityTap,
              onEntityAction: onEntityAction,
            ),
          AllocationSectionResult(:final allocatedTasks) =>
            _AllocationSectionContent(
              tasks: allocatedTasks,
              onEntityTap: onEntityTap,
              onEntityAction: onEntityAction,
            ),
          AgendaSectionResult(:final groupedTasks, :final groupOrder) =>
            _AgendaSectionContent(
              groupedTasks: groupedTasks,
              groupOrder: groupOrder,
              onEntityTap: onEntityTap,
              onEntityAction: onEntityAction,
            ),
        },
      ],
    );
  }
}

class _DataSectionContent extends StatelessWidget {
  const _DataSectionContent({
    required this.entities,
    required this.entityType,
    required this.onEntityTap,
    required this.onEntityAction,
  });

  final List<dynamic> entities;
  final String entityType;
  final EntityTapCallback onEntityTap;
  final EntityActionCallback onEntityAction;

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No items'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        return _EntityTile(
          entity: entity,
          entityType: entityType,
          onTap: onEntityTap,
          onAction: onEntityAction,
        );
      },
    );
  }
}

class _AllocationSectionContent extends StatelessWidget {
  const _AllocationSectionContent({
    required this.tasks,
    required this.onEntityTap,
    required this.onEntityAction,
  });

  final List<Task> tasks;
  final EntityTapCallback onEntityTap;
  final EntityActionCallback onEntityAction;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks allocated'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _EntityTile(
          entity: task,
          entityType: 'task',
          onTap: onEntityTap,
          onAction: onEntityAction,
        );
      },
    );
  }
}

class _AgendaSectionContent extends StatelessWidget {
  const _AgendaSectionContent({
    required this.groupedTasks,
    required this.groupOrder,
    required this.onEntityTap,
    required this.onEntityAction,
  });

  final Map<String, List<Task>> groupedTasks;
  final List<String> groupOrder;
  final EntityTapCallback onEntityTap;
  final EntityActionCallback onEntityAction;

  @override
  Widget build(BuildContext context) {
    if (groupedTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupOrder.map((groupKey) {
        final tasks = groupedTasks[groupKey] ?? [];
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                groupKey,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...tasks.map((task) => _EntityTile(
              entity: task,
              entityType: 'task',
              onTap: onEntityTap,
              onAction: onEntityAction,
            )),
          ],
        );
      }).toList(),
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({
    required this.entity,
    required this.entityType,
    required this.onTap,
    required this.onAction,
  });

  final dynamic entity;
  final String entityType;
  final EntityTapCallback onTap;
  final EntityActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    // Render based on entity type
    return switch (entity) {
      Task task => _TaskTile(
          task: task,
          onTap: () => onTap(task.id, 'task'),
          onComplete: () => onAction(
            task.id,
            'task',
            task.completed
                ? EntityActionType.uncomplete
                : EntityActionType.complete,
            null,
          ),
        ),
      Project project => _ProjectTile(
          project: project,
          onTap: () => onTap(project.id, 'project'),
        ),
      _ => ListTile(
          title: Text('Unknown entity: $entityType'),
        ),
    };
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(
          task.completed
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: task.completed
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        onPressed: onComplete,
      ),
      title: Text(
        task.name,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: task.project != null
          ? Text(task.project!.name)
          : null,
      onTap: onTap,
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onTap,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.folder,
        color: project.color != null
            ? Color(int.parse(project.color!.replaceFirst('#', '0xFF')))
            : null,
      ),
      title: Text(project.name),
      trailing: project.completed
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: onTap,
    );
  }
}
```

---

## Task 2.4: Update View Exports

**File**: `lib/presentation/features/screens/screens.dart`

Add the new exports:

```dart
export 'bloc/bloc.dart';
export 'view/screen_creator_page.dart';
export 'view/screen_host_page.dart';
export 'view/screen_management_page.dart';
export 'view/unified_screen_page.dart';
export 'widgets/section_list_widget.dart';
```

---

## Task 2.5: Register Services in DI

**File**: `lib/core/dependency_injection/dependency_injection.dart`

Add registration for new services (check existing patterns):

```dart
// In the appropriate registration section:

// Screen services
getIt.registerLazySingleton<ScreenDataInterpreter>(
  () => ScreenDataInterpreter(
    sectionDataService: getIt(),
    supportBlockComputer: getIt(),
  ),
);

getIt.registerLazySingleton<EntityActionService>(
  () => EntityActionService(
    taskRepository: getIt(),
    projectRepository: getIt(),
  ),
);
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `UnifiedScreenPage` compiles without errors
- [ ] `SectionListWidget` compiles without errors
- [ ] `EntityNavigator` compiles without errors
- [ ] DI registration compiles
- [ ] Can instantiate `UnifiedScreenPage` with a definition

---

## Files Created

| File | Purpose | LOC |
|------|---------|-----|
| `lib/presentation/features/navigation/services/entity_navigator.dart` | Navigation helper | ~50 |
| `lib/presentation/features/screens/view/unified_screen_page.dart` | Unified rendering | ~250 |
| `lib/presentation/features/screens/widgets/section_list_widget.dart` | Section rendering | ~250 |

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/screens/screens.dart` | Add new exports |
| `lib/core/dependency_injection/dependency_injection.dart` | Register services |

---

## Next Phase

Proceed to **Phase 3: Router Integration** after validation passes.
