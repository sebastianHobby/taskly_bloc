import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/attention/attention_item.dart';
import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';

void main() {
  group('AttentionItem', () {
    test('creates valid item with all fields', () {
      final item = AttentionItem(
        id: 'item-id',
        ruleId: 'rule-id',
        ruleKey: 'problem_task_overdue',
        ruleType: AttentionRuleType.problem,
        entityId: 'task-123',
        entityType: AttentionEntityType.task,
        severity: AttentionSeverity.warning,
        title: 'Overdue Task',
        description: 'Task "Buy groceries" is overdue',
        availableActions: const [
          AttentionResolutionAction.reviewed,
          AttentionResolutionAction.dismissed,
        ],
        detectedAt: DateTime(2026, 1, 15),
        metadata: const {'task_name': 'Buy groceries'},
      );

      check(item.id).equals('item-id');
      check(item.ruleId).equals('rule-id');
      check(item.ruleKey).equals('problem_task_overdue');
      check(item.ruleType).equals(AttentionRuleType.problem);
      check(item.entityId).equals('task-123');
      check(item.entityType).equals(AttentionEntityType.task);
      check(item.severity).equals(AttentionSeverity.warning);
      check(item.title).equals('Overdue Task');
      check(item.availableActions).length.equals(2);
      check(item.metadata?['task_name']).equals('Buy groceries');
    });

    test('copyWith creates modified copy', () {
      final original = AttentionItem(
        id: 'item-id',
        ruleId: 'rule-id',
        ruleKey: 'problem_project_idle',
        ruleType: AttentionRuleType.problem,
        entityId: 'project-456',
        entityType: AttentionEntityType.project,
        severity: AttentionSeverity.info,
        title: 'Idle Project',
        description: 'Project has no recent activity',
        availableActions: const [AttentionResolutionAction.reviewed],
        detectedAt: DateTime(2026, 1, 15),
        metadata: const {},
      );

      final modified = original.copyWith(
        severity: AttentionSeverity.warning,
      );

      check(modified.severity).equals(AttentionSeverity.warning);
      check(modified.id).equals(original.id);
      check(modified.title).equals(original.title);
    });

    test('JSON round trip preserves data', () {
      final original = AttentionItem(
        id: 'item-id',
        ruleId: 'rule-id',
        ruleKey: 'review_weekly',
        ruleType: AttentionRuleType.review,
        entityId: 'review-weekly',
        entityType: AttentionEntityType.reviewSession,
        severity: AttentionSeverity.info,
        title: 'Weekly Review Due',
        description: 'Time to review your week',
        availableActions: const [AttentionResolutionAction.reviewed],
        detectedAt: DateTime(2026, 1, 20),
        metadata: const {'frequency_days': 7},
      );

      final json = original.toJson();
      final restored = AttentionItem.fromJson(json);

      check(restored.id).equals(original.id);
      check(restored.ruleKey).equals(original.ruleKey);
      check(restored.ruleType).equals(original.ruleType);
      check(restored.entityType).equals(original.entityType);
      check(restored.severity).equals(original.severity);
    });

    test('default metadata is empty map', () {
      final item = AttentionItem(
        id: 'item-id',
        ruleId: 'rule-id',
        ruleKey: 'test_rule',
        ruleType: AttentionRuleType.problem,
        entityId: 'entity-id',
        entityType: AttentionEntityType.task,
        severity: AttentionSeverity.info,
        title: 'Test',
        description: '',
        availableActions: const [],
        detectedAt: DateTime.now(),
      );

      check(item.metadata).isNull();
    });
  });
}
