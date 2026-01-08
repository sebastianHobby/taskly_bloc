import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart';

void main() {
  group('AttentionResolution', () {
    test('creates valid resolution with all fields', () {
      final resolution = AttentionResolution(
        id: 'resolution-id',
        ruleId: 'rule-id',
        entityId: 'task-123',
        entityType: AttentionEntityType.task,
        resolutionAction: AttentionResolutionAction.reviewed,
        resolvedAt: DateTime(2026, 1, 15),
        actionDetails: const {'state_hash': 'abc123'},
        createdAt: DateTime(2026, 1, 15),
      );

      check(resolution.id).equals('resolution-id');
      check(resolution.ruleId).equals('rule-id');
      check(resolution.entityId).equals('task-123');
      check(resolution.entityType).equals(AttentionEntityType.task);
      check(
        resolution.resolutionAction,
      ).equals(AttentionResolutionAction.reviewed);
    });

    test('copyWith creates modified copy', () {
      final original = AttentionResolution(
        id: 'resolution-id',
        ruleId: 'rule-id',
        entityId: 'task-123',
        entityType: AttentionEntityType.task,
        resolutionAction: AttentionResolutionAction.snoozed,
        resolvedAt: DateTime(2026, 1, 15),
        actionDetails: const {},
        createdAt: DateTime(2026, 1, 15),
      );

      final modified = original.copyWith(
        resolutionAction: AttentionResolutionAction.reviewed,
      );

      check(
        modified.resolutionAction,
      ).equals(AttentionResolutionAction.reviewed);
      check(modified.id).equals(original.id);
      check(modified.ruleId).equals(original.ruleId);
    });

    test('JSON round trip preserves data', () {
      final original = AttentionResolution(
        id: 'resolution-id',
        ruleId: 'rule-id',
        entityId: 'project-456',
        entityType: AttentionEntityType.project,
        resolutionAction: AttentionResolutionAction.dismissed,
        resolvedAt: DateTime(2026, 1, 20),
        actionDetails: const {'reason': 'Not applicable'},
        createdAt: DateTime(2026, 1, 20),
      );

      final json = original.toJson();
      final restored = AttentionResolution.fromJson(json);

      check(restored.id).equals(original.id);
      check(restored.ruleId).equals(original.ruleId);
      check(restored.entityType).equals(original.entityType);
      check(restored.resolutionAction).equals(original.resolutionAction);
    });
  });

  group('AttentionEntityType', () {
    test('all values are present', () {
      check(AttentionEntityType.values).length.equals(6);
      check(AttentionEntityType.values).contains(AttentionEntityType.task);
      check(AttentionEntityType.values).contains(AttentionEntityType.project);
      check(AttentionEntityType.values).contains(AttentionEntityType.journal);
      check(AttentionEntityType.values).contains(AttentionEntityType.value);
      check(AttentionEntityType.values).contains(AttentionEntityType.tracker);
      check(
        AttentionEntityType.values,
      ).contains(AttentionEntityType.reviewSession);
    });
  });

  group('AttentionResolutionAction', () {
    test('all values are present', () {
      check(AttentionResolutionAction.values).length.equals(4);
      check(
        AttentionResolutionAction.values,
      ).contains(AttentionResolutionAction.reviewed);
      check(
        AttentionResolutionAction.values,
      ).contains(AttentionResolutionAction.snoozed);
      check(
        AttentionResolutionAction.values,
      ).contains(AttentionResolutionAction.dismissed);
      check(
        AttentionResolutionAction.values,
      ).contains(AttentionResolutionAction.skipped);
    });
  });
}
