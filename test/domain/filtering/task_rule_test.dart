@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/task_rules.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskRule.fromJson', () {
    testSafe('defaults to BooleanRule when type is missing or unknown', () async {
      final missing = TaskRule.fromJson(const <String, dynamic>{});
      final unknown = TaskRule.fromJson(const <String, dynamic>{'type': 'nope'});

      expect(missing, isA<BooleanRule>());
      expect(unknown, isA<BooleanRule>());
    });

    testSafe('hydrates known rule types', () async {
      final dateRule = TaskRule.fromJson(const <String, dynamic>{
        'type': 'date',
        'field': 'deadlineDate',
        'operator': 'on',
        'date': '2025-01-15',
      });
      final boolRule = TaskRule.fromJson(const <String, dynamic>{
        'type': 'boolean',
        'field': 'completed',
        'operator': 'isTrue',
      });
      final valueRule = TaskRule.fromJson(const <String, dynamic>{
        'type': 'value',
        'operator': 'hasAny',
        'valueIds': ['v1'],
      });
      final projectRule = TaskRule.fromJson(const <String, dynamic>{
        'type': 'project',
        'operator': 'matches',
        'projectId': 'p1',
      });

      expect(dateRule, isA<DateRule>());
      expect(boolRule, isA<BooleanRule>());
      expect(valueRule, isA<ValueRule>());
      expect(projectRule, isA<ProjectRule>());
    });
  });

  group('DateRule', () {
    testSafe('validates required fields per operator', () async {
      final between = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
      );
      final relative = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
      );
      final onOrAfter = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrAfter,
      );
      final isNull = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.isNull,
      );

      expect(between.validate(), isNotEmpty);
      expect(relative.validate(), isNotEmpty);
      expect(onOrAfter.validate(), isNotEmpty);
      expect(isNull.validate(), isEmpty);
    });

    testSafe('evaluates date operators using date-only semantics', () async {
      final task = TestData.task(
        deadlineDate: DateTime(2025, 1, 15, 18),
        startDate: DateTime(2025, 1, 10, 9),
      );

      final onOrAfter = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrAfter,
        date: DateTime(2025, 1, 15, 1),
      );
      final onOrBefore = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrBefore,
        date: DateTime(2025, 1, 14, 23),
      );
      final on = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.on,
        date: DateTime(2025, 1, 15, 0),
      );
      final between = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.between,
        startDate: DateTime(2025, 1, 9),
        endDate: DateTime(2025, 1, 12),
      );

      expect(onOrAfter.applies(task, TestConstants.referenceDate), isTrue);
      expect(onOrBefore.applies(task, TestConstants.referenceDate), isFalse);
      expect(on.applies(task, TestConstants.referenceDate), isTrue);
      expect(between.applies(task, TestConstants.referenceDate), isTrue);
    });

    testSafe('evaluates relative operators against today', () async {
      final today = DateTime(2025, 1, 15, 12);
      final task = TestData.task(deadlineDate: DateTime(2025, 1, 17, 9));

      final relativeOn = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
        relativeComparison: RelativeComparison.on,
        relativeDays: 2,
      );
      final relativeBefore = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
        relativeComparison: RelativeComparison.before,
        relativeDays: 1,
      );

      expect(relativeOn.applies(task, today), isTrue);
      expect(relativeBefore.applies(task, today), isFalse);
    });

    testSafe('handles null date targets', () async {
      final task = TestData.task(startDate: null);

      final isNull = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.isNull,
      );
      final isNotNull = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.isNotNull,
      );

      expect(isNull.applies(task, TestConstants.referenceDate), isTrue);
      expect(isNotNull.applies(task, TestConstants.referenceDate), isFalse);
    });

    testSafe('matches completedAt via occurrence data', () async {
      final task = TestData.task(
        occurrence: TestData.occurrenceData(
          completedAt: DateTime(2025, 1, 20, 9),
        ),
      );
      final rule = DateRule(
        field: DateRuleField.completedAt,
        operator: DateRuleOperator.on,
        date: DateTime(2025, 1, 20, 22),
      );

      expect(rule.applies(task, TestConstants.referenceDate), isTrue);
    });
  });

  group('BooleanRule', () {
    testSafe('applies based on boolean operator', () async {
      final completed = TestData.task(completed: true);
      final isTrue = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isTrue,
      );
      final isFalse = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      );

      expect(isTrue.applies(completed, TestConstants.referenceDate), isTrue);
      expect(isFalse.applies(completed, TestConstants.referenceDate), isFalse);
    });
  });

  group('ValueRule', () {
    testSafe('validates required value IDs for hasAny/hasAll', () async {
      final empty = ValueRule(operator: ValueRuleOperator.hasAny);
      final blanks = ValueRule(
        operator: ValueRuleOperator.hasAll,
        valueIds: const [' ', ''],
      );
      final isNull = ValueRule(operator: ValueRuleOperator.isNull);

      expect(empty.validate(), isNotEmpty);
      expect(blanks.validate(), isNotEmpty);
      expect(isNull.validate(), isEmpty);
    });

    testSafe('applies value operators against task values', () async {
      final urgent = TestData.value(id: 'urgent');
      final work = TestData.value(id: 'work');
      final task = TestData.task(values: [urgent, work]);

      final hasAll = ValueRule(
        operator: ValueRuleOperator.hasAll,
        valueIds: const ['urgent', 'work'],
      );
      final hasAny = ValueRule(
        operator: ValueRuleOperator.hasAny,
        valueIds: const ['missing', 'urgent'],
      );
      final isNull = ValueRule(operator: ValueRuleOperator.isNull);

      expect(hasAll.applies(task, TestConstants.referenceDate), isTrue);
      expect(hasAny.applies(task, TestConstants.referenceDate), isTrue);
      expect(isNull.applies(task, TestConstants.referenceDate), isFalse);
    });
  });

  group('ProjectRule', () {
    testSafe('validates required project IDs', () async {
      final matches = ProjectRule(
        operator: ProjectRuleOperator.matches,
      );
      final matchesAny = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
      );
      final isNotNull = ProjectRule(
        operator: ProjectRuleOperator.isNotNull,
      );

      expect(matches.validate(), isNotEmpty);
      expect(matchesAny.validate(), isNotEmpty);
      expect(isNotNull.validate(), isEmpty);
    });

    testSafe('applies project operators', () async {
      final task = TestData.task(projectId: 'project-1');
      final matches = ProjectRule(
        operator: ProjectRuleOperator.matches,
        projectId: 'project-1',
      );
      final matchesAny = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: const ['project-2', 'project-1'],
      );
      final isNull = ProjectRule(operator: ProjectRuleOperator.isNull);

      expect(matches.applies(task, TestConstants.referenceDate), isTrue);
      expect(matchesAny.applies(task, TestConstants.referenceDate), isTrue);
      expect(isNull.applies(task, TestConstants.referenceDate), isFalse);
    });

    testSafe('compares list order for equality', () async {
      const ruleA = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: ['a', 'b'],
      );
      const ruleB = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: ['b', 'a'],
      );

      expect(ruleA == ruleB, isFalse);
    });
  });
}
