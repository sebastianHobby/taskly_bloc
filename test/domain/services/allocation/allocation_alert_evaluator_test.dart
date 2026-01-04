import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_alert_evaluator.dart';

import '../../../fixtures/test_data.dart';

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
            task: TestData.task(name: 'Test'),
            reason: 'Test',
            exclusionType: ExclusionType.noCategory,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: const AllocationAlertConfig(enabled: false),
        );

        expect(result.hasAlerts, isFalse);
        expect(result, AlertEvaluationResult.empty);
      });

      test('returns empty result when no excluded tasks', () {
        final result = evaluator.evaluate(
          excludedTasks: [],
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isFalse);
      });

      test('detects overdue task', () {
        final overdueTask = TestData.task(
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
            task: TestData.task(name: 'Urgent'),
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
            task: TestData.task(name: 'No Value'),
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

      test('detects lowPriority exclusion', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Low Priority'),
            reason: 'Low priority',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isTrue);
        expect(
          result.alerts.first.type,
          AllocationAlertType.lowPriorityExcluded,
        );
      });

      test('detects categoryLimitReached exclusion', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Quota Full'),
            reason: 'Quota full',
            exclusionType: ExclusionType.categoryLimitReached,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.hasAlerts, isTrue);
        expect(result.alerts.first.type, AllocationAlertType.quotaFullExcluded);
      });

      test('ignores disabled alert types', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Low Priority'),
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
            task: TestData.task(name: 'No Value'),
            reason: 'No value',
            exclusionType: ExclusionType.noCategory,
          ),
          ExcludedTask(
            task: TestData.task(
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
        expect(result.alerts.last.severity, AlertSeverity.warning);
      });

      test('groups alerts by type', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Urgent 1'),
            reason: 'Urgent',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
          ExcludedTask(
            task: TestData.task(name: 'Urgent 2'),
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

      test('groups alerts by severity', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(
              name: 'Overdue 1',
              deadlineDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
            reason: 'Overdue',
            exclusionType: ExclusionType.lowPriority,
          ),
          ExcludedTask(
            task: TestData.task(
              name: 'Overdue 2',
              deadlineDate: DateTime.now().subtract(const Duration(days: 2)),
            ),
            reason: 'Overdue',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.bySeverity[AlertSeverity.critical]?.length, 2);
      });

      test('highestSeverity returns most critical', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Notice'),
            reason: 'Low priority',
            exclusionType: ExclusionType.lowPriority,
          ),
          ExcludedTask(
            task: TestData.task(name: 'Urgent'),
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
            task: TestData.task(name: 'Completed', completed: true),
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

      test('totalCount returns correct count', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Task 1'),
            reason: 'Test',
            exclusionType: ExclusionType.noCategory,
          ),
          ExcludedTask(
            task: TestData.task(name: 'Task 2'),
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.totalCount, 2);
      });

      test('countBySeverity returns correct counts', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(
              name: 'Overdue',
              deadlineDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
            reason: 'Overdue',
            exclusionType: ExclusionType.lowPriority,
          ),
          ExcludedTask(
            task: TestData.task(name: 'Low Priority'),
            reason: 'Low priority',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.countBySeverity(AlertSeverity.critical), 1);
        expect(result.countBySeverity(AlertSeverity.notice), 1);
      });
    });

    group('overdue priority over urgent', () {
      test('overdue task shows as overdue even if also urgent', () {
        final overdueUrgent = TestData.task(
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

    group('reason formatting', () {
      test('formats overdue reason correctly for today', () {
        final task = TestData.task(
          name: 'Due Today',
          deadlineDate: DateTime.now(),
        );
        final excluded = [
          ExcludedTask(
            task: task,
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.realist,
        );

        expect(result.alerts.first.reason, 'Due today');
      });

      test('formats overdue reason correctly for 1 day', () {
        final task = TestData.task(
          name: 'Overdue 1 Day',
          deadlineDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final excluded = [
          ExcludedTask(
            task: task,
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.realist,
        );

        expect(result.alerts.first.reason, 'Overdue by 1 day');
      });

      test('formats overdue reason correctly for multiple days', () {
        final task = TestData.task(
          name: 'Overdue 3 Days',
          deadlineDate: DateTime.now().subtract(const Duration(days: 3)),
        );
        final excluded = [
          ExcludedTask(
            task: task,
            reason: 'Test',
            exclusionType: ExclusionType.lowPriority,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.realist,
        );

        expect(result.alerts.first.reason, 'Overdue by 3 days');
      });

      test('formats urgent reason for task without deadline', () {
        final excluded = [
          ExcludedTask(
            task: TestData.task(name: 'Urgent No Deadline'),
            reason: 'Test',
            exclusionType: ExclusionType.categoryLimitReached,
            isUrgent: true,
          ),
        ];

        final result = evaluator.evaluate(
          excludedTasks: excluded,
          config: AllocationAlertTemplates.firefighter,
        );

        expect(result.alerts.first.reason, 'Marked urgent');
      });
    });
  });

  group('AlertEvaluationResult', () {
    test('empty result has expected properties', () {
      const result = AlertEvaluationResult.empty;

      expect(result.hasAlerts, isFalse);
      expect(result.totalCount, 0);
      expect(result.highestSeverity, isNull);
      expect(result.alerts, isEmpty);
      expect(result.byType, isEmpty);
      expect(result.bySeverity, isEmpty);
    });
  });

  group('EvaluatedAlert', () {
    test('sortKey orders by severity then type', () {
      final alert1 = EvaluatedAlert(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.critical,
        excludedTask: ExcludedTask(
          task: TestData.task(name: 'Test'),
          reason: 'Test',
          exclusionType: ExclusionType.lowPriority,
        ),
        reason: 'Test',
      );

      final alert2 = EvaluatedAlert(
        type: AllocationAlertType.urgentExcluded,
        severity: AlertSeverity.warning,
        excludedTask: ExcludedTask(
          task: TestData.task(name: 'Test'),
          reason: 'Test',
          exclusionType: ExclusionType.lowPriority,
        ),
        reason: 'Test',
      );

      // Critical (sortOrder 0) should come before Warning (sortOrder 1)
      expect(alert1.sortKey < alert2.sortKey, isTrue);
    });
  });
}
