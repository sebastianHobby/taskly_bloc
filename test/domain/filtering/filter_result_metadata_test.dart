import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

void main() {
  group('FilterResultMetadata', () {
    test('isFullyApplied returns true when no pending rules or sort', () {
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

      expect(metadata.isFullyApplied, isTrue);
      expect(metadata.requiresPostProcessing, isFalse);
    });

    test('isFullyApplied returns false when there are pending rules', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [
          LabelRule(
            operator: LabelRuleOperator.hasAll,
            labelIds: ['label1'],
          ),
        ],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.isFullyApplied, isFalse);
      expect(metadata.requiresPostProcessing, isTrue);
    });

    test(
      'isFullyApplied returns false when there are pending sort criteria',
      () {
        const metadata = FilterResultMetadata(
          appliedRules: [],
          pendingRules: [],
          appliedSort: [],
          pendingSort: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(metadata.isFullyApplied, isFalse);
        expect(metadata.requiresPostProcessing, isTrue);
      },
    );

    test(
      'isFullyApplied returns false when both pending rules and sort exist',
      () {
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
              labelIds: ['label1'],
            ),
          ],
          appliedSort: [
            SortCriterion(field: SortField.deadlineDate),
          ],
          pendingSort: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(metadata.isFullyApplied, isFalse);
        expect(metadata.requiresPostProcessing, isTrue);
      },
    );

    test('hasPendingRules returns true when pending rules exist', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [
          LabelRule(
            operator: LabelRuleOperator.hasAll,
            labelIds: ['label1'],
          ),
        ],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.hasPendingRules, isTrue);
    });

    test('hasPendingRules returns false when no pending rules', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.hasPendingRules, isFalse);
    });

    test('hasPendingSort returns true when pending sort criteria exist', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [
          SortCriterion(field: SortField.name),
          SortCriterion(field: SortField.deadlineDate),
        ],
      );

      expect(metadata.hasPendingSort, isTrue);
    });

    test('hasPendingSort returns false when no pending sort criteria', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.hasPendingSort, isFalse);
    });

    test('requiresPostProcessing matches isFullyApplied inverse', () {
      const fullyApplied = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
      );
      expect(fullyApplied.requiresPostProcessing, isFalse);
      expect(fullyApplied.isFullyApplied, isTrue);

      const notFullyApplied = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [
          LabelRule(
            operator: LabelRuleOperator.hasAll,
            labelIds: ['label1'],
          ),
        ],
        appliedSort: [],
        pendingSort: [],
      );
      expect(notFullyApplied.requiresPostProcessing, isTrue);
      expect(notFullyApplied.isFullyApplied, isFalse);
    });

    test('occurrencesExpanded defaults to false', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.occurrencesExpanded, isFalse);
    });

    test('occurrencesExpanded can be set to true', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
        occurrencesExpanded: true,
      );

      expect(metadata.occurrencesExpanded, isTrue);
    });

    test('expansionRange is optional', () {
      const metadata = FilterResultMetadata(
        appliedRules: [],
        pendingRules: [],
        appliedSort: [],
        pendingSort: [],
      );

      expect(metadata.expansionRange, isNull);
    });

    test('expansionRange can be provided', () {
      final start = DateTime(2024);
      final end = DateTime(2024, 12, 31);
      final range = DateRange(start: start, end: end);

      final metadata = FilterResultMetadata(
        appliedRules: const [],
        pendingRules: const [],
        appliedSort: const [],
        pendingSort: const [],
        expansionRange: range,
      );

      expect(metadata.expansionRange, range);
      expect(metadata.expansionRange!.start, start);
      expect(metadata.expansionRange!.end, end);
    });

    test('multiple rules and sort criteria are tracked correctly', () {
      const metadata = FilterResultMetadata(
        appliedRules: [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
          DateRule(
            field: DateRuleField.deadlineDate,
            operator: DateRuleOperator.onOrBefore,
          ),
        ],
        pendingRules: [
          LabelRule(
            operator: LabelRuleOperator.hasAll,
            labelIds: ['label1'],
          ),
          LabelRule(
            operator: LabelRuleOperator.hasAll,
            labelIds: ['label2'],
          ),
        ],
        appliedSort: [
          SortCriterion(field: SortField.deadlineDate),
          SortCriterion(field: SortField.startDate),
        ],
        pendingSort: [
          SortCriterion(field: SortField.name),
        ],
      );

      expect(metadata.appliedRules.length, 2);
      expect(metadata.pendingRules.length, 2);
      expect(metadata.appliedSort.length, 2);
      expect(metadata.pendingSort.length, 1);
      expect(metadata.hasPendingRules, isTrue);
      expect(metadata.hasPendingSort, isTrue);
      expect(metadata.isFullyApplied, isFalse);
    });
  });

  group('DateRange', () {
    test('creates date range with start and end', () {
      final start = DateTime(2024);
      final end = DateTime(2024, 12, 31);
      final range = DateRange(start: start, end: end);

      expect(range.start, start);
      expect(range.end, end);
    });

    test('equality works correctly', () {
      final start = DateTime(2024);
      final end = DateTime(2024, 12, 31);
      final range1 = DateRange(start: start, end: end);
      final range2 = DateRange(start: start, end: end);
      final range3 = DateRange(
        start: DateTime(2024, 2),
        end: DateTime(2024, 12, 31),
      );

      expect(range1, range2);
      expect(range1, isNot(range3));
      expect(range1.hashCode, range2.hashCode);
    });

    test('handles same start and end date', () {
      final date = DateTime(2024, 6, 15);
      final range = DateRange(start: date, end: date);

      expect(range.start, date);
      expect(range.end, date);
    });
  });
}
