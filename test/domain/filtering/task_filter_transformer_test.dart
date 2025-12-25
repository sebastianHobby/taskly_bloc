import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_transformer.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

void main() {
  group('TaskFilterTransformer', () {
    // Helper to create test tasks
    Task createTask({
      required String id,
      required String name,
      bool completed = false,
      DateTime? deadlineDate,
      DateTime? startDate,
      String? projectId,
      List<Label> labels = const [],
    }) {
      return Task(
        id: id,
        name: name,
        completed: completed,
        deadlineDate: deadlineDate,
        startDate: startDate,
        projectId: projectId,
        labels: labels,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('Filtering', () {
      test('filters tasks by BooleanRule', () async {
        final transformer = TaskFilterTransformer(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2', completed: true),
          createTask(id: '3', name: 'Task 3'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '3'), isTrue);
        expect(result.any((t) => t.id == '2'), isFalse);
      });

      test('filters tasks by DateRule', () async {
        final today = DateTime(2024, 6, 15);
        final transformer = TaskFilterTransformer(
          rules: [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: today,
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: today),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Past Task',
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '2',
            name: 'Today Task',
            deadlineDate: DateTime(2024, 6, 15),
          ),
          createTask(
            id: '3',
            name: 'Future Task',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(id: '4', name: 'No Deadline'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '2'), isTrue);
        expect(result.any((t) => t.id == '3'), isFalse);
        expect(result.any((t) => t.id == '4'), isFalse);
      });

      test('filters tasks by ProjectRule', () async {
        final transformer = TaskFilterTransformer(
          rules: const [
            ProjectRule(
              operator: ProjectRuleOperator.matches,
              projectId: 'project-1',
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1', projectId: 'project-1'),
          createTask(id: '2', name: 'Task 2', projectId: 'project-2'),
          createTask(id: '3', name: 'Task 3', projectId: 'project-1'),
          createTask(id: '4', name: 'Task 4'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '3'), isTrue);
      });

      test('filters tasks by LabelRule', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Important',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transformer = TaskFilterTransformer(
          rules: const [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-1'],
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1', labels: [label1]),
          createTask(id: '2', name: 'Task 2', labels: []),
          createTask(id: '3', name: 'Task 3', labels: [label1]),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '3'), isTrue);
      });

      test('applies multiple rules with AND logic', () async {
        final today = DateTime(2024, 6, 15);
        final transformer = TaskFilterTransformer(
          rules: [
            const BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: today,
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: today),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Incomplete Past',
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '2',
            name: 'Completed Past',
            completed: true,
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '3',
            name: 'Incomplete Future',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(
            id: '4',
            name: 'Completed Future',
            completed: true,
            deadlineDate: DateTime(2024, 6, 20),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        // Only task 1 matches both rules
        expect(result.length, 1);
        expect(result.first.id, '1');
      });

      test('returns all tasks when no rules', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2'),
          createTask(id: '3', name: 'Task 3'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result.length, 3);
      });
    });

    group('Sorting', () {
      test('sorts tasks by deadline date ascending', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(
              field: SortField.deadlineDate,
            ),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Task 1',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(
            id: '2',
            name: 'Task 2',
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '3',
            name: 'Task 3',
            deadlineDate: DateTime(2024, 6, 15),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result[0].id, '2'); // June 10
        expect(result[1].id, '3'); // June 15
        expect(result[2].id, '1'); // June 20
      });

      test('sorts tasks by deadline date descending', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(
              field: SortField.deadlineDate,
              direction: SortDirection.descending,
            ),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Task 1',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(
            id: '2',
            name: 'Task 2',
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '3',
            name: 'Task 3',
            deadlineDate: DateTime(2024, 6, 15),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result[0].id, '1'); // June 20
        expect(result[1].id, '3'); // June 15
        expect(result[2].id, '2'); // June 10
      });

      test('sorts tasks by name', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Zebra'),
          createTask(id: '2', name: 'Apple'),
          createTask(id: '3', name: 'Mango'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result[0].name, 'Apple');
        expect(result[1].name, 'Mango');
        expect(result[2].name, 'Zebra');
      });

      test('sorts with multiple criteria (deadline then name)', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Zebra',
            deadlineDate: DateTime(2024, 6, 15),
          ),
          createTask(
            id: '2',
            name: 'Apple',
            deadlineDate: DateTime(2024, 6, 15),
          ),
          createTask(
            id: '3',
            name: 'Mango',
            deadlineDate: DateTime(2024, 6, 10),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result[0].name, 'Mango'); // Earliest date
        expect(result[1].name, 'Apple'); // Same date, alphabetically first
        expect(result[2].name, 'Zebra'); // Same date, alphabetically last
      });

      test('handles null values in sorting', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(
              field: SortField.deadlineDate,
            ),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Has deadline',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(id: '2', name: 'No deadline'),
          createTask(
            id: '3',
            name: 'Another deadline',
            deadlineDate: DateTime(2024, 6, 10),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        // Null values should sort last
        expect(result[0].id, '3');
        expect(result[1].id, '1');
        expect(result[2].id, '2');
      });

      test('returns unsorted tasks when no sort criteria', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2'),
          createTask(id: '3', name: 'Task 3'),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        expect(result[0].id, '1');
        expect(result[1].id, '2');
        expect(result[2].id, '3');
      });
    });

    group('Combined Filtering and Sorting', () {
      test('filters then sorts tasks', () async {
        final today = DateTime(2024, 6, 15);
        final transformer = TaskFilterTransformer(
          rules: [
            const BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          sortCriteria: const [
            SortCriterion(
              field: SortField.deadlineDate,
            ),
          ],
          context: EvaluationContext(today: today),
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Incomplete Future',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(
            id: '2',
            name: 'Completed Past',
            completed: true,
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '3',
            name: 'Incomplete Past',
            deadlineDate: DateTime(2024, 6, 12),
          ),
          createTask(
            id: '4',
            name: 'Completed Future',
            completed: true,
            deadlineDate: DateTime(2024, 6, 25),
          ),
        ];

        final stream = Stream.value(tasks);
        final result = await stream.transform(transformer).first;

        // Only incomplete tasks, sorted by deadline
        expect(result.length, 2);
        expect(result[0].id, '3'); // June 12
        expect(result[1].id, '1'); // June 20
      });
    });

    group('Error Handling', () {
      test('handles errors gracefully during evaluation', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final controller = StreamController<List<Task>>();
        final errorStream = controller.stream.transform(transformer);

        final errors = <Object>[];
        errorStream.handleError(errors.add).listen((_) {});

        controller.addError(Exception('Test error'));
        await controller.close();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(errors.length, greaterThan(0));
      });

      test('continues processing after error', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final controller = StreamController<List<Task>>();
        final transformedStream = controller.stream.transform(transformer);

        final results = <List<Task>>[];
        transformedStream.handleError((_) {}).listen(results.add);

        final tasks1 = [createTask(id: '1', name: 'Task 1')];
        controller.add(tasks1);

        controller.addError(Exception('Test error'));

        final tasks2 = [createTask(id: '2', name: 'Task 2')];
        controller.add(tasks2);

        await controller.close();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(results.length, 2);
        expect(results[0].first.id, '1');
        expect(results[1].first.id, '2');
      });
    });

    group('Stream Processing', () {
      test('processes multiple emissions', () async {
        final transformer = TaskFilterTransformer(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final controller = StreamController<List<Task>>();
        final transformedStream = controller.stream.transform(transformer);

        final results = <List<Task>>[];
        transformedStream.listen(results.add);

        // First emission
        controller.add([
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2', completed: true),
        ]);

        // Second emission
        controller.add([
          createTask(id: '3', name: 'Task 3'),
          createTask(id: '4', name: 'Task 4'),
        ]);

        await controller.close();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(results.length, 2);
        expect(results[0].length, 1); // First emission had 1 incomplete
        expect(results[1].length, 2); // Second emission had 2 incomplete
      });

      test('handles empty task lists', () async {
        final transformer = TaskFilterTransformer(
          rules: const [],
          sortCriteria: const [],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        final stream = Stream.value(<Task>[]);
        final result = await stream.transform(transformer).first;

        expect(result, isEmpty);
      });
    });
  });
}
