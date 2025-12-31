/// Enums and types used for task rule configuration.
library;

/// Types of task rules available for filtering.
enum RuleType {
  date,
  boolean,
  labels,
  project,
  value,
}

/// Boolean operators for combining rules within a rule set.
enum RuleSetOperator { and, or }

/// Date fields that can be filtered on a task.
enum DateRuleField {
  startDate,
  deadlineDate,
  createdAt,
  updatedAt,
  completedAt,
}

/// Operators for date-based filtering.
enum DateRuleOperator {
  onOrAfter,
  onOrBefore,
  before,
  after,
  on,
  between,
  relative,
  isNull,
  isNotNull,
}

/// Comparison types for relative date rules.
enum RelativeComparison { on, before, after, onOrAfter, onOrBefore }

/// Boolean fields that can be filtered on a task.
enum BooleanRuleField { completed }

/// Operators for boolean-based filtering.
enum BooleanRuleOperator { isTrue, isFalse }

/// Operators for label-based filtering.
enum LabelRuleOperator { hasAll, hasAny, isNull, isNotNull }

/// Operators for value-based filtering.
enum ValueRuleOperator { hasAll, hasAny, isNull, isNotNull }

/// Operators for project-based filtering.
enum ProjectRuleOperator { matches, matchesAny, isNull, isNotNull }
