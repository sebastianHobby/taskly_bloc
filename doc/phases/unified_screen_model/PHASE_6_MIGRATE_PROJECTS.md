# Phase 6: Migrate Project Screens

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Migrate project detail screens to use `UnifiedScreenPage`. These screens are dynamic (per-project) and need special handling.

---

## Prerequisites

- Phase 5 complete (simple list screens migrated)
- Understanding of current project detail page structure

---

## Task 6.1: Create ProjectScreenDefinition Factory

**File**: `lib/domain/models/screens/system_screen_definitions.dart`

Add a factory method to create project-specific screen definitions:

```dart
/// Create a screen definition for a specific project
static ScreenDefinition forProject({
  required String projectId,
  required String projectName,
  String? projectColor,
}) {
  return ScreenDefinition(
    id: 'project_$projectId',
    screenKey: 'project_detail',
    name: projectName,
    screenType: ScreenType.list,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isSystem: false, // Dynamic, not a fixed system screen
    iconName: 'folder',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig(
          entityType: EntityType.task,
          filter: TaskQuery(
            predicates: [
              TaskPredicate.inProject(projectId),
              const TaskPredicate.isCompleted(false),
            ],
          ),
        ),
        title: 'Tasks',
      ),
      Section.data(
        config: DataConfig(
          entityType: EntityType.task,
          filter: TaskQuery(
            predicates: [
              TaskPredicate.inProject(projectId),
              const TaskPredicate.isCompleted(true),
            ],
          ),
        ),
        title: 'Completed',
      ),
    ],
  );
}
```

---

## Task 6.2: Create ProjectDetailUnifiedPage

**File**: `lib/presentation/features/projects/view/project_detail_unified_page.dart`

Create a wrapper that fetches the project first, then creates the definition:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_event.dart';
import 'package:taskly_bloc/presentation/features/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/features/screens/view/unified_screen_page.dart';

/// Project detail page using unified screen model.
///
/// Fetches the project first to get its name and color,
/// then creates a dynamic screen definition.
class ProjectDetailUnifiedPage extends StatefulWidget {
  const ProjectDetailUnifiedPage({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  State<ProjectDetailUnifiedPage> createState() =>
      _ProjectDetailUnifiedPageState();
}

class _ProjectDetailUnifiedPageState extends State<ProjectDetailUnifiedPage> {
  Project? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final repository = getIt<ProjectRepositoryContract>();
      final project = await repository.getById(widget.projectId);
      
      if (mounted) {
        setState(() {
          _project = project;
          _isLoading = false;
          if (project == null) {
            _error = 'Project not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load project: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(_error ?? 'Unknown error'),
        ),
      );
    }

    final definition = SystemScreenDefinitions.forProject(
      projectId: widget.projectId,
      projectName: _project!.name,
      projectColor: _project!.color,
    );

    return _ProjectScreenWithActions(
      definition: definition,
      project: _project!,
    );
  }
}

/// Wrapper that adds project-specific actions to the app bar.
class _ProjectScreenWithActions extends StatelessWidget {
  const _ProjectScreenWithActions({
    required this.definition,
    required this.project,
  });

  final ScreenDefinition definition;
  final Project project;

  @override
  Widget build(BuildContext context) {
    final entityActionService = getIt<EntityActionService>();

    return BlocProvider(
      create: (context) => ScreenBloc(
        screenRepository: getIt(),
        interpreter: getIt<ScreenDataInterpreter>(),
      )..add(ScreenEvent.load(definition: definition)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          actions: [
            // Complete/uncomplete project action
            IconButton(
              icon: Icon(
                project.completed ? Icons.undo : Icons.check,
              ),
              tooltip: project.completed ? 'Reopen' : 'Complete',
              onPressed: () async {
                if (project.completed) {
                  await entityActionService.uncompleteProject(project.id);
                } else {
                  await entityActionService.completeProject(project.id);
                }
              },
            ),
            // More actions menu
            PopupMenuButton<String>(
              onSelected: (action) async {
                switch (action) {
                  case 'edit':
                    // Navigate to edit page
                    // context.push('/projects/${project.id}/edit');
                    break;
                  case 'delete':
                    await entityActionService.deleteProject(project.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<ScreenBloc, ScreenState>(
          builder: (context, state) {
            return switch (state) {
              ScreenInitialState() ||
              ScreenLoadingState() =>
                const Center(child: CircularProgressIndicator()),
              ScreenLoadedState(:final data) => _ProjectContent(data: data),
              ScreenErrorState(:final message) => Center(child: Text(message)),
            };
          },
        ),
      ),
    );
  }
}

class _ProjectContent extends StatelessWidget {
  const _ProjectContent({required this.data});

  final ScreenData data;

  @override
  Widget build(BuildContext context) {
    // Reuse the content builder from UnifiedScreenPage
    // This is a simplified version - integrate with SectionListWidget
    return ListView.builder(
      itemCount: data.sections.length,
      itemBuilder: (context, index) {
        final section = data.sections[index];
        return SectionListWidget(
          title: section.title,
          result: section.result,
          onEntityTap: (entityId, entityType) {
            // Navigate to entity
            const EntityNavigator().navigateToEntity(
              context,
              entityId: entityId,
              entityType: entityType,
            );
          },
          onEntityAction: (entityId, entityType, action, params) async {
            await getIt<EntityActionService>().performAction(
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
```

---

## Task 6.3: Update Project Detail Route

**File**: `lib/core/routing/router.dart`

Update the project detail route to use the new unified page:

```dart
GoRoute(
  name: AppRouteName.projectDetail,
  path: '${AppRoutePath.projectDetail}/:projectId',
  builder: (context, state) {
    final projectId = state.pathParameters['projectId']!;
    return ProjectDetailUnifiedPage(projectId: projectId);
  },
),
```

---

## Task 6.4: Mark Legacy ProjectDetailPage Deprecated

**File**: `lib/presentation/features/projects/view/project_detail_page.dart`

```dart
@Deprecated('Use ProjectDetailUnifiedPage instead')
class ProjectDetailPage extends StatelessWidget { ... }
```

---

## Task 6.5: Functional Testing

- [ ] Navigate to a project from projects list
- [ ] Project name shows in app bar
- [ ] Tasks for the project appear
- [ ] Completed tasks appear in separate section
- [ ] Complete project action works
- [ ] Delete project action works
- [ ] Tapping a task navigates to task detail
- [ ] Completing a task works

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `ProjectDetailUnifiedPage` compiles
- [ ] `forProject()` factory method works
- [ ] Route updated
- [ ] Legacy page deprecated
- [ ] All project features work

---

## Files Created

| File | Purpose | LOC |
|------|---------|-----|
| `lib/presentation/features/projects/view/project_detail_unified_page.dart` | Project detail via unified model | ~180 |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/system_screen_definitions.dart` | Add forProject() factory |
| `lib/core/routing/router.dart` | Update project detail route |
| `lib/presentation/features/projects/view/project_detail_page.dart` | Add @Deprecated |

---

## Next Phase

Proceed to **Phase 7: Migrate Allocation Screens** after functional testing passes.
