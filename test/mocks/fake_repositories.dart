import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// Shared fake implementations for integration tests.
///
/// These fakes provide in-memory implementations with simpler logic
/// than full repositories, making integration tests faster and more maintainable.

/// Minimal in-memory fake repository for task operations.
import 'package:taskly_domain/taskly_domain.dart';

DateTime _defaultNow() => DateTime(2025, 1, 15, 12);

class FakeTaskRepository implements TaskRepositoryContract {
  FakeTaskRepository({DateTime Function()? now}) : _now = now ?? _defaultNow;

  static int _idCounter = 0;
  final DateTime Function() _now;

  final _controller = BehaviorSubject<List<Task>>.seeded([]);
  Completer<void>? updateCalled;
  List<Task> get _last => _controller.value;
  set _last(List<Task> value) => _controller.add(value);

  void pushTasks(List<Task> tasks) {
    _controller.add(tasks);
  }

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() {
    return const Stream<List<CompletionHistoryData>>.empty().startWith(
      const <CompletionHistoryData>[],
    );
  }

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() {
    return const Stream<List<RecurrenceExceptionData>>.empty().startWith(
      const <RecurrenceExceptionData>[],
    );
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
  Future<List<Task>> getByIds(Iterable<String> ids) async {
    final idList = ids.toList(growable: false);
    final byId = <String, Task>{for (final t in _last) t.id: t};
    return [
      for (final id in idList)
        if (byId[id] != null) byId[id]!,
    ];
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
  Stream<List<Task>> watchByIds(Iterable<String> ids) {
    final idList = ids.toList(growable: false);
    return _controller.stream.map((rows) {
      final byId = <String, Task>{for (final t in rows) t.id: t};
      return [
        for (final id in idList)
          if (byId[id] != null) byId[id]!,
      ];
    });
  }

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
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    OperationContext? context,
  }) async {
    final idx = _last.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(
      updatedAt: _now(),
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? old.repeatFromCompletion,
      seriesEnded: seriesEnded ?? old.seriesEnded,
      isPinned: isPinned ?? old.isPinned,
    );

    _last = updated;
    _controller.add(_last);
    updateCalled?.complete();
  }

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async {
    final idx = _last.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(isPinned: isPinned, updatedAt: _now());

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
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    final now = _now();
    final id = 'gen-task-${_idCounter++}';
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
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
    );
    _last = [..._last, newTask];
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
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
  Future<List<Task>> getOccurrencesForTask({
    required String taskId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    return _last.where((t) => t.id == taskId).toList(growable: false);
  }

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
    OperationContext? context,
  }) async {}

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    OperationContext? context,
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
    Map<String, SortPreferences> pageSort = const <String, SortPreferences>{},
  }) : _global = global,
       _allocation = allocation,
       _pageSort = Map<String, SortPreferences>.from(pageSort);

  final _controller = StreamController<void>.broadcast();
  GlobalSettings _global;
  AllocationConfig _allocation;
  final Map<String, SortPreferences> _pageSort;

  @override
  Stream<T> watch<T>(SettingsKey<T> key) async* {
    yield _extractValue(key);
    yield* _controller.stream.map((_) => _extractValue(key)).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async => _extractValue(key);

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {
    _applyValue(key, value);
    _controller.add(null);
  }

  T _extractValue<T>(SettingsKey<T> key) {
    return switch (key) {
      SettingsKey.global => _global as T,
      SettingsKey.allocation => _allocation as T,
      _ => _extractKeyedValue(key),
    };
  }

  T _extractKeyedValue<T>(SettingsKey<T> key) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _pageSort[subKey] as T,
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
  FakeProjectRepository({DateTime Function()? now}) : _now = now ?? _defaultNow;

  static int _idCounter = 0;
  final DateTime Function() _now;

  final _controller = BehaviorSubject<List<Project>>.seeded([]);
  List<Project> get _last => _controller.value;
  set _last(List<Project> value) => _controller.add(value);

  void pushProjects(List<Project> projects) {
    _controller.add(projects);
  }

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() {
    return const Stream<List<CompletionHistoryData>>.empty().startWith(
      const <CompletionHistoryData>[],
    );
  }

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() {
    return const Stream<List<RecurrenceExceptionData>>.empty().startWith(
      const <RecurrenceExceptionData>[],
    );
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
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async {
    final idx = _last.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(isPinned: isPinned, updatedAt: _now());

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
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    final now = _now();
    final id = 'gen-project-${_idCounter++}';
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
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
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
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    OperationContext? context,
  }) async {
    final idx = _last.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(
      updatedAt: _now(),
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? old.repeatFromCompletion,
      seriesEnded: seriesEnded ?? old.seriesEnded,
      isPinned: isPinned ?? old.isPinned,
    );

    _last = updated;
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
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
  Future<List<Project>> getOccurrencesForProject({
    required String projectId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    return _last.where((p) => p.id == projectId).toList(growable: false);
  }

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
    OperationContext? context,
  }) async {}

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    OperationContext? context,
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
  FakeValueRepository({DateTime Function()? now}) : _now = now ?? _defaultNow;

  static int _idCounter = 0;
  final DateTime Function() _now;

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
    OperationContext? context,
  }) async {
    final now = _now();
    final id = 'gen-value-${_idCounter++}';
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
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    String? iconName,
    ValuePriority? priority,
    OperationContext? context,
  }) async {
    final idx = _last.indexWhere((v) => v.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    final updated = [..._last];
    updated[idx] = old.copyWith(
      updatedAt: _now(),
      name: name,
      color: color,
      iconName: iconName,
      priority: priority ?? old.priority,
    );

    _last = updated;
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    _last = _last.where((v) => v.id != id).toList();
  }

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) async =>
      _last.where((v) => ids.contains(v.id)).toList();

  void dispose() {
    _controller.close();
  }
}
