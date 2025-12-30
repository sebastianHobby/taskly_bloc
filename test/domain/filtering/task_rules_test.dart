import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/models/task.dart';

void main() {
  group('TaskPriorityBucketRule', () {
    test('fromJson creates instance with default values', () {
      final json = <String, dynamic>{'ruleSets': <dynamic>[]};
      final rule = TaskPriorityBucketRule.fromJson(json);

      expect(rule.priority, 1);
      expect(rule.name, 'Priority 1');
      expect(rule.ruleSets, isEmpty);
      expect(rule.limit, isNull);
      expect(rule.sortCriterion, isNull);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'priority': 2,
        'name': 'High Priority',
        'limit': 10,
        'sortCriterion': {
          'field': 'deadlineDate',
          'direction': 'asc',
        },
        'ruleSets': [
          {
            'operator': 'and',
            'rules': [
              {'type': 'boolean', 'field': 'completed', 'operator': 'isFalse'},
            ],
          },
        ],
      };

      final rule = TaskPriorityBucketRule.fromJson(json);

      expect(rule.priority, 2);
      expect(rule.name, 'High Priority');
      expect(rule.limit, 10);
      expect(rule.sortCriterion, isNotNull);
      expect(rule.ruleSets, hasLength(1));
    });

    test('toJson serializes correctly', () {
      final rule = TaskPriorityBucketRule(
        priority: 3,
        name: 'Medium',
        ruleSets: [
          const TaskRuleSet(
            operator: RuleSetOperator.or,
            rules: [
              BooleanRule(
                field: BooleanRuleField.completed,
                operator: BooleanRuleOperator.isTrue,
              ),
            ],
          ),
        ],
        limit: 5,
        sortCriterion: const SortCriterion(
          field: SortField.name,
          direction: SortDirection.descending,
        ),
      );

      final json = rule.toJson();

      expect(json['priority'], 3);
      expect(json['name'], 'Medium');
      expect(json['limit'], 5);
      expect(json['sortCriterion'], isNotNull);
      expect(json['ruleSets'], isA<List>());
    });

    test('evaluate returns true when ruleSets is empty', () {
      const rule = TaskPriorityBucketRule(
        priority: 1,
        name: 'Test',
        ruleSets: [],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, EvaluationContext()), isTrue);
    });

    test('evaluate uses OR logic across rule sets', () {
      final rule = TaskPriorityBucketRule(
        priority: 1,
        name: 'Test',
        ruleSets: [
          const TaskRuleSet(
            operator: RuleSetOperator.and,
            rules: [
              BooleanRule(
                field: BooleanRuleField.completed,
                operator: BooleanRuleOperator.isTrue,
              ),
            ],
          ),
          const TaskRuleSet(
            operator: RuleSetOperator.and,
            rules: [
              ProjectRule(
                operator: ProjectRuleOperator.isNull,
              ),
            ],
          ),
        ],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test Task',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      // First rule set fails (not completed), second succeeds (projectId is null)
      expect(rule.evaluate(task, EvaluationContext()), isTrue);
    });

    test('copyWith preserves unchanged values', () {
      final original = TaskPriorityBucketRule(
        priority: 1,
        name: 'Original',
        ruleSets: [],
        limit: 10,
      );

      final copy = original.copyWith(name: 'Updated');

      expect(copy.priority, 1);
      expect(copy.name, 'Updated');
      expect(copy.limit, 10);
    });

    test('equality compares all fields', () {
      const rule1 = TaskPriorityBucketRule(
        priority: 1,
        name: 'Test',
        ruleSets: [],
      );
      const rule2 = TaskPriorityBucketRule(
        priority: 1,
        name: 'Test',
        ruleSets: [],
      );
      const rule3 = TaskPriorityBucketRule(
        priority: 2,
        name: 'Test',
        ruleSets: [],
      );

      expect(rule1, equals(rule2));
      expect(rule1, isNot(equals(rule3)));
    });
  });

  group('TaskRuleSet', () {
    test('fromJson with default operator', () {
      final json = {
        'rules': [
          {'type': 'boolean', 'field': 'completed', 'operator': 'isFalse'},
        ],
      };

      final ruleSet = TaskRuleSet.fromJson(json);

      expect(ruleSet.operator, RuleSetOperator.and);
      expect(ruleSet.rules, hasLength(1));
    });

    test('evaluate returns true for empty rules', () {
      const ruleSet = TaskRuleSet(operator: RuleSetOperator.and, rules: []);

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(ruleSet.evaluate(task, EvaluationContext()), isTrue);
    });

    test('evaluate applies AND operator correctly', () {
      const ruleSet = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
          ProjectRule(operator: ProjectRuleOperator.isNull),
        ],
      );

      final task1 = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test',
        completed: true,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(ruleSet.evaluate(task1, EvaluationContext()), isTrue);
      expect(ruleSet.evaluate(task2, EvaluationContext()), isFalse);
    });

    test('evaluate applies OR operator correctly', () {
      const ruleSet = TaskRuleSet(
        operator: RuleSetOperator.or,
        rules: [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isTrue,
          ),
          ProjectRule(operator: ProjectRuleOperator.isNull),
        ],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(ruleSet.evaluate(task, EvaluationContext()), isTrue);
    });

    test('validate returns error when rules is empty', () {
      const ruleSet = TaskRuleSet(operator: RuleSetOperator.and, rules: []);

      final errors = ruleSet.validate();

      expect(errors, hasLength(1));
      expect(errors.first, contains('at least one rule'));
    });

    test('validate propagates rule errors', () {
      const ruleSet = TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [
          DateRule(
            field: DateRuleField.deadlineDate,
            operator: DateRuleOperator.on,
          ),
        ],
      );

      final errors = ruleSet.validate();

      expect(errors, isNotEmpty);
      expect(errors.first, contains('Rule 1'));
    });

    test('toJson and fromJson roundtrip', () {
      const original = TaskRuleSet(
        operator: RuleSetOperator.or,
        rules: [
          BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
        ],
      );

      final json = original.toJson();
      final restored = TaskRuleSet.fromJson(json);

      expect(restored.operator, original.operator);
      expect(restored.rules, hasLength(original.rules.length));
    });
  });

  group('DateRule', () {
    final now = DateTime(2025, 12, 26);
    final context = EvaluationContext(today: now);

    test('onOrAfter operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrAfter,
        date: DateTime(2025, 12, 25),
      );

      final task1 = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 26, 10),
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 24),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task1, context), isTrue);
      expect(rule.evaluate(task2, context), isFalse);
    });

    test('onOrBefore operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.onOrBefore,
        date: DateTime(2025, 12, 25),
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 24),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('before operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.before,
        date: DateTime(2025, 12, 25),
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 24),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('after operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.after,
        date: DateTime(2025, 12, 25),
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 26),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('on operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.on,
        date: DateTime(2025, 12, 25),
      );

      final task1 = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 25, 14, 30),
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 26),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task1, context), isTrue);
      expect(rule.evaluate(task2, context), isFalse);
    });

    test('between operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: DateTime(2025, 12, 20),
        endDate: DateTime(2025, 12, 30),
      );

      final task1 = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 25),
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 31),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task1, context), isTrue);
      expect(rule.evaluate(task2, context), isFalse);
    });

    test('relative operator', () {
      final rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
        relativeComparison: RelativeComparison.onOrBefore,
        relativeDays: 7,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 30),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('isNull operator', () {
      const rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.isNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('isNotNull operator', () {
      const rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.isNotNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        deadlineDate: DateTime(2025, 12, 25),
        createdAt: now,
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('validates between operator requires dates', () {
      const rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
      );

      final errors = rule.validate();

      expect(errors, isNotEmpty);
      expect(errors.first, contains('start and end dates'));
    });

    test('validates relative operator requires parameters', () {
      const rule = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.relative,
      );

      final errors = rule.validate();

      expect(errors.length, 2);
    });

    test('supports different date fields', () {
      final rule = DateRule(
        field: DateRuleField.createdAt,
        operator: DateRuleOperator.after,
        date: DateTime(2025),
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025, 6),
        updatedAt: now,
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('toJson and fromJson roundtrip', () {
      final original = DateRule(
        field: DateRuleField.deadlineDate,
        operator: DateRuleOperator.between,
        startDate: DateTime(2025),
        endDate: DateTime(2025, 12, 31),
      );

      final json = original.toJson();
      final restored = DateRule.fromJson(json);

      expect(restored.field, original.field);
      expect(restored.operator, original.operator);
    });
  });

  group('BooleanRule', () {
    final context = EvaluationContext();

    test('isTrue operator', () {
      const rule = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isTrue,
      );

      final task1 = Task(
        id: 'task-1',
        name: 'Test',
        completed: true,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final task2 = Task(
        id: 'task-2',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task1, context), isTrue);
      expect(rule.evaluate(task2, context), isFalse);
    });

    test('isFalse operator', () {
      const rule = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('validate returns no errors', () {
      const rule = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isTrue,
      );

      expect(rule.validate(), isEmpty);
    });

    test('toJson and fromJson roundtrip', () {
      const original = BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      );

      final json = original.toJson();
      final restored = BooleanRule.fromJson(json);

      expect(restored.field, original.field);
      expect(restored.operator, original.operator);
    });
  });

  group('LabelRule', () {
    final context = EvaluationContext();

    test('hasAll operator matches when task has all labels', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.hasAll,
        labelIds: ['label-1', 'label-2'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'label-1',
            name: 'Label 1',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
          Label(
            id: 'label-2',
            name: 'Label 2',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
          Label(
            id: 'label-3',
            name: 'Label 3',
            createdAt: DateTime(2025),
            updatedAt: DateTime(2025),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('hasAll operator fails when task missing labels', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.hasAll,
        labelIds: ['label-1', 'label-2'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'label-1',
            name: 'Label 1',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isFalse);
    });

    test('hasAny operator matches when task has any label', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.hasAny,
        labelIds: ['label-1', 'label-2'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'label-2',
            name: 'Label 2',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('isNull operator matches when task has no labels', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.isNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('isNotNull operator matches when task has labels', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.isNotNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'label-1',
            name: 'Label 1',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('filters by label type', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.hasAny,
        labelIds: ['value-1'],
        labelType: LabelType.value,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'value-1',
            name: 'Value 1',
            type: LabelType.value,
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
          Label(
            id: 'label-1',
            name: 'Label 1',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('validates hasAll requires label IDs', () {
      const rule = LabelRule(
        operator: LabelRuleOperator.hasAll,
      );

      final errors = rule.validate();

      expect(errors, isNotEmpty);
      expect(errors.first, contains('at least one label ID'));
    });

    test('toJson and fromJson roundtrip', () {
      const original = LabelRule(
        operator: LabelRuleOperator.hasAll,
        labelIds: ['label-1', 'label-2'],
        labelType: LabelType.value,
      );

      final json = original.toJson();
      final restored = LabelRule.fromJson(json);

      expect(restored.operator, original.operator);
      expect(restored.labelIds, original.labelIds);
      expect(restored.labelType, original.labelType);
    });
  });

  group('ValueRule', () {
    final context = EvaluationContext();

    test('hasAll operator matches when task has all values', () {
      const rule = ValueRule(
        operator: ValueRuleOperator.hasAll,
        labelIds: ['value-1', 'value-2'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'value-1',
            name: 'Value 1',
            type: LabelType.value,
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
          Label(
            id: 'value-2',
            name: 'Value 2',
            type: LabelType.value,
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('hasAny operator matches when task has any value', () {
      const rule = ValueRule(
        operator: ValueRuleOperator.hasAny,
        labelIds: ['value-1', 'value-2'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'value-2',
            name: 'Value 2',
            type: LabelType.value,
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('filters only value type labels', () {
      const rule = ValueRule(
        operator: ValueRuleOperator.hasAny,
        labelIds: ['label-1'],
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        labels: [
          Label(
            id: 'label-1',
            name: 'Label 1',
            createdAt: DateTime(2025, 1),
            updatedAt: DateTime(2025, 1),
          ),
        ],
      );

      expect(rule.evaluate(task, context), isFalse);
    });

    test('validates hasAll requires value IDs', () {
      const rule = ValueRule(
        operator: ValueRuleOperator.hasAll,
      );

      final errors = rule.validate();

      expect(errors, isNotEmpty);
      expect(errors.first, contains('at least one value ID'));
    });

    test('toJson and fromJson roundtrip', () {
      const original = ValueRule(
        operator: ValueRuleOperator.hasAny,
        labelIds: ['value-1', 'value-2'],
      );

      final json = original.toJson();
      final restored = ValueRule.fromJson(json);

      expect(restored.operator, original.operator);
      expect(restored.labelIds, original.labelIds);
    });
  });

  group('ProjectRule', () {
    final context = EvaluationContext();

    test('matches operator succeeds when projectId matches', () {
      const rule = ProjectRule(
        operator: ProjectRuleOperator.matches,
        projectId: 'project-1',
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        projectId: 'project-1',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('matches operator fails when projectId differs', () {
      const rule = ProjectRule(
        operator: ProjectRuleOperator.matches,
        projectId: 'project-1',
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        projectId: 'project-2',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isFalse);
    });

    test('isNull operator matches when projectId is null', () {
      const rule = ProjectRule(
        operator: ProjectRuleOperator.isNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('isNotNull operator matches when projectId exists', () {
      const rule = ProjectRule(
        operator: ProjectRuleOperator.isNotNull,
      );

      final task = Task(
        id: 'task-1',
        name: 'Test',
        completed: false,
        projectId: 'project-1',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      expect(rule.evaluate(task, context), isTrue);
    });

    test('validates matches operator requires projectId', () {
      const rule = ProjectRule(
        operator: ProjectRuleOperator.matches,
      );

      final errors = rule.validate();

      expect(errors, isNotEmpty);
      expect(errors.first, contains('project ID'));
    });

    test('toJson and fromJson roundtrip', () {
      const original = ProjectRule(
        operator: ProjectRuleOperator.matches,
        projectId: 'project-1',
      );

      final json = original.toJson();
      final restored = ProjectRule.fromJson(json);

      expect(restored.operator, original.operator);
      expect(restored.projectId, original.projectId);
    });
  });

  group('TaskRule.fromJson factory', () {
    test('creates DateRule from JSON', () {
      final json = {
        'type': 'date',
        'field': 'deadlineDate',
        'operator': 'after',
        'date': '2025-01-01T00:00:00.000',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<DateRule>());
    });

    test('creates BooleanRule from JSON', () {
      final json = {
        'type': 'boolean',
        'field': 'completed',
        'operator': 'isTrue',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<BooleanRule>());
    });

    test('creates LabelRule from JSON', () {
      final json = {
        'type': 'labels',
        'operator': 'hasAll',
        'labelIds': ['label-1'],
        'labelType': 'label',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<LabelRule>());
    });

    test('creates ValueRule from JSON', () {
      final json = {
        'type': 'value',
        'operator': 'hasAny',
        'labelIds': ['value-1'],
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<ValueRule>());
    });

    test('creates ProjectRule from JSON', () {
      final json = {
        'type': 'project',
        'operator': 'matches',
        'projectId': 'project-1',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<ProjectRule>());
    });

    test('defaults to BooleanRule when type is invalid', () {
      final json = {
        'type': 'invalid',
        'field': 'completed',
        'operator': 'isTrue',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<BooleanRule>());
    });
  });
}
