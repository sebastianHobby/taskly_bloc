import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator, RelativeComparison;

/// Evaluates project filters (shared AND + one-level OR groups).
class ProjectFilterEvaluator {
  const ProjectFilterEvaluator();

  bool matches(
    Project project,
    QueryFilter<ProjectPredicate> filter,
    EvaluationContext ctx,
  ) {
    if (filter.isMatchAll) return true;

    final sharedOk = filter.shared.every(
      (p) => _evalPredicate(project, p, ctx),
    );
    if (!sharedOk) return false;

    if (filter.orGroups.isEmpty) return true;

    for (final group in filter.orGroups) {
      final groupOk = group.every((p) => _evalPredicate(project, p, ctx));
      if (groupOk) return true;
    }

    return false;
  }

  bool _evalPredicate(
    Project project,
    ProjectPredicate p,
    EvaluationContext ctx,
  ) {
    return switch (p) {
      ProjectBoolPredicate() => _evalBool(project, p),
      ProjectDatePredicate() => _evalDate(project, p, ctx),
      ProjectLabelPredicate() => _evalLabel(project, p),
    };
  }

  bool _evalBool(Project project, ProjectBoolPredicate p) {
    final value = switch (p.field) {
      ProjectBoolField.completed => project.completed,
    };

    return switch (p.operator) {
      BoolOperator.isTrue => value,
      BoolOperator.isFalse => !value,
    };
  }

  bool _evalLabel(Project project, ProjectLabelPredicate p) {
    final ids = project.labels
        .where((l) => l.type == p.labelType)
        .map((l) => l.id)
        .toSet();

    return switch (p.operator) {
      LabelOperator.hasAny => p.labelIds.any(ids.contains),
      LabelOperator.hasAll => p.labelIds.every(ids.contains),
      LabelOperator.isNull => ids.isEmpty,
      LabelOperator.isNotNull => ids.isNotEmpty,
    };
  }

  bool _evalDate(
    Project project,
    ProjectDatePredicate p,
    EvaluationContext ctx,
  ) {
    final fieldValue = switch (p.field) {
      ProjectDateField.startDate => project.startDate,
      ProjectDateField.deadlineDate => project.deadlineDate,
      ProjectDateField.createdAt => project.createdAt,
      ProjectDateField.updatedAt => project.updatedAt,
      ProjectDateField.completedAt => project.occurrence?.completedAt,
    };

    if (p.operator == DateOperator.relative) {
      final comp = p.relativeComparison;
      final days = p.relativeDays;
      if (comp == null || days == null) return false;

      final pivot = dateOnly(ctx.today.add(Duration(days: days)));
      final target = fieldValue == null ? null : dateOnly(fieldValue);
      if (target == null) return false;

      return switch (comp) {
        RelativeComparison.on => target.isAtSameMomentAs(pivot),
        RelativeComparison.before => target.isBefore(pivot),
        RelativeComparison.after => target.isAfter(pivot),
        RelativeComparison.onOrAfter => !target.isBefore(pivot),
        RelativeComparison.onOrBefore => !target.isAfter(pivot),
      };
    }

    final absoluteDate = p.date;
    final absoluteStart = p.startDate;
    final absoluteEnd = p.endDate;

    return switch (p.operator) {
      DateOperator.onOrAfter =>
        fieldValue != null && !fieldValue.isBefore(absoluteDate!),
      DateOperator.onOrBefore =>
        fieldValue != null && !fieldValue.isAfter(absoluteDate!),
      DateOperator.before =>
        fieldValue != null && fieldValue.isBefore(absoluteDate!),
      DateOperator.after =>
        fieldValue != null && fieldValue.isAfter(absoluteDate!),
      DateOperator.on =>
        fieldValue != null && dateOnly(fieldValue) == dateOnly(absoluteDate!),
      DateOperator.between =>
        fieldValue != null &&
            !fieldValue.isBefore(absoluteStart!) &&
            !fieldValue.isAfter(absoluteEnd!),
      DateOperator.isNull => fieldValue == null,
      DateOperator.isNotNull => fieldValue != null,
      DateOperator.relative => false,
    };
  }
}
