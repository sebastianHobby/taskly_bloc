import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';
import 'package:taskly_bloc/domain/services/allocation/task_filter_evaluator.dart';

/// Evaluates excluded tasks against alert configuration.
///
/// Pure function service - takes inputs, produces outputs, no side effects.
/// Called by SectionDataService when building AllocationSectionResult.
class AllocationAlertEvaluator {
  const AllocationAlertEvaluator({
    this.filterEvaluator = const TaskFilterEvaluator(),
  });

  final TaskFilterEvaluator filterEvaluator;

  /// Evaluate excluded tasks against alert config.
  ///
  /// Returns [AlertEvaluationResult] with all triggered alerts,
  /// grouped and sorted for UI consumption.
  AlertEvaluationResult evaluate({
    required List<ExcludedTask> excludedTasks,
    required AllocationAlertConfig config,
  }) {
    if (!config.enabled || excludedTasks.isEmpty) {
      return AlertEvaluationResult.empty;
    }

    final alerts = <EvaluatedAlert>[];

    for (final excluded in excludedTasks) {
      final alert = _evaluateTask(excluded, config);
      if (alert != null) {
        alerts.add(alert);
      }
    }

    // Sort by severity (most severe first), then by rule name
    alerts.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // Group by rule ID
    final byRuleId = <String, List<EvaluatedAlert>>{};
    for (final alert in alerts) {
      byRuleId.putIfAbsent(alert.ruleId, () => []).add(alert);
    }

    // Group by severity
    final bySeverity = <AlertSeverity, List<EvaluatedAlert>>{};
    for (final alert in alerts) {
      bySeverity.putIfAbsent(alert.severity, () => []).add(alert);
    }

    return AlertEvaluationResult(
      alerts: alerts,
      byRuleId: byRuleId,
      bySeverity: bySeverity,
    );
  }

  /// Evaluate a single excluded task against all enabled rules.
  ///
  /// Returns the first matching alert (highest priority rule wins).
  EvaluatedAlert? _evaluateTask(
    ExcludedTask excluded,
    AllocationAlertConfig config,
  ) {
    // Iterate through rules in order. First match wins.
    // Assuming rules are ordered by priority in the config.
    for (final rule in config.rules) {
      if (!rule.enabled) continue;

      if (filterEvaluator.evaluate(rule.condition, excluded.task)) {
        return EvaluatedAlert(
          ruleId: rule.id,
          ruleName: rule.name,
          severity: rule.severity,
          excludedTask: excluded,
          reason: _formatReason(rule.name, excluded),
        );
      }
    }
    return null;
  }

  String _formatReason(String ruleName, ExcludedTask excluded) {
    // TODO: Improve reason formatting based on rule type or condition
    return ruleName;
  }
}
