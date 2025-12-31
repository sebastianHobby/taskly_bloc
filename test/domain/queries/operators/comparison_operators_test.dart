import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/queries/operators/operators.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

void main() {
  group('DateComparison', () {
    group('evaluate()', () {
      final baseDate = DateTime(2025, 6, 15);

      group('DateOperator.isNull', () {
        test('returns true when field is null', () {
          expect(
            DateComparison.evaluate(
              fieldValue: null,
              operator: DateOperator.isNull,
            ),
            isTrue,
          );
        });

        test('returns false when field has value', () {
          expect(
            DateComparison.evaluate(
              fieldValue: baseDate,
              operator: DateOperator.isNull,
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.isNotNull', () {
        test('returns true when field has value', () {
          expect(
            DateComparison.evaluate(
              fieldValue: baseDate,
              operator: DateOperator.isNotNull,
            ),
            isTrue,
          );
        });

        test('returns false when field is null', () {
          expect(
            DateComparison.evaluate(
              fieldValue: null,
              operator: DateOperator.isNotNull,
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.on', () {
        test('returns true when dates match (date-only comparison)', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15, 10, 30),
              operator: DateOperator.on,
              date: DateTime(2025, 6, 15, 8),
            ),
            isTrue,
          );
        });

        test('returns false when dates differ', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 14),
              operator: DateOperator.on,
              date: DateTime(2025, 6, 15),
            ),
            isFalse,
          );
        });

        test('returns false when field is null', () {
          expect(
            DateComparison.evaluate(
              fieldValue: null,
              operator: DateOperator.on,
              date: baseDate,
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.before', () {
        test('returns true when field is before target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 14),
              operator: DateOperator.before,
              date: DateTime(2025, 6, 15),
            ),
            isTrue,
          );
        });

        test('returns false when field is same day', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15, 8),
              operator: DateOperator.before,
              date: DateTime(2025, 6, 15, 20),
            ),
            isFalse,
          );
        });

        test('returns false when field is after target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 16),
              operator: DateOperator.before,
              date: DateTime(2025, 6, 15),
            ),
            isFalse,
          );
        });

        test('returns false when field is null', () {
          expect(
            DateComparison.evaluate(
              fieldValue: null,
              operator: DateOperator.before,
              date: baseDate,
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.after', () {
        test('returns true when field is after target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 16),
              operator: DateOperator.after,
              date: DateTime(2025, 6, 15),
            ),
            isTrue,
          );
        });

        test('returns false when field is same day', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15, 20),
              operator: DateOperator.after,
              date: DateTime(2025, 6, 15, 8),
            ),
            isFalse,
          );
        });

        test('returns false when field is null', () {
          expect(
            DateComparison.evaluate(
              fieldValue: null,
              operator: DateOperator.after,
              date: baseDate,
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.onOrBefore', () {
        test('returns true when field is before target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 14),
              operator: DateOperator.onOrBefore,
              date: DateTime(2025, 6, 15),
            ),
            isTrue,
          );
        });

        test('returns true when field is same day', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15, 20),
              operator: DateOperator.onOrBefore,
              date: DateTime(2025, 6, 15, 8),
            ),
            isTrue,
          );
        });

        test('returns false when field is after target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 16),
              operator: DateOperator.onOrBefore,
              date: DateTime(2025, 6, 15),
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.onOrAfter', () {
        test('returns true when field is after target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 16),
              operator: DateOperator.onOrAfter,
              date: DateTime(2025, 6, 15),
            ),
            isTrue,
          );
        });

        test('returns true when field is same day', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15, 8),
              operator: DateOperator.onOrAfter,
              date: DateTime(2025, 6, 15, 20),
            ),
            isTrue,
          );
        });

        test('returns false when field is before target', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 14),
              operator: DateOperator.onOrAfter,
              date: DateTime(2025, 6, 15),
            ),
            isFalse,
          );
        });
      });

      group('DateOperator.between', () {
        test('returns true when field is within range', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 15),
              operator: DateOperator.between,
              startDate: DateTime(2025, 6, 10),
              endDate: DateTime(2025, 6, 20),
            ),
            isTrue,
          );
        });

        test('returns true when field is on start boundary', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 10, 23, 59),
              operator: DateOperator.between,
              startDate: DateTime(2025, 6, 10),
              endDate: DateTime(2025, 6, 20),
            ),
            isTrue,
          );
        });

        test('returns true when field is on end boundary', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 20),
              operator: DateOperator.between,
              startDate: DateTime(2025, 6, 10),
              endDate: DateTime(2025, 6, 20),
            ),
            isTrue,
          );
        });

        test('returns false when field is before range', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 9),
              operator: DateOperator.between,
              startDate: DateTime(2025, 6, 10),
              endDate: DateTime(2025, 6, 20),
            ),
            isFalse,
          );
        });

        test('returns false when field is after range', () {
          expect(
            DateComparison.evaluate(
              fieldValue: DateTime(2025, 6, 21),
              operator: DateOperator.between,
              startDate: DateTime(2025, 6, 10),
              endDate: DateTime(2025, 6, 20),
            ),
            isFalse,
          );
        });
      });
    });

    group('evaluateRelative()', () {
      final today = DateTime(2025, 6, 15);

      group('RelativeComparison.on', () {
        test('returns true when field matches pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 15, 10, 30),
              comparison: RelativeComparison.on,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns false when field differs from pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 16),
              comparison: RelativeComparison.on,
              pivot: today,
            ),
            isFalse,
          );
        });

        test('returns false when field is null', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: null,
              comparison: RelativeComparison.on,
              pivot: today,
            ),
            isFalse,
          );
        });
      });

      group('RelativeComparison.before', () {
        test('returns true when field is before pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 14),
              comparison: RelativeComparison.before,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns false when field equals pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: today,
              comparison: RelativeComparison.before,
              pivot: today,
            ),
            isFalse,
          );
        });
      });

      group('RelativeComparison.after', () {
        test('returns true when field is after pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 16),
              comparison: RelativeComparison.after,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns false when field equals pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: today,
              comparison: RelativeComparison.after,
              pivot: today,
            ),
            isFalse,
          );
        });
      });

      group('RelativeComparison.onOrBefore', () {
        test('returns true when field equals pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: today,
              comparison: RelativeComparison.onOrBefore,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns true when field is before pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 14),
              comparison: RelativeComparison.onOrBefore,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns false when field is after pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 16),
              comparison: RelativeComparison.onOrBefore,
              pivot: today,
            ),
            isFalse,
          );
        });
      });

      group('RelativeComparison.onOrAfter', () {
        test('returns true when field equals pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: today,
              comparison: RelativeComparison.onOrAfter,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns true when field is after pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 16),
              comparison: RelativeComparison.onOrAfter,
              pivot: today,
            ),
            isTrue,
          );
        });

        test('returns false when field is before pivot', () {
          expect(
            DateComparison.evaluateRelative(
              fieldValue: DateTime(2025, 6, 14),
              comparison: RelativeComparison.onOrAfter,
              pivot: today,
            ),
            isFalse,
          );
        });
      });
    });
  });

  group('BoolComparison', () {
    group('evaluate()', () {
      test('BoolOperator.isTrue returns true when field is true', () {
        expect(
          BoolComparison.evaluate(
            fieldValue: true,
            operator: BoolOperator.isTrue,
          ),
          isTrue,
        );
      });

      test('BoolOperator.isTrue returns false when field is false', () {
        expect(
          BoolComparison.evaluate(
            fieldValue: false,
            operator: BoolOperator.isTrue,
          ),
          isFalse,
        );
      });

      test('BoolOperator.isFalse returns true when field is false', () {
        expect(
          BoolComparison.evaluate(
            fieldValue: false,
            operator: BoolOperator.isFalse,
          ),
          isTrue,
        );
      });

      test('BoolOperator.isFalse returns false when field is true', () {
        expect(
          BoolComparison.evaluate(
            fieldValue: true,
            operator: BoolOperator.isFalse,
          ),
          isFalse,
        );
      });
    });
  });

  group('LabelComparison', () {
    group('evaluate()', () {
      final entityLabels = {'label-1', 'label-2', 'label-3'};

      group('LabelOperator.hasAny', () {
        test('returns true when any label matches', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: ['label-1', 'label-4'],
              operator: LabelOperator.hasAny,
            ),
            isTrue,
          );
        });

        test('returns false when no labels match', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: ['label-4', 'label-5'],
              operator: LabelOperator.hasAny,
            ),
            isFalse,
          );
        });

        test('returns false when predicate labels is empty', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: [],
              operator: LabelOperator.hasAny,
            ),
            isFalse,
          );
        });
      });

      group('LabelOperator.hasAll', () {
        test('returns true when all predicate labels match', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: ['label-1', 'label-2'],
              operator: LabelOperator.hasAll,
            ),
            isTrue,
          );
        });

        test('returns false when not all predicate labels match', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: ['label-1', 'label-4'],
              operator: LabelOperator.hasAll,
            ),
            isFalse,
          );
        });

        test('returns true when predicate labels is empty', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: [],
              operator: LabelOperator.hasAll,
            ),
            isTrue,
          );
        });
      });

      group('LabelOperator.isNull', () {
        test('returns true when entity has no labels', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: {},
              predicateLabelIds: [],
              operator: LabelOperator.isNull,
            ),
            isTrue,
          );
        });

        test('returns false when entity has labels', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: [],
              operator: LabelOperator.isNull,
            ),
            isFalse,
          );
        });
      });

      group('LabelOperator.isNotNull', () {
        test('returns true when entity has labels', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: entityLabels,
              predicateLabelIds: [],
              operator: LabelOperator.isNotNull,
            ),
            isTrue,
          );
        });

        test('returns false when entity has no labels', () {
          expect(
            LabelComparison.evaluate(
              entityLabelIds: {},
              predicateLabelIds: [],
              operator: LabelOperator.isNotNull,
            ),
            isFalse,
          );
        });
      });
    });
  });
}
