import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
// removed unused direct import; test uses createTestDb from helpers
import 'package:taskly_bloc/features/tasks/view/task_overview_page.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_form.dart';

import '../helpers/test_db.dart';

// Minimal in-test fake repository to avoid external test helper dependency.
class FakeTaskRepository extends TaskRepository {
  FakeTaskRepository() : super(driftDb: createTestDb());

  final _controller = StreamController<List<TaskTableData>>.broadcast();
  Completer<void>? updateCalled;
  List<TaskTableData> _last = [];

  void pushTasks(List<TaskTableData> tasks) {
    _last = tasks;
    _controller.add(tasks);
  }

  @override
  Stream<List<TaskTableData>> get getTasks => _controller.stream;

  @override
  @override
  Future<TaskTableData?> getTaskById(String id) async {
    try {
      return _last.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> updateTask(TaskTableCompanion updateCompanion) async {
    // apply update to in-memory list if id present
    try {
      final id = updateCompanion.id.value as String?;
      if (id != null) {
        final idx = _last.indexWhere((t) => t.id == id);
        if (idx != -1) {
          final old = _last[idx];
          final updated = TaskTableData(
            id: id,
            createdAt: old.createdAt,
            updatedAt: updateCompanion.updatedAt.present
                ? updateCompanion.updatedAt.value
                : DateTime.now(),
            name: updateCompanion.name.present
                ? updateCompanion.name.value
                : old.name,
            completed: updateCompanion.completed.present
                ? updateCompanion.completed.value
                : old.completed,
            startDate: old.startDate,
            deadlineDate: old.deadlineDate,
            description: updateCompanion.description.present
                ? updateCompanion.description.value
                : old.description,
            projectId: old.projectId,
            userId: old.userId,
            repeatIcalRrule: old.repeatIcalRrule,
          );
          _last[idx] = updated;
          _controller.add(_last);
        }
      }
    } catch (_) {}
    updateCalled?.complete();
    return 1;
  }

  @override
  Future<int> createTask(TaskTableCompanion createCompanion) async {
    final id = createCompanion.id.present
        ? createCompanion.id.value
        : 'gen-${DateTime.now().millisecondsSinceEpoch}';
    final now = createCompanion.createdAt.present
        ? createCompanion.createdAt.value
        : DateTime.now();
    final newTask = TaskTableData(
      id: id,
      createdAt: now,
      updatedAt: createCompanion.updatedAt.present
          ? createCompanion.updatedAt.value
          : now,
      name: createCompanion.name.present ? createCompanion.name.value : '',
      completed:
          createCompanion.completed.present && createCompanion.completed.value,
    );
    _last = [..._last, newTask];
    _controller.add(_last);
    return 1;
  }

  @override
  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    try {
      final id = deleteCompanion.id.value as String?;
      if (id != null) {
        _last.removeWhere((t) => t.id == id);
        _controller.add(_last);
        return 1;
      }
    } catch (_) {}
    return 0;
  }
}

void main() {
  testWidgets('tasks flow: display, toggle, open detail and create sheets', (
    tester,
  ) async {
    final repo = FakeTaskRepository();

    final sample = TaskTableData(
      id: 't-int-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Integration Task',
      completed: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: TaskOverviewPage(taskRepository: repo)),
    );
    // push tasks after widget builds so the bloc subscription receives the value
    // from the broadcast stream.
    repo.pushTasks([sample]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Task is displayed
    expect(find.text('Integration Task'), findsOneWidget);

    // Toggle completion via the checkbox (should call repository.updateTask)
    repo.updateCalled = Completer<void>();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await repo.updateCalled!.future;
    expect(repo.updateCalled!.isCompleted, isTrue);

    // Open detail sheet by tapping the task tile
    await tester.tap(find.text('Integration Task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TaskForm), findsOneWidget);

    // Close sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TaskForm), findsOneWidget);
  });

  testWidgets('create task via UI updates list', (tester) async {
    final repo = FakeTaskRepository();
    await tester.pumpWidget(
      MaterialApp(home: TaskOverviewPage(taskRepository: repo)),
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
    final sample = TaskTableData(
      id: 't-update-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'To Update',
      completed: false,
    );
    await tester.pumpWidget(
      MaterialApp(home: TaskOverviewPage(taskRepository: repo)),
    );
    await tester.pump();
    repo.pushTasks([sample]);
    await tester.pump();

    // Open detail sheet
    await tester.tap(find.text('To Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Change name and press update
    final textFields2 = find.descendant(
      of: find.byType(FormBuilder),
      matching: find.byType(TextField),
    );
    await tester.enterText(textFields2.at(0), 'Updated UI');
    await tester.tap(find.byTooltip('Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify list updated
    await tester.pump();
    expect(find.text('Updated UI'), findsOneWidget);
  });
}
