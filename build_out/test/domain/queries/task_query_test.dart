import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

void main() {
  group('TaskQuery factories', () {
    group('inbox', () {
      test('creates query with completed=false rule', () {
        final query = TaskQuery.inbox();

        expect(query.rules.length, 1);
        expect(query.rules.first, isA<BooleanRule>());

        final rule = query.rules.first as BooleanRule;
        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isFalse);
      });

      test('uses default sort criteria', () {
        final query = TaskQuery.inbox();

        expect(query.sortCriteria.isNotEmpty, isTrue);
        expect(query.sortCriteria.first.field, SortField.deadlineDate);
      });

      test('accepts custom sort criteria', () {
        final customSort = [
          const SortCriterion(field: SortField.name),
        ];
        final query = TaskQuery.inbox(sortCriteria: customSort);

        expect(query.sortCriteria, customSort);
      });
    });

    group('today', () {
      test('creates query with completed=false and deadline<=today rules', () {
        final now = DateTime(2025, 12, 25, 14, 30);
        final query = TaskQuery.today(now: now);

        expect(query.rules.length, 2);

        // Boolean rule for incomplete
        final boolRule = query.rules.whereType<BooleanRule>().first;
        expect(boolRule.field, BooleanRuleField.completed);
        expect(boolRule.operator, BooleanRuleOperator.isFalse);

        // Date rule for deadline
        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.field, DateRuleField.deadlineDate);
        expect(dateRule.operator, DateRuleOperator.onOrBefore);
        expect(dateRule.date, dateOnly(now));
      });

      test('normalizes date to midnight', () {
        final now = DateTime(2025, 12, 25, 14, 30, 45);
        final query = TaskQuery.today(now: now);

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.date?.hour, 0);
        expect(dateRule.date?.minute, 0);
        expect(dateRule.date?.second, 0);
      });
    });

    group('upcoming', () {
      test('creates query with completed=false and deadline!=null rules', () {
        final query = TaskQuery.upcoming();

        expect(query.rules.length, 2);

        final boolRule = query.rules.whereType<BooleanRule>().first;
        expect(boolRule.operator, BooleanRuleOperator.isFalse);

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.field, DateRuleField.deadlineDate);
        expect(dateRule.operator, DateRuleOperator.isNotNull);
      });
    });

    group('forProject', () {
      test('creates query with project filter', () {
        final query = TaskQuery.forProject(projectId: 'proj-123');

        expect(query.rules.length, 1);
        expect(query.rules.first, isA<ProjectRule>());

        final rule = query.rules.first as ProjectRule;
        expect(rule.operator, ProjectRuleOperator.matches);
        expect(rule.projectId, 'proj-123');
      });
    });

    group('forLabel', () {
      test('creates query with label filter', () {
        final query = TaskQuery.forLabel(labelId: 'label-456');

        expect(query.rules.length, 1);
        expect(query.rules.first, isA<LabelRule>());

        final rule = query.rules.first as LabelRule;
        expect(rule.operator, LabelRuleOperator.hasAll);
        expect(rule.labelIds, ['label-456']);
      });

      test('accepts custom label type', () {
        final query = TaskQuery.forLabel(
          labelId: 'value-789',
          labelType: LabelType.value,
        );

        final rule = query.rules.first as LabelRule;
        expect(rule.labelType, LabelType.value);
      });
    });

    group('nextActions', () {
      test('creates query with completed=false and project=null rules', () {
        final query = TaskQuery.nextActions();

        expect(query.rules.length, 2);

        final boolRule = query.rules.whereType<BooleanRule>().first;
        expect(boolRule.operator, BooleanRuleOperator.isFalse);

        final projectRule = query.rules.whereType<ProjectRule>().first;
        expect(projectRule.operator, ProjectRuleOperator.isNull);
      });
    });

    group('schedule', () {
      test('creates query with date range and occurrence expansion', () {
        final start = DateTime(2025, 12);
        final end = DateTime(2025, 12, 31);
        final query = TaskQuery.schedule(rangeStart: start, rangeEnd: end);

        expect(query.rules.length, 2);
        expect(query.occurrenceExpansion, isNotNull);
        expect(query.occurrenceExpansion?.rangeStart, start);
        expect(query.occurrenceExpansion?.rangeEnd, end);
      });
    });

    group('all', () {
      test('creates query with no rules', () {
        final query = TaskQuery.all();

        expect(query.rules, isEmpty);
      });

      test('uses default sort criteria', () {
        final query = TaskQuery.all();

        expect(query.sortCriteria.isNotEmpty, isTrue);
      });
    });
  });

  group('TaskQuery helper properties', () {
    test('needsLabels returns true when LabelRule present', () {
      final query = TaskQuery.forLabel(labelId: 'label-1');
      expect(query.needsLabels, isTrue);
    });

    test('needsLabels returns false when no LabelRule', () {
      final query = TaskQuery.inbox();
      expect(query.needsLabels, isFalse);
    });

    test('shouldExpandOccurrences returns true when expansion configured', () {
      final query = TaskQuery.schedule(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      expect(query.shouldExpandOccurrences, isTrue);
    });

    test('shouldExpandOccurrences returns false when no expansion', () {
      final query = TaskQuery.inbox();
      expect(query.shouldExpandOccurrences, isFalse);
    });

    test('hasProjectFilter returns true when ProjectRule present', () {
      final query = TaskQuery.forProject(projectId: 'p1');
      expect(query.hasProjectFilter, isTrue);
    });

    test('hasDateFilter returns true when DateRule present', () {
      final query = TaskQuery.today(now: DateTime.now());
      expect(query.hasDateFilter, isTrue);
    });
  });

  group('TaskQuery modification methods', () {
    test('copyWith creates new instance with modified rules', () {
      final original = TaskQuery.inbox();
      final modified = original.copyWith(
        rules: [
          const ProjectRule(operator: ProjectRuleOperator.isNull),
        ],
      );

      expect(modified.rules.length, 1);
      expect(modified.rules.first, isA<ProjectRule>());
      expect(original.rules.first, isA<BooleanRule>()); // Original unchanged
    });

    test('withAdditionalRules appends rules', () {
      final original = TaskQuery.inbox();
      final modified = original.withAdditionalRules([
        const ProjectRule(operator: ProjectRuleOperator.isNull),
      ]);

      expect(modified.rules.length, 2);
      expect(modified.rules.first, isA<BooleanRule>());
      expect(modified.rules.last, isA<ProjectRule>());
    });

    test('withSortCriteria replaces sort criteria', () {
      final original = TaskQuery.inbox();
      final newSort = [const SortCriterion(field: SortField.name)];
      final modified = original.withSortCriteria(newSort);

      expect(modified.sortCriteria, newSort);
      expect(modified.rules, original.rules); // Rules unchanged
    });

    test('withOccurrenceExpansion adds expansion', () {
      final original = TaskQuery.inbox();
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      final modified = original.withOccurrenceExpansion(expansion);

      expect(modified.occurrenceExpansion, expansion);
      expect(original.occurrenceExpansion, isNull);
    });

    test('copyWith with clearOccurrenceExpansion removes expansion', () {
      final withExpansion = TaskQuery.schedule(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      final withoutExpansion = withExpansion.copyWith(
        clearOccurrenceExpansion: true,
      );

      expect(withExpansion.occurrenceExpansion, isNotNull);
      expect(withoutExpansion.occurrenceExpansion, isNull);
    });
  });

  group('TaskQuery equality', () {
    test('equal queries have same hashCode', () {
      final query1 = TaskQuery.inbox();
      final query2 = TaskQuery.inbox();

      expect(query1, equals(query2));
      expect(query1.hashCode, query2.hashCode);
    });

    test('different rules produce different queries', () {
      final inbox = TaskQuery.inbox();
      final upcoming = TaskQuery.upcoming();

      expect(inbox, isNot(equals(upcoming)));
    });

    test('different sort criteria produce different queries', () {
      final query1 = TaskQuery.inbox();
      final query2 = TaskQuery.inbox(
        sortCriteria: const [SortCriterion(field: SortField.name)],
      );

      expect(query1, isNot(equals(query2)));
    });

    test('different occurrence expansion produce different queries', () {
      final query1 = TaskQuery.all();
      final query2 = query1.withOccurrenceExpansion(
        OccurrenceExpansion(
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        ),
      );

      expect(query1, isNot(equals(query2)));
    });
  });

  group('TaskQuery toString', () {
    test('produces readable output', () {
      final query = TaskQuery.inbox();
      final str = query.toString();

      expect(str, contains('TaskQuery'));
      expect(str, contains('rules'));
      expect(str, contains('sortCriteria'));
    });
  });
}
