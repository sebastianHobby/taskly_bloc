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

    // Never alert for completed tasks.
    final candidates = excludedTasks.where((e) => !e.task.completed).toList();
    if (candidates.isEmpty) {
      return AlertEvaluationResult.empty;
    }

    final alerts = <EvaluatedAlert>[];

    for (final excluded in candidates) {
      final alert = _evaluateTask(excluded, config);
      if (alert != null) {
        alerts.add(alert);
      }
    }

    // Sort by severity (most severe first), then by rule name.
    alerts.sort((a, b) {
      final severityCompare = a.severity.sortOrder.compareTo(
        b.severity.sortOrder,
      );
      if (severityCompare != 0) return severityCompare;
      return a.ruleName.compareTo(b.ruleName);
    });

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
    // 1) Prefer explicit rule-id matches (exclusionType, urgent flag, etc)
    // so that allocation exclusion reasons take precedence over generic
    // query-filter matches (e.g. "no_value").
    for (final rule in config.rules) {
      if (!rule.enabled) continue;
      if (!_matchesRule(rule.id, excluded)) continue;

      return EvaluatedAlert(
        ruleId: rule.id,
        ruleName: rule.name,
        severity: rule.severity,
        excludedTask: excluded,
        reason: _formatReason(rule.id, rule.name, excluded),
      );
    }

    // 2) Fall back to query-filter matches.
    // Avoid treating matchAll() as a match here, otherwise rules that cannot
    // be expressed as task predicates (quota/low_priority) would match every
    // task.
    for (final rule in config.rules) {
      if (!rule.enabled) continue;
      if (rule.condition.isMatchAll) continue;

      if (filterEvaluator.evaluate(rule.condition, excluded.task)) {
        return EvaluatedAlert(
          ruleId: rule.id,
          ruleName: rule.name,
          severity: rule.severity,
          excludedTask: excluded,
          reason: _formatReason(rule.id, rule.name, excluded),
        );
      }
    }

    return null;
  }

  bool _matchesRule(String ruleId, ExcludedTask excluded) {
    final id = ruleId.toLowerCase();

    if (id.contains('overdue')) {
      return _isDueTodayOrOverdue(excluded);
    }

    if (id.contains('urgent')) {
      return _isUrgent(excluded);
    }

    if (id.contains('no_value')) {
      return excluded.exclusionType == ExclusionType.noCategory;
    }

    if (id.contains('low_priority')) {
      return excluded.exclusionType == ExclusionType.lowPriority;
    }

    if (id.contains('quota')) {
      return excluded.exclusionType == ExclusionType.categoryLimitReached;
    }

    return false;
  }

  bool _isUrgent(ExcludedTask excluded) {
    if (excluded.isUrgent ?? false) return true;

    final deadline = excluded.task.deadlineDate;
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline.year, deadline.month, deadline.day);

    // Treat items due within the next 3 days (including today) as urgent.
    final threshold = today.add(const Duration(days: 3));
    return !due.isAfter(threshold);
  }

  bool _isDueTodayOrOverdue(ExcludedTask excluded) {
    final deadline = excluded.task.deadlineDate;
    if (deadline == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline.year, deadline.month, deadline.day);

    return !due.isAfter(today);
  }

  String _formatReason(String ruleId, String ruleName, ExcludedTask excluded) {
    final id = ruleId.toLowerCase();

    if (id.contains('overdue')) {
      final deadline = excluded.task.deadlineDate;
      if (deadline == null) return ruleName;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(deadline.year, deadline.month, deadline.day);
      final daysOverdue = today.difference(due).inDays;

      if (daysOverdue <= 0) return 'Due today';
      if (daysOverdue == 1) return 'Overdue by 1 day';
      return 'Overdue by $daysOverdue days';
    }

    if (id.contains('urgent')) {
      final deadline = excluded.task.deadlineDate;
      if (deadline == null) return 'Marked urgent';
      return ruleName;
    }

    return ruleName;
  }
}
