import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

import '../../fixtures/test_data.dart';

void main() {
  late TaskFilterEvaluator evaluator;
  late EvaluationContext ctx;

  setUp(() {
    evaluator = const TaskFilterEvaluator();
    ctx = EvaluationContext.forDate(DateTime(2025, 6, 15));
  });

  group('TaskFilterEvaluator', () {
    group('matches()', () {
      test('returns true for matchAll filter', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>.matchAll();

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('returns true when all shared predicates match', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('returns false when any shared predicate fails', () {
        final task = TestData.task(completed: true);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('returns true when shared passes and no orGroups', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('returns true when shared passes and any orGroup matches', () {
        final task = TestData.task(
          deadlineDate: DateTime(2025, 6, 20),
        );
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
            [
              TaskDatePredicate(
                field: TaskDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('returns false when shared passes but no orGroup matches', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
            [
              TaskDatePredicate(
                field: TaskDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });
    });

    group('_evalBool', () {
      test('isTrue operator returns true for completed task', () {
        final task = TestData.task(completed: true);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isTrue operator returns false for incomplete task', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('isFalse operator returns true for incomplete task', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isFalse operator returns false for completed task', () {
        final task = TestData.task(completed: true);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });
    });

    group('_evalProject', () {
      test('matches operator returns true for matching projectId', () {
        final task = TestData.task(projectId: 'project-1');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'project-1',
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('matches operator returns false for non-matching projectId', () {
        final task = TestData.task(projectId: 'project-2');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'project-1',
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('matches operator returns false for null projectId', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'project-1',
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('matchesAny returns true when projectId in list', () {
        final task = TestData.task(projectId: 'project-2');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matchesAny,
              projectIds: ['project-1', 'project-2', 'project-3'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('matchesAny returns false when projectId not in list', () {
        final task = TestData.task(projectId: 'project-4');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matchesAny,
              projectIds: ['project-1', 'project-2', 'project-3'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('matchesAny returns false for null projectId', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(
              operator: ProjectOperator.matchesAny,
              projectIds: ['project-1', 'project-2'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('isNull returns true when projectId is null', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isNull returns false when projectId is not null', () {
        final task = TestData.task(projectId: 'project-1');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('isNotNull returns true when projectId is not null', () {
        final task = TestData.task(projectId: 'project-1');
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(operator: ProjectOperator.isNotNull),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isNotNull returns false when projectId is null', () {
        final task = TestData.task();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskProjectPredicate(operator: ProjectOperator.isNotNull),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });
    });

    group('_evalLabel', () {
      test('hasAny returns true when task has any matching label', () {
        final label = TestData.label(id: 'label-1');
        final task = TestData.task(labels: [label]);
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('hasAny returns false when task has no matching label', () {
        final label = TestData.label(id: 'label-3');
        final task = TestData.task(labels: [label]);
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('hasAll returns true when task has all matching labels', () {
        final label1 = TestData.label(id: 'label-1');
        final label2 = TestData.label(id: 'label-2');
        final task = TestData.task(labels: [label1, label2]);
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskLabelPredicate(
              operator: LabelOperator.hasAll,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('hasAll returns false when task missing some labels', () {
        final label1 = TestData.label(id: 'label-1');
        final task = TestData.task(labels: [label1]);
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskLabelPredicate(
              operator: LabelOperator.hasAll,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('isNull returns true when task has no labels of type', () {
        final task = TestData.task(labels: []);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskLabelPredicate(
              operator: LabelOperator.isNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isNull returns false when task has labels of type', () {
        final label = TestData.label();
        final task = TestData.task(labels: [label]);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskLabelPredicate(
              operator: LabelOperator.isNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('isNotNull returns true when task has labels of type', () {
        final label = TestData.label();
        final task = TestData.task(labels: [label]);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskLabelPredicate(
              operator: LabelOperator.isNotNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });

      test('isNotNull returns false when task has no labels of type', () {
        final task = TestData.task(labels: []);
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskLabelPredicate(
              operator: LabelOperator.isNotNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });

      test('filters by label type', () {
        final valueLabel = TestData.label(id: 'value-1', type: LabelType.value);
        final task = TestData.task(labels: [valueLabel]);
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label, // Looking for labels, not values
              labelIds: ['value-1'],
            ),
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isFalse);
      });
    });

    group('_evalDate', () {
      group('absolute date operators', () {
        test('on operator matches same date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20, 10, 30),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.on,
                date: DateTime(2025, 6, 20, 8),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('on operator does not match different date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 21),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.on,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });

        test('before operator matches earlier date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 19),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.before,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('before operator does not match same or later date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.before,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });

        test('after operator matches later date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 21),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.after,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('onOrAfter operator matches same date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.onOrAfter,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('onOrBefore operator matches same date', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.onOrBefore,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('between operator matches date in range', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 15),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.between,
                startDate: DateTime(2025, 6, 10),
                endDate: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('between operator does not match date outside range', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 25),
          );
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.between,
                startDate: DateTime(2025, 6, 10),
                endDate: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });
      });

      group('null operators', () {
        test('isNull returns true when field is null', () {
          final task = TestData.task();
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNull,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('isNull returns false when field is not null', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNull,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });

        test('isNotNull returns true when field is not null', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('isNotNull returns false when field is null', () {
          final task = TestData.task();
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });
      });

      group('relative date operators', () {
        test('relative on matches exact relative date', () {
          // ctx.today is 2025-06-15, so +5 days = 2025-06-20
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('relative before matches earlier than pivot', () {
          // ctx.today is 2025-06-15, +5 days = 2025-06-20
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 18),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.before,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('relative after matches later than pivot', () {
          // ctx.today is 2025-06-15, +5 days = 2025-06-20
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 22),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.after,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('relative onOrAfter matches same or later', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.onOrAfter,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('relative onOrBefore matches same or earlier', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.onOrBefore,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('relative returns false when relativeDays is null', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });

        test('relative returns false when relativeComparison is null', () {
          final task = TestData.task(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });

        test('relative returns false when fieldValue is null', () {
          final task = TestData.task();
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isFalse);
        });
      });

      group('date fields', () {
        test('evaluates startDate field', () {
          final task = TestData.task(
            startDate: DateTime(2025, 6, 10),
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('evaluates createdAt field', () {
          final createdAt = DateTime(2025);
          final task = TestData.task(createdAt: createdAt);
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.createdAt,
                operator: DateOperator.on,
                date: createdAt,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });

        test('evaluates updatedAt field', () {
          final updatedAt = DateTime(2025, 5);
          final task = TestData.task(updatedAt: updatedAt);
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.updatedAt,
                operator: DateOperator.on,
                date: updatedAt,
              ),
            ],
          );

          expect(evaluator.matches(task, filter, ctx), isTrue);
        });
      });
    });

    group('complex filters', () {
      test('combines project, label, and date predicates', () {
        final label = TestData.label(id: 'urgent');
        final task = TestData.task(
          projectId: 'project-1',
          labels: [label],
          deadlineDate: DateTime(2025, 6, 20),
        );
        final filter = QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'project-1',
            ),
          ],
          orGroups: [
            const [
              TaskLabelPredicate(
                operator: LabelOperator.hasAny,
                labelType: LabelType.label,
                labelIds: ['urgent'],
              ),
            ],
            [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.before,
                date: DateTime(2025, 6, 25),
              ),
            ],
          ],
        );

        expect(evaluator.matches(task, filter, ctx), isTrue);
      });
    });
  });
}
