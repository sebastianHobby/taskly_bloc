import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';

void main() {
  group('AttentionRule', () {
    test('creates valid rule with all fields', () {
      final rule = AttentionRule(
        id: 'test-id',
        ruleKey: 'problem_task_overdue',
        ruleType: AttentionRuleType.problem,
        triggerType: AttentionTriggerType.realtime,
        triggerConfig: const {'threshold_hours': 0},
        entitySelector: const {'entity_type': 'task', 'predicate': 'isOverdue'},
        severity: AttentionSeverity.warning,
        displayConfig: const {'title': 'Overdue Tasks', 'icon': 'warning'},
        resolutionActions: const ['resolved', 'snoozed', 'dismissed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      check(rule.id).equals('test-id');
      check(rule.ruleKey).equals('problem_task_overdue');
      check(rule.ruleType).equals(AttentionRuleType.problem);
      check(rule.severity).equals(AttentionSeverity.warning);
      check(rule.active).isTrue();
      check(rule.source).equals(AttentionEntitySource.systemTemplate);
    });

    test('copyWith creates modified copy', () {
      final original = AttentionRule(
        id: 'test-id',
        ruleKey: 'review_progress',
        ruleType: AttentionRuleType.review,
        triggerType: AttentionTriggerType.scheduled,
        triggerConfig: const {'frequency_days': 30},
        entitySelector: const {'entity_type': 'review_session'},
        severity: AttentionSeverity.info,
        displayConfig: const {'title': 'Progress Review'},
        resolutionActions: const ['resolved', 'snoozed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final modified = original.copyWith(active: false);

      check(modified.active).isFalse();
      check(modified.id).equals(original.id);
      check(modified.ruleKey).equals(original.ruleKey);
    });

    test('JSON round trip preserves data', () {
      final original = AttentionRule(
        id: 'test-id',
        ruleKey: 'problem_task_overdue',
        ruleType: AttentionRuleType.problem,
        triggerType: AttentionTriggerType.realtime,
        triggerConfig: const {'threshold_hours': 24},
        entitySelector: const {'entity_type': 'task', 'predicate': 'isOverdue'},
        severity: AttentionSeverity.critical,
        displayConfig: const {'title': 'Overdue Tasks'},
        resolutionActions: const ['resolved', 'dismissed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final restored = AttentionRule.fromJson(json);

      check(restored.id).equals(original.id);
      check(restored.ruleKey).equals(original.ruleKey);
      check(restored.ruleType).equals(original.ruleType);
      check(restored.severity).equals(original.severity);
      check(restored.active).equals(original.active);
    });
  });

  group('AttentionRuleType', () {
    test('all values are present', () {
      check(AttentionRuleType.values).length.equals(4);
      check(AttentionRuleType.values).contains(AttentionRuleType.problem);
      check(AttentionRuleType.values).contains(AttentionRuleType.review);
      check(AttentionRuleType.values).contains(AttentionRuleType.workflowStep);
      check(
        AttentionRuleType.values,
      ).contains(AttentionRuleType.allocationWarning);
    });
  });

  group('AttentionSeverity', () {
    test('all values are present', () {
      check(AttentionSeverity.values).length.equals(3);
      check(AttentionSeverity.values).contains(AttentionSeverity.info);
      check(AttentionSeverity.values).contains(AttentionSeverity.warning);
      check(AttentionSeverity.values).contains(AttentionSeverity.critical);
    });
  });

  group('AttentionTriggerType', () {
    test('all values are present', () {
      check(AttentionTriggerType.values).length.equals(2);
      check(
        AttentionTriggerType.values,
      ).contains(AttentionTriggerType.realtime);
      check(
        AttentionTriggerType.values,
      ).contains(AttentionTriggerType.scheduled);
    });
  });

  group('AttentionEntitySource', () {
    test('all values are present', () {
      check(AttentionEntitySource.values).length.equals(3);
      check(
        AttentionEntitySource.values,
      ).contains(AttentionEntitySource.systemTemplate);
      check(
        AttentionEntitySource.values,
      ).contains(AttentionEntitySource.userCreated);
      check(
        AttentionEntitySource.values,
      ).contains(AttentionEntitySource.imported);
    });
  });
}
