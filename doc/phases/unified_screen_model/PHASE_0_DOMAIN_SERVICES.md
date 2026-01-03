# Phase 0: Domain Services Foundation

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Create core domain services that contain all business logic for the unified screen model.

**Design Decisions Implemented**:
- D1: Streams via `ScreenDataInterpreter.watchScreen()`
- D2: Service-driven architecture
- D6: `EntityActionService` scope (complete/uncomplete, delete, pin/unpin, move)

---

## Prerequisites

- Existing `SectionDataService` at `lib/domain/services/screens/section_data_service.dart`
- Existing `SupportBlockComputer` at `lib/domain/services/screens/support_block_computer.dart`
- Existing repository contracts in `lib/domain/interfaces/`

---

## Task 0.1: Create ScreenData Model

**File**: `lib/domain/services/screens/screen_data.dart`

This model holds the interpreted data for an entire screen.

```dart
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_result.dart';

/// Interpreted data for an entire screen.
///
/// Emitted by [ScreenDataInterpreter.watchScreen] as a stream.
@immutable
class ScreenData {
  const ScreenData({
    required this.definition,
    required this.sections,
    required this.supportBlocks,
    this.isLoading = false,
    this.error,
  });

  /// The screen definition being rendered
  final ScreenDefinition definition;

  /// Data for each section, indexed by section position
  final List<SectionDataWithMeta> sections;

  /// Computed support block results
  final List<SupportBlockWithMeta> supportBlocks;

  /// Whether any section is currently loading
  final bool isLoading;

  /// Error message if screen failed to load
  final String? error;

  /// Create a loading state
  factory ScreenData.loading(ScreenDefinition definition) {
    return ScreenData(
      definition: definition,
      sections: [],
      supportBlocks: [],
      isLoading: true,
    );
  }

  /// Create an error state
  factory ScreenData.error(ScreenDefinition definition, String message) {
    return ScreenData(
      definition: definition,
      sections: [],
      supportBlocks: [],
      error: message,
    );
  }

  ScreenData copyWith({
    ScreenDefinition? definition,
    List<SectionDataWithMeta>? sections,
    List<SupportBlockWithMeta>? supportBlocks,
    bool? isLoading,
    String? error,
  }) {
    return ScreenData(
      definition: definition ?? this.definition,
      sections: sections ?? this.sections,
      supportBlocks: supportBlocks ?? this.supportBlocks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Section data with metadata for rendering.
@immutable
class SectionDataWithMeta {
  const SectionDataWithMeta({
    required this.index,
    required this.result,
    this.title,
    this.isLoading = false,
    this.error,
  });

  final int index;
  final String? title;
  final SectionDataResult result;
  final bool isLoading;
  final String? error;

  SectionDataWithMeta copyWith({
    int? index,
    String? title,
    SectionDataResult? result,
    bool? isLoading,
    String? error,
  }) {
    return SectionDataWithMeta(
      index: index ?? this.index,
      title: title ?? this.title,
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Support block result with metadata.
@immutable
class SupportBlockWithMeta {
  const SupportBlockWithMeta({
    required this.index,
    required this.result,
  });

  final int index;
  final SupportBlockResult result;
}
```

---

## Task 0.2: Create ScreenDataInterpreter

**File**: `lib/domain/services/screens/screen_data_interpreter.dart`

This service interprets a `ScreenDefinition` into a reactive stream of `ScreenData`.

```dart
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';

/// Interprets a [ScreenDefinition] into a reactive stream of [ScreenData].
///
/// This is the core service for the unified screen model (DR-017).
/// It coordinates [SectionDataService] and [SupportBlockComputer] to
/// produce a single stream that widgets can consume.
class ScreenDataInterpreter {
  ScreenDataInterpreter({
    required SectionDataService sectionDataService,
    required SupportBlockComputer supportBlockComputer,
  }) : _sectionDataService = sectionDataService,
       _supportBlockComputer = supportBlockComputer;

  final SectionDataService _sectionDataService;
  final SupportBlockComputer _supportBlockComputer;

  /// Watch a screen definition and emit [ScreenData] on changes.
  ///
  /// Combines streams from all sections and recomputes support blocks
  /// whenever section data changes.
  Stream<ScreenData> watchScreen(ScreenDefinition definition) {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'watchScreen: ${definition.id} with ${definition.sections.length} sections',
    );

    if (definition.sections.isEmpty) {
      return Stream.value(ScreenData(
        definition: definition,
        sections: [],
        supportBlocks: [],
      ));
    }

    // Create streams for each section
    final sectionStreams = definition.sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      return _watchSection(index, section);
    }).toList();

    // Combine all section streams
    return Rx.combineLatestList(sectionStreams).asyncMap((sectionResults) async {
      // Compute support blocks based on section data
      final supportBlocks = await _computeSupportBlocks(
        definition,
        sectionResults,
      );

      return ScreenData(
        definition: definition,
        sections: sectionResults,
        supportBlocks: supportBlocks,
      );
    }).handleError((Object error, StackTrace stackTrace) {
      talker.handle(error, stackTrace, '[ScreenDataInterpreter] watchScreen failed');
      return ScreenData.error(definition, error.toString());
    });
  }

  /// Fetch screen data once (non-reactive).
  Future<ScreenData> fetchScreen(ScreenDefinition definition) async {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'fetchScreen: ${definition.id}',
    );

    try {
      final sections = await Future.wait(
        definition.sections.asMap().entries.map((entry) async {
          final index = entry.key;
          final section = entry.value;
          return _fetchSection(index, section);
        }),
      );

      final supportBlocks = await _computeSupportBlocks(definition, sections);

      return ScreenData(
        definition: definition,
        sections: sections,
        supportBlocks: supportBlocks,
      );
    } catch (e, st) {
      talker.handle(e, st, '[ScreenDataInterpreter] fetchScreen failed');
      return ScreenData.error(definition, e.toString());
    }
  }

  Stream<SectionDataWithMeta> _watchSection(int index, Section section) {
    return _sectionDataService.watchSectionData(section).map((result) {
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: result,
      );
    }).handleError((Object error, StackTrace stackTrace) {
      talker.handle(error, stackTrace, '[ScreenDataInterpreter] Section $index failed');
      // Return error state for this section
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: const SectionDataResult.data(
          primaryEntities: [],
          primaryEntityType: 'unknown',
        ),
        error: error.toString(),
      );
    });
  }

  Future<SectionDataWithMeta> _fetchSection(int index, Section section) async {
    try {
      final result = await _sectionDataService.fetchSectionData(section);
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: result,
      );
    } catch (e) {
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: const SectionDataResult.data(
          primaryEntities: [],
          primaryEntityType: 'unknown',
        ),
        error: e.toString(),
      );
    }
  }

  String? _getSectionTitle(Section section) {
    return switch (section) {
      DataSection(:final title) => title,
      AllocationSection(:final title) => title,
      AgendaSection(:final title) => title,
    };
  }

  Future<List<SupportBlockWithMeta>> _computeSupportBlocks(
    ScreenDefinition definition,
    List<SectionDataWithMeta> sections,
  ) async {
    if (definition.supportBlocks.isEmpty) {
      return [];
    }

    final results = <SupportBlockWithMeta>[];

    for (var i = 0; i < definition.supportBlocks.length; i++) {
      final block = definition.supportBlocks[i];
      try {
        final result = await _supportBlockComputer.compute(
          block,
          sections.map((s) => s.result).toList(),
        );
        results.add(SupportBlockWithMeta(index: i, result: result));
      } catch (e) {
        talker.warning('[ScreenDataInterpreter] Support block $i failed: $e');
      }
    }

    return results;
  }
}
```

---

## Task 0.3: Create EntityActionService

**File**: `lib/domain/services/screens/entity_action_service.dart`

This service handles all entity mutations (complete, delete, pin, move).

```dart
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Actions that can be performed on entities.
enum EntityActionType {
  complete,
  uncomplete,
  delete,
  pin,
  unpin,
  move,
}

/// Service for performing actions on entities (tasks, projects, etc.).
///
/// This service is used by the unified screen model to handle entity
/// mutations without coupling to any specific bloc or screen.
class EntityActionService {
  EntityActionService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  // ===========================================================================
  // TASK ACTIONS
  // ===========================================================================

  /// Complete a task.
  Future<void> completeTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'completeTask: $taskId');
    await _taskRepository.completeTask(taskId: taskId);
  }

  /// Uncomplete a task.
  Future<void> uncompleteTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'uncompleteTask: $taskId');
    await _taskRepository.uncompleteTask(taskId: taskId);
  }

  /// Delete a task.
  Future<void> deleteTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'deleteTask: $taskId');
    await _taskRepository.delete(taskId);
  }

  /// Pin a task for allocation.
  Future<void> pinTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'pinTask: $taskId');
    // TODO: Implement when allocation pinning is available
    throw UnimplementedError('Task pinning not yet implemented');
  }

  /// Unpin a task from allocation.
  Future<void> unpinTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'unpinTask: $taskId');
    // TODO: Implement when allocation pinning is available
    throw UnimplementedError('Task unpinning not yet implemented');
  }

  /// Move a task to a different project.
  Future<void> moveTask(String taskId, String? targetProjectId) async {
    talker.serviceLog(
      'EntityActionService',
      'moveTask: $taskId -> $targetProjectId',
    );
    final task = await _taskRepository.getById(taskId);
    if (task != null) {
      await _taskRepository.update(
        Task(
          id: task.id,
          createdAt: task.createdAt,
          updatedAt: DateTime.now(),
          name: task.name,
          completed: task.completed,
          projectId: targetProjectId,
          startDate: task.startDate,
          deadlineDate: task.deadlineDate,
          description: task.description,
          priority: task.priority,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          seriesEnded: task.seriesEnded,
          lastReviewedAt: task.lastReviewedAt,
        ),
      );
    }
  }

  // ===========================================================================
  // PROJECT ACTIONS
  // ===========================================================================

  /// Complete a project.
  Future<void> completeProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'completeProject: $projectId');
    await _projectRepository.complete(projectId);
  }

  /// Uncomplete a project.
  Future<void> uncompleteProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'uncompleteProject: $projectId');
    await _projectRepository.uncomplete(projectId);
  }

  /// Delete a project.
  Future<void> deleteProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'deleteProject: $projectId');
    await _projectRepository.delete(projectId);
  }

  // ===========================================================================
  // GENERIC DISPATCH
  // ===========================================================================

  /// Perform an action on an entity by type.
  ///
  /// This is a convenience method for widgets that need to dispatch
  /// actions without knowing the entity type at compile time.
  Future<void> performAction({
    required String entityId,
    required String entityType,
    required EntityActionType action,
    Map<String, dynamic>? params,
  }) async {
    talker.serviceLog(
      'EntityActionService',
      'performAction: $action on $entityType/$entityId',
    );

    switch (entityType) {
      case 'task':
        await _performTaskAction(entityId, action, params);
      case 'project':
        await _performProjectAction(entityId, action);
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }

  Future<void> _performTaskAction(
    String taskId,
    EntityActionType action,
    Map<String, dynamic>? params,
  ) async {
    switch (action) {
      case EntityActionType.complete:
        await completeTask(taskId);
      case EntityActionType.uncomplete:
        await uncompleteTask(taskId);
      case EntityActionType.delete:
        await deleteTask(taskId);
      case EntityActionType.pin:
        await pinTask(taskId);
      case EntityActionType.unpin:
        await unpinTask(taskId);
      case EntityActionType.move:
        final targetProjectId = params?['targetProjectId'] as String?;
        await moveTask(taskId, targetProjectId);
    }
  }

  Future<void> _performProjectAction(
    String projectId,
    EntityActionType action,
  ) async {
    switch (action) {
      case EntityActionType.complete:
        await completeProject(projectId);
      case EntityActionType.uncomplete:
        await uncompleteProject(projectId);
      case EntityActionType.delete:
        await deleteProject(projectId);
      case EntityActionType.pin:
      case EntityActionType.unpin:
      case EntityActionType.move:
        throw UnsupportedError('Action $action not supported for projects');
    }
  }
}
```

---

## Task 0.4: Update Screens Services Barrel Export

**File**: `lib/domain/services/screens/screens.dart`

Create or update the barrel export for screen services:

```dart
export 'entity_action_service.dart';
export 'entity_grouper.dart';
export 'screen_data.dart';
export 'screen_data_interpreter.dart';
export 'screen_query_builder.dart';
export 'section_data_result.dart';
export 'section_data_service.dart';
export 'support_block_computer.dart';
export 'support_block_result.dart';
export 'trigger_evaluator.dart';
```

---

## Task 0.5: Update Domain Services Barrel Export

**File**: `lib/domain/services/services.dart`

Ensure the screens barrel is exported. Check if this file exists and add/update:

```dart
export 'screens/screens.dart';
// ... other existing exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `ScreenData` class compiles without errors
- [ ] `ScreenDataInterpreter` compiles without errors  
- [ ] `EntityActionService` compiles without errors
- [ ] Barrel exports are correct
- [ ] No circular imports

---

## Files Created

| File | Purpose | LOC |
|------|---------|-----|
| `lib/domain/services/screens/screen_data.dart` | Screen data model | ~110 |
| `lib/domain/services/screens/screen_data_interpreter.dart` | Stream-based interpreter | ~160 |
| `lib/domain/services/screens/entity_action_service.dart` | Entity mutations | ~150 |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/services/screens/screens.dart` | Add new exports |
| `lib/domain/services/services.dart` | Ensure screens export (if needed) |

---

## Dependencies Added

This phase requires `rxdart` for stream combination. Check if already in `pubspec.yaml`:

```yaml
dependencies:
  rxdart: ^0.28.0  # or existing version
```

---

## Next Phase

Proceed to **Phase 1: Thin ScreenBloc** after validation passes.
