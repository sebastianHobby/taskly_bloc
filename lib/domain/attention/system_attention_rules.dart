import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';

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

  /// Detects overdue tasks (past deadline)
  static const problemTaskOverdue = AttentionRuleTemplate(
    ruleKey: 'problem_task_overdue',
    bucket: AttentionBucket.action,
    evaluator: 'task_predicate_v1',
    evaluatorParams: {
      'predicate': 'isOverdue',
      'thresholdHours': 0,
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Overdue Tasks',
      'description': 'Tasks past their deadline',
      'icon': 'warning',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 10,
  );

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

  // ==========================================================================
  // REVIEW RULES (3 rules)
  // ==========================================================================

  /// Values alignment review
  static const reviewValuesAlignment = AttentionRuleTemplate(
    ruleKey: 'review_values_alignment',
    bucket: AttentionBucket.review,
    evaluator: 'review_session_due_v1',
    evaluatorParams: {
      'reviewType': 'values_alignment',
      'frequencyDays': 90,
    },
    severity: AttentionSeverity.info, // Reviews always info
    displayConfig: {
      'title': 'Values Alignment',
      'description': 'Reflect on your value priorities',
      'icon': 'star',
    },
    resolutionActions: ['reviewed', 'snoozed'],
    sortOrder: 100,
  );

  /// Balance review
  static const reviewBalance = AttentionRuleTemplate(
    ruleKey: 'review_balance',
    bucket: AttentionBucket.review,
    evaluator: 'review_session_due_v1',
    evaluatorParams: {
      'reviewType': 'balance',
      'frequencyDays': 30,
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Life Balance',
      'description': 'Review your life balance',
      'icon': 'balance',
    },
    resolutionActions: ['reviewed', 'snoozed'],
    sortOrder: 130,
  );

  // ========================================================================
  // REVIEW RULES (PROJECT HEALTH - coaching)
  // ========================================================================

  /// High-value project neglected (allocation-based).
  static const reviewProjectHighValueNeglected = AttentionRuleTemplate(
    ruleKey: 'review_project_high_value_neglected',
    bucket: AttentionBucket.action,
    evaluator: 'project_predicate_v1',
    evaluatorParams: {
      'predicate': 'highValueNeglected',
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'High-value project neglected',
      'description': 'Consider taking a small step on {project_name}.',
      'icon': 'star',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 200,
  );

  /// Project has not been allocated recently (portfolio hygiene).
  static const reviewProjectNoAllocatedRecently = AttentionRuleTemplate(
    ruleKey: 'review_project_no_allocated_recently',
    bucket: AttentionBucket.action,
    evaluator: 'project_predicate_v1',
    evaluatorParams: {
      'predicate': 'noAllocatedRecently',
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Project not allocated recently',
      'description': 'Do you still intend to move {project_name} forward?',
      'icon': 'history',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 210,
  );

  /// Project has no allocatable tasks for > 1 day (time gated).
  static const reviewProjectNoAllocatableTasks = AttentionRuleTemplate(
    ruleKey: 'review_project_no_allocatable_tasks',
    bucket: AttentionBucket.action,
    evaluator: 'project_predicate_v1',
    evaluatorParams: {
      'predicate': 'noAllocatableTasks',
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'No next action',
      'description': 'Add a next action for {project_name}.',
      'icon': 'check_circle',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 220,
  );

  /// Pinned tasks review
  static const reviewPinnedTasks = AttentionRuleTemplate(
    ruleKey: 'review_pinned_tasks',
    bucket: AttentionBucket.review,
    evaluator: 'review_session_due_v1',
    evaluatorParams: {
      'reviewType': 'pinned_tasks',
      'frequencyDays': 7,
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Pinned Tasks',
      'description': 'Review your pinned/important tasks',
      'icon': 'push_pin',
    },
    resolutionActions: ['reviewed', 'snoozed'],
    sortOrder: 140,
  );

  // ==========================================================================
  // ALLOCATION WARNING RULES (3 rules)
  // ==========================================================================

  /// Warns about tasks that need allocation attention
  static const allocationExcludedTasks = AttentionRuleTemplate(
    ruleKey: 'allocation_excluded_tasks',
    bucket: AttentionBucket.action,
    evaluator: 'allocation_snapshot_task_v1',
    evaluatorParams: {
      'predicate': 'urgentValueless',
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Needs Allocation',
      'description': 'Urgent tasks not in your day allocation',
      'icon': 'error_outline',
    },
    resolutionActions: ['reviewed', 'dismissed'],
    sortOrder: 200,
  );

  /// Warns about urgent tasks that ARE value-aligned but still not allocated.
  static const allocationUrgentValueAligned = AttentionRuleTemplate(
    ruleKey: 'allocation_urgent_value_aligned',
    bucket: AttentionBucket.action,
    evaluator: 'allocation_snapshot_task_v1',
    evaluatorParams: {
      'predicate': 'urgentValueAligned',
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Urgent but Not Allocated',
      'description': 'Urgent tasks aligned to your values, but not in focus',
      'icon': 'error_outline',
    },
    resolutionActions: ['reviewed', 'dismissed'],
    sortOrder: 210,
  );

  /// Warns about tasks under urgent projects that have no effective value.
  static const allocationProjectUrgentValueless = AttentionRuleTemplate(
    ruleKey: 'allocation_project_urgent_valueless',
    bucket: AttentionBucket.action,
    evaluator: 'allocation_snapshot_task_v1',
    evaluatorParams: {
      'predicate': 'projectUrgentValueless',
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Urgent Project Needs Alignment',
      'description': 'Tasks in urgent projects with no effective value',
      'icon': 'error_outline',
    },
    resolutionActions: ['reviewed', 'dismissed'],
    sortOrder: 220,
  );

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// All system rule templates
  static List<AttentionRuleTemplate> get all => [
    // Problem detection (3)
    problemTaskOverdue,
    problemTaskStale,
    problemProjectIdle,
    // Reviews (3 + 3 project health)
    reviewValuesAlignment,
    reviewBalance,
    reviewPinnedTasks,
    reviewProjectHighValueNeglected,
    reviewProjectNoAllocatedRecently,
    reviewProjectNoAllocatableTasks,
    // Allocation warnings (3)
    allocationExcludedTasks,
    allocationUrgentValueAligned,
    allocationProjectUrgentValueless,
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
