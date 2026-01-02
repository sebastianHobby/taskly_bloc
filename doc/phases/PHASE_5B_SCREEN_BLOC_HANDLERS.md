# Phase 5B: Unified ScreenBloc - Handlers

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Implement all event handlers in `ScreenBloc` and delete legacy `ViewBloc`.

**Decisions Implemented**: DR-017 (Unified Screen Model), Clean Slate

---

## Prerequisites

- Phase 5A complete (ScreenBloc shell exists)

---

## Task 1: Implement _onLoad Handler

**File**: `lib/presentation/features/screens/bloc/screen_bloc.dart`

```dart
Future<void> _onLoad(
  ScreenLoadEvent event,
  Emitter<ScreenState> emit,
) async {
  emit(ScreenState.loading(definition: event.definition));

  try {
    final sectionsData = await _fetchAllSections(event.definition);
    final supportBlocksData = _computeSupportBlocks(
      event.definition,
      sectionsData,
    );

    emit(ScreenState.loaded(
      definition: event.definition,
      sections: sectionsData,
      supportBlocks: supportBlocksData,
    ));
  } catch (e, stackTrace) {
    emit(ScreenState.error(
      message: 'Failed to load screen: ${e.toString()}',
      definition: event.definition,
      error: e,
      stackTrace: stackTrace,
    ));
  }
}
```

---

## Task 2: Implement _onLoadById Handler

```dart
Future<void> _onLoadById(
  ScreenLoadByIdEvent event,
  Emitter<ScreenState> emit,
) async {
  emit(const ScreenState.loading());

  try {
    final definition = await _screenRepository.getScreenById(event.screenId);
    if (definition == null) {
      emit(ScreenState.error(
        message: 'Screen not found: ${event.screenId}',
      ));
      return;
    }

    add(ScreenEvent.load(definition: definition));
  } catch (e, stackTrace) {
    emit(ScreenState.error(
      message: 'Failed to load screen: ${e.toString()}',
      error: e,
      stackTrace: stackTrace,
    ));
  }
}
```

---

## Task 3: Implement _onRefresh Handler

```dart
Future<void> _onRefresh(
  ScreenRefreshEvent event,
  Emitter<ScreenState> emit,
) async {
  final currentState = state;
  if (currentState is! ScreenLoadedState) return;

  emit(currentState.copyWith(isRefreshing: true));

  try {
    final sectionsData = await _fetchAllSections(currentState.definition);
    final supportBlocksData = _computeSupportBlocks(
      currentState.definition,
      sectionsData,
    );

    emit(ScreenState.loaded(
      definition: currentState.definition,
      sections: sectionsData,
      supportBlocks: supportBlocksData,
      isRefreshing: false,
    ));
  } catch (e, stackTrace) {
    emit(ScreenState.error(
      message: 'Failed to refresh: ${e.toString()}',
      definition: currentState.definition,
      error: e,
      stackTrace: stackTrace,
    ));
  }
}
```

---

## Task 4: Implement _onRefreshSection Handler

```dart
Future<void> _onRefreshSection(
  ScreenRefreshSectionEvent event,
  Emitter<ScreenState> emit,
) async {
  final currentState = state;
  if (currentState is! ScreenLoadedState) return;

  final sectionIndex = event.sectionIndex;
  if (sectionIndex < 0 || sectionIndex >= currentState.sections.length) return;

  // Mark section as loading
  final updatedSections = currentState.sections.toList();
  updatedSections[sectionIndex] = updatedSections[sectionIndex].copyWith(
    isLoading: true,
  );
  emit(currentState.copyWith(sections: updatedSections));

  try {
    final section = currentState.definition.sections[sectionIndex];
    final sectionData = await _sectionDataService.fetchSectionData(section);

    updatedSections[sectionIndex] = SectionData(
      index: sectionIndex,
      title: section.title,
      data: sectionData,
      isLoading: false,
    );

    // Recompute support blocks with new data
    final supportBlocksData = _computeSupportBlocks(
      currentState.definition,
      updatedSections,
    );

    emit(currentState.copyWith(
      sections: updatedSections,
      supportBlocks: supportBlocksData,
    ));
  } catch (e) {
    updatedSections[sectionIndex] = updatedSections[sectionIndex].copyWith(
      isLoading: false,
      error: e.toString(),
    );
    emit(currentState.copyWith(sections: updatedSections));
  }
}
```

---

## Task 5: Implement _onEntityAction Handler

```dart
Future<void> _onEntityAction(
  ScreenEntityActionEvent event,
  Emitter<ScreenState> emit,
) async {
  // Delegate to appropriate repository based on entity type
  switch (event.entityType) {
    case 'task':
      await _handleTaskAction(event.entityId, event.action);
    case 'project':
      await _handleProjectAction(event.entityId, event.action);
    case 'label':
    case 'value':
      await _handleLabelAction(event.entityId, event.action);
  }

  // Refresh to show updated data
  add(const ScreenEvent.refresh());
}

Future<void> _handleTaskAction(String taskId, EntityAction action) async {
  switch (action) {
    case EntityAction.complete:
      await _taskRepository.completeTask(taskId);
    case EntityAction.uncomplete:
      await _taskRepository.uncompleteTask(taskId);
    case EntityAction.delete:
      await _taskRepository.deleteTask(taskId);
    case EntityAction.archive:
      await _taskRepository.archiveTask(taskId);
    case EntityAction.tap:
    case EntityAction.move:
    case EntityAction.edit:
      // These are handled by navigation or UI, not bloc
      break;
  }
}

Future<void> _handleProjectAction(String projectId, EntityAction action) async {
  switch (action) {
    case EntityAction.complete:
      await _projectRepository.completeProject(projectId);
    case EntityAction.uncomplete:
      await _projectRepository.uncompleteProject(projectId);
    case EntityAction.delete:
      await _projectRepository.deleteProject(projectId);
    case EntityAction.archive:
      await _projectRepository.archiveProject(projectId);
    case EntityAction.tap:
    case EntityAction.move:
    case EntityAction.edit:
      break;
  }
}

Future<void> _handleLabelAction(String labelId, EntityAction action) async {
  switch (action) {
    case EntityAction.delete:
      await _labelRepository.deleteLabel(labelId);
    default:
      break;
  }
}
```

---

## Task 6: Implement _onNavigateToEntity Handler

```dart
Future<void> _onNavigateToEntity(
  ScreenNavigateToEntityEvent event,
  Emitter<ScreenState> emit,
) async {
  // Navigation is handled by the UI layer using EntityNavigator (Phase 6A)
  // This event is primarily for logging/analytics
  // The actual navigation happens in the widget layer
}
```

---

## Task 7: Implement Helper Methods

Add these helper methods to `ScreenBloc`:

```dart
/// Fetch data for all sections
Future<List<SectionData>> _fetchAllSections(
  ScreenDefinition definition,
) async {
  final results = <SectionData>[];

  for (var i = 0; i < definition.sections.length; i++) {
    final section = definition.sections[i];
    try {
      final data = await _sectionDataService.fetchSectionData(section);
      results.add(SectionData(
        index: i,
        title: section.title,
        data: data,
      ));
    } catch (e) {
      results.add(SectionData(
        index: i,
        title: section.title,
        data: const SectionDataResult.data(
          primaryEntities: [],
          primaryEntityType: 'unknown',
        ),
        error: e.toString(),
      ));
    }
  }

  return results;
}

/// Compute all support blocks
List<SupportBlockData> _computeSupportBlocks(
  ScreenDefinition definition,
  List<SectionData> sections,
) {
  // Gather all tasks and projects from sections for problem detection
  final allTasks = sections.expand((s) => s.data.allTasks).toList();
  final allProjects = sections.expand((s) => s.data.allProjects).toList();

  final results = <SupportBlockData>[];

  for (var i = 0; i < definition.supportBlocks.length; i++) {
    final block = definition.supportBlocks[i];
    final result = _supportBlockComputer.compute(
      block,
      tasks: allTasks,
      projects: allProjects,
    );
    results.add(SupportBlockData(
      index: i,
      config: block,
      result: result,
    ));
  }

  // Sort by order
  results.sort((a, b) => a.config.order.compareTo(b.config.order));

  return results;
}
```

---

## Task 8: Add Repository Dependencies

Update the bloc constructor to include all needed repositories:

```dart
class ScreenBloc extends Bloc<ScreenEvent, ScreenState> {
  final ScreenRepository _screenRepository;
  final SectionDataService _sectionDataService;
  final SupportBlockComputer _supportBlockComputer;
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final LabelRepository _labelRepository;

  ScreenBloc({
    required ScreenRepository screenRepository,
    required SectionDataService sectionDataService,
    required SupportBlockComputer supportBlockComputer,
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required LabelRepository labelRepository,
  })  : _screenRepository = screenRepository,
        _sectionDataService = sectionDataService,
        _supportBlockComputer = supportBlockComputer,
        _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _labelRepository = labelRepository,
        super(const ScreenState.initial()) {
    // ... event handlers
  }
}
```

---

## Task 9: Delete Legacy ViewBloc

**Action**: DELETE FILE

**File**: `lib/presentation/features/screens/bloc/view_bloc.dart`

Delete this file and any related view_event.dart, view_state.dart files.

---

## Task 10: Update References to ViewBloc

Search for and update any imports of ViewBloc to use ScreenBloc:

```bash
# For reference
grep -r "ViewBloc" lib/
grep -r "view_bloc" lib/
```

Update widgets that used ViewBloc to use the new ScreenBloc.

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] All event handlers implemented
- [ ] `view_bloc.dart` deleted
- [ ] No references to ViewBloc remain
- [ ] Helper methods work correctly
- [ ] Repository dependencies added to constructor

---

## Files Deleted

| File | Reason |
|------|--------|
| `lib/presentation/features/screens/bloc/view_bloc.dart` | Replaced by ScreenBloc |
| `lib/presentation/features/screens/bloc/view_event.dart` | Replaced by screen_event.dart |
| `lib/presentation/features/screens/bloc/view_state.dart` | Replaced by screen_state.dart |

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/screens/bloc/screen_bloc.dart` | Implement all handlers |
| Various widget files | Update ViewBloc → ScreenBloc |

---

## Next Phase

Proceed to **Phase 6A: Entity Navigation** after validation passes.
