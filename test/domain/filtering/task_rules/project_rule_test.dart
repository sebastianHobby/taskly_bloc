import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('ProjectRule', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    group('construction', () {
      test('creates with required fields', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );

        expect(rule.operator, ProjectRuleOperator.matches);
        expect(rule.projectId, 'project-1');
        expect(rule.type, RuleType.project);
      });

      test('creates with projectIds list', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );

        expect(rule.projectIds, ['project-1', 'project-2']);
      });

      test('defaults projectIds to empty list', () {
        final rule = TestData.projectRule();

        expect(rule.projectIds, isEmpty);
      });
    });

    group('evaluate - matches operator', () {
      test('matches task in specified project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task in different project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final task = TestData.task(projectId: 'project-2');

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with no project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final task = TestData.task(projectId: null);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when projectId is null', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: null,
        );
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - matchesAny operator', () {
      test('matches task in any of the specified projects', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2', 'project-3'],
        );
        final task = TestData.task(projectId: 'project-2');

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task in different project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );
        final task = TestData.task(projectId: 'project-3');

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with no project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );
        final task = TestData.task(projectId: null);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('ignores empty string projectIds', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['', 'project-1', '  '],
        );
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isTrue);
      });

      test('returns false when projectIds is empty', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: [],
        );
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNull operator', () {
      test('matches task with no project', () {
        final rule = TestData.projectRule(operator: ProjectRuleOperator.isNull);
        final task = TestData.task(projectId: null);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with project', () {
        final rule = TestData.projectRule(operator: ProjectRuleOperator.isNull);
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNotNull operator', () {
      test('matches task with project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.isNotNull,
        );
        final task = TestData.task(projectId: 'project-1');

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task without project', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.isNotNull,
        );
        final task = TestData.task(projectId: null);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('validate', () {
      test('returns empty for valid matches rule', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when matches has no projectId', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: null,
        );

        expect(
          rule.validate(),
          contains(contains('requires a project ID')),
        );
      });

      test('returns error when matches has empty projectId', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: '   ',
        );

        expect(
          rule.validate(),
          contains(contains('requires a project ID')),
        );
      });

      test('returns empty for valid matchesAny rule', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when matchesAny has no projectIds', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: [],
        );

        expect(
          rule.validate(),
          contains(contains('requires at least one project ID')),
        );
      });

      test('returns error when matchesAny has only empty projectIds', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['', '   '],
        );

        expect(
          rule.validate(),
          contains(contains('All project IDs are empty')),
        );
      });

      test('returns empty for isNull operator', () {
        final rule = TestData.projectRule(operator: ProjectRuleOperator.isNull);

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for isNotNull operator', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.isNotNull,
        );

        expect(rule.validate(), isEmpty);
      });
    });

    group('toJson', () {
      test('serializes matches operator', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );

        final json = rule.toJson();

        expect(json['type'], 'project');
        expect(json['operator'], 'matches');
        expect(json['projectId'], 'project-1');
      });

      test('serializes matchesAny operator', () {
        final rule = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );

        final json = rule.toJson();

        expect(json['operator'], 'matchesAny');
        expect(json['projectIds'], ['project-1', 'project-2']);
      });
    });

    group('fromJson', () {
      test('parses matches operator', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matches',
          'projectId': 'project-1',
        };

        final rule = ProjectRule.fromJson(json);

        expect(rule.operator, ProjectRuleOperator.matches);
        expect(rule.projectId, 'project-1');
      });

      test('parses matchesAny operator', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectIds': ['project-1', 'project-2'],
        };

        final rule = ProjectRule.fromJson(json);

        expect(rule.operator, ProjectRuleOperator.matchesAny);
        expect(rule.projectIds, ['project-1', 'project-2']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'project'};

        final rule = ProjectRule.fromJson(json);

        expect(rule.operator, ProjectRuleOperator.matches);
        expect(rule.projectId, isNull);
        expect(rule.projectIds, isEmpty);
      });

      test('filters non-string projectIds', () {
        final json = <String, dynamic>{
          'type': 'project',
          'operator': 'matchesAny',
          'projectIds': ['project-1', 123, null, 'project-2'],
        };

        final rule = ProjectRule.fromJson(json);

        expect(rule.projectIds, ['project-1', 'project-2']);
      });
    });

    group('equality', () {
      test('equal when all fields match for matches operator', () {
        final rule1 = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final rule2 = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('equal when all fields match for matchesAny operator', () {
        final rule1 = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );
        final rule2 = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2'],
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('not equal when operator differs', () {
        final rule1 = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final rule2 = TestData.projectRule(
          operator: ProjectRuleOperator.isNull,
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when projectId differs', () {
        final rule1 = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );
        final rule2 = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-2',
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when projectIds differ', () {
        final rule1 = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1'],
        );
        final rule2 = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-2'],
        );

        expect(rule1, isNot(equals(rule2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips matches operator', () {
        final original = TestData.projectRule(
          operator: ProjectRuleOperator.matches,
          projectId: 'project-1',
        );

        final json = original.toJson();
        final restored = ProjectRule.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips matchesAny operator', () {
        final original = TestData.projectRule(
          operator: ProjectRuleOperator.matchesAny,
          projectIds: ['project-1', 'project-2', 'project-3'],
        );

        final json = original.toJson();
        final restored = ProjectRule.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips isNull operator', () {
        final original = TestData.projectRule(
          operator: ProjectRuleOperator.isNull,
        );

        final json = original.toJson();
        final restored = ProjectRule.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
