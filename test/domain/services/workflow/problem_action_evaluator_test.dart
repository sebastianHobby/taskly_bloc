import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_action_evaluator.dart';

import '../../../fixtures/test_data.dart';
import '../../../mocks/fake_repositories.dart';

void main() {
  group('ProblemActionEvaluator', () {
    late FakeTaskRepository fakeTaskRepository;
    late ProblemActionEvaluator evaluator;

    setUp(() {
      fakeTaskRepository = FakeTaskRepository();
      evaluator = ProblemActionEvaluator(
        taskRepository: fakeTaskRepository,
      );
    });

    group('requiresUiInteraction', () {
      test('returns true for pickDate', () {
        expect(
          evaluator.requiresUiInteraction(const ProblemAction.pickDate()),
          isTrue,
        );
      });

      test('returns true for pickValue', () {
        expect(
          evaluator.requiresUiInteraction(const ProblemAction.pickValue()),
          isTrue,
        );
      });

      test('returns false for rescheduleToday', () {
        expect(
          evaluator.requiresUiInteraction(
            const ProblemAction.rescheduleToday(),
          ),
          isFalse,
        );
      });

      test('returns false for clearDeadline', () {
        expect(
          evaluator.requiresUiInteraction(const ProblemAction.clearDeadline()),
          isFalse,
        );
      });

      test('returns false for lowerPriority', () {
        expect(
          evaluator.requiresUiInteraction(const ProblemAction.lowerPriority()),
          isFalse,
        );
      });
    });

    group('executeOnTask - date actions', () {
      test('rescheduleToday updates task deadline to today', () async {
        final task = TestData.task(
          id: 't1',
          deadlineDate: DateTime(2025, 12, 31),
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.rescheduleToday(),
        );

        expect(result, isTrue);

        // Verify the task was updated
        final updated = await fakeTaskRepository.getById('t1');
        expect(updated, isNotNull);

        final now = DateTime.now();
        expect(updated!.deadlineDate?.year, now.year);
        expect(updated.deadlineDate?.month, now.month);
        expect(updated.deadlineDate?.day, now.day);
      });

      test('rescheduleTomorrow updates task deadline to tomorrow', () async {
        final task = TestData.task(
          id: 't1',
          deadlineDate: DateTime(2025, 12, 31),
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.rescheduleTomorrow(),
        );

        expect(result, isTrue);

        final updated = await fakeTaskRepository.getById('t1');
        expect(updated, isNotNull);

        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(updated!.deadlineDate?.year, tomorrow.year);
        expect(updated.deadlineDate?.month, tomorrow.month);
        expect(updated.deadlineDate?.day, tomorrow.day);
      });

      test(
        'rescheduleInDays updates task deadline by specified days',
        () async {
          final task = TestData.task(
            id: 't1',
            deadlineDate: DateTime(2025, 12, 31),
          );
          fakeTaskRepository.pushTasks([task]);

          final result = await evaluator.executeOnTask(
            task: task,
            action: const ProblemAction.rescheduleInDays(days: 7),
          );

          expect(result, isTrue);

          final updated = await fakeTaskRepository.getById('t1');
          expect(updated, isNotNull);

          final expected = DateTime.now().add(const Duration(days: 7));
          expect(updated!.deadlineDate?.year, expected.year);
          expect(updated.deadlineDate?.month, expected.month);
          expect(updated.deadlineDate?.day, expected.day);
        },
      );

      test('clearDeadline removes task deadline', () async {
        final task = TestData.task(
          id: 't1',
          deadlineDate: DateTime(2025, 12, 31),
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.clearDeadline(),
        );

        expect(result, isTrue);

        final updated = await fakeTaskRepository.getById('t1');
        expect(updated, isNotNull);
        expect(updated!.deadlineDate, isNull);
      });

      test('pickDate returns false without selectedDate', () async {
        final task = TestData.task(
          id: 't1',
          deadlineDate: DateTime(2025, 12, 31),
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.pickDate(),
        );

        expect(result, isFalse);

        // Task should not be modified
        final updated = await fakeTaskRepository.getById('t1');
        expect(updated!.deadlineDate, DateTime(2025, 12, 31));
      });

      test('pickDate with selectedDate updates deadline', () async {
        final task = TestData.task(
          id: 't1',
          deadlineDate: DateTime(2025, 12, 31),
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.pickDate(),
          selectedDate: DateTime(2026, 6, 15),
        );

        expect(result, isTrue);

        final updated = await fakeTaskRepository.getById('t1');
        expect(updated!.deadlineDate, DateTime(2026, 6, 15));
      });
    });

    group('executeOnTask - value actions', () {
      test('pickValue returns false without selectedValueId', () async {
        final task = TestData.task(id: 't1');
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.pickValue(),
        );

        expect(result, isFalse);
      });

      test('assignValue adds value to task labels', () async {
        final task = TestData.task(id: 't1');
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.assignValue(
            valueId: 'v1',
            valueName: 'Work',
          ),
        );

        expect(result, isTrue);
        // Note: Full label update verification would require checking
        // the labelIds passed to the repository's update method
      });
    });

    group('executeOnTask - priority actions', () {
      test('lowerPriority returns false for task with no priority', () async {
        final task = TestData.task(
          id: 't1',
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.lowerPriority(),
        );

        expect(result, isFalse);
      });

      test('lowerPriority returns false for P4 priority', () async {
        final task = TestData.task(
          id: 't1',
          priority: 4,
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.lowerPriority(),
        );

        expect(result, isFalse);
      });

      test('lowerPriority returns true for P1-P3 priority', () async {
        final task = TestData.task(
          id: 't1',
          priority: 2,
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.lowerPriority(),
        );

        expect(result, isTrue);
      });

      test('removePriority returns false for task with no priority', () async {
        final task = TestData.task(
          id: 't1',
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.removePriority(),
        );

        expect(result, isFalse);
      });

      test('removePriority returns true for task with priority', () async {
        final task = TestData.task(
          id: 't1',
          priority: 2,
        );
        fakeTaskRepository.pushTasks([task]);

        final result = await evaluator.executeOnTask(
          task: task,
          action: const ProblemAction.removePriority(),
        );

        expect(result, isTrue);
      });
    });
  });
}
