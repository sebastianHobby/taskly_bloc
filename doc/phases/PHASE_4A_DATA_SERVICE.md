# Phase 4A: Data Fetching - Service

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create `SectionDataService` that fetches data for any section type.

**Decisions Implemented**: DR-002 (Queries in DataConfig), DR-005 (Related data), DR-017

---

## Prerequisites

- Phase 2A complete (Section model exists)
- Phase 2C complete (ScreenDefinition updated)
- Existing repositories for Task, Project, Label

---

## Task 1: Create SectionDataResult

**File**: `lib/domain/services/section_data_result.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';

part 'section_data_result.freezed.dart';

/// Result of fetching data for a section
@freezed
sealed class SectionDataResult with _$SectionDataResult {
  /// Data section result
  const factory SectionDataResult.data({
    required List<dynamic> primaryEntities,
    required String primaryEntityType,
    @Default({}) Map<String, List<dynamic>> relatedEntities,
  }) = DataSectionResult;

  /// Allocation section result
  const factory SectionDataResult.allocation({
    required List<Task> allocatedTasks,
    required int totalAvailable,
  }) = AllocationSectionResult;

  /// Agenda section result
  const factory SectionDataResult.agenda({
    required Map<String, List<Task>> groupedTasks,
    required List<String> groupOrder,
  }) = AgendaSectionResult;

  const SectionDataResult._();

  /// Get all tasks from any result type
  List<Task> get allTasks => switch (this) {
        DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
            primaryEntityType == 'task' ? primaryEntities.cast<Task>() : [],
        AllocationSectionResult(:final allocatedTasks) => allocatedTasks,
        AgendaSectionResult(:final groupedTasks) =>
            groupedTasks.values.expand((list) => list).toList(),
      };

  /// Get all projects from any result type
  List<Project> get allProjects => switch (this) {
        DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
            primaryEntityType == 'project' ? primaryEntities.cast<Project>() : [],
        _ => [],
      };
}
```

---

## Task 2: Create SectionDataService

**File**: `lib/domain/services/section_data_service.dart`

```dart
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/repositories/project_repository.dart';
import 'package:taskly_bloc/domain/repositories/label_repository.dart';
import 'package:taskly_bloc/domain/services/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/section_data_result.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';

/// Service for fetching data for screen sections
class SectionDataService {
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final LabelRepository _labelRepository;
  final AllocationOrchestrator _allocationOrchestrator;

  SectionDataService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required LabelRepository labelRepository,
    required AllocationOrchestrator allocationOrchestrator,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _labelRepository = labelRepository,
        _allocationOrchestrator = allocationOrchestrator;

  /// Fetch data for a section
  Future<SectionDataResult> fetchSectionData(Section section) async {
    return switch (section) {
      DataSection(:final config, :final relatedData) =>
          _fetchDataSection(config, relatedData),
      AllocationSection(:final sourceFilter, :final maxTasks) =>
          _fetchAllocationSection(sourceFilter, maxTasks),
      AgendaSection(:final dateField, :final grouping, :final additionalFilter) =>
          _fetchAgendaSection(dateField, grouping, additionalFilter),
    };
  }

  /// Fetch data section
  Future<SectionDataResult> _fetchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
  ) async {
    final (entities, entityType) = await _fetchPrimaryEntities(config);
    final related = await _fetchRelatedData(entities, entityType, relatedData);

    return SectionDataResult.data(
      primaryEntities: entities,
      primaryEntityType: entityType,
      relatedEntities: related,
    );
  }

  /// Fetch primary entities based on DataConfig
  Future<(List<dynamic>, String)> _fetchPrimaryEntities(DataConfig config) async {
    return switch (config) {
      TaskDataConfig(:final query) => (
          await _taskRepository.queryTasks(query),
          'task',
        ),
      ProjectDataConfig(:final query) => (
          await _projectRepository.queryProjects(query),
          'project',
        ),
      LabelDataConfig(:final query) => (
          await _labelRepository.queryLabels(
            query ?? LabelQuery.labelsOnly(),
          ),
          'label',
        ),
      ValueDataConfig(:final query) => (
          await _labelRepository.queryLabels(
            query ?? LabelQuery.values(),
          ),
          'value',
        ),
    };
  }

  /// Fetch related data for primary entities
  Future<Map<String, List<dynamic>>> _fetchRelatedData(
    List<dynamic> primaryEntities,
    String entityType,
    List<RelatedDataConfig> relatedData,
  ) async {
    final result = <String, List<dynamic>>{};

    for (final config in relatedData) {
      final key = _getRelatedDataKey(config);
      result[key] = await _fetchRelatedEntities(
        primaryEntities,
        entityType,
        config,
      );
    }

    return result;
  }

  String _getRelatedDataKey(RelatedDataConfig config) {
    return switch (config) {
      RelatedTasksConfig() => 'tasks',
      RelatedProjectsConfig() => 'projects',
      ValueHierarchyConfig() => 'valueHierarchy',
    };
  }

  Future<List<dynamic>> _fetchRelatedEntities(
    List<dynamic> primaryEntities,
    String entityType,
    RelatedDataConfig config,
  ) async {
    // Implementation depends on entity relationships
    // This is a simplified version - expand based on actual repository methods
    return switch (config) {
      RelatedTasksConfig(:final additionalFilter) => 
          await _fetchRelatedTasks(primaryEntities, entityType, additionalFilter),
      RelatedProjectsConfig(:final additionalFilter) =>
          await _fetchRelatedProjects(primaryEntities, entityType, additionalFilter),
      ValueHierarchyConfig() =>
          await _fetchValueHierarchy(primaryEntities),
    };
  }

  Future<List<Task>> _fetchRelatedTasks(
    List<dynamic> entities,
    String entityType,
    TaskQuery? filter,
  ) async {
    // Get task IDs based on primary entity type
    final taskIds = <String>[];
    
    switch (entityType) {
      case 'project':
        for (final project in entities.cast<Project>()) {
          final tasks = await _taskRepository.getTasksByProject(project.id);
          taskIds.addAll(tasks.map((t) => t.id));
        }
      case 'label':
      case 'value':
        for (final label in entities.cast<Label>()) {
          final tasks = await _taskRepository.getTasksByLabel(label.id);
          taskIds.addAll(tasks.map((t) => t.id));
        }
    }

    if (taskIds.isEmpty) return [];

    // Apply additional filter if provided
    var query = TaskQuery.byIds(taskIds);
    if (filter != null) {
      // Merge filters - implementation depends on QueryFilter design
      query = query.copyWith(
        filter: query.filter?.merge(filter.filter),
      );
    }

    return _taskRepository.queryTasks(query);
  }

  Future<List<Project>> _fetchRelatedProjects(
    List<dynamic> entities,
    String entityType,
    ProjectQuery? filter,
  ) async {
    // Similar implementation for projects
    return [];
  }

  Future<List<dynamic>> _fetchValueHierarchy(List<dynamic> values) async {
    // Special 3-level hierarchy: Value → Project → Task
    // Implementation for value screens
    return [];
  }

  /// Fetch allocation section
  Future<SectionDataResult> _fetchAllocationSection(
    TaskQuery? sourceFilter,
    int? maxTasks,
  ) async {
    final allocation = await _allocationOrchestrator.getAllocation(
      sourceFilter: sourceFilter,
      maxTasks: maxTasks,
    );

    return SectionDataResult.allocation(
      allocatedTasks: allocation.tasks,
      totalAvailable: allocation.totalAvailable,
    );
  }

  /// Fetch agenda section
  Future<SectionDataResult> _fetchAgendaSection(
    AgendaDateField dateField,
    AgendaGrouping grouping,
    TaskQuery? additionalFilter,
  ) async {
    // Get tasks and group by date
    final tasks = await _taskRepository.queryTasks(
      additionalFilter ?? const TaskQuery(),
    );

    final grouped = _groupTasksByDate(tasks, dateField, grouping);

    return SectionDataResult.agenda(
      groupedTasks: grouped.$1,
      groupOrder: grouped.$2,
    );
  }

  (Map<String, List<Task>>, List<String>) _groupTasksByDate(
    List<Task> tasks,
    AgendaDateField dateField,
    AgendaGrouping grouping,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final groups = <String, List<Task>>{};
    final order = <String>[];

    DateTime? getDate(Task task) {
      return switch (dateField) {
        AgendaDateField.deadlineDate => task.deadlineDate,
        AgendaDateField.startDate => task.startDate,
        AgendaDateField.scheduledFor => task.scheduledFor,
      };
    }

    for (final task in tasks) {
      final date = getDate(task);
      if (date == null) continue;

      final groupKey = switch (grouping) {
        AgendaGrouping.standard => _getStandardGroupKey(date, today, tomorrow, weekEnd),
        AgendaGrouping.byDate => _formatDate(date),
        AgendaGrouping.overdueFirst => _getOverdueFirstGroupKey(date, today, tomorrow, weekEnd),
      };

      groups.putIfAbsent(groupKey, () => []).add(task);
      if (!order.contains(groupKey)) order.add(groupKey);
    }

    return (groups, order);
  }

  String _getStandardGroupKey(DateTime date, DateTime today, DateTime tomorrow, DateTime weekEnd) {
    if (date.isBefore(today)) return 'Overdue';
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, tomorrow)) return 'Tomorrow';
    if (date.isBefore(weekEnd)) return 'This Week';
    return 'Later';
  }

  String _getOverdueFirstGroupKey(DateTime date, DateTime today, DateTime tomorrow, DateTime weekEnd) {
    // Same as standard but ensures Overdue is first in order
    return _getStandardGroupKey(date, today, tomorrow, weekEnd);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
```

---

## Task 3: Export from Services Barrel

**File**: `lib/domain/services/services.dart`

Add exports:

```dart
export 'section_data_service.dart';
export 'section_data_result.dart';
// ... existing exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `section_data_result.freezed.dart` generated
- [ ] `SectionDataService` compiles without errors
- [ ] Can instantiate `SectionDataService` with required dependencies
- [ ] `fetchSectionData` handles all section types

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/domain/services/section_data_result.dart` | Result type for section data |
| `lib/domain/services/section_data_service.dart` | Service for fetching section data |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/services/services.dart` | Add new exports |

---

## Next Phase

Proceed to **Phase 4B: Data Fetching - Repository Updates** after validation passes.
