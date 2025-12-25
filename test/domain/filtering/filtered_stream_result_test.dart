import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/filtered_stream_result.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_service.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

void main() {
  group('FilteredStreamResult', () {
    // Helper to create test tasks
    Task createTask({
      required String id,
      required String name,
      bool completed = false,
      List<Label> labels = const [],
      DateTime? deadline,
    }) {
      return Task(
        id: id,
        name: name,
        completed: completed,
        labels: labels,
        deadlineDate: deadline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('Construction', () {
      test('creates with stream and metadata', () {
        final stream = Stream.value([createTask(id: '1', name: 'Task 1')]);
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [],
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.stream, stream);
        expect(result.metadata, metadata);
      });
    });

    group('isFullyFiltered', () {
      test('returns true when metadata is fully applied', () {
        final stream = Stream.value([createTask(id: '1', name: 'Task 1')]);
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

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.isFullyFiltered, isTrue);
      });

      test('returns false when there are pending rules', () {
        final stream = Stream.value([createTask(id: '1', name: 'Task 1')]);
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

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.isFullyFiltered, isFalse);
      });

      test('returns false when there are pending sort criteria', () {
        final stream = Stream.value([createTask(id: '1', name: 'Task 1')]);
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [
            SortCriterion(field: SortField.name),
          ],
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.isFullyFiltered, isFalse);
      });
    });

    group('finalize()', () {
      test('returns stream unchanged when fully filtered', () async {
        final tasks = [
          createTask(id: '1', name: 'Task 1'),
          createTask(id: '2', name: 'Task 2'),
        ];

        final stream = Stream.value(tasks);
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [],
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        expect(finalizedTasks, tasks);
      });

      test('applies pending rules when not fully filtered', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tasks = [
          createTask(id: '1', name: 'Task 1', labels: [label1]),
          createTask(id: '2', name: 'Task 2', labels: []),
          createTask(id: '3', name: 'Task 3', labels: [label1]),
        ];

        final stream = Stream.value(tasks);
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

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        expect(finalizedTasks.length, 2);
        expect(finalizedTasks.any((t) => t.id == '1'), isTrue);
        expect(finalizedTasks.any((t) => t.id == '3'), isTrue);
      });

      test('applies pending sort when not fully filtered', () async {
        final tasks = [
          createTask(id: '1', name: 'Zebra'),
          createTask(id: '2', name: 'Apple'),
          createTask(id: '3', name: 'Mango'),
        ];

        final stream = Stream.value(tasks);
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [
            SortCriterion(
              field: SortField.name,
            ),
          ],
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        expect(finalizedTasks[0].name, 'Apple');
        expect(finalizedTasks[1].name, 'Mango');
        expect(finalizedTasks[2].name, 'Zebra');
      });

      test('applies both pending rules and sort', () async {
        final label1 = Label(
          id: 'label-1',
          name: 'Work',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tasks = [
          createTask(id: '1', name: 'Zebra', labels: [label1]),
          createTask(id: '2', name: 'Apple', labels: []),
          createTask(id: '3', name: 'Mango', labels: [label1]),
        ];

        final stream = Stream.value(tasks);
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

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        expect(finalizedTasks.length, 2);
        expect(finalizedTasks[0].name, 'Mango');
        expect(finalizedTasks[1].name, 'Zebra');
      });

      test('works with multiple stream emissions', () async {
        final controller = StreamController<List<Task>>();
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

        final result = FilteredStreamResult(
          stream: controller.stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
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
        final stream = Stream.value(<Task>[]);
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

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        expect(finalizedTasks, isEmpty);
      });
    });

    group('Integration Scenarios', () {
      test('complex filtering with metadata tracking', () async {
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

        // Simulate SQL applied BooleanRule, but LabelRule pending
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
          createTask(id: '1', name: 'Zebra Work', labels: [label1]),
          createTask(id: '2', name: 'Apple Personal', labels: [label2]),
          createTask(id: '3', name: 'Mango Work', labels: [label1]),
        ];

        final stream = Stream.value(tasks);
        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.isFullyFiltered, isFalse);

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        // Should filter to only Work label tasks and sort by name
        expect(finalizedTasks.length, 2);
        expect(finalizedTasks[0].name, 'Mango Work');
        expect(finalizedTasks[1].name, 'Zebra Work');
      });

      test('fully filtered result skips post-processing', () async {
        // All rules and sort applied at SQL level
        const metadata = FilterResultMetadata(
          appliedRules: [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.isNotNull,
            ),
          ],
          pendingRules: [],
          appliedSort: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
          pendingSort: [],
        );

        final tasks = [
          createTask(
            id: '1',
            name: 'Task 1',
          ),
          createTask(
            id: '2',
            name: 'Task 2',
          ),
        ];

        final stream = Stream.value(tasks);
        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.isFullyFiltered, isTrue);

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        // Should return tasks unchanged since fully filtered
        expect(finalizedTasks, tasks);
      });

      test('occurrence expansion metadata is preserved', () {
        final stream = Stream.value([createTask(id: '1', name: 'Task 1')]);

        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [],
          occurrencesExpanded: true,
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        expect(result.metadata.occurrencesExpanded, isTrue);
      });

      test('works with different evaluation contexts', () async {
        final tasks = [
          createTask(
            id: '1',
            name: 'Task 1',
            deadline: DateTime(2024, 6, 10),
          ),
          createTask(
            id: '2',
            name: 'Task 2',
            deadline: DateTime(2024, 6, 20),
          ),
        ];

        final stream = Stream.value(tasks);
        final metadata = FilterResultMetadata(
          appliedRules: const [],
          pendingRules: [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: DateTime(2024, 6, 15),
            ),
          ],
          appliedSort: const [],
          pendingSort: const [],
        );

        final result = FilteredStreamResult(
          stream: stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);
        final finalizedTasks = await finalizedStream.first;

        // Only task 1 should pass (deadline on or before June 15)
        expect(finalizedTasks.length, 1);
        expect(finalizedTasks.first.id, '1');
      });
    });

    group('Error Handling', () {
      test('propagates errors from source stream', () async {
        final controller = StreamController<List<Task>>();
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [],
        );

        final result = FilteredStreamResult(
          stream: controller.stream,
          metadata: metadata,
        );

        const service = TaskFilterService();
        final context = EvaluationContext(today: DateTime(2024, 6, 15));

        final finalizedStream = result.finalize(service, context);

        final errors = <Object>[];
        finalizedStream.handleError(errors.add).listen((_) {});

        controller.addError(Exception('Test error'));
        await controller.close();

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(errors.length, greaterThan(0));
      });
    });
  });
}
