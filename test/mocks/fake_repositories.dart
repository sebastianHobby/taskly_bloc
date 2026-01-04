import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

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
    List<String>? labelIds,
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
      labels: old.labels,
    );

    _last = updated;
    _controller.add(_last);
    updateCalled?.complete();
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
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? labelIds,
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

  @override
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
    DateTime? newDeadline,
  }) async {}

  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  }) async {}

  Future<void> stopSeries(String taskId) async {}

  Future<void> completeSeries(String taskId) async {}

  Future<void> convertToOneTime(String taskId) async {}

  @override
  Future<int> count([TaskQuery? query]) async => _last.length;

  @override
  Stream<int> watchCount([TaskQuery? query]) =>
      _controller.stream.map((tasks) => tasks.length);

  @override
  Future<List<Task>> queryTasks(TaskQuery query) async => _last;

  @override
  Future<List<Task>> getTasksByIds(List<String> ids) async =>
      _last.where((t) => ids.contains(t.id)).toList();

  @override
  Future<List<Task>> getTasksByProject(String projectId) async =>
      _last.where((t) => t.projectId == projectId).toList();

  @override
  Future<List<Task>> getTasksByLabel(String labelId) async =>
      _last.where((t) => t.labels.any((l) => l.id == labelId)).toList();

  void dispose() {
    _controller.close();
  }
}

/// Fake settings repository for integration tests.
class FakeSettingsRepository implements SettingsRepositoryContract {
  FakeSettingsRepository({AppSettings initial = const AppSettings()})
    : _current = initial;

  final _controller = StreamController<AppSettings>.broadcast();
  AppSettings _current;

  @override
  Stream<T> watch<T>(SettingsKey<T> key) async* {
    yield _extractValue(key);
    yield* _controller.stream.map((_) => _extractValue(key)).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async => _extractValue(key);

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    _current = _applyValue(key, value);
    _controller.add(_current);
  }

  T _extractValue<T>(SettingsKey<T> key) {
    return switch (key) {
      SettingsKey.global => _current.global as T,
      SettingsKey.allocation => _current.allocation as T,
      SettingsKey.softGates => _current.softGates as T,
      SettingsKey.nextActions => _current.nextActions as T,
      SettingsKey.valueRanking => _current.valueRanking as T,
      SettingsKey.allScreenPrefs => _current.screenPreferences as T,
      SettingsKey.all => _current as T,
      _ => _extractKeyedValue(key),
    };
  }

  T _extractKeyedValue<T>(SettingsKey<T> key) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _current.sortFor(subKey) as T,
      'pageDisplay' => _current.displaySettingsFor(subKey) as T,
      'screenPrefs' => _current.screenPreferencesFor(subKey) as T,
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
  }

  AppSettings _applyValue<T>(SettingsKey<T> key, T value) {
    return switch (key) {
      SettingsKey.global => _current.updateGlobal(value as GlobalSettings),
      SettingsKey.allocation => _current.updateAllocation(
        value as AllocationConfig,
      ),
      SettingsKey.softGates => _current.updateSoftGates(
        value as SoftGatesSettings,
      ),
      SettingsKey.nextActions => _current.updateNextActions(
        value as NextActionsSettings,
      ),
      SettingsKey.valueRanking => _current.updateValueRanking(
        value as ValueRanking,
      ),
      SettingsKey.allScreenPrefs => _current.copyWith(
        screenPreferences: value as Map<String, ScreenPreferences>,
      ),
      SettingsKey.all => value as AppSettings,
      _ => _applyKeyedValue(key, value),
    };
  }

  AppSettings _applyKeyedValue<T>(SettingsKey<T> key, T value) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _current.upsertPageSort(
        pageKey: subKey,
        preferences: value as SortPreferences,
      ),
      'pageDisplay' => _current.upsertPageDisplaySettings(
        pageKey: subKey,
        settings: value as PageDisplaySettings,
      ),
      'screenPrefs' => _current.upsertScreenPreferences(
        screenKey: subKey,
        preferences: value as ScreenPreferences,
      ),
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
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
  Future<int> count([ProjectQuery? query]) async => _last.length;

  @override
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
    List<String>? labelIds,
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
    List<String>? labelIds,
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
      labels: old.labels,
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
    DateTime? newDeadline,
  }) async {}

  @override
  Future<List<Project>> getProjectsByIds(List<String> ids) async =>
      _last.where((p) => ids.contains(p.id)).toList();

  @override
  Future<List<Project>> getProjectsByLabel(String labelId) async =>
      _last.where((p) => p.labels.any((l) => l.id == labelId)).toList();

  void dispose() {
    _controller.close();
  }
}

/// Minimal in-memory fake repository for label operations.
class FakeLabelRepository implements LabelRepositoryContract {
  FakeLabelRepository();

  final _controller = BehaviorSubject<List<Label>>.seeded([]);
  List<Label> get _last => _controller.value;
  set _last(List<Label> value) => _controller.add(value);

  void pushLabels(List<Label> labels) {
    _controller.add(labels);
  }

  @override
  Stream<List<Label>> watchAll([LabelQuery? query]) => _controller.stream;

  @override
  Future<List<Label>> getAll([LabelQuery? query]) async => _last;

  @override
  Stream<List<Label>> watchByType(LabelType type) => _controller.stream.map(
    (labels) => labels.where((l) => l.type == type).toList(),
  );

  @override
  Future<List<Label>> getAllByType(
    LabelType type,
  ) async => _last.where((l) => l.type == type).toList();

  @override
  Stream<Label?> watchById(String id) => _controller.stream.map((labels) {
    try {
      return labels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  });

  @override
  Future<Label?> getById(String id) async {
    try {
      return _last.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Label?> getSystemLabel(SystemLabelType type) async {
    try {
      return _last.firstWhere(
        (l) => l.isSystemLabel && l.systemLabelType == type,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Label> getOrCreateSystemLabel(SystemLabelType type) async {
    final existing = await getSystemLabel(type);
    if (existing != null) return existing;

    final now = DateTime.now();
    final label = Label(
      id: 'system-${type.name}',
      createdAt: now,
      updatedAt: now,
      name: type.name,
      isSystemLabel: true,
      systemLabelType: type,
    );
    _last = [..._last, label];
    _controller.add(_last);
    return label;
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  }) async {
    final now = DateTime.now();
    final id = 'gen-${now.microsecondsSinceEpoch}';
    final newLabel = Label(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
      color: color,
      type: type,
      iconName: iconName,
    );
    _last = [..._last, newLabel];
    _controller.add(_last);
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  }) async {
    final idx = _last.indexWhere((l) => l.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = Label(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: name,
      color: color,
      type: type,
      iconName: iconName,
      isSystemLabel: old.isSystemLabel,
      systemLabelType: old.systemLabelType,
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    final idx = _last.indexWhere((l) => l.id == id);
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
    _last = _last.where((l) => l.id != id).toList();
    _controller.add(_last);
  }

  @override
  Future<void> addLabelToTask({
    required String taskId,
    required String labelId,
  }) async {}

  @override
  Future<void> removeLabelFromTask({
    required String taskId,
    required String labelId,
  }) async {}

  @override
  Future<List<Label>> getLabelsByIds(List<String> ids) async =>
      _last.where((l) => ids.contains(l.id)).toList();

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
