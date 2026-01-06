import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/queries/operators/operators.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator;

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
      ProjectValuePredicate() => _evalValue(project, p),
      ProjectIdPredicate() => _evalId(project, p),
    };
  }

  bool _evalBool(Project project, ProjectBoolPredicate p) {
    final value = switch (p.field) {
      ProjectBoolField.completed => project.completed,
    };
    return BoolComparison.evaluate(fieldValue: value, operator: p.operator);
  }

  bool _evalValue(Project project, ProjectValuePredicate p) {
    final ids = project.values.map((v) => v.id).toSet();
    return ValueComparison.evaluate(
      entityValueIds: ids,
      predicateValueIds: p.valueIds,
      operator: p.operator,
    );
  }

  bool _evalId(Project project, ProjectIdPredicate p) {
    return project.id == p.id;
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

      return DateComparison.evaluateRelative(
        fieldValue: fieldValue,
        comparison: comp,
        pivot: ctx.today.add(Duration(days: days)),
      );
    }

    return DateComparison.evaluate(
      fieldValue: fieldValue,
      operator: p.operator,
      date: p.date,
      startDate: p.startDate,
      endDate: p.endDate,
    );
  }
}
