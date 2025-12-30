import 'package:taskly_bloc/domain/filtering/task_rules.dart' as legacy;
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// Converts legacy rule types (`TaskRule` from `task_rules.dart`) into the
/// new predicate-based query model.
///
/// This allows existing UI/editor code paths (still emitting legacy rules)
/// to keep working while repositories and query objects move to
/// `QueryFilter<...Predicate>`.
QueryFilter<TaskPredicate> taskFilterFromLegacyRules(
  List<legacy.TaskRule> rules,
) {
  return QueryFilter<TaskPredicate>(
    shared: rules
        .map(taskPredicateFromLegacyRule)
        .whereType<TaskPredicate>()
        .toList(growable: false),
  );
}

TaskPredicate? taskPredicateFromLegacyRule(legacy.TaskRule rule) {
  return switch (rule) {
    legacy.BooleanRule() => TaskBoolPredicate(
      field: TaskBoolField.completed,
      operator: switch (rule.operator) {
        legacy.BooleanRuleOperator.isTrue => BoolOperator.isTrue,
        legacy.BooleanRuleOperator.isFalse => BoolOperator.isFalse,
      },
    ),
    legacy.DateRule() => TaskDatePredicate(
      field: switch (rule.field) {
        legacy.DateRuleField.startDate => TaskDateField.startDate,
        legacy.DateRuleField.deadlineDate => TaskDateField.deadlineDate,
        legacy.DateRuleField.createdAt => TaskDateField.createdAt,
        legacy.DateRuleField.updatedAt => TaskDateField.updatedAt,
        legacy.DateRuleField.completedAt => TaskDateField.completedAt,
      },
      operator: switch (rule.operator) {
        legacy.DateRuleOperator.onOrAfter => DateOperator.onOrAfter,
        legacy.DateRuleOperator.onOrBefore => DateOperator.onOrBefore,
        legacy.DateRuleOperator.before => DateOperator.before,
        legacy.DateRuleOperator.after => DateOperator.after,
        legacy.DateRuleOperator.on => DateOperator.on,
        legacy.DateRuleOperator.between => DateOperator.between,
        legacy.DateRuleOperator.relative => DateOperator.relative,
        legacy.DateRuleOperator.isNull => DateOperator.isNull,
        legacy.DateRuleOperator.isNotNull => DateOperator.isNotNull,
      },
      date: rule.date,
      startDate: rule.startDate,
      endDate: rule.endDate,
      relativeComparison: rule.relativeComparison == null
          ? null
          : RelativeComparison.values.byName(rule.relativeComparison!.name),
      relativeDays: rule.relativeDays,
    ),
    legacy.LabelRule() => TaskLabelPredicate(
      operator: switch (rule.operator) {
        legacy.LabelRuleOperator.hasAny => LabelOperator.hasAny,
        legacy.LabelRuleOperator.hasAll => LabelOperator.hasAll,
        legacy.LabelRuleOperator.isNull => LabelOperator.isNull,
        legacy.LabelRuleOperator.isNotNull => LabelOperator.isNotNull,
      },
      labelType: rule.labelType,
      labelIds: rule.labelIds,
    ),
    legacy.ValueRule() => TaskLabelPredicate(
      operator: switch (rule.operator) {
        legacy.ValueRuleOperator.hasAny => LabelOperator.hasAny,
        legacy.ValueRuleOperator.hasAll => LabelOperator.hasAll,
        legacy.ValueRuleOperator.isNull => LabelOperator.isNull,
        legacy.ValueRuleOperator.isNotNull => LabelOperator.isNotNull,
      },
      labelType: LabelType.value,
      labelIds: rule.labelIds,
    ),
    legacy.ProjectRule() => TaskProjectPredicate(
      operator: switch (rule.operator) {
        legacy.ProjectRuleOperator.matches => ProjectOperator.matches,
        legacy.ProjectRuleOperator.matchesAny => ProjectOperator.matchesAny,
        legacy.ProjectRuleOperator.isNull => ProjectOperator.isNull,
        legacy.ProjectRuleOperator.isNotNull => ProjectOperator.isNotNull,
      },
      projectId: rule.projectId,
      projectIds: rule.projectIds,
    ),
    _ => null,
  };
}

QueryFilter<ProjectPredicate> projectFilterFromLegacyRules(
  List<legacy.TaskRule> rules,
) {
  return QueryFilter<ProjectPredicate>(
    shared: rules
        .map(projectPredicateFromLegacyRule)
        .whereType<ProjectPredicate>()
        .toList(growable: false),
  );
}

ProjectPredicate? projectPredicateFromLegacyRule(legacy.TaskRule rule) {
  return switch (rule) {
    legacy.BooleanRule() => ProjectBoolPredicate(
      field: ProjectBoolField.completed,
      operator: switch (rule.operator) {
        legacy.BooleanRuleOperator.isTrue => BoolOperator.isTrue,
        legacy.BooleanRuleOperator.isFalse => BoolOperator.isFalse,
      },
    ),
    legacy.DateRule() => ProjectDatePredicate(
      field: switch (rule.field) {
        legacy.DateRuleField.startDate => ProjectDateField.startDate,
        legacy.DateRuleField.deadlineDate => ProjectDateField.deadlineDate,
        legacy.DateRuleField.createdAt => ProjectDateField.createdAt,
        legacy.DateRuleField.updatedAt => ProjectDateField.updatedAt,
        legacy.DateRuleField.completedAt => ProjectDateField.completedAt,
      },
      operator: switch (rule.operator) {
        legacy.DateRuleOperator.onOrAfter => DateOperator.onOrAfter,
        legacy.DateRuleOperator.onOrBefore => DateOperator.onOrBefore,
        legacy.DateRuleOperator.before => DateOperator.before,
        legacy.DateRuleOperator.after => DateOperator.after,
        legacy.DateRuleOperator.on => DateOperator.on,
        legacy.DateRuleOperator.between => DateOperator.between,
        legacy.DateRuleOperator.relative => DateOperator.relative,
        legacy.DateRuleOperator.isNull => DateOperator.isNull,
        legacy.DateRuleOperator.isNotNull => DateOperator.isNotNull,
      },
      date: rule.date,
      startDate: rule.startDate,
      endDate: rule.endDate,
      relativeComparison: rule.relativeComparison == null
          ? null
          : RelativeComparison.values.byName(rule.relativeComparison!.name),
      relativeDays: rule.relativeDays,
    ),
    legacy.LabelRule() => ProjectLabelPredicate(
      operator: switch (rule.operator) {
        legacy.LabelRuleOperator.hasAny => LabelOperator.hasAny,
        legacy.LabelRuleOperator.hasAll => LabelOperator.hasAll,
        legacy.LabelRuleOperator.isNull => LabelOperator.isNull,
        legacy.LabelRuleOperator.isNotNull => LabelOperator.isNotNull,
      },
      labelType: rule.labelType,
      labelIds: rule.labelIds,
    ),
    legacy.ValueRule() => ProjectLabelPredicate(
      operator: switch (rule.operator) {
        legacy.ValueRuleOperator.hasAny => LabelOperator.hasAny,
        legacy.ValueRuleOperator.hasAll => LabelOperator.hasAll,
        legacy.ValueRuleOperator.isNull => LabelOperator.isNull,
        legacy.ValueRuleOperator.isNotNull => LabelOperator.isNotNull,
      },
      labelType: LabelType.value,
      labelIds: rule.labelIds,
    ),
    legacy.ProjectRule() => null,
    _ => null,
  };
}
