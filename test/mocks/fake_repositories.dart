import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';

/// Shared fake implementations for integration tests.
///
/// These fakes provide in-memory implementations with simpler logic
/// than full repositories, making integration tests faster and more maintainable.

/// Minimal in-memory fake repository for task operations.
class FakeTaskRepository implements TaskRepositoryContract {
  FakeTaskRepository();

  final _controller = BehaviorSubject<List<Task>>.seeded([]);
  Completer<void>? updateCalled;
  List<Task> get _last => _controller.value;
  set _last(List<Task> value) => _controller.add(value);

  void pushTasks(List<Task> tasks) {
    _controller.add(tasks);
  }

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) => _controller.stream;

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async => _last;

  @override
  Stream<int> watchAllCount([TaskQuery? query]) =>
      _controller.stream.map((tasks) => tasks.length);

  @override
  Future<Task?> getById(String id) async {
    try {
      return _last.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Task?> watchById(String id) => _controller.stream.map((rows) {
    try {
      return rows.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  });

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    bool? isPinned,
  }) async {
    final idx = _last.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = Task(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      values: old.values,
    );

    _last = updated;
    _controller.add(_last);
    updateCalled?.complete();
  }

  @override
  Future<void> setPinned({required String id, required bool isPinned}) async {
    final idx = _last.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(isPinned: isPinned, updatedAt: DateTime.now());

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    final idx = _last.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(
      lastReviewedAt: reviewedAt,
      updatedAt: DateTime.now(),
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
  }) async {
    final now = DateTime.now();
    final id = 'gen-${now.microsecondsSinceEpoch}';
    final newTask = Task(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
    );
    _last = [..._last, newTask];
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id) async {
    _last = _last.where((t) => t.id != id).toList();
    _controller.add(_last);
  }

  Stream<Map<String, ProjectTaskCounts>> watchTaskCountsByProject() {
    return _controller.stream.map(_aggregateCounts);
  }

  Future<Map<String, ProjectTaskCounts>> getTaskCountsByProject() async {
    return _aggregateCounts(_last);
  }

  Map<String, ProjectTaskCounts> _aggregateCounts(List<Task> tasks) {
    final counts = <String, ({int total, int completed})>{};
    for (final task in tasks) {
      final projectId = task.projectId;
      if (projectId != null) {
        final current = counts[projectId] ?? (total: 0, completed: 0);
        counts[projectId] = (
          total: current.total + 1,
          completed: current.completed + (task.completed ? 1 : 0),
        );
      }
    }
    return counts.map(
      (projectId, data) => MapEntry(
        projectId,
        ProjectTaskCounts(
          projectId: projectId,
          totalCount: data.total,
          completedCount: data.completed,
        ),
      ),
    );
  }

  // Stub implementations for occurrence methods
  @override
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => _last;

  @override
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => _controller.stream;

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) async {}

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  }) async {}

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) async {}

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
  }) async {}

  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  }) async {}

  Future<void> stopSeries(String taskId) async {}

  Future<void> completeSeries(String taskId) async {}

  Future<void> convertToOneTime(String taskId) async {}

  Future<int> count([TaskQuery? query]) async => _last.length;

  Stream<int> watchCount([TaskQuery? query]) =>
      _controller.stream.map((tasks) => tasks.length);

  Future<List<Task>> queryTasks(TaskQuery query) async => _last;

  Future<List<Task>> getTasksByIds(List<String> ids) async =>
      _last.where((t) => ids.contains(t.id)).toList();

  Future<List<Task>> getTasksByProject(String projectId) async =>
      _last.where((t) => t.projectId == projectId).toList();

  void dispose() {
    _controller.close();
  }
}

/// Fake settings repository for integration tests.
class FakeSettingsRepository implements SettingsRepositoryContract {
  FakeSettingsRepository({
    GlobalSettings global = const GlobalSettings(),
    AllocationConfig allocation = const AllocationConfig(),
    SoftGatesSettings softGates = const SoftGatesSettings(),
    Map<String, SortPreferences> pageSort = const <String, SortPreferences>{},
    Map<String, PageDisplaySettings> pageDisplay =
        const <String, PageDisplaySettings>{},
  }) : _global = global,
       _allocation = allocation,
       _softGates = softGates,
       _pageSort = Map<String, SortPreferences>.from(pageSort),
       _pageDisplay = Map<String, PageDisplaySettings>.from(pageDisplay);

  final _controller = StreamController<void>.broadcast();
  GlobalSettings _global;
  AllocationConfig _allocation;
  SoftGatesSettings _softGates;
  final Map<String, SortPreferences> _pageSort;
  final Map<String, PageDisplaySettings> _pageDisplay;

  @override
  Stream<T> watch<T>(SettingsKey<T> key) async* {
    yield _extractValue(key);
    yield* _controller.stream.map((_) => _extractValue(key)).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async => _extractValue(key);

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    _applyValue(key, value);
    _controller.add(null);
  }

  T _extractValue<T>(SettingsKey<T> key) {
    return switch (key) {
      SettingsKey.global => _global as T,
      SettingsKey.allocation => _allocation as T,
      SettingsKey.softGates => _softGates as T,
      _ => _extractKeyedValue(key),
    };
  }

  T _extractKeyedValue<T>(SettingsKey<T> key) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _pageSort[subKey] as T,
      'pageDisplay' =>
        (_pageDisplay[subKey] ?? const PageDisplaySettings()) as T,
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
  }

  void _applyValue<T>(SettingsKey<T> key, T value) {
    if (identical(key, SettingsKey.global)) {
      _global = value as GlobalSettings;
      return;
    }
    if (identical(key, SettingsKey.allocation)) {
      _allocation = value as AllocationConfig;
      return;
    }
    if (identical(key, SettingsKey.softGates)) {
      _softGates = value as SoftGatesSettings;
      return;
    }

    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;
    switch (name) {
      case 'pageSort':
        final prefs = value as SortPreferences?;
        if (prefs == null) {
          _pageSort.remove(subKey);
        } else {
          _pageSort[subKey] = prefs;
        }
        return;
      case 'pageDisplay':
        _pageDisplay[subKey] = value as PageDisplaySettings;
        return;
      default:
        throw ArgumentError('Unknown keyed key: $name');
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Minimal in-memory fake repository for project operations.
class FakeProjectRepository implements ProjectRepositoryContract {
  FakeProjectRepository();

  final _controller = BehaviorSubject<List<Project>>.seeded([]);
  List<Project> get _last => _controller.value;
  set _last(List<Project> value) => _controller.add(value);

  void pushProjects(List<Project> projects) {
    _controller.add(projects);
  }

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) => _controller.stream;

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) =>
      _controller.stream.map((projects) => projects.length);

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async => _last;

  @override
  Stream<Project?> watchById(String id) => _controller.stream.map((projects) {
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  });

  @override
  Future<Project?> getById(String id) async {
    try {
      return _last.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setPinned({required String id, required bool isPinned}) async {
    final idx = _last.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(isPinned: isPinned, updatedAt: DateTime.now());

    _last = updated;
    _controller.add(_last);
  }

  Future<int> count([ProjectQuery? query]) async => _last.length;

  Stream<int> watchCount([ProjectQuery? query]) =>
      _controller.stream.map((projects) => projects.length);

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
  }) async {
    final now = DateTime.now();
    final id = 'gen-${now.microsecondsSinceEpoch}';
    final newProject = Project(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
    );
    _last = [..._last, newProject];
    _controller.add(_last);
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    bool? isPinned,
  }) async {
    final idx = _last.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = Project(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      values: old.values,
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    final idx = _last.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    // Project.copyWith doesn't include lastReviewedAt, so construct manually
    updated[idx] = Project(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: old.name,
      completed: old.completed,
      description: old.description,
      startDate: old.startDate,
      deadlineDate: old.deadlineDate,
      priority: old.priority,
      lastReviewedAt: reviewedAt,
      repeatIcalRrule: old.repeatIcalRrule,
      repeatFromCompletion: old.repeatFromCompletion,
      seriesEnded: old.seriesEnded,
      values: old.values,
      occurrence: old.occurrence,
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id) async {
    _last = _last.where((p) => p.id != id).toList();
    _controller.add(_last);
  }

  // Occurrence methods - stubs
  @override
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async => _last;

  @override
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) => _controller.stream;

  @override
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) async {}

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  }) async {}

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) async {}

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
  }) async {}

  Future<List<Project>> getProjectsByIds(List<String> ids) async =>
      _last.where((p) => ids.contains(p.id)).toList();

  Future<List<Project>> getProjectsByValue(String valueId) async =>
      _last.where((p) => p.values.any((v) => v.id == valueId)).toList();

  void dispose() {
    _controller.close();
  }
}

/// Minimal in-memory fake repository for value operations.
class FakeValueRepository implements ValueRepositoryContract {
  FakeValueRepository();

  final _controller = BehaviorSubject<List<Value>>.seeded([]);
  List<Value> get _last => _controller.value;
  set _last(List<Value> value) => _controller.add(value);

  void pushValues(List<Value> values) {
    _controller.add(values);
  }

  @override
  Stream<List<Value>> watchAll([ValueQuery? query]) => _controller.stream;

  @override
  Future<List<Value>> getAll([ValueQuery? query]) async => _last;

  @override
  Stream<Value?> watchById(String id) => _controller.stream.map((values) {
    try {
      return values.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  });

  @override
  Future<Value?> getById(String id) async {
    try {
      return _last.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
  }) async {
    final now = DateTime.now();
    final id = 'gen-${now.microsecondsSinceEpoch}';
    final newValue = Value(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
      color: color,
      iconName: iconName,
      priority: priority,
    );
    _last = [..._last, newValue];
    _controller.add(_last);
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
  }) async {
    final idx = _last.indexWhere((v) => v.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = Value(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: name,
      color: color,
      iconName: iconName,
      priority: priority ?? old.priority,
      lastReviewedAt: old.lastReviewedAt,
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    final idx = _last.indexWhere((v) => v.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(
      lastReviewedAt: reviewedAt,
      updatedAt: DateTime.now(),
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id) async {
    _last = _last.where((v) => v.id != id).toList();
    _controller.add(_last);
  }

  @override
  Future<void> addValueToTask({
    required String taskId,
    required String valueId,
  }) async {}

  @override
  Future<void> removeValueFromTask({
    required String taskId,
    required String valueId,
  }) async {}

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) async =>
      _last.where((v) => ids.contains(v.id)).toList();

  void dispose() {
    _controller.close();
  }
}

/// Minimal in-memory fake repository for workflow operations.
class FakeWorkflowRepository implements WorkflowRepositoryContract {
  FakeWorkflowRepository();

  final _definitionsController =
      BehaviorSubject<List<WorkflowDefinition>>.seeded([]);
  final _workflowControllers = <String, BehaviorSubject<Workflow>>{};
  final _activeWorkflowsController = BehaviorSubject<List<Workflow>>.seeded([]);

  List<WorkflowDefinition> get _definitions => _definitionsController.value;
  set _definitions(List<WorkflowDefinition> value) =>
      _definitionsController.add(value);

  List<Workflow> _workflows = [];

  // === Test Helpers ===

  void pushWorkflowDefinitions(List<WorkflowDefinition> definitions) {
    _definitionsController.add(definitions);
  }

  void pushWorkflows(List<Workflow> workflows) {
    _workflows = workflows;
    _activeWorkflowsController.add(
      workflows.where((w) => w.status == WorkflowStatus.inProgress).toList(),
    );
    // Also update individual workflow controllers
    for (final workflow in workflows) {
      _workflowControllers.putIfAbsent(
        workflow.id,
        () => BehaviorSubject<Workflow>.seeded(workflow),
      );
      _workflowControllers[workflow.id]!.add(workflow);
    }
  }

  // === Workflow Definitions ===

  @override
  Future<WorkflowDefinition> createWorkflowDefinition(
    WorkflowDefinition definition,
  ) async {
    final id = definition.id.isEmpty
        ? 'workflow-def-${DateTime.now().microsecondsSinceEpoch}'
        : definition.id;
    final created = definition.id.isEmpty
        ? WorkflowDefinition(
            id: id,
            name: definition.name,
            steps: definition.steps,
            createdAt: definition.createdAt,
            updatedAt: definition.updatedAt,
            triggerConfig: definition.triggerConfig,
            lastCompletedAt: definition.lastCompletedAt,
            description: definition.description,
            iconName: definition.iconName,
            isSystem: definition.isSystem,
            isActive: definition.isActive,
          )
        : definition;
    _definitions = [..._definitions, created];
    _definitionsController.add(_definitions);
    return created;
  }

  @override
  Future<void> updateWorkflowDefinition(WorkflowDefinition definition) async {
    final idx = _definitions.indexWhere((d) => d.id == definition.id);
    if (idx == -1) return;

    final updated = [..._definitions];
    updated[idx] = definition;
    _definitions = updated;
    _definitionsController.add(_definitions);
  }

  @override
  Future<void> deleteWorkflowDefinition(String id) async {
    _definitions = _definitions.where((d) => d.id != id).toList();
    _definitionsController.add(_definitions);
  }

  @override
  Future<WorkflowDefinition?> getWorkflowDefinition(String id) async {
    try {
      return _definitions.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WorkflowDefinition>> getAllWorkflowDefinitions() async {
    return _definitions;
  }

  @override
  Stream<List<WorkflowDefinition>> watchWorkflowDefinitions() {
    return _definitionsController.stream;
  }

  // === Workflow Instances ===

  @override
  Future<Workflow> createWorkflow(Workflow workflow) async {
    final id = workflow.id.isEmpty
        ? 'workflow-${DateTime.now().microsecondsSinceEpoch}'
        : workflow.id;
    final created = workflow.id.isEmpty
        ? Workflow(
            id: id,
            workflowDefinitionId: workflow.workflowDefinitionId,
            status: workflow.status,
            stepStates: workflow.stepStates,
            createdAt: workflow.createdAt,
            updatedAt: workflow.updatedAt,
            completedAt: workflow.completedAt,
            currentStepIndex: workflow.currentStepIndex,
          )
        : workflow;
    _workflows = [..._workflows, created];
    _activeWorkflowsController.add(
      _workflows.where((w) => w.status == WorkflowStatus.inProgress).toList(),
    );
    return created;
  }

  @override
  Future<void> updateWorkflow(Workflow workflow) async {
    final idx = _workflows.indexWhere((w) => w.id == workflow.id);
    if (idx == -1) return;

    final updated = [..._workflows];
    updated[idx] = workflow;
    _workflows = updated;

    // Update individual workflow stream
    _workflowControllers[workflow.id]?.add(workflow);

    // Update active workflows stream
    _activeWorkflowsController.add(
      _workflows.where((w) => w.status == WorkflowStatus.inProgress).toList(),
    );
  }

  @override
  Future<void> deleteWorkflow(String id) async {
    _workflows = _workflows.where((w) => w.id != id).toList();
    _activeWorkflowsController.add(
      _workflows.where((w) => w.status == WorkflowStatus.inProgress).toList(),
    );
  }

  @override
  Future<Workflow?> getWorkflow(String id) async {
    try {
      return _workflows.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Workflow> watchWorkflow(String id) {
    _workflowControllers.putIfAbsent(
      id,
      BehaviorSubject<Workflow>.new,
    );
    return _workflowControllers[id]!.stream;
  }

  @override
  Stream<List<Workflow>> watchActiveWorkflows() {
    return _activeWorkflowsController.stream;
  }

  @override
  Future<List<Workflow>> getWorkflowsByDefinition(String definitionId) async {
    return _workflows
        .where((w) => w.workflowDefinitionId == definitionId)
        .toList();
  }

  void dispose() {
    _definitionsController.close();
    _activeWorkflowsController.close();
    for (final controller in _workflowControllers.values) {
      controller.close();
    }
  }
}
