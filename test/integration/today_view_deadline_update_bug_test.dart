import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';

import '../helpers/test_db.dart';

/// Integration test to reproduce the bug:
/// 1. Task has deadline of today
/// 2. User opens today view - task appears
/// 3. User edits task to change deadline to tomorrow
/// 4. User saves changes
/// 5. Bug: Task stays in today view, deadline is not persisted
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;
  late LabelRepository labelRepo;

  setUp(() {
    db = createTestDb();
    taskRepo = TaskRepository(driftDb: db);
    projectRepo = ProjectRepository(driftDb: db);
    labelRepo = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Bug reproduction: task deadline update from today to tomorrow', () async {
    // Setup: Get today and tomorrow dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    print('Test setup:');
    print('  Today: $today');
    print('  Tomorrow: $tomorrow');

    // Step 1: Create a task with today's deadline
    await taskRepo.create(
      name: 'Test Task with Today Deadline',
      deadlineDate: today,
    );
    print('\n1. Created task with today deadline');

    // Verify task was created
    var allTasks = await taskRepo.getAll();
    expect(allTasks, hasLength(1));
    final taskId = allTasks.first.id;
    print('   Task ID: $taskId');
    print('   Initial deadline: ${allTasks.first.deadlineDate}');

    // Step 2: Verify task appears in "today" filter
    // Tasks with deadline today or earlier should appear
    final tasksForToday = allTasks.where((t) {
      final deadline = t.deadlineDate;
      return deadline != null && !deadline.isAfter(today);
    }).toList();

    expect(tasksForToday, hasLength(1));
    print('\n2. Verified task appears in today view');

    // Step 3: Update task deadline to tomorrow (simulating user edit)
    final taskToUpdate = allTasks.first;
    await taskRepo.update(
      id: taskToUpdate.id,
      name: taskToUpdate.name,
      completed: taskToUpdate.completed,
      description: taskToUpdate.description,
      startDate: taskToUpdate.startDate,
      deadlineDate: tomorrow, // Changed from today to tomorrow
      projectId: taskToUpdate.project?.id,
      repeatIcalRrule: taskToUpdate.repeatIcalRrule,
      labelIds: taskToUpdate.labels.map((l) => l.id).toList(),
    );
    print('\n3. Updated task deadline to tomorrow');

    // Step 4: Verify the update was persisted in database
    final updatedTask = await taskRepo.get(taskId, withRelated: true);
    print('\n4. Checking if update was persisted:');
    print('   Updated deadline in DB: ${updatedTask?.deadlineDate}');
    print('   Expected deadline: $tomorrow');

    expect(updatedTask, isNotNull, reason: 'Task should still exist');
    expect(
      updatedTask!.deadlineDate,
      equals(tomorrow),
      reason: 'Deadline should be updated to tomorrow in database',
    );

    // Step 5: Verify task no longer appears in "today" filter
    allTasks = await taskRepo.getAll();
    final tasksForTodayAfterUpdate = allTasks.where((t) {
      final deadline = t.deadlineDate;
      return deadline != null && !deadline.isAfter(today);
    }).toList();

    print('\n5. Checking today view after update:');
    print('   Tasks in today view: ${tasksForTodayAfterUpdate.length}');

    expect(
      tasksForTodayAfterUpdate,
      isEmpty,
      reason:
          'Task should NOT appear in today view after deadline changed to tomorrow',
    );

    // Step 6: Verify task appears in "tomorrow" filter
    final tasksForTomorrow = allTasks.where((t) {
      final deadline = t.deadlineDate;
      if (deadline == null) return false;
      final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
      return deadlineDay == tomorrow;
    }).toList();

    print('\n6. Checking if task appears in tomorrow filter:');
    print('   Tasks with tomorrow deadline: ${tasksForTomorrow.length}');

    expect(
      tasksForTomorrow,
      hasLength(1),
      reason: 'Task should appear when filtering for tomorrow',
    );

    print('\n✅ Test passed - bug is fixed!');
  });

  test(
    'Bug reproduction: verify repository stream emits updated task',
    () async {
      // This test verifies that the watchAll stream emits the updated task
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      print('\nStream emission test:');

      // Create a task with today's deadline
      await taskRepo.create(
        name: 'Stream Test Task',
        deadlineDate: today,
      );

      // Get the task ID
      final tasks = await taskRepo.getAll();
      final taskId = tasks.first.id;
      print('  Created task: $taskId with deadline: $today');

      // Set up stream listener
      final streamEvents = <List<DateTime?>>[];
      final subscription = taskRepo.watchAll().listen((taskList) {
        final deadlines = taskList.map((t) => t.deadlineDate).toList();
        streamEvents.add(deadlines);
        print('  Stream event: deadlines = $deadlines');
      });

      // Wait for initial stream event
      await Future.delayed(const Duration(milliseconds: 100));
      expect(
        streamEvents,
        isNotEmpty,
        reason: 'Should have initial stream event',
      );

      // Update the task
      final task = tasks.first;
      await taskRepo.update(
        id: task.id,
        name: task.name,
        completed: task.completed,
        description: task.description,
        startDate: task.startDate,
        deadlineDate: tomorrow,
        projectId: task.project?.id,
        repeatIcalRrule: task.repeatIcalRrule,
        labelIds: task.labels.map((l) => l.id).toList(),
      );
      print('  Updated task deadline to: $tomorrow');

      // Wait for stream to emit updated data
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify stream emitted at least 2 events (initial + update)
      expect(
        streamEvents.length,
        greaterThanOrEqualTo(2),
        reason: 'Stream should emit updated task after update',
      );

      // Verify the latest event has the updated deadline
      final latestDeadlines = streamEvents.last;
      expect(latestDeadlines, hasLength(1));
      expect(
        latestDeadlines.first,
        equals(tomorrow),
        reason: 'Stream should emit task with updated deadline',
      );

      await subscription.cancel();
      print('  ✅ Stream correctly emitted updated task');
    },
  );

  test('Bug reproduction: multiple updates in sequence', () async {
    // Test that multiple rapid updates all persist correctly
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    print('\nMultiple updates test:');

    // Create task
    await taskRepo.create(
      name: 'Multi-Update Task',
      deadlineDate: today,
    );

    final tasks = await taskRepo.getAll();
    final taskId = tasks.first.id;
    print('  Created task: $taskId');

    // Update 1: Change to tomorrow
    await taskRepo.update(
      id: taskId,
      name: 'Multi-Update Task',
      completed: false,
      deadlineDate: tomorrow,
    );
    print('  Update 1: Changed deadline to tomorrow');

    var task = await taskRepo.get(taskId);
    expect(task?.deadlineDate, equals(tomorrow));

    // Update 2: Change to day after tomorrow
    await taskRepo.update(
      id: taskId,
      name: 'Multi-Update Task',
      completed: false,
      deadlineDate: dayAfterTomorrow,
    );
    print('  Update 2: Changed deadline to day after tomorrow');

    task = await taskRepo.get(taskId);
    expect(task?.deadlineDate, equals(dayAfterTomorrow));

    // Update 3: Remove deadline
    await taskRepo.update(
      id: taskId,
      name: 'Multi-Update Task',
      completed: false,
    );
    print('  Update 3: Removed deadline');

    task = await taskRepo.get(taskId);
    expect(task?.deadlineDate, isNull);

    print('  ✅ All updates persisted correctly');
  });
}
