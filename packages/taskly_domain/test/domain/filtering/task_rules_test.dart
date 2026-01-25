@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/src/filtering/evaluation_context.dart';
import 'package:taskly_domain/task_rules.dart';

void main() {
  Value value(String id) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'V$id',
    );
  }

  Task task({
    DateTime? startDate,
    DateTime? deadlineDate,
    bool completed = false,
    String? projectId,
    Project? project,
    List<Value> values = const <Value>[],
    String? overridePrimaryValueId,
    String? overrideSecondaryValueId,
    OccurrenceData? occurrence,
  }) {
    return Task(
      id: 't1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      name: 'Task',
      completed: completed,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId ?? project?.id,
      project: project,
      values: values,
      overridePrimaryValueId: overridePrimaryValueId,
      overrideSecondaryValueId: overrideSecondaryValueId,
      occurrence: occurrence,
    );
  }

  testSafe(
    'TaskRule.fromJson falls back to BooleanRule on unknown type',
    () async {
      final rule = TaskRule.fromJson(<String, dynamic>{
        'type': 'not-a-real-rule-type',
        'field': BooleanRuleField.completed.name,
        'operator': BooleanRuleOperator.isTrue.name,
      });

      expect(rule, isA<BooleanRule>());
    },
  );

  group('DateRule.validate', () {
    testSafe('between requires startDate and endDate', () async {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: null,
        endDate: null,
      );

      expect(
        rule.validate(),
        contains('Between operator requires both start and end dates'),
      );
    });

    testSafe('between requires endDate not before startDate', () async {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: DateTime.utc(2026, 1, 10),
        endDate: DateTime.utc(2026, 1, 9),
      );

      expect(rule.validate(), contains('End date must be after start date'));
    });

    testSafe('onOrAfter requires a date', () async {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrAfter,
        date: null,
      );

      expect(rule.validate().single, contains('requires a date value'));
    });

    testSafe('relative requires comparison and days', () async {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
      );

      final errors = rule.validate();
      expect(errors, contains('Relative operator requires comparison type'));
      expect(errors, contains('Relative operator requires days value'));
    });
  });

  group('DateRule.applies', () {
    testSafe('onOrAfter matches when target is on pivot date', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 20, 9));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrAfter,
        date: DateTime.utc(2026, 1, 20, 23, 59),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('before matches when target is before pivot date', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(startDate: DateTime.utc(2026, 1, 10, 9));

      final rule = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.before,
        date: DateTime.utc(2026, 1, 11),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('on matches exact date-only equality', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(startDate: DateTime.utc(2026, 1, 10, 22, 10));

      final rule = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.on,
        date: DateTime.utc(2026, 1, 10, 0, 0, 1),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('between matches inclusive range', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 15, 12));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: DateTime.utc(2026, 1, 10),
        endDate: DateTime.utc(2026, 1, 15, 23, 59),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('relative builds pivot from today + days', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 20, 8));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
        relativeComparison: RelativeComparison.on,
        relativeDays: 2,
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('isNull matches null target', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: null);

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.isNull,
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('completedAt uses occurrence.completedAt', () async {
      final today = DateTime.utc(2026, 1, 18);

      final t = task(
        occurrence: OccurrenceData(
          date: DateTime.utc(2026, 1, 17),
          isRescheduled: false,
          completionId: 'c1',
          completedAt: DateTime.utc(2026, 1, 18, 9),
        ),
      );

      final rule = DateRule(
        field: DateRuleField.completedAt,
        operator: DateRuleOperator.on,
        date: DateTime.utc(2026, 1, 18),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('onOrBefore matches when target is before pivot date', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 10));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrBefore,
        date: DateTime.utc(2026, 1, 11),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('after matches when target is after pivot date', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(startDate: DateTime.utc(2026, 1, 12));

      final rule = DateRule(
        field: DateRuleField.startDate,
        operator: DateRuleOperator.after,
        date: DateTime.utc(2026, 1, 11),
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('between returns false when end is before start', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 15));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: DateTime.utc(2026, 1, 20),
        endDate: DateTime.utc(2026, 1, 10),
      );

      expect(rule.applies(t, today), isFalse);
    });

    testSafe('relative supports onOrBefore', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 19));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
        relativeComparison: RelativeComparison.onOrBefore,
        relativeDays: 1,
      );

      expect(rule.applies(t, today), isTrue);
    });

    testSafe('isNotNull matches non-null target', () async {
      final today = DateTime.utc(2026, 1, 18);
      final t = task(deadlineDate: DateTime.utc(2026, 1, 20));

      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.isNotNull,
      );

      expect(rule.applies(t, today), isTrue);
    });
  });

  group('BooleanRule', () {
    testSafe('isTrue matches completed=true', () async {
      final t = task(completed: true);
      final rule = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isTrue,
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('isFalse matches completed=false', () async {
      final t = task(completed: false);
      final rule = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });
  });

  group('ValueRule', () {
    testSafe('isNull matches empty values', () async {
      final t = task(values: const <Value>[]);
      final rule = ValueRule(operator: ValueRuleOperator.isNull);

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('hasAll requires all ids present', () async {
      final v1 = value('a');
      final v2 = value('b');
      final project = Project(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        values: [v1, v2],
        primaryValueId: 'a',
      );
      final t = task(
        project: project,
        values: [v2],
        overridePrimaryValueId: 'b',
      );
      final rule = ValueRule(
        operator: ValueRuleOperator.hasAll,
        valueIds: const ['a', 'b'],
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('hasAny matches when any id present', () async {
      final v1 = value('a');
      final project = Project(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        values: [v1],
        primaryValueId: 'a',
      );
      final t = task(project: project);
      final rule = ValueRule(
        operator: ValueRuleOperator.hasAny,
        valueIds: const ['x', 'a'],
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('validate requires non-empty ids for hasAll/hasAny', () async {
      final empty = ValueRule(operator: ValueRuleOperator.hasAll);
      expect(empty.validate(), isNotEmpty);

      final whitespace = ValueRule(
        operator: ValueRuleOperator.hasAny,
        valueIds: const ['   '],
      );
      expect(whitespace.validate(), contains('All value IDs are empty'));
    });

    testSafe('toJson/fromJson roundtrips', () async {
      final rule = ValueRule(
        operator: ValueRuleOperator.hasAny,
        valueIds: const ['a', 'b'],
      );

      final decoded = TaskRule.fromJson(rule.toJson());
      expect(decoded, equals(rule));
    });

    testSafe('isNotNull matches when task has any values', () async {
      final v1 = value('a');
      final project = Project(
        id: 'p1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Project',
        completed: false,
        values: [v1],
        primaryValueId: 'a',
      );
      final t = task(project: project);
      final rule = ValueRule(operator: ValueRuleOperator.isNotNull);

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
      expect(rule.validate(), isEmpty);
    });
  });

  group('ProjectRule', () {
    testSafe('matches compares exact projectId', () async {
      final t = task(projectId: 'p1');
      final rule = ProjectRule(
        operator: ProjectRuleOperator.matches,
        projectId: 'p1',
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('matchesAny checks membership', () async {
      final t = task(projectId: 'p2');
      final rule = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: const ['p1', 'p2'],
      );

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('isNull matches missing project', () async {
      final t = task(projectId: null);
      final rule = ProjectRule(operator: ProjectRuleOperator.isNull);

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
    });

    testSafe('validate enforces required ids', () async {
      final missing = ProjectRule(operator: ProjectRuleOperator.matches);
      expect(
        missing.validate(),
        contains('Matches operator requires a project ID'),
      );

      final anyEmpty = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: const ['   '],
      );
      expect(anyEmpty.validate(), contains('All project IDs are empty'));
    });

    testSafe('toJson/fromJson roundtrips', () async {
      final rule = ProjectRule(
        operator: ProjectRuleOperator.matchesAny,
        projectIds: const ['p1', 'p2'],
      );

      final decoded = TaskRule.fromJson(rule.toJson());
      expect(decoded, equals(rule));
    });

    testSafe('isNotNull matches when projectId is present', () async {
      final t = task(projectId: 'p1');
      final rule = ProjectRule(operator: ProjectRuleOperator.isNotNull);

      expect(rule.applies(t, DateTime.utc(2026, 1, 18)), isTrue);
      expect(rule.validate(), isEmpty);
    });
  });

  group('TaskRuleSet', () {
    testSafe('evaluate returns true for empty rules (vacuous truth)', () async {
      final set = TaskRuleSet(operator: RuleSetOperator.and, rules: const []);
      final t = task();

      expect(
        set.evaluate(t, EvaluationContext(today: DateTime.utc(2026, 1, 18))),
        isTrue,
      );
    });

    testSafe('and requires all rules match', () async {
      final t = task(completed: true, projectId: 'p1');

      final set = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: const [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isTrue,
          ),
          ProjectRule(operator: ProjectRuleOperator.matches, projectId: 'p1'),
        ],
      );

      expect(
        set.evaluate(t, EvaluationContext(today: DateTime.utc(2026, 1, 18))),
        isTrue,
      );
    });

    testSafe('or requires any rule match', () async {
      final t = task(completed: false, projectId: 'p1');

      final set = TaskRuleSet(
        operator: RuleSetOperator.or,
        rules: const [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isTrue,
          ),
          ProjectRule(operator: ProjectRuleOperator.matches, projectId: 'p1'),
        ],
      );

      expect(
        set.evaluate(t, EvaluationContext(today: DateTime.utc(2026, 1, 18))),
        isTrue,
      );
    });

    testSafe('validate prefixes nested rule errors with index', () async {
      final set = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: const [
          ProjectRule(operator: ProjectRuleOperator.matches, projectId: ''),
        ],
      );

      expect(
        set.validate(),
        contains('Rule 1: Matches operator requires a project ID'),
      );
    });

    testSafe('toJson/fromJson roundtrips', () async {
      final set = TaskRuleSet(
        operator: RuleSetOperator.or,
        rules: const [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
        ],
      );

      final decoded = TaskRuleSet.fromJson(set.toJson());
      expect(decoded, equals(set));
    });
  });
}
