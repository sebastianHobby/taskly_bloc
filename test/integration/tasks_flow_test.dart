import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
// removed unused direct import; test uses createTestDb from helpers
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_db.dart';

// Minimal in-test fake repository to avoid external test helper dependency.
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
  Stream<List<Task>> watchAll({bool withRelated = false}) => _controller.stream;

  @override
  Future<List<Task>> getAll({bool withRelated = false}) async => _last;

  @override
  Stream<Task?> watch(String id, {bool withRelated = false}) =>
      _controller.stream.map((rows) {
        try {
          return rows.firstWhere((r) => r.id == id);
        } catch (_) {
          return null;
        }
      });

  @override
  Future<Task?> get(String id, {bool withRelated = false}) async {
    try {
      return _last.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
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
    String? repeatIcalRrule,
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

  @override
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
}

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
  Stream<SortPreferences?> watchPageSort(String pageKey) async* {
    yield _current.sortFor(pageKey);
    yield* _controller.stream
        .map((settings) => settings.sortFor(pageKey))
        .distinct();
  }

  @override
  Future<SortPreferences?> loadPageSort(String pageKey) async {
    return _current.sortFor(pageKey);
  }

  @override
  Future<void> savePageSort(String pageKey, SortPreferences preferences) async {
    _current = _current.upsertPageSort(
      pageKey: pageKey,
      preferences: preferences,
    );
    _controller.add(_current);
  }

  @override
  Stream<PageDisplaySettings> watchPageDisplaySettings(String pageKey) async* {
    yield _current.displaySettingsFor(pageKey);
    yield* _controller.stream
        .map((settings) => settings.displaySettingsFor(pageKey))
        .distinct();
  }

  @override
  Future<PageDisplaySettings> loadPageDisplaySettings(String pageKey) async {
    return _current.displaySettingsFor(pageKey);
  }

  @override
  Future<void> savePageDisplaySettings(
    String pageKey,
    PageDisplaySettings settings,
  ) async {
    _current = _current.upsertPageDisplaySettings(
      pageKey: pageKey,
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
}

void main() {
  testWidgets('tasks flow: display, toggle, open detail and create sheets', (
    tester,
  ) async {
    final repo = FakeTaskRepository();

    final now = DateTime.now();
    final sample = Task(
      id: 't-int-1',
      createdAt: now,
      updatedAt: now,
      name: 'Integration Task',
      completed: false,
    );

    final db = createTestDb();
    final projectRepo = ProjectRepository(driftDb: db);
    final labelRepo = LabelRepository(driftDb: db);
    final settingsRepository = FakeSettingsRepository();
    final sortAdapter = PageSortAdapter(
      settingsRepository: settingsRepository,
      pageKey: 'tasks',
    );

    await pumpLocalizedApp(
      tester,
      home: TaskOverviewPage(
        taskRepository: repo,
        projectRepository: projectRepo,
        labelRepository: labelRepo,
        sortAdapter: sortAdapter,
      ),
    );
    // push tasks after widget builds so the bloc subscription receives the value
    // from the broadcast stream.
    repo.pushTasks([sample]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Task is displayed
    expect(find.byKey(const Key('task-t-int-1')), findsOneWidget);

    // Toggle completion via the checkbox (should call repository.updateTask)
    repo.updateCalled = Completer<void>();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await repo.updateCalled!.future;
    expect(repo.updateCalled!.isCompleted, isTrue);

    // Open detail sheet by tapping the task tile
    await tester.tap(find.byKey(const Key('task-t-int-1')));
    await tester.pumpAndSettle();
    expect(find.byType(TaskForm), findsOneWidget);

    // Close sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create task'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskForm), findsOneWidget);
  });

  testWidgets('create task via UI updates list', (tester) async {
    final repo = FakeTaskRepository();
    final db = createTestDb();
    final projectRepo = ProjectRepository(driftDb: db);
    final labelRepo = LabelRepository(driftDb: db);
    final settingsRepository = FakeSettingsRepository();
    final sortAdapter = PageSortAdapter(
      settingsRepository: settingsRepository,
      pageKey: 'tasks',
    );

    await pumpLocalizedApp(
      tester,
      home: TaskOverviewPage(
        taskRepository: repo,
        projectRepository: projectRepo,
        labelRepository: labelRepo,
        sortAdapter: sortAdapter,
      ),
    );
    await tester.pump();

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create task'));
    // Use multiple pumps with delay to allow modal animation to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify the TaskForm is visible
    expect(find.byType(TaskForm), findsOneWidget);

    // Enter name and submit — find all text fields in the TaskForm
    final textFields = find.descendant(
      of: find.byType(TaskForm),
      matching: find.byType(TextField),
    );
    expect(textFields, findsWidgets);
    await tester.enterText(textFields.at(0), 'New UI Task');
    await tester.enterText(textFields.at(1), 'desc');
    // Tap the Create Task button
    await tester.tap(find.text('Create Task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The fake repo should have emitted the new task and the list should update
    await tester.pump();
    expect(find.text('New UI Task'), findsOneWidget);
  });

  testWidgets('update task via detail sheet updates list', (tester) async {
    final repo = FakeTaskRepository();
    final now = DateTime.now();
    final sample = Task(
      id: 't-update-1',
      createdAt: now,
      updatedAt: now,
      name: 'To Update',
      completed: false,
    );
    final db = createTestDb();
    final projectRepo = ProjectRepository(driftDb: db);
    final labelRepo = LabelRepository(driftDb: db);
    final settingsRepository = FakeSettingsRepository();
    final sortAdapter = PageSortAdapter(
      settingsRepository: settingsRepository,
      pageKey: 'tasks',
    );

    await pumpLocalizedApp(
      tester,
      home: TaskOverviewPage(
        taskRepository: repo,
        projectRepository: projectRepo,
        labelRepository: labelRepo,
        sortAdapter: sortAdapter,
      ),
    );
    await tester.pump();
    repo.pushTasks([sample]);
    await tester.pump();

    // Open detail sheet
    await tester.tap(find.byKey(const Key('task-t-update-1')));
    await tester.pumpAndSettle();

    // Verify the TaskForm is visible
    expect(find.byType(TaskForm), findsOneWidget);

    // Change name and press update - find text fields in the TaskForm
    final textFields2 = find.descendant(
      of: find.byType(TaskForm),
      matching: find.byType(TextField),
    );
    expect(textFields2, findsWidgets);
    await tester.enterText(textFields2.at(0), 'Updated UI');

    repo.updateCalled = Completer<void>();
    // Tap the Save Changes button (in the sticky footer)
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await repo.updateCalled!.future;

    final updatedTask = await repo.get(sample.id);
    expect(updatedTask?.name, 'Updated UI');

    // Dismiss the sheet if still open, then settle animations.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      if (find.text('Updated UI').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Verify list updated
    expect(find.text('Updated UI'), findsOneWidget);
  });
}
