import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
// removed unused direct import; test uses createTestDb from helpers
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/features/settings/settings.dart';

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
  Stream<AppSettings> watch() => _controller.stream;

  @override
  Future<AppSettings> load() async => _current;

  @override
  Future<void> save(AppSettings settings) async {
    _current = settings;
    _controller.add(settings);
  }
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
    final settingsBloc = SettingsBloc(settingsRepository: settingsRepository);
    addTearDown(settingsBloc.close);

    await pumpLocalizedApp(
      tester,
      home: BlocProvider.value(
        value: settingsBloc,
        child: TaskOverviewPage(
          taskRepository: repo,
          projectRepository: projectRepo,
          labelRepository: labelRepo,
        ),
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
    final settingsBloc = SettingsBloc(settingsRepository: settingsRepository);
    addTearDown(settingsBloc.close);

    await pumpLocalizedApp(
      tester,
      home: BlocProvider.value(
        value: settingsBloc,
        child: TaskOverviewPage(
          taskRepository: repo,
          projectRepository: projectRepo,
          labelRepository: labelRepo,
        ),
      ),
    );
    await tester.pump();

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Enter name and submit — locate text fields inside the FormBuilder
    final textFields = find.descendant(
      of: find.byType(FormBuilder),
      matching: find.byType(TextField),
    );
    await tester.enterText(textFields.at(0), 'New UI Task');
    await tester.enterText(textFields.at(1), 'desc');
    await tester.tap(find.byTooltip('Create'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

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
    final settingsBloc = SettingsBloc(settingsRepository: settingsRepository);
    addTearDown(settingsBloc.close);

    await pumpLocalizedApp(
      tester,
      home: BlocProvider.value(
        value: settingsBloc,
        child: TaskOverviewPage(
          taskRepository: repo,
          projectRepository: projectRepo,
          labelRepository: labelRepo,
        ),
      ),
    );
    await tester.pump();
    repo.pushTasks([sample]);
    await tester.pump();

    // Open detail sheet
    await tester.tap(find.byKey(const Key('task-t-update-1')));
    await tester.pumpAndSettle();

    // Change name and press update
    final textFields2 = find.descendant(
      of: find.byType(FormBuilder),
      matching: find.byType(TextField),
    );
    await tester.enterText(textFields2.at(0), 'Updated UI');

    repo.updateCalled = Completer<void>();
    await tester.tap(find.byTooltip('Update'));
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
