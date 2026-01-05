import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// Predefined alert configurations for each persona.
///
/// These are code-defined templates that match persona philosophy.
/// Users can customize after applying a template.
abstract class AllocationAlertTemplates {
  AllocationAlertTemplates._();

  /// Idealist: Trust the system, minimal alerts
  /// Only critical issues surface (overdue)
  static const idealist = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        id: 'idealist_overdue',
        name: 'Overdue Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: 0,
            ),
          ],
        ),
        severity: AlertSeverity.notice,
      ),
    ],
  );

  /// Reflector: Balanced awareness
  /// Overdue is warning, urgent is notice
  static const reflector = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        id: 'reflector_overdue',
        name: 'Overdue Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: 0,
            ),
          ],
        ),
        severity: AlertSeverity.warning,
      ),
      AllocationAlertRule(
        id: 'reflector_urgent',
        name: 'Urgent Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 3,
            ),
          ],
        ),
        severity: AlertSeverity.notice,
      ),
      AllocationAlertRule(
        id: 'reflector_no_value',
        name: 'Uncategorized Tasks',
        condition: QueryFilter(
          shared: [
            TaskValuePredicate(
              operator: ValueOperator.isNull,
            ),
          ],
        ),
        severity: AlertSeverity.notice,
      ),
    ],
  );

  /// Realist: Deadline-focused, strong alerts
  /// Overdue and urgent are critical
  static const realist = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        id: 'realist_overdue',
        name: 'Overdue Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: 0,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      ),
      AllocationAlertRule(
        id: 'realist_urgent',
        name: 'Urgent Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 3,
            ),
          ],
        ),
        severity: AlertSeverity.warning,
      ),
      AllocationAlertRule(
        id: 'realist_no_value',
        name: 'Uncategorized Tasks',
        condition: QueryFilter(
          shared: [
            TaskValuePredicate(
              operator: ValueOperator.isNull,
            ),
          ],
        ),
        severity: AlertSeverity.notice,
      ),
    ],
  );

  /// Firefighter: Maximum visibility
  /// Everything that might be urgent is surfaced
  static const firefighter = AllocationAlertConfig(
    rules: [
      AllocationAlertRule(
        id: 'firefighter_overdue',
        name: 'Overdue Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: 0,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      ),
      AllocationAlertRule(
        id: 'firefighter_urgent',
        name: 'Urgent Tasks',
        condition: QueryFilter(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 3,
            ),
          ],
        ),
        severity: AlertSeverity.critical,
      ),
    ],
  );

  /// Custom: Same as Reflector (sensible default)
  static const AllocationAlertConfig custom = reflector;

  /// Get template for a persona
  static AllocationAlertConfig forPersona(AllocationPersona persona) =>
      switch (persona) {
        AllocationPersona.idealist => idealist,
        AllocationPersona.reflector => reflector,
        AllocationPersona.realist => realist,
        AllocationPersona.firefighter => firefighter,
        AllocationPersona.custom => custom,
      };

  /// All available templates with metadata
  static const List<AlertTemplateInfo> all = [
    AlertTemplateInfo(
      id: 'idealist',
      name: 'Idealist',
      description: 'Trust the system. Minimal alerts.',
      config: idealist,
    ),
    AlertTemplateInfo(
      id: 'reflector',
      name: 'Reflector',
      description: 'Balanced awareness of exclusions.',
      config: reflector,
    ),
    AlertTemplateInfo(
      id: 'realist',
      name: 'Realist',
      description: 'Deadline-focused. Strong alerts for time-sensitive items.',
      config: realist,
    ),
    AlertTemplateInfo(
      id: 'firefighter',
      name: 'Firefighter',
      description: 'Maximum visibility. See everything outside Focus.',
      config: firefighter,
    ),
  ];
}

/// Metadata for a template
class AlertTemplateInfo {
  const AlertTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
  });

  final String id;
  final String name;
  final String description;
  final AllocationAlertConfig config;
}
