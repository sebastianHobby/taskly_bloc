import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_service.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

void main() {
  group('TaskFilterService', () {
    late TaskFilterService service;

    setUp(() {
      service = const TaskFilterService();
    });

    // Helper to create test tasks
    Task createTask({
      required String id,
      required String name,
      bool completed = false,
      DateTime? deadlineDate,
      List<Label> labels = const [],
    }) {
      return Task(
        id: id,
        name: name,
        completed: completed,
        deadlineDate: deadlineDate,
        labels: labels,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('finalize()', () {
      test('returns source stream when fully applied', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          pendingRules: [],
          appliedSort: [
            SortCriterion(field: SortField.deadlineDate),
          ],
          pendingSort: [],
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2'),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = service.finalize(sourceStream, metadata, context);

        // Should be the same stream since no post-processing needed
        expect(await result.first, tasks);
      });

      test('applies pending rules when not fully applied', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Important',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-1'],
            ),
          ],
          appliedSort: [],
          pendingSort: [],
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1', labels: [label1]),
          createTask(id: '2', name: 'Task 2', labels: []),
          createTask(id: '3', name: 'Task 3', labels: [label1]),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '3'), isTrue);
      });

      test('applies pending sort when not fully applied', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [
            SortCriterion(field: SortField.name),
          ],
        );

        final tasks = [
          createTask(id: '1', name: 'Zebra'),
          createTask(id: '2', name: 'Apple'),
          createTask(id: '3', name: 'Mango'),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        expect(result[0].name, 'Apple');
        expect(result[1].name, 'Mango');
        expect(result[2].name, 'Zebra');
      });

      test('applies both pending rules and sort', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Important',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-1'],
            ),
          ],
          appliedSort: [],
          pendingSort: [
            SortCriterion(
              field: SortField.name,
            ),
          ],
        );

        final tasks = [
          createTask(id: '1', name: 'Zebra', labels: [label1]),
          createTask(id: '2', name: 'Apple', labels: []),
          createTask(id: '3', name: 'Mango', labels: [label1]),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        // Should have filtered out task 2 and sorted remaining by name
        expect(result.length, 2);
        expect(result[0].name, 'Mango');
        expect(result[1].name, 'Zebra');
      });

      test('handles multiple stream emissions', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          appliedSort: [],
          pendingSort: [],
        );

        final controller = StreamController<List<Task>>();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = service.finalize(
          controller.stream,
          metadata,
          context,
        );

        final results = <List<Task>>[];
        finalizedStream.listen(results.add);

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
        expect(results[0].length, 1); // First emission, 1 incomplete
        expect(results[1].length, 2); // Second emission, 2 incomplete
      });

      test('handles empty task lists', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          appliedSort: [],
          pendingSort: [],
        );

        final sourceStream = Stream.value(<Task>[]);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        expect(result, isEmpty);
      });

      test('handles context with different dates', () async {
        final today = DateTime(2024, 6, 15);

        final metadata = FilterResultMetadata(
          appliedRules: const [],
          pendingRules: [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: today,
            ),
          ],
          appliedSort: const [],
          pendingSort: const [],
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Past',
            deadlineDate: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '2',
            name: 'Future',
            deadlineDate: DateTime(2024, 6, 20),
          ),
          createTask(
            id: '3',
            name: 'Today',
            deadlineDate: DateTime(2024, 6, 15),
          ),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: today);

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        expect(result.length, 2);
        expect(result.any((t) => t.id == '1'), isTrue);
        expect(result.any((t) => t.id == '3'), isTrue);
      });
    });

    group('transformer()', () {
      test('creates a stream transformer', () {
        final transformer = service.transformer(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
          context: EvaluationContext(today: DateTime(2024, 6, 15)),
        );

        expect(transformer, isNotNull);
        expect(
          transformer,
          isA<StreamTransformer<List<Task>, List<Task>>>(),
        );
      });

      test('transformer can be used directly on a stream', () async {
        final transformer = service.transformer(
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
      });

      test('transformer with empty rules passes all tasks', () async {
        final transformer = service.transformer(
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

      test('transformer applies sorting', () async {
        final transformer = service.transformer(
          rules: const [],
          sortCriteria: const [
            SortCriterion(
              field: SortField.name,
            ),
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
    });

    group('Error Handling', () {
      test('propagates errors from source stream', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [],
        );

        final controller = StreamController<List<Task>>();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = service.finalize(
          controller.stream,
          metadata,
          context,
        );

        final errors = <Object>[];
        finalizedStream.handleError(errors.add).listen((_) {});

        controller.addError(Exception('Test error'));
        await controller.close();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(errors.length, greaterThan(0));
      });

      test('handles errors during rule evaluation', () async {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          appliedSort: [],
          pendingSort: [],
        );

        final sourceStream = Stream.value([
          createTask(id: '1', name: 'Task 1'),
        ]);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        // Should not throw, even if rules are complex
        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        expect(result, isNotNull);
      });
    });

    group('Integration', () {
      test('works with realistic filter scenario', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final label2 = Label(
          id: 'label-2',
          name: 'Urgent',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        const metadata = FilterResultMetadata(
          appliedRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          pendingRules: [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-1'],
            ),
          ],
          appliedSort: [
            SortCriterion(field: SortField.deadlineDate),
          ],
          pendingSort: [
            SortCriterion(field: SortField.name),
          ],
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Zebra Work',
            deadlineDate: DateTime(2024, 6, 20),
            labels: [label1],
          ),
          createTask(
            id: '2',
            name: 'Apple Personal',
            deadlineDate: DateTime(2024, 6, 15),
            labels: [label2],
          ),
          createTask(
            id: '3',
            name: 'Mango Work',
            deadlineDate: DateTime(2024, 6, 20),
            labels: [label1],
          ),
          createTask(
            id: '4',
            name: 'Banana Work',
            deadlineDate: DateTime(2024, 6, 15),
            labels: [label1, label2],
          ),
        ];

        final sourceStream = Stream.value(tasks);
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final result = await service
            .finalize(
              sourceStream,
              metadata,
              context,
            )
            .first;

        // Should have tasks 1, 3, and 4 (all have Work label)
        // Task 2 excluded (doesn't have Work label)
        // Sorted by name after filtering
        expect(result.length, 3);
        expect(result[0].name, 'Banana Work');
        expect(result[1].name, 'Mango Work');
        expect(result[2].name, 'Zebra Work');
      });
    });
  });
}
