import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';

/// Evaluates excluded tasks against alert configuration.
///
/// Pure function service - takes inputs, produces outputs, no side effects.
/// Called by SectionDataService when building AllocationSectionResult.
class AllocationAlertEvaluator {
  const AllocationAlertEvaluator();

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

    // Sort by severity (most severe first), then by type
    alerts.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // Group by type
    final byType = <AllocationAlertType, List<EvaluatedAlert>>{};
    for (final alert in alerts) {
      byType.putIfAbsent(alert.type, () => []).add(alert);
    }

    // Group by severity
    final bySeverity = <AlertSeverity, List<EvaluatedAlert>>{};
    for (final alert in alerts) {
      bySeverity.putIfAbsent(alert.severity, () => []).add(alert);
    }

    return AlertEvaluationResult(
      alerts: alerts,
      byType: byType,
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
    // Check each rule in priority order (most specific first)

    // 1. Overdue check (most critical - task is past deadline)
    if (_isOverdue(excluded)) {
      final severity = config.severityFor(AllocationAlertType.overdueExcluded);
      if (severity != null) {
        return EvaluatedAlert(
          type: AllocationAlertType.overdueExcluded,
          severity: severity,
          excludedTask: excluded,
          reason: _formatOverdueReason(excluded),
        );
      }
    }

    // 2. Urgent check (time-sensitive)
    if (excluded.isUrgent ?? false) {
      final severity = config.severityFor(AllocationAlertType.urgentExcluded);
      if (severity != null) {
        return EvaluatedAlert(
          type: AllocationAlertType.urgentExcluded,
          severity: severity,
          excludedTask: excluded,
          reason: _formatUrgentReason(excluded),
        );
      }
    }

    // 3. Exclusion type-based checks
    switch (excluded.exclusionType) {
      case ExclusionType.noCategory:
        final severity = config.severityFor(
          AllocationAlertType.noValueExcluded,
        );
        if (severity != null) {
          return EvaluatedAlert(
            type: AllocationAlertType.noValueExcluded,
            severity: severity,
            excludedTask: excluded,
            reason: 'No value assigned',
          );
        }

      case ExclusionType.lowPriority:
        final severity = config.severityFor(
          AllocationAlertType.lowPriorityExcluded,
        );
        if (severity != null) {
          return EvaluatedAlert(
            type: AllocationAlertType.lowPriorityExcluded,
            severity: severity,
            excludedTask: excluded,
            reason: 'Filtered by priority',
          );
        }

      case ExclusionType.categoryLimitReached:
        final severity = config.severityFor(
          AllocationAlertType.quotaFullExcluded,
        );
        if (severity != null) {
          return EvaluatedAlert(
            type: AllocationAlertType.quotaFullExcluded,
            severity: severity,
            excludedTask: excluded,
            reason: 'Category quota reached',
          );
        }

      case ExclusionType.completed:
        // Never alert for completed tasks
        break;
    }

    return null;
  }

  bool _isOverdue(ExcludedTask excluded) {
    final deadline = excluded.task.deadlineDate;
    if (deadline == null) return false;
    if (excluded.task.completed) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    // Overdue if deadline is today or earlier
    return !deadlineDay.isAfter(today);
  }

  String _formatOverdueReason(ExcludedTask excluded) {
    final deadline = excluded.task.deadlineDate!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysOverdue = today.difference(deadlineDay).inDays;
    if (daysOverdue == 0) {
      return 'Due today';
    } else if (daysOverdue == 1) {
      return 'Overdue by 1 day';
    } else {
      return 'Overdue by $daysOverdue days';
    }
  }

  String _formatUrgentReason(ExcludedTask excluded) {
    final deadline = excluded.task.deadlineDate;
    if (deadline == null) {
      return 'Marked urgent';
    }
    final daysUntil = deadline.difference(DateTime.now()).inDays;
    if (daysUntil <= 0) {
      return 'Due today';
    } else if (daysUntil == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $daysUntil days';
    }
  }
}
