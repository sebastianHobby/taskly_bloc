import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';

/// System-defined attention rule templates
///
/// These are TEMPLATES that get seeded to the database on first launch.
/// The source of truth is always the database.
///
/// Pattern matches SystemScreenDefinitions:
/// - Templates defined as static fields
/// - Seeded with source='system_template'
/// - Users customize via database rows
/// - Repository reads from database, not these templates
abstract class SystemAttentionRules {
  SystemAttentionRules._();

  // ==========================================================================
  // PROBLEM DETECTION RULES (4 rules)
  // ==========================================================================

  /// Detects overdue tasks (past deadline)
  static const problemTaskOverdue = AttentionRuleTemplate(
    ruleKey: 'problem_task_overdue',
    ruleType: AttentionRuleType.problem,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {
      'threshold_hours': 0, // Alert as soon as overdue
    },
    entitySelector: {
      'entity_type': 'task',
      'predicate': 'isOverdue',
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
    ruleType: AttentionRuleType.problem,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'threshold_days': 30,
    },
    entitySelector: {
      'entity_type': 'task',
      'predicate': 'isStale',
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
    ruleType: AttentionRuleType.problem,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'threshold_days': 30,
    },
    entitySelector: {
      'entity_type': 'project',
      'predicate': 'isIdle',
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

  /// Detects overdue journal entries
  static const problemJournalOverdue = AttentionRuleTemplate(
    ruleKey: 'problem_journal_overdue',
    ruleType: AttentionRuleType.problem,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {
      'threshold_days': 1,
    },
    entitySelector: {
      'entity_type': 'journal',
      'predicate': 'isOverdue',
    },
    severity: AttentionSeverity.warning,
    displayConfig: {
      'title': 'Journal Overdue',
      'description': 'Journal entries past due date',
      'icon': 'book',
    },
    resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
    sortOrder: 40,
  );

  // ==========================================================================
  // REVIEW RULES (5 rules - from existing ReviewSettings)
  // ==========================================================================

  /// Values alignment review
  static const reviewValuesAlignment = AttentionRuleTemplate(
    ruleKey: 'review_values_alignment',
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'frequency_days': 90, // Quarterly
    },
    entitySelector: {
      'entity_type': 'review_session',
      'review_type': 'values_alignment',
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

  /// Progress review
  static const reviewProgress = AttentionRuleTemplate(
    ruleKey: 'review_progress',
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'frequency_days': 30, // Monthly
    },
    entitySelector: {
      'entity_type': 'review_session',
      'review_type': 'progress',
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Progress Review',
      'description': 'Review your goal progress',
      'icon': 'trending_up',
    },
    resolutionActions: ['reviewed', 'snoozed'],
    sortOrder: 110,
  );

  /// Wellbeing review
  static const reviewWellbeing = AttentionRuleTemplate(
    ruleKey: 'review_wellbeing',
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'frequency_days': 14, // Bi-weekly
    },
    entitySelector: {
      'entity_type': 'review_session',
      'review_type': 'wellbeing',
    },
    severity: AttentionSeverity.info,
    displayConfig: {
      'title': 'Wellbeing Check-in',
      'description': 'Check in on your wellbeing',
      'icon': 'favorite',
    },
    resolutionActions: ['reviewed', 'snoozed'],
    sortOrder: 120,
  );

  /// Balance review
  static const reviewBalance = AttentionRuleTemplate(
    ruleKey: 'review_balance',
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'frequency_days': 30, // Monthly
    },
    entitySelector: {
      'entity_type': 'review_session',
      'review_type': 'balance',
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
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {},
    entitySelector: {
      'entity_type': 'project',
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
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {},
    entitySelector: {
      'entity_type': 'project',
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
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {},
    entitySelector: {
      'entity_type': 'project',
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
    ruleType: AttentionRuleType.review,
    triggerType: AttentionTriggerType.scheduled,
    triggerConfig: {
      'frequency_days': 7, // Weekly
    },
    entitySelector: {
      'entity_type': 'review_session',
      'review_type': 'pinned_tasks',
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
    ruleType: AttentionRuleType.allocationWarning,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {
      'show_in': 'my_day',
    },
    entitySelector: {
      'entity_type': 'task',
      // Candidates are selected by predicate and then filtered by
      // persisted allocation snapshot membership (allocated-only).
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
    ruleType: AttentionRuleType.allocationWarning,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {
      'show_in': 'my_day',
    },
    entitySelector: {
      'entity_type': 'task',
      // Candidates are selected by predicate and then filtered by
      // persisted allocation snapshot membership (allocated-only).
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
    ruleType: AttentionRuleType.allocationWarning,
    triggerType: AttentionTriggerType.realtime,
    triggerConfig: {
      'show_in': 'my_day',
    },
    entitySelector: {
      'entity_type': 'task',
      // Candidates are selected by predicate and then filtered by
      // persisted allocation snapshot membership (allocated-only).
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
    // Problem detection (4)
    problemTaskOverdue,
    problemTaskStale,
    problemProjectIdle,
    problemJournalOverdue,
    // Reviews (5 + 3 project health)
    reviewValuesAlignment,
    reviewProgress,
    reviewWellbeing,
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

  /// Get all templates of a specific type
  static List<AttentionRuleTemplate> byType(AttentionRuleType type) {
    return all.where((rule) => rule.ruleType == type).toList();
  }
}

/// Template class for attention rules (not a domain model)
/// This exists only for seeding - never used directly in business logic
class AttentionRuleTemplate {
  const AttentionRuleTemplate({
    required this.ruleKey,
    required this.ruleType,
    required this.triggerType,
    required this.triggerConfig,
    required this.entitySelector,
    required this.severity,
    required this.displayConfig,
    required this.resolutionActions,
    required this.sortOrder,
  });
  final String ruleKey;
  final AttentionRuleType ruleType;
  final AttentionTriggerType triggerType;
  final Map<String, dynamic> triggerConfig;
  final Map<String, dynamic> entitySelector;
  final AttentionSeverity severity;
  final Map<String, dynamic> displayConfig;
  final List<String> resolutionActions;
  final int sortOrder;
}
