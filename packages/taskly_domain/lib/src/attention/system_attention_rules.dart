import 'package:taskly_domain/src/attention/model/attention_rule.dart';

/// System-defined attention rule templates
///
/// These are TEMPLATES that get seeded to the database on first launch.
/// The source of truth is always the database.
///
/// Pattern matches the code-seeded system-template approach:
/// - Templates are defined as static fields
/// - Seeded with source='system_template'
/// - Users customize via database rows
/// - Repository reads from the database, not these templates
abstract class SystemAttentionRules {
  SystemAttentionRules._();

  // ==========================================================================
  // PROBLEM DETECTION RULES (3 rules)
  // ==========================================================================

  /// Detects stale tasks (no activity for 30+ days)
  static const problemTaskStale = AttentionRuleTemplate(
    ruleKey: 'problem_task_stale',
    bucket: AttentionBucket.action,
    evaluator: 'task_predicate_v1',
    evaluatorParams: {
      'predicate': 'isStale',
      'thresholdDays': 30,
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Stale Tasks',
      'description': 'Tasks with no activity in 30+ days',
      'icon': 'schedule',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 20,
  );

  /// Detects idle projects (no activity)
  static const problemProjectIdle = AttentionRuleTemplate(
    ruleKey: 'problem_project_idle',
    bucket: AttentionBucket.action,
    evaluator: 'project_predicate_v1',
    evaluatorParams: {
      'predicate': 'isIdle',
      'thresholdDays': 30,
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Idle Projects',
      'description': 'Projects with no recent activity',
      'icon': 'folder_off',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 30,
  );

  /// Detects projects that are due soon but still have many unscheduled tasks.
  ///
  /// “Unscheduled” (for this rule) means:
  /// - missing both start + deadline
  /// - OR start date is in the past AND no deadline is set
  static const problemProjectDeadlineRisk = AttentionRuleTemplate(
    ruleKey: 'problem_project_deadline_risk',
    bucket: AttentionBucket.action,
    evaluator: 'project_predicate_v1',
    evaluatorParams: {
      'predicate': 'dueSoonManyUnscheduledTasks',
      'dueWithinDays': 14,
      'minUnscheduledCount': 5,
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Deadline Risk',
      'description': 'Project due soon with many unscheduled tasks.',
      'icon': 'warning',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 40,
  );

  /// Detects routines that are either in an early building phase or trending
  /// down and likely need support.
  static const problemRoutineSupport = AttentionRuleTemplate(
    ruleKey: 'problem_routine_support',
    bucket: AttentionBucket.action,
    evaluator: 'routine_support_v1',
    evaluatorParams: {
      'buildingMinAgeDays': 7,
      'buildingMaxAgeDays': 28,
      'needsHelpDropPp': 15,
      'needsHelpRecentAdherenceMax': 60,
      'maxCards': 2,
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Routine Support',
      'description':
          'Small changes restore momentum. Tune this routine for this week.',
      'icon': 'self_improvement',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 45,
  );

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// All system rule templates
  static List<AttentionRuleTemplate> get all => [
    // Problem detection (3)
    problemTaskStale,
    problemProjectIdle,
    problemProjectDeadlineRisk,
    problemRoutineSupport,
  ];

  /// Get template by rule key
  static AttentionRuleTemplate? getByKey(String ruleKey) {
    for (final rule in all) {
      if (rule.ruleKey == ruleKey) {
        return rule;
      }
    }
    return null;
  }
}

/// Template class for attention rules (not a domain model)
/// This exists only for seeding - never used directly in business logic
class AttentionRuleTemplate {
  const AttentionRuleTemplate({
    required this.ruleKey,
    required this.bucket,
    required this.evaluator,
    required this.evaluatorParams,
    required this.severity,
    required this.displayConfig,
    required this.resolutionActions,
    required this.sortOrder,
  });
  final String ruleKey;
  final AttentionBucket bucket;
  final String evaluator;
  final Map<String, dynamic> evaluatorParams;
  final AttentionSeverity severity;
  final Map<String, dynamic> displayConfig;
  final List<String> resolutionActions;
  final int sortOrder;
}
