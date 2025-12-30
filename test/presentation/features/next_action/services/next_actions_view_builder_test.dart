import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/presentation/features/next_action/services/next_actions_view_builder.dart';

void main() {
  group('NextActionsViewBuilder.build (explicit tagging)', () {
    final builder = NextActionsViewBuilder();

    Task task({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      required bool isNextAction,
      int? nextActionPriority,
      Project? project,
    }) {
      return Task(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
        completed: false,
        isNextAction: isNextAction,
        nextActionPriority: nextActionPriority,
        project: project,
      );
    }

    test('excludes tasks not explicitly marked', () {
      final now = DateTime(2025, 1, 31, 10);
      final selection = builder.build(
        tasks: [
          task(
            id: 't1',
            name: 'Not marked',
            createdAt: now,
            updatedAt: now,
            isNextAction: false,
          ),
        ],
        settings: const NextActionsSettings(),
        now: now,
      );

      expect(selection.totalCount, 0);
    });

    test('uses manual nextActionPriority as the bucket priority', () {
      final now = DateTime(2025, 1, 31, 10);
      final p = Project(
        id: 'p1',
        name: 'Project',
        createdAt: now,
        updatedAt: now,
        completed: false,
      );

      final selection = builder.build(
        tasks: [
          task(
            id: 't1',
            name: 'Marked',
            createdAt: now,
            updatedAt: now,
            isNextAction: true,
            nextActionPriority: 7,
            project: p,
          ),
        ],
        settings: const NextActionsSettings(),
        now: now,
      );

      expect(selection.priorityBuckets.containsKey(7), true);
      expect(selection.totalCount, 1);
    });

    test('keeps unmatched tagged tasks visible in fallback priority 9999', () {
      final now = DateTime(2025, 1, 31, 10);
      final p = Project(
        id: 'p1',
        name: 'Project',
        createdAt: now,
        updatedAt: now,
        completed: false,
      );

      // This task is tagged but (intentionally) may not match any bucket rule.
      final selection = builder.build(
        tasks: [
          task(
            id: 't1',
            name: 'Tagged but unmatched',
            createdAt: now,
            updatedAt: now,
            isNextAction: true,
            project: p,
          ),
        ],
        settings: NextActionsSettings.withDefaults(
          bucketRules: const <TaskPriorityBucketRule>[],
        ),
        now: now,
      );

      expect(selection.priorityBuckets.containsKey(9999), true);
      expect(selection.totalCount, 1);
    });
  });
}
