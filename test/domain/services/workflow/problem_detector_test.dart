import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector.dart';

void main() {
  group('ProblemDetector.detectForWorkflowRun', () {
    const detector = ProblemDetector();

    Task task({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      bool completed = false,
      DateTime? deadlineDate,
    }) {
      return Task(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completed: completed,
        deadlineDate: deadlineDate,
      );
    }

    test('detects stale tasks within workflow', () {
      final now = DateTime(2025, 1, 31, 12);
      const settings = SoftGatesSettings();

      final stale = task(
        id: 't1',
        name: 'Stale',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 31)),
      );
      final fresh = task(
        id: 't2',
        name: 'Fresh',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );

      final problems = detector.detectForWorkflowRun(
        workflowTasks: [stale, fresh],
        urgentTasksAllOpen: const [],
        settings: settings,
        now: now,
      );

      expect(
        problems.where((p) => p.type == ProblemType.staleTasks).length,
        1,
      );
      expect(
        problems.any(
          (p) => p.type == ProblemType.staleTasks && p.entityId == 't1',
        ),
        true,
      );
    });

    test('does not mark completed tasks as stale', () {
      final now = DateTime(2025, 1, 31, 12);
      const settings = SoftGatesSettings();

      final completedStale = task(
        id: 't1',
        name: 'Completed stale',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 31)),
        completed: true,
      );

      final problems = detector.detectForWorkflowRun(
        workflowTasks: [completedStale],
        urgentTasksAllOpen: const [],
        settings: settings,
        now: now,
      );

      expect(problems.any((p) => p.type == ProblemType.staleTasks), false);
    });

    test('detects urgent tasks excluded from workflow', () {
      final now = DateTime(2025, 1, 31, 12);
      const settings = SoftGatesSettings();

      final inWorkflow = task(
        id: 'w1',
        name: 'In workflow',
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.add(const Duration(days: 3)),
      );
      final urgentOutside = task(
        id: 'u1',
        name: 'Urgent outside',
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.add(const Duration(days: 2)),
      );

      final problems = detector.detectForWorkflowRun(
        workflowTasks: [inWorkflow],
        urgentTasksAllOpen: [inWorkflow, urgentOutside],
        settings: settings,
        now: now,
      );

      expect(
        problems.any(
          (p) => p.type == ProblemType.excludedUrgentTask && p.entityId == 'u1',
        ),
        true,
      );

      expect(
        problems.any(
          (p) => p.type == ProblemType.excludedUrgentTask && p.entityId == 'w1',
        ),
        false,
      );
    });

    test('treats overdue tasks as urgent', () {
      final now = DateTime(2025, 1, 31, 12);
      const settings = SoftGatesSettings();

      final overdueOutside = task(
        id: 'u1',
        name: 'Overdue',
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.subtract(const Duration(days: 1)),
      );

      final problems = detector.detectForWorkflowRun(
        workflowTasks: const [],
        urgentTasksAllOpen: [overdueOutside],
        settings: settings,
        now: now,
      );

      expect(
        problems.any(
          (p) => p.type == ProblemType.excludedUrgentTask && p.entityId == 'u1',
        ),
        true,
      );
    });
  });
}
