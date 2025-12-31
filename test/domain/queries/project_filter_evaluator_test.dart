import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/project_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator, RelativeComparison;

import '../../fixtures/test_data.dart';

void main() {
  late ProjectFilterEvaluator evaluator;
  late EvaluationContext ctx;

  setUp(() {
    evaluator = const ProjectFilterEvaluator();
    ctx = EvaluationContext.forDate(DateTime(2025, 6, 15));
  });

  group('ProjectFilterEvaluator', () {
    group('matches()', () {
      test('returns true for matchAll filter', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>.matchAll();

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('returns true when all shared predicates match', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('returns false when any shared predicate fails', () {
        final project = TestData.project(completed: true);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('returns true when shared passes and no orGroups', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('returns true when shared passes and any orGroup matches', () {
        final project = TestData.project(
          deadlineDate: DateTime(2025, 6, 20),
        );
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
            [
              ProjectDatePredicate(
                field: ProjectDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('returns false when shared passes but no orGroup matches', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
            [
              ProjectDatePredicate(
                field: ProjectDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });
    });

    group('_evalBool', () {
      test('isTrue operator returns true for completed project', () {
        final project = TestData.project(completed: true);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('isTrue operator returns false for incomplete project', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('isFalse operator returns true for incomplete project', () {
        final project = TestData.project();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('isFalse operator returns false for completed project', () {
        final project = TestData.project(completed: true);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });
    });

    group('_evalLabel', () {
      test('hasAny returns true when project has any matching label', () {
        final label = TestData.label(id: 'label-1');
        final project = TestData.project(labels: [label]);
        final filter = QueryFilter<ProjectPredicate>(
          shared: const [
            ProjectLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('hasAny returns false when project has no matching label', () {
        final label = TestData.label(id: 'label-3');
        final project = TestData.project(labels: [label]);
        final filter = QueryFilter<ProjectPredicate>(
          shared: const [
            ProjectLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('hasAll returns true when project has all matching labels', () {
        final label1 = TestData.label(id: 'label-1');
        final label2 = TestData.label(id: 'label-2');
        final project = TestData.project(labels: [label1, label2]);
        final filter = QueryFilter<ProjectPredicate>(
          shared: const [
            ProjectLabelPredicate(
              operator: LabelOperator.hasAll,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('hasAll returns false when project missing some labels', () {
        final label1 = TestData.label(id: 'label-1');
        final project = TestData.project(labels: [label1]);
        final filter = QueryFilter<ProjectPredicate>(
          shared: const [
            ProjectLabelPredicate(
              operator: LabelOperator.hasAll,
              labelType: LabelType.label,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('isNull returns true when project has no labels of type', () {
        final project = TestData.project(labels: []);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectLabelPredicate(
              operator: LabelOperator.isNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('isNull returns false when project has labels of type', () {
        final label = TestData.label();
        final project = TestData.project(labels: [label]);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectLabelPredicate(
              operator: LabelOperator.isNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('isNotNull returns true when project has labels of type', () {
        final label = TestData.label();
        final project = TestData.project(labels: [label]);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectLabelPredicate(
              operator: LabelOperator.isNotNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isTrue);
      });

      test('isNotNull returns false when project has no labels of type', () {
        final project = TestData.project(labels: []);
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectLabelPredicate(
              operator: LabelOperator.isNotNull,
              labelType: LabelType.label,
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });

      test('filters by label type', () {
        final valueLabel = TestData.label(id: 'value-1', type: LabelType.value);
        final project = TestData.project(labels: [valueLabel]);
        final filter = QueryFilter<ProjectPredicate>(
          shared: const [
            ProjectLabelPredicate(
              operator: LabelOperator.hasAny,
              labelType: LabelType.label, // Looking for labels, not values
              labelIds: ['value-1'],
            ),
          ],
        );

        expect(evaluator.matches(project, filter, ctx), isFalse);
      });
    });

    group('_evalDate', () {
      group('absolute date operators', () {
        test('on operator matches same date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20, 10, 30),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.on,
                date: DateTime(2025, 6, 20, 8),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('on operator does not match different date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 21),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.on,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });

        test('before operator matches earlier date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 19),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.before,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('before operator does not match same or later date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.before,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });

        test('after operator matches later date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 21),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.after,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('onOrAfter operator matches same date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.onOrAfter,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('onOrBefore operator matches same date', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.onOrBefore,
                date: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('between operator matches date in range', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 15),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.between,
                startDate: DateTime(2025, 6, 10),
                endDate: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('between operator does not match date outside range', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 25),
          );
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.between,
                startDate: DateTime(2025, 6, 10),
                endDate: DateTime(2025, 6, 20),
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });
      });

      group('null operators', () {
        test('isNull returns true when field is null', () {
          final project = TestData.project();
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNull,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('isNull returns false when field is not null', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNull,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });

        test('isNotNull returns true when field is not null', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('isNotNull returns false when field is null', () {
          final project = TestData.project();
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });
      });

      group('relative date operators', () {
        test('relative on matches exact relative date', () {
          // ctx.today is 2025-06-15, so +5 days = 2025-06-20
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('relative before matches earlier than pivot', () {
          // ctx.today is 2025-06-15, +5 days = 2025-06-20
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 18),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.before,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('relative after matches later than pivot', () {
          // ctx.today is 2025-06-15, +5 days = 2025-06-20
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 22),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.after,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('relative onOrAfter matches same or later', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.onOrAfter,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('relative onOrBefore matches same or earlier', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.onOrBefore,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('relative returns false when relativeDays is null', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });

        test('relative returns false when relativeComparison is null', () {
          final project = TestData.project(
            deadlineDate: DateTime(2025, 6, 20),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });

        test('relative returns false when fieldValue is null', () {
          final project = TestData.project();
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.relative,
                relativeComparison: RelativeComparison.on,
                relativeDays: 5,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isFalse);
        });
      });

      group('date fields', () {
        test('evaluates startDate field', () {
          final project = TestData.project(
            startDate: DateTime(2025, 6, 10),
          );
          const filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.startDate,
                operator: DateOperator.isNotNull,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('evaluates createdAt field', () {
          final createdAt = DateTime(2025);
          final project = TestData.project(createdAt: createdAt);
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.createdAt,
                operator: DateOperator.on,
                date: createdAt,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });

        test('evaluates updatedAt field', () {
          final updatedAt = DateTime(2025, 5);
          final project = TestData.project(updatedAt: updatedAt);
          final filter = QueryFilter<ProjectPredicate>(
            shared: [
              ProjectDatePredicate(
                field: ProjectDateField.updatedAt,
                operator: DateOperator.on,
                date: updatedAt,
              ),
            ],
          );

          expect(evaluator.matches(project, filter, ctx), isTrue);
        });
      });
    });
  });
}
