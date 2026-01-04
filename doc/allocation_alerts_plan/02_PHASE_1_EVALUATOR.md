# Phase 1b: Allocation Alert Evaluator

> **Status:** Ready for implementation  
> **Depends on:** Phase 1a (Models)  
> **Outputs:** AllocationAlertEvaluator service, EvaluatedAlert model

## Overview

Service that evaluates `ExcludedTask` list against user's `AllocationAlertConfig` to produce actionable alerts. Pure function - no side effects, easily testable.

## New Files

### 1. `lib/domain/models/settings/evaluated_alert.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';

part 'evaluated_alert.freezed.dart';

/// A single evaluated alert with its source task and metadata.
///
/// Produced by AllocationAlertEvaluator when an ExcludedTask matches
/// an enabled alert rule.
@freezed
abstract class EvaluatedAlert with _$EvaluatedAlert {
  const EvaluatedAlert._();

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

  /// Sort key: severity first, then type
  int get sortKey => severity.sortOrder * 100 + type.index;
}

/// Result of alert evaluation - grouped and sorted alerts.
@freezed
abstract class AlertEvaluationResult with _$AlertEvaluationResult {
  const AlertEvaluationResult._();

  const factory AlertEvaluationResult({
    /// All alerts, sorted by severity then type
    required List<EvaluatedAlert> alerts,
    
    /// Alerts grouped by type (for section rendering)
    required Map<AllocationAlertType, List<EvaluatedAlert>> byType,
    
    /// Alerts grouped by severity (for banner styling)
    required Map<AlertSeverity, List<EvaluatedAlert>> bySeverity,
  }) = _AlertEvaluationResult;

  /// True if any alerts were triggered
  bool get hasAlerts => alerts.isNotEmpty;

  /// Total count of alerts
  int get totalCount => alerts.length;

  /// Highest severity present (for banner color)
  AlertSeverity? get highestSeverity {
    if (alerts.isEmpty) return null;
    return bySeverity.keys.reduce((a, b) => 
      a.sortOrder < b.sortOrder ? a : b
    );
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
```

### 2. `lib/domain/services/allocation/allocation_alert_evaluator.dart`

```dart
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
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
    if (excluded.isUrgent == true) {
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
        final severity = config.severityFor(AllocationAlertType.noValueExcluded);
        if (severity != null) {
          return EvaluatedAlert(
            type: AllocationAlertType.noValueExcluded,
            severity: severity,
            excludedTask: excluded,
            reason: 'No value assigned',
          );
        }

      case ExclusionType.lowPriority:
        final severity = config.severityFor(AllocationAlertType.lowPriorityExcluded);
        if (severity != null) {
          return EvaluatedAlert(
            type: AllocationAlertType.lowPriorityExcluded,
            severity: severity,
            excludedTask: excluded,
            reason: 'Filtered by priority',
          );
        }

      case ExclusionType.categoryLimitReached:
        final severity = config.severityFor(AllocationAlertType.quotaFullExcluded);
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
    return deadline.isBefore(DateTime.now()) && !excluded.task.completed;
  }

  String _formatOverdueReason(ExcludedTask excluded) {
    final deadline = excluded.task.deadlineDate!;
    final daysOverdue = DateTime.now().difference(deadline).inDays;
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
```

### 3. Register in Dependency Injection

Update `lib/core/dependency_injection/service_module.dart`:

```dart
// Add to service registrations
getIt.registerLazySingleton<AllocationAlertEvaluator>(
  () => const AllocationAlertEvaluator(),
);
```

## Integration Point

The evaluator will be called by `SectionDataService` when building `AllocationSectionResult`. This happens in Phase 1d (UI), but the integration point is:

```dart
// In SectionDataService._buildAllocationSectionResult()
final alertEvaluator = getIt<AllocationAlertEvaluator>();
final alertSettings = await settingsRepository.load(SettingsKey.allocationAlerts);

final alertResult = alertEvaluator.evaluate(
  excludedTasks: allocationResult.excludedTasks,
  config: alertSettings.config,
);

return AllocationSectionResult(
  // ... existing fields ...
  alertEvaluationResult: alertResult,  // NEW field
);
```

## Tests

### `test/domain/services/allocation/allocation_alert_evaluator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_alert_evaluator.dart';
import 'package:taskly_bloc/test/fixtures/test_data.dart';

void main() {
  late AllocationAlertEvaluator evaluator;

  setUp(() {
    evaluator = const AllocationAlertEvaluator();
  });

  group('AllocationAlertEvaluator', () {
    group('evaluate', () {
      test('returns empty result when config is disabled', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Test'),
            reason: 'Test',
            exclusionType: ExclusionType.noCategory,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: const AllocationAlertConfig(enabled: false),
        );

        expect(result.hasAlerts, isFalse);
      });

      test('returns empty result when no excluded tasks', () {
        final result = evaluator.evaluate(
          excludedTasks: [],
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isFalse);
      });

      test('detects overdue task', () {
        final overdueTask = TestData.createTask(
          name: 'Overdue',
          deadlineDate: DateTime.now().subtract(const Duration(days: 2)),
        );
        final excluded = [
          ExcludedTask(
            task: overdueTask,
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.realist,
        );

        expect(result.hasAlerts, isTrue);
        expect(result.alerts.first.type, AllocationAlertType.overdueExcluded);
        expect(result.alerts.first.severity, AlertSeverity.critical);
      });

      test('detects urgent task', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Urgent'),
            reason: 'Test',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isTrue);
        expect(result.alerts.first.type, AllocationAlertType.urgentExcluded);
      });

      test('detects noCategory exclusion', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'No Value'),
            reason: 'No value',
            exclusionType: ExclusionType.noCategory,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.reflector,
        );

        expect(result.hasAlerts, isTrue);
        expect(result.alerts.first.type, AllocationAlertType.noValueExcluded);
      });

      test('ignores disabled alert types', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Low Priority'),
            reason: 'Low priority',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        // Idealist doesn't have lowPriority alerts enabled
        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.idealist,
        );

        expect(result.hasAlerts, isFalse);
      });

      test('sorts alerts by severity', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'No Value'),
            reason: 'No value',
            exclusionType: ExclusionType.noCategory,
          ),
          ExcludedTask(
            task: TestData.createTask(
              name: 'Overdue',
              deadlineDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
            reason: 'Overdue',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.alerts.length, 2);
        // Critical (overdue) should come first
        expect(result.alerts.first.severity, AlertSeverity.critical);
      });

      test('groups alerts by type', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Urgent 1'),
            reason: 'Urgent',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
          ExcludedTask(
            task: TestData.createTask(name: 'Urgent 2'),
            reason: 'Urgent',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.byType[AllocationAlertType.urgentExcluded]?.length, 2);
      });

      test('highestSeverity returns most critical', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Notice'),
            reason: 'Low priority',
            exclusionType: ExclusionType.lowPriority,
          ),
          ExcludedTask(
            task: TestData.createTask(name: 'Urgent'),
            reason: 'Urgent',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.highestSeverity, AlertSeverity.critical);
      });

      test('never alerts for completed tasks', () {
        final excluded = [
          ExcludedTask(
            task: TestData.createTask(name: 'Completed', completed: true),
            reason: 'Completed',
            exclusionType: ExclusionType.completed,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isFalse);
      });
    });

    group('overdue priority over urgent', () {
      test('overdue task shows as overdue even if also urgent', () {
        final overdueUrgent = TestData.createTask(
          name: 'Overdue and Urgent',
          deadlineDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final excluded = [
          ExcludedTask(
            task: overdueUrgent,
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
            isUrgent: true,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        // Should be categorized as overdue, not urgent
        expect(result.alerts.first.type, AllocationAlertType.overdueExcluded);
      });
    });
  });
}
```

## AI Implementation Instructions

1. **Create EvaluatedAlert first** - Evaluator depends on it
2. **Pure function pattern** - No dependencies, just inputs → outputs
3. **Priority matters** - Overdue > Urgent > ExclusionType
4. **Single alert per task** - First matching rule wins
5. **Test edge cases** - Disabled config, empty list, completed tasks

## Checklist

- [ ] Create `evaluated_alert.dart` (freezed)
- [ ] Create `allocation_alert_evaluator.dart`
- [ ] Run build_runner for freezed
- [ ] Register in DI
- [ ] Create and run tests
- [ ] Verify all persona templates produce expected alerts
