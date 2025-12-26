import 'dart:async';

import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Shared fake implementations for integration tests.
///
/// These fakes provide in-memory implementations with simpler logic
/// than full repositories, making integration tests faster and more maintainable.

/// Minimal in-memory fake repository for task operations.
class FakeTaskRepository implements TaskRepositoryContract {
  FakeTaskRepository();

  final _controller = StreamController<List<Task>>.broadcast();
  Completer<void>? updateCalled;
  List<Task> _last = [];

  void pushTasks(List<Task> tasks) {
    _last = tasks;
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
      repeatIcalRrule: repeatIcalRrule,
      labels: old.labels,
    );

    _last = updated;
    _controller.add(_last);
    updateCalled?.complete();
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

  @override
  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  }) async {}

  @override
  Future<void> stopSeries(String taskId) async {}

  @override
  Future<void> completeSeries(String taskId) async {}

  @override
  Future<void> convertToOneTime(String taskId) async {}

  @override
  Future<int> count([TaskQuery? query]) async => _last.length;

  @override
  Stream<int> watchCount([TaskQuery? query]) =>
      _controller.stream.map((tasks) => tasks.length);

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
  Stream<NextActionsSettings> watchNextActionsSettings() async* {
    yield _current.nextActions;
    yield* _controller.stream
        .map((settings) => settings.nextActions)
        .distinct();
  }

  @override
  Future<NextActionsSettings> loadNextActionsSettings() async {
    return _current.nextActions;
  }

  @override
  Future<void> saveNextActionsSettings(NextActionsSettings settings) async {
    _current = _current.updateNextActions(settings);
    _controller.add(_current);
  }

  @override
  Stream<SortPreferences?> watchPageSort(PageKey pageKey) async* {
    yield _current.sortFor(pageKey.key);
    yield* _controller.stream
        .map((settings) => settings.sortFor(pageKey.key))
        .distinct();
  }

  @override
  Future<SortPreferences?> loadPageSort(PageKey pageKey) async {
    return _current.sortFor(pageKey.key);
  }

  @override
  Future<void> savePageSort(
    PageKey pageKey,
    SortPreferences preferences,
  ) async {
    _current = _current.upsertPageSort(
      pageKey: pageKey.key,
      preferences: preferences,
    );
    _controller.add(_current);
  }

  @override
  Stream<PageDisplaySettings> watchPageDisplaySettings(PageKey pageKey) async* {
    yield _current.displaySettingsFor(pageKey.key);
    yield* _controller.stream
        .map((settings) => settings.displaySettingsFor(pageKey.key))
        .distinct();
  }

  @override
  Future<PageDisplaySettings> loadPageDisplaySettings(PageKey pageKey) async {
    return _current.displaySettingsFor(pageKey.key);
  }

  @override
  Future<void> savePageDisplaySettings(
    PageKey pageKey,
    PageDisplaySettings settings,
  ) async {
    _current = _current.upsertPageDisplaySettings(
      pageKey: pageKey.key,
      settings: settings,
    );
    _controller.add(_current);
  }

  @override
  Stream<AppSettings> watchAll() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppSettings> loadAll() async => _current;

  void dispose() {
    _controller.close();
  }
}
