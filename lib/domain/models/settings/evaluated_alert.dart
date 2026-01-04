import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';

part 'evaluated_alert.freezed.dart';

/// A single evaluated alert with its source task and metadata.
///
/// Produced by AllocationAlertEvaluator when an ExcludedTask matches
/// an enabled alert rule.
@freezed
abstract class EvaluatedAlert with _$EvaluatedAlert {
  const factory EvaluatedAlert({
    /// The alert type that was triggered
    required AllocationAlertType type,

    /// Severity from user's config
    required AlertSeverity severity,

    /// The excluded task that triggered this alert
    required ExcludedTask excludedTask,

    /// Human-readable reason (for display)
    required String reason,
  }) = _EvaluatedAlert;
  const EvaluatedAlert._();

  /// Sort key: severity first, then type
  int get sortKey => severity.sortOrder * 100 + type.index;
}

/// Result of alert evaluation - grouped and sorted alerts.
@freezed
abstract class AlertEvaluationResult with _$AlertEvaluationResult {
  const factory AlertEvaluationResult({
    /// All alerts, sorted by severity then type
    required List<EvaluatedAlert> alerts,

    /// Alerts grouped by type (for section rendering)
    required Map<AllocationAlertType, List<EvaluatedAlert>> byType,

    /// Alerts grouped by severity (for banner styling)
    required Map<AlertSeverity, List<EvaluatedAlert>> bySeverity,
  }) = _AlertEvaluationResult;
  const AlertEvaluationResult._();

  /// True if any alerts were triggered
  bool get hasAlerts => alerts.isNotEmpty;

  /// Total count of alerts
  int get totalCount => alerts.length;

  /// Highest severity present (for banner color)
  AlertSeverity? get highestSeverity {
    if (alerts.isEmpty) return null;
    return bySeverity.keys.reduce((a, b) => a.sortOrder < b.sortOrder ? a : b);
  }

  /// Count by severity
  int countBySeverity(AlertSeverity severity) =>
      bySeverity[severity]?.length ?? 0;

  /// Empty result
  static const empty = AlertEvaluationResult(
    alerts: [],
    byType: {},
    bySeverity: {},
  );
}
