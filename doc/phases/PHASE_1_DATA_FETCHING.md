# Phase 1: Data Fetching Layer

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Create the service layer that fetches data based on Section configurations. This runs parallel to existing ViewService (which remains untouched until Phase 6).

### Prerequisites
- Phase 0 complete (all foundation types exist and compile)

---

## Task 1: Create FetchResult Sealed Class

**File**: `lib/domain/models/screens/fetch_result.dart`

**Requirements**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';

part 'fetch_result.freezed.dart';

/// Result of fetching section data.
/// Different variants for different data shapes.
@Freezed(genericArgumentFactories: true)
sealed class FetchResult<T> with _$FetchResult<T> {
  /// Simple list of entities
  const factory FetchResult.list(List<T> items) = ListFetchResult<T>;
  
  /// Entities grouped by parent ID
  const factory FetchResult.grouped({
    required Map<String, List<T>> itemsByParentId,
    required Map<String, dynamic> parentsById,
  }) = GroupedFetchResult<T>;

  // Note: No fromJson - these are runtime-only, not persisted
}

/// Result specifically for Value → Project → Task hierarchy
@freezed
class ValueHierarchyResult with _$ValueHierarchyResult {
  const factory ValueHierarchyResult({
    required Label value,
    required List<ProjectWithTasks> projects,
    /// Tasks with explicit value assignment but no project
    required List<Task> directTasks,
  }) = _ValueHierarchyResult;
}

/// A project with its tasks in hierarchy context
@freezed
class ProjectWithTasks with _$ProjectWithTasks {
  const factory ProjectWithTasks({
    required Project project,
    /// Tasks explicitly assigned this value
    required List<Task> explicitTasks,
    /// Tasks inheriting value from this project
    required List<Task> inheritedTasks,
  }) = _ProjectWithTasks;
  
  const ProjectWithTasks._();
  
  /// All tasks (explicit + inherited)
  List<Task> get allTasks => [...explicitTasks, ...inheritedTasks];
}

/// Combined result for a DataSection with related data
@freezed
class SectionData with _$SectionData {
  /// Task section data
  const factory SectionData.tasks({
    required List<Task> tasks,
    /// Related projects (if requested)
    Map<String, Project>? projectsById,
    /// Related labels (if requested)
    Map<String, Label>? labelsById,
  }) = TaskSectionData;
  
  /// Project section data
  const factory SectionData.projects({
    required List<Project> projects,
    /// Child tasks per project (if requested)
    Map<String, List<Task>>? tasksByProjectId,
    /// Related labels (if requested)
    Map<String, Label>? labelsById,
  }) = ProjectSectionData;
  
  /// Label section data
  const factory SectionData.labels({
    required List<Label> labels,
    /// Tasks per label (if requested)
    Map<String, List<Task>>? tasksByLabelId,
    /// Projects per label (if requested)
    Map<String, List<Project>>? projectsByLabelId,
  }) = LabelSectionData;
  
  /// Value section data (can include hierarchy)
  const factory SectionData.values({
    required List<Label> values,
    /// Simple: tasks per value
    Map<String, List<Task>>? tasksByValueId,
    /// Simple: projects per value
    Map<String, List<Project>>? projectsByValueId,
    /// Complex: full hierarchy results
    List<ValueHierarchyResult>? hierarchies,
  }) = ValueSectionData;
  
  /// Allocation data (Next Actions)
  const factory SectionData.allocation({
    required List<Task> allocatedTasks,
  }) = AllocationSectionData;
  
  /// Navigation data (Settings menu)
  const factory SectionData.navigation({
    required List<NavigationItemData> items,
  }) = NavigationSectionData;
  
  /// Support block data
  const factory SectionData.support({
    required SupportBlockData data,
  }) = SupportSectionData;
}

/// Runtime navigation item with resolved data
@freezed
class NavigationItemData with _$NavigationItemData {
  const factory NavigationItemData({
    required String id,
    required String title,
    required String route,
    String? iconName,
    String? subtitle,
    int? badgeCount,
  }) = _NavigationItemData;
}

/// Runtime support block data
@freezed
class SupportBlockData with _$SupportBlockData {
  const factory SupportBlockData.reviewBanner({
    required int taskCount,
    required DateTime? oldestReviewDate,
  }) = ReviewBannerData;
  
  const factory SupportBlockData.problemBanner({
    required List<String> problemDescriptions,
  }) = ProblemBannerData;
  
  const factory SupportBlockData.analytics({
    required Map<String, dynamic> metrics,
  }) = AnalyticsBlockData;
}
```

---

## Task 2: Create SectionDataService

**File**: `lib/domain/services/screens/section_data_service.dart`

**Requirements**:
```dart
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/screens/value_hierarchy_service.dart';

/// Service for fetching data for any Section type.
/// Used by both screen BLoCs and workflow BLoCs.
class SectionDataService {
  SectionDataService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
    required AllocationOrchestrator allocationOrchestrator,
    required ValueHierarchyService valueHierarchyService,
    DateTime Function()? nowFactory,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _labelRepository = labelRepository,
        _allocationOrchestrator = allocationOrchestrator,
        _valueHierarchyService = valueHierarchyService,
        _nowFactory = nowFactory ?? DateTime.now;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final LabelRepositoryContract _labelRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final ValueHierarchyService _valueHierarchyService;
  final DateTime Function() _nowFactory;

  /// Watch section data as a stream (for screens)
  Stream<SectionData> watchSection(
    Section section, {
    String? parentEntityId,
  }) {
    return switch (section) {
      DataSection(:final config, :final relatedData) =>
        _watchDataSection(config, relatedData, parentEntityId),
      SupportSection(:final config) =>
        _watchSupportSection(config),
      NavigationSection(:final items) =>
        _watchNavigationSection(items),
      AllocationSection(:final maxTasks) =>
        _watchAllocationSection(maxTasks),
    };
  }

  /// Load section data once (for workflows)
  Future<SectionData> loadSectionOnce(
    Section section, {
    String? parentEntityId,
  }) {
    return watchSection(section, parentEntityId: parentEntityId).first;
  }

  // Private implementation methods below...
  
  Stream<SectionData> _watchDataSection(
    DataConfig config,
    List<RelatedDataConfig> relatedData,
    String? parentEntityId,
  ) {
    return switch (config) {
      TaskDataConfig(:final query) =>
        _watchTaskData(query, relatedData, parentEntityId),
      ProjectDataConfig(:final query) =>
        _watchProjectData(query, relatedData, parentEntityId),
      LabelDataConfig(:final query) =>
        _watchLabelData(query, relatedData),
      ValueDataConfig(:final query) =>
        _watchValueData(query, relatedData),
    };
  }

  Stream<SectionData> _watchTaskData(
    TaskQuery query,
    List<RelatedDataConfig> relatedData,
    String? parentEntityId,
  ) async* {
    // Apply parent constraint if provided
    final constrainedQuery = parentEntityId != null
        ? _applyParentConstraint(query, parentEntityId)
        : query;
    
    await for (final tasks in _taskRepository.watchAll(constrainedQuery)) {
      // Fetch related data if requested
      Map<String, Project>? projectsById;
      Map<String, Label>? labelsById;
      
      for (final related in relatedData) {
        switch (related) {
          case RelatedProjectsConfig():
            // Fetch projects for these tasks
            final projectIds = tasks
                .map((t) => t.projectId)
                .whereType<String>()
                .toSet();
            if (projectIds.isNotEmpty) {
              final projects = await _projectRepository
                  .getByIds(projectIds.toList());
              projectsById = {for (final p in projects) p.id: p};
            }
          case RelatedTasksConfig():
            // Tasks as related to tasks doesn't make sense, skip
            break;
          case ValueHierarchyConfig():
            // Not applicable to task primary
            break;
        }
      }
      
      yield SectionData.tasks(
        tasks: tasks,
        projectsById: projectsById,
        labelsById: labelsById,
      );
    }
  }

  Stream<SectionData> _watchProjectData(
    ProjectQuery query,
    List<RelatedDataConfig> relatedData,
    String? parentEntityId,
  ) async* {
    await for (final projects in _projectRepository.watchAllByQuery(query)) {
      Map<String, List<Task>>? tasksByProjectId;
      Map<String, Label>? labelsById;
      
      for (final related in relatedData) {
        switch (related) {
          case RelatedTasksConfig(:final additionalFilter):
            // Fetch tasks for each project
            tasksByProjectId = {};
            for (final project in projects) {
              final tasks = await _taskRepository
                  .watchAll(_buildTaskQueryForProject(project.id, additionalFilter))
                  .first;
              tasksByProjectId[project.id] = tasks;
            }
          case RelatedProjectsConfig():
            // Projects related to projects - skip (not supported)
            break;
          case ValueHierarchyConfig():
            // Not applicable to project primary
            break;
        }
      }
      
      yield SectionData.projects(
        projects: projects,
        tasksByProjectId: tasksByProjectId,
        labelsById: labelsById,
      );
    }
  }

  Stream<SectionData> _watchLabelData(
    LabelQuery? query,
    List<RelatedDataConfig> relatedData,
  ) async* {
    // Filter out values (type != value)
    final labelStream = query != null
        ? _labelRepository.watchByQuery(query)
        : _labelRepository.watchAll().map(
            (labels) => labels.where((l) => l.type != LabelType.value).toList(),
          );
    
    await for (final labels in labelStream) {
      Map<String, List<Task>>? tasksByLabelId;
      Map<String, List<Project>>? projectsByLabelId;
      
      for (final related in relatedData) {
        switch (related) {
          case RelatedTasksConfig(:final additionalFilter):
            tasksByLabelId = {};
            for (final label in labels) {
              final tasks = await _taskRepository
                  .watchAll(_buildTaskQueryForLabel(label.id, additionalFilter))
                  .first;
              tasksByLabelId[label.id] = tasks;
            }
          case RelatedProjectsConfig(:final additionalFilter):
            projectsByLabelId = {};
            for (final label in labels) {
              final projects = await _projectRepository
                  .watchAllByQuery(_buildProjectQueryForLabel(label.id, additionalFilter))
                  .first;
              projectsByLabelId[label.id] = projects;
            }
          case ValueHierarchyConfig():
            // Not applicable to label primary
            break;
        }
      }
      
      yield SectionData.labels(
        labels: labels,
        tasksByLabelId: tasksByLabelId,
        projectsByLabelId: projectsByLabelId,
      );
    }
  }

  Stream<SectionData> _watchValueData(
    ValueQuery? query,
    List<RelatedDataConfig> relatedData,
  ) async* {
    // Values are labels with type == value
    final valueStream = _labelRepository.watchAll().map(
      (labels) => labels.where((l) => l.type == LabelType.value).toList(),
    );
    
    await for (final values in valueStream) {
      Map<String, List<Task>>? tasksByValueId;
      Map<String, List<Project>>? projectsByValueId;
      List<ValueHierarchyResult>? hierarchies;
      
      for (final related in relatedData) {
        switch (related) {
          case RelatedTasksConfig(:final additionalFilter):
            tasksByValueId = {};
            for (final value in values) {
              final tasks = await _taskRepository
                  .watchAll(_buildTaskQueryForValue(value.id, additionalFilter))
                  .first;
              tasksByValueId[value.id] = tasks;
            }
          case RelatedProjectsConfig(:final additionalFilter):
            projectsByValueId = {};
            for (final value in values) {
              final projects = await _projectRepository
                  .watchAllByQuery(_buildProjectQueryForValue(value.id, additionalFilter))
                  .first;
              projectsByValueId[value.id] = projects;
            }
          case ValueHierarchyConfig(
            :final includeInheritedTasks,
            :final projectFilter,
            :final taskFilter,
          ):
            // Use specialized service for 3-level hierarchy
            hierarchies = await _valueHierarchyService.buildHierarchies(
              values: values,
              includeInheritedTasks: includeInheritedTasks,
              projectFilter: projectFilter,
              taskFilter: taskFilter,
            );
        }
      }
      
      yield SectionData.values(
        values: values,
        tasksByValueId: tasksByValueId,
        projectsByValueId: projectsByValueId,
        hierarchies: hierarchies,
      );
    }
  }

  Stream<SectionData> _watchSupportSection(SupportBlockConfig config) async* {
    // Implementation depends on block type
    // Delegate to existing support block computation
    yield SectionData.support(
      data: await _computeSupportBlockData(config),
    );
  }

  Stream<SectionData> _watchNavigationSection(List<NavigationItem> items) async* {
    // Navigation items are static, just convert to runtime data
    yield SectionData.navigation(
      items: items.map((item) => NavigationItemData(
        id: item.id,
        title: item.title,
        route: item.route,
        iconName: item.iconName,
        subtitle: item.subtitle,
      )).toList(),
    );
  }

  Stream<SectionData> _watchAllocationSection(int maxTasks) {
    // Use existing AllocationOrchestrator
    return _allocationOrchestrator.watchAllocatedTasks(maxTasks: maxTasks)
        .map((tasks) => SectionData.allocation(allocatedTasks: tasks));
  }

  // Helper methods for building constrained queries
  TaskQuery _applyParentConstraint(TaskQuery query, String parentId) {
    // Add projectId constraint to existing query
    // Implementation depends on TaskQuery structure
    return query; // TODO: Implement properly
  }

  TaskQuery _buildTaskQueryForProject(String projectId, TaskQuery? additional) {
    // Build query: projectId == projectId AND additional filters
    return TaskQuery(
      filter: QueryFilter(
        shared: [
          TaskStringPredicate(
            field: TaskStringField.projectId,
            operator: StringOperator.equals,
            value: projectId,
          ),
          ...?additional?.filter.shared,
        ],
        orGroups: additional?.filter.orGroups ?? [],
      ),
      sortCriteria: additional?.sortCriteria ?? [],
    );
  }

  TaskQuery _buildTaskQueryForLabel(String labelId, TaskQuery? additional) {
    // Build query: labelIds contains labelId
    return TaskQuery(
      filter: QueryFilter(
        shared: [
          TaskListPredicate(
            field: TaskListField.labelIds,
            operator: ListOperator.contains,
            value: labelId,
          ),
          ...?additional?.filter.shared,
        ],
        orGroups: additional?.filter.orGroups ?? [],
      ),
      sortCriteria: additional?.sortCriteria ?? [],
    );
  }

  TaskQuery _buildTaskQueryForValue(String valueId, TaskQuery? additional) {
    // Same as label - values are stored in labelIds
    return _buildTaskQueryForLabel(valueId, additional);
  }

  ProjectQuery _buildProjectQueryForLabel(String labelId, ProjectQuery? additional) {
    // Build query: labelIds contains labelId
    return ProjectQuery(
      filter: QueryFilter(
        shared: [
          // TODO: Add ProjectListPredicate for labelIds
          ...?additional?.filter.shared,
        ],
        orGroups: additional?.filter.orGroups ?? [],
      ),
      sortCriteria: additional?.sortCriteria ?? [],
    );
  }

  ProjectQuery _buildProjectQueryForValue(String valueId, ProjectQuery? additional) {
    return _buildProjectQueryForLabel(valueId, additional);
  }

  Future<SupportBlockData> _computeSupportBlockData(SupportBlockConfig config) async {
    // TODO: Implement based on config.blockType
    // Delegate to existing SupportBlockComputer
    return const SupportBlockData.analytics(metrics: {});
  }
}
```

---

## Task 3: Create ValueHierarchyService

**File**: `lib/domain/services/screens/value_hierarchy_service.dart`

**Requirements**:
```dart
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/screens/fetch_result.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Service for building Value → Project → Task hierarchies.
/// Handles the special case where tasks can inherit values from their parent project.
class ValueHierarchyService {
  ValueHierarchyService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  /// Build hierarchies for multiple values
  Future<List<ValueHierarchyResult>> buildHierarchies({
    required List<Label> values,
    required bool includeInheritedTasks,
    ProjectQuery? projectFilter,
    TaskQuery? taskFilter,
  }) async {
    final results = <ValueHierarchyResult>[];
    
    for (final value in values) {
      final hierarchy = await buildHierarchy(
        value: value,
        includeInheritedTasks: includeInheritedTasks,
        projectFilter: projectFilter,
        taskFilter: taskFilter,
      );
      results.add(hierarchy);
    }
    
    return results;
  }

  /// Build hierarchy for a single value
  Future<ValueHierarchyResult> buildHierarchy({
    required Label value,
    required bool includeInheritedTasks,
    ProjectQuery? projectFilter,
    TaskQuery? taskFilter,
  }) async {
    // 1. Get all projects with this value
    final projects = await _getProjectsWithValue(value.id, projectFilter);
    
    // 2. Get all tasks explicitly assigned this value
    final explicitTasks = await _getTasksWithExplicitValue(value.id, taskFilter);
    
    // 3. Build project-task relationships
    final projectsWithTasks = <ProjectWithTasks>[];
    final directTasks = <Task>[]; // Tasks with value but no project
    
    for (final project in projects) {
      // Tasks explicitly assigned to this value AND this project
      final projectExplicitTasks = explicitTasks
          .where((t) => t.projectId == project.id)
          .toList();
      
      // Tasks inherited from project (project has value, task doesn't explicitly)
      List<Task> inheritedTasks = [];
      if (includeInheritedTasks) {
        inheritedTasks = await _getInheritedTasks(
          projectId: project.id,
          valueId: value.id,
          taskFilter: taskFilter,
        );
      }
      
      projectsWithTasks.add(ProjectWithTasks(
        project: project,
        explicitTasks: projectExplicitTasks,
        inheritedTasks: inheritedTasks,
      ));
    }
    
    // Tasks with value but no project (or project doesn't have value)
    final projectIds = projects.map((p) => p.id).toSet();
    directTasks.addAll(
      explicitTasks.where((t) => 
        t.projectId == null || !projectIds.contains(t.projectId)
      ),
    );
    
    return ValueHierarchyResult(
      value: value,
      projects: projectsWithTasks,
      directTasks: directTasks,
    );
  }

  Future<List<Project>> _getProjectsWithValue(
    String valueId,
    ProjectQuery? additionalFilter,
  ) async {
    // Projects where labelIds contains valueId
    // TODO: Implement with proper ProjectQuery
    final allProjects = await _projectRepository.watchAll().first;
    return allProjects.where((p) => p.labelIds.contains(valueId)).toList();
  }

  Future<List<Task>> _getTasksWithExplicitValue(
    String valueId,
    TaskQuery? additionalFilter,
  ) async {
    // Tasks where labelIds explicitly contains valueId
    final query = TaskQuery(
      filter: QueryFilter(
        shared: [
          TaskListPredicate(
            field: TaskListField.labelIds,
            operator: ListOperator.contains,
            value: valueId,
          ),
          ...?additionalFilter?.filter.shared,
        ],
        orGroups: additionalFilter?.filter.orGroups ?? [],
      ),
      sortCriteria: additionalFilter?.sortCriteria ?? [],
    );
    
    return _taskRepository.watchAll(query).first;
  }

  Future<List<Task>> _getInheritedTasks({
    required String projectId,
    required String valueId,
    TaskQuery? taskFilter,
  }) async {
    // Tasks that:
    // 1. Belong to this project
    // 2. Do NOT explicitly have this value in labelIds
    final query = TaskQuery(
      filter: QueryFilter(
        shared: [
          TaskStringPredicate(
            field: TaskStringField.projectId,
            operator: StringOperator.equals,
            value: projectId,
          ),
          // NOT contains valueId - need to implement this predicate
          // For now, filter in memory
          ...?taskFilter?.filter.shared,
        ],
        orGroups: taskFilter?.filter.orGroups ?? [],
      ),
      sortCriteria: taskFilter?.sortCriteria ?? [],
    );
    
    final projectTasks = await _taskRepository.watchAll(query).first;
    
    // Filter out tasks that explicitly have this value
    return projectTasks
        .where((t) => !t.labelIds.contains(valueId))
        .toList();
  }
}
```

---

## Task 4: Add Repository Methods (if needed)

**Check existing files first**:
- `lib/domain/interfaces/label_repository_contract.dart`
- `lib/domain/interfaces/project_repository_contract.dart`

**Add if missing**:

```dart
// In LabelRepositoryContract:
Stream<List<Label>> watchByQuery(LabelQuery query);
Future<List<Label>> getByIds(List<String> ids);

// In ProjectRepositoryContract:
Future<List<Project>> getByIds(List<String> ids);
```

**Then implement in**:
- `lib/data/features/labels/label_repository.dart`
- `lib/data/features/projects/project_repository.dart`

---

## Task 5: Register Services in DI

**File**: `lib/core/dependency_injection/dependency_injection.dart`

**Add registrations**:
```dart
// After existing service registrations

..registerLazySingleton<ValueHierarchyService>(
  () => ValueHierarchyService(
    taskRepository: getIt<TaskRepositoryContract>(),
    projectRepository: getIt<ProjectRepositoryContract>(),
  ),
)
..registerLazySingleton<SectionDataService>(
  () => SectionDataService(
    taskRepository: getIt<TaskRepositoryContract>(),
    projectRepository: getIt<ProjectRepositoryContract>(),
    labelRepository: getIt<LabelRepositoryContract>(),
    allocationOrchestrator: getIt<AllocationOrchestrator>(),
    valueHierarchyService: getIt<ValueHierarchyService>(),
  ),
)
```

---

## Task 6: Update Barrel Exports

**File**: `lib/domain/services/screens/screens.dart` (create if not exists)

```dart
export 'section_data_service.dart';
export 'value_hierarchy_service.dart';
// Keep existing
export 'entity_grouper.dart';
export 'screen_query_builder.dart';
export 'support_block_computer.dart';
export 'trigger_evaluator.dart';
export 'view_service.dart';
```

**File**: `lib/domain/models/screens/screens.dart`

Add:
```dart
export 'fetch_result.dart';
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] Verify all `.freezed.dart` files generated for new models
3. [ ] Confirm SectionDataService can be instantiated via DI
4. [ ] Verify no breaking changes to existing code
5. [ ] Existing screens still work (ViewService untouched)

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/domain/models/screens/fetch_result.dart` | Runtime result types |
| `lib/domain/services/screens/section_data_service.dart` | Main orchestration service |
| `lib/domain/services/screens/value_hierarchy_service.dart` | 3-level Value hierarchy |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/core/dependency_injection/dependency_injection.dart` | Register new services |
| `lib/domain/interfaces/*_repository_contract.dart` | Add missing methods (if needed) |
| `lib/data/features/*/repository.dart` | Implement missing methods (if needed) |
| `lib/domain/models/screens/screens.dart` | Add exports |
| `lib/domain/services/screens/screens.dart` | Add exports |

---

## Known TODOs for Later Phases

These are acceptable to leave as TODOs in Phase 1:
- `_applyParentConstraint` - full implementation in Phase 3
- `_computeSupportBlockData` - integrate with existing SupportBlockComputer
- `ProjectListPredicate` - may need to add to project_query.dart
- NOT contains predicate for task labels

---

## Next Phase
Proceed to **Phase 2: Screen Definition Migration** after all validation passes.
