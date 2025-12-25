import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_filter_config.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/label.dart';

void main() {
  group('TaskFilterConfig', () {
    group('Rule Partitioning', () {
      test('_partitionRules splits DateRule to SQL rules', () {
        final config = TaskFilterConfig.fromRules(
          rules: [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: DateTime(2024, 12, 31),
            ),
          ],
        );

        expect(config.sqlRules.length, 1);
        expect(config.dartRules.length, 0);
        expect(config.sqlRules.first, isA<DateRule>());
      });

      test('_partitionRules splits BooleanRule to SQL rules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
        );

        expect(config.sqlRules.length, 1);
        expect(config.dartRules.length, 0);
        expect(config.sqlRules.first, isA<BooleanRule>());
      });

      test('_partitionRules splits ProjectRule to SQL rules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            ProjectRule(
              operator: ProjectRuleOperator.matches,
              projectId: 'project-123',
            ),
          ],
        );

        expect(config.sqlRules.length, 1);
        expect(config.dartRules.length, 0);
        expect(config.sqlRules.first, isA<ProjectRule>());
      });

      test('_partitionRules splits LabelRule to Dart rules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-123'],
            ),
          ],
        );

        expect(config.sqlRules.length, 0);
        expect(config.dartRules.length, 1);
        expect(config.dartRules.first, isA<LabelRule>());
      });

      test('_partitionRules splits ValueRule to Dart rules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            ValueRule(
              operator: ValueRuleOperator.hasAll,
              labelIds: ['test-label-id'],
            ),
          ],
        );

        expect(config.sqlRules.length, 0);
        expect(config.dartRules.length, 1);
        expect(config.dartRules.first, isA<ValueRule>());
      });

      test('_partitionRules handles mixed rules correctly', () {
        final config = TaskFilterConfig.fromRules(
          rules: [
            const BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: DateTime(2024, 12, 31),
            ),
            const ProjectRule(
              operator: ProjectRuleOperator.matches,
              projectId: 'project-123',
            ),
            const LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-123'],
            ),
            const ValueRule(
              operator: ValueRuleOperator.hasAll,
              labelIds: ['important-label-id'],
            ),
          ],
        );

        expect(config.sqlRules.length, 3);
        expect(config.dartRules.length, 2);
        expect(config.sqlRules.any((r) => r is BooleanRule), isTrue);
        expect(config.sqlRules.any((r) => r is DateRule), isTrue);
        expect(config.sqlRules.any((r) => r is ProjectRule), isTrue);
        expect(config.dartRules.any((r) => r is LabelRule), isTrue);
        expect(config.dartRules.any((r) => r is ValueRule), isTrue);
      });
    });

    group('Factory Methods', () {
      test('inbox creates correct configuration', () {
        final config = TaskFilterConfig.inbox();

        expect(config.allRules.length, 1);
        expect(config.allRules.first, isA<BooleanRule>());
        final rule = config.allRules.first as BooleanRule;
        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isFalse);
        expect(config.withRelated, isTrue);
        expect(config.sortCriteria.length, 3);
      });

      test('inbox accepts custom sort criteria', () {
        const customSort = [
          SortCriterion(field: SortField.name),
        ];
        final config = TaskFilterConfig.inbox(sortCriteria: customSort);

        expect(config.sortCriteria, customSort);
      });

      test('today creates correct configuration', () {
        final now = DateTime(2024, 6, 15, 14, 30);
        final config = TaskFilterConfig.today(now: now);

        expect(config.allRules.length, 2);
        expect(config.allRules.any((r) => r is BooleanRule), isTrue);
        expect(config.allRules.any((r) => r is DateRule), isTrue);

        final dateRule = config.allRules.whereType<DateRule>().first;
        expect(dateRule.field, DateRuleField.deadlineDate);
        expect(dateRule.operator, DateRuleOperator.onOrBefore);
        expect(dateRule.date?.year, 2024);
        expect(dateRule.date?.month, 6);
        expect(dateRule.date?.day, 15);
        expect(dateRule.date?.hour, 0); // Normalized to midnight
        expect(config.withRelated, isTrue);
      });

      test('upcoming creates correct configuration', () {
        final config = TaskFilterConfig.upcoming();

        expect(config.allRules.length, 2);
        expect(config.allRules.any((r) => r is BooleanRule), isTrue);
        expect(config.allRules.any((r) => r is DateRule), isTrue);

        final dateRule = config.allRules.whereType<DateRule>().first;
        expect(dateRule.field, DateRuleField.deadlineDate);
        expect(dateRule.operator, DateRuleOperator.isNotNull);
        expect(config.withRelated, isTrue);
      });

      test('forProject creates correct configuration', () {
        const projectId = 'project-abc-123';
        final config = TaskFilterConfig.forProject(projectId: projectId);

        expect(config.allRules.length, 1);
        expect(config.allRules.first, isA<ProjectRule>());
        final rule = config.allRules.first as ProjectRule;
        expect(rule.operator, ProjectRuleOperator.matches);
        expect(rule.projectId, projectId);
        expect(config.withRelated, isTrue);
      });

      test('forLabel creates correct configuration', () {
        const labelId = 'label-xyz-456';
        final config = TaskFilterConfig.forLabel(labelId: labelId);

        expect(config.allRules.length, 1);
        expect(config.allRules.first, isA<LabelRule>());
        final rule = config.allRules.first as LabelRule;
        expect(rule.operator, LabelRuleOperator.hasAll);
        expect(rule.labelIds, [labelId]);
        expect(rule.labelType, LabelType.label);
        expect(config.withRelated, isTrue);
      });

      test('forLabel accepts custom label type', () {
        const labelId = 'context-123';
        final config = TaskFilterConfig.forLabel(
          labelId: labelId,
          labelType: LabelType.value,
        );

        final rule = config.allRules.first as LabelRule;
        expect(rule.labelType, LabelType.value);
      });

      test('nextActions creates correct configuration', () {
        final config = TaskFilterConfig.nextActions();

        expect(config.allRules.length, 2);
        expect(config.allRules.any((r) => r is BooleanRule), isTrue);
        expect(config.allRules.any((r) => r is ProjectRule), isTrue);

        final projectRule = config.allRules.whereType<ProjectRule>().first;
        expect(projectRule.operator, ProjectRuleOperator.isNull);
        expect(config.withRelated, isTrue);
      });

      test('all creates correct configuration', () {
        final config = TaskFilterConfig.all();

        expect(config.allRules.isEmpty, isTrue);
        expect(config.withRelated, isTrue);
        expect(config.sortCriteria.length, 3);
      });
    });

    group('Configuration Properties', () {
      test('withRelated flag is respected', () {
        final configWithRelated = TaskFilterConfig.fromRules(
          rules: const [],
          withRelated: true,
        );
        final configWithoutRelated = TaskFilterConfig.fromRules(
          rules: const [],
        );

        expect(configWithRelated.withRelated, isTrue);
        expect(configWithoutRelated.withRelated, isFalse);
      });

      test('expandOccurrences flag is respected', () {
        final configWithExpansion = TaskFilterConfig.fromRules(
          rules: const [],
          expandOccurrences: true,
        );
        final configWithoutExpansion = TaskFilterConfig.fromRules(
          rules: const [],
        );

        expect(configWithExpansion.expandOccurrences, isTrue);
        expect(configWithoutExpansion.expandOccurrences, isFalse);
      });

      test('occurrenceRange is optional', () {
        final config = TaskFilterConfig.fromRules(rules: const []);

        expect(config.occurrenceRange, isNull);
      });

      test('occurrenceRange can be provided', () {
        final start = DateTime(2024);
        final end = DateTime(2024, 12, 31);
        final range = DateRange(start: start, end: end);

        final config = TaskFilterConfig.fromRules(
          rules: const [],
          occurrenceRange: range,
        );

        expect(config.occurrenceRange, range);
      });

      test('sortCriteria defaults to empty list', () {
        const config = TaskFilterConfig(
          sqlRules: [],
          dartRules: [],
        );

        expect(config.sortCriteria, isEmpty);
      });

      test('sortCriteria can be provided', () {
        const criteria = [
          SortCriterion(field: SortField.name),
          SortCriterion(
            field: SortField.createdDate,
            direction: SortDirection.descending,
          ),
        ];
        const config = TaskFilterConfig(
          sqlRules: [],
          dartRules: [],
          sortCriteria: criteria,
        );

        expect(config.sortCriteria, criteria);
      });
    });

    group('Computed Properties', () {
      test('allRules combines sqlRules and dartRules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-123'],
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.isNotNull,
            ),
          ],
        );

        expect(config.allRules.length, 3);
        expect(config.allRules.whereType<BooleanRule>().length, 1);
        expect(config.allRules.whereType<LabelRule>().length, 1);
        expect(config.allRules.whereType<DateRule>().length, 1);
      });

      test('requiresPostProcessing returns true when dartRules exist', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: ['label-123'],
            ),
          ],
        );

        expect(config.requiresPostProcessing, isTrue);
      });

      test('requiresPostProcessing returns false when no dartRules', () {
        final config = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
        );

        expect(config.requiresPostProcessing, isFalse);
      });
    });

    group('Equality', () {
      test('configs with same properties are equal', () {
        final config1 = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          withRelated: true,
        );

        final config2 = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          withRelated: true,
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('configs with different rules are not equal', () {
        final config1 = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
        );

        final config2 = TaskFilterConfig.fromRules(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isTrue,
            ),
          ],
        );

        expect(config1, isNot(config2));
      });

      test('configs with different flags are not equal', () {
        final config1 = TaskFilterConfig.fromRules(
          rules: const [],
          withRelated: true,
        );

        final config2 = TaskFilterConfig.fromRules(
          rules: const [],
        );

        expect(config1, isNot(config2));
      });
    });
  });
}
