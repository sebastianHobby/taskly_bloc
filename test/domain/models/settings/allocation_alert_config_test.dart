import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

void main() {
  group('AllocationAlertConfig', () {
    test('defaults are correct', () {
      const config = AllocationAlertConfig();
      expect(config.rules, isEmpty);
      expect(config.enabled, isTrue);
    });

    test('can create config with rules', () {
      final rule = AllocationAlertRule(
        id: 'rule-1',
        name: 'Test Rule',
        condition: QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      );

      final config = AllocationAlertConfig(rules: [rule]);

      expect(config.rules, hasLength(1));
      expect(config.rules.first, rule);
    });

    test('supports JSON serialization', () {
      final rule = AllocationAlertRule(
        id: 'rule-1',
        name: 'Test Rule',
        condition: QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      );

      final config = AllocationAlertConfig(rules: [rule]);
      final json = config.toJson();
      final decoded = AllocationAlertConfig.fromJson(json);

      expect(decoded, config);
    });

    test('supports copyWith', () {
      const config = AllocationAlertConfig();
      final updated = config.copyWith(enabled: false);
      expect(updated.enabled, isFalse);
      expect(updated.rules, isEmpty);
    });
  });

  group('AllocationAlertRule', () {
    test('supports JSON serialization', () {
      final rule = AllocationAlertRule(
        id: 'rule-1',
        name: 'Test Rule',
        condition: QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      );

      final json = rule.toJson();
      final decoded = AllocationAlertRule.fromJson(json);

      expect(decoded, rule);
    });

    test('supports copyWith', () {
      final rule = AllocationAlertRule(
        id: 'rule-1',
        name: 'Test Rule',
        condition: QueryFilter<TaskPredicate>(
          shared: const [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      );

      final updated = rule.copyWith(name: 'Updated Rule');
      expect(updated.name, 'Updated Rule');
      expect(updated.id, rule.id);
    });
  });
}
