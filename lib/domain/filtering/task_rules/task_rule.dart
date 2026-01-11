import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules/rule_types.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Base class for all task filtering rules.
abstract class TaskRule {
  const TaskRule();

  /// The type of this rule for serialization and UI purposes.
  RuleType get type;

  /// Evaluates whether this rule applies to the given task.
  bool applies(Task task, DateTime today) =>
      evaluate(task, EvaluationContext(today: today));

  /// Enhanced evaluation method with full context.
  bool evaluate(Task task, EvaluationContext context);

  /// Validates the rule configuration and returns error messages.
  List<String> validate() => const [];

  /// Serializes the rule to JSON.
  Map<String, dynamic> toJson();

  static TaskRule fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = RuleType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => RuleType.boolean,
    );

    switch (type) {
      case RuleType.date:
        return DateRule.fromJson(json);
      case RuleType.boolean:
        return BooleanRule.fromJson(json);
      case RuleType.value:
        return ValueRule.fromJson(json);
      case RuleType.project:
        return ProjectRule.fromJson(json);
    }
  }
}

/// Rule for filtering tasks by date fields.
class DateRule extends TaskRule {
  const DateRule({
    required this.field,
    required this.operator,
    this.date,
    this.startDate,
    this.endDate,
    this.relativeComparison,
    this.relativeDays,
  });

  factory DateRule.fromJson(Map<String, dynamic> json) {
    return DateRule(
      field: DateRuleField.values.byName(
        json['field'] as String? ?? DateRuleField.deadlineDate.name,
      ),
      operator: DateRuleOperator.values.byName(
        json['operator'] as String? ?? DateRuleOperator.onOrAfter.name,
      ),
      date: tryParseDateOnly(json['date'] as String?),
      startDate: tryParseDateOnly(json['startDate'] as String?),
      endDate: tryParseDateOnly(json['endDate'] as String?),
      relativeComparison: json['relativeComparison'] == null
          ? null
          : RelativeComparison.values.byName(
              json['relativeComparison'] as String,
            ),
      relativeDays: json['relativeDays'] as int?,
    );
  }

  final DateRuleField field;
  final DateRuleOperator operator;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final RelativeComparison? relativeComparison;
  final int? relativeDays;

  @override
  RuleType get type => RuleType.date;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case DateRuleOperator.between:
        if (startDate == null || endDate == null) {
          errors.add('Between operator requires both start and end dates');
        } else if (endDate!.isBefore(startDate!)) {
          errors.add('End date must be after start date');
        }
      case DateRuleOperator.relative:
        if (relativeComparison == null) {
          errors.add('Relative operator requires comparison type');
        }
        if (relativeDays == null) {
          errors.add('Relative operator requires days value');
        }
      case DateRuleOperator.onOrAfter:
      case DateRuleOperator.onOrBefore:
      case DateRuleOperator.before:
      case DateRuleOperator.after:
      case DateRuleOperator.on:
        if (date == null) {
          errors.add('${operator.name} operator requires a date value');
        }
      case DateRuleOperator.isNull:
      case DateRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final target = _extractDate(task);
    final dateOnlyTarget = target == null ? null : dateOnly(target);

    switch (operator) {
      case DateRuleOperator.onOrAfter:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            !dateOnlyTarget.isBefore(pivot);
      case DateRuleOperator.onOrBefore:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            !dateOnlyTarget.isAfter(pivot);
      case DateRuleOperator.before:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isBefore(pivot);
      case DateRuleOperator.after:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isAfter(pivot);
      case DateRuleOperator.on:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isAtSameMomentAs(pivot);
      case DateRuleOperator.between:
        final start = _pivotDate(startDate);
        final end = _pivotDate(endDate);
        if (start == null || end == null || end.isBefore(start)) return false;
        if (dateOnlyTarget == null) return false;
        return !dateOnlyTarget.isBefore(start) && !dateOnlyTarget.isAfter(end);
      case DateRuleOperator.relative:
        final comparison = relativeComparison;
        final days = relativeDays;
        if (comparison == null || days == null) return false;
        if (dateOnlyTarget == null) return false;
        final pivot = dateOnly(today.add(Duration(days: days)));
        return switch (comparison) {
          RelativeComparison.on => dateOnlyTarget.isAtSameMomentAs(pivot),
          RelativeComparison.before => dateOnlyTarget.isBefore(pivot),
          RelativeComparison.after => dateOnlyTarget.isAfter(pivot),
          RelativeComparison.onOrAfter => !dateOnlyTarget.isBefore(pivot),
          RelativeComparison.onOrBefore => !dateOnlyTarget.isAfter(pivot),
        };
      case DateRuleOperator.isNull:
        return target == null;
      case DateRuleOperator.isNotNull:
        return target != null;
    }
  }

  DateTime? _extractDate(Task task) {
    return switch (field) {
      DateRuleField.startDate => task.startDate,
      DateRuleField.deadlineDate => task.deadlineDate,
      DateRuleField.createdAt => task.createdAt,
      DateRuleField.updatedAt => task.updatedAt,
      DateRuleField.completedAt => task.occurrence?.completedAt,
    };
  }

  DateTime? _pivotDate(DateTime? value) =>
      value == null ? null : dateOnly(value);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'field': field.name,
    'operator': operator.name,
    'date': encodeDateOnlyOrNull(date),
    'startDate': encodeDateOnlyOrNull(startDate),
    'endDate': encodeDateOnlyOrNull(endDate),
    'relativeComparison': relativeComparison?.name,
    'relativeDays': relativeDays,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRule &&
        other.field == field &&
        other.operator == operator &&
        _datesEqual(other.date, date) &&
        _datesEqual(other.startDate, startDate) &&
        _datesEqual(other.endDate, endDate) &&
        other.relativeComparison == relativeComparison &&
        other.relativeDays == relativeDays;
  }

  bool _datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }

  @override
  int get hashCode => Object.hash(
    field,
    operator,
    date?.millisecondsSinceEpoch,
    startDate?.millisecondsSinceEpoch,
    endDate?.millisecondsSinceEpoch,
    relativeComparison,
    relativeDays,
  );
}

/// Rule for filtering tasks by boolean fields.
class BooleanRule extends TaskRule {
  const BooleanRule({
    required this.field,
    required this.operator,
  });

  factory BooleanRule.fromJson(Map<String, dynamic> json) {
    return BooleanRule(
      field: BooleanRuleField.values.byName(
        json['field'] as String? ?? BooleanRuleField.completed.name,
      ),
      operator: BooleanRuleOperator.values.byName(
        json['operator'] as String? ?? BooleanRuleOperator.isFalse.name,
      ),
    );
  }

  final BooleanRuleField field;
  final BooleanRuleOperator operator;

  @override
  RuleType get type => RuleType.boolean;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    // BooleanRule is always valid as it has simple structure
    return const [];
  }

  @override
  bool applies(Task task, DateTime today) {
    final value = switch (field) {
      BooleanRuleField.completed => task.completed,
    };

    return switch (operator) {
      BooleanRuleOperator.isTrue => value,
      BooleanRuleOperator.isFalse => !value,
    };
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'field': field.name,
    'operator': operator.name,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BooleanRule &&
        other.field == field &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(field, operator);
}

/// Rule for filtering tasks by values.
class ValueRule extends TaskRule {
  const ValueRule({
    required this.operator,
    this.valueIds = const <String>[],
  });

  factory ValueRule.fromJson(Map<String, dynamic> json) {
    return ValueRule(
      operator: ValueRuleOperator.values.byName(
        json['operator'] as String? ?? ValueRuleOperator.hasAll.name,
      ),
      valueIds: (json['valueIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final ValueRuleOperator operator;
  final List<String> valueIds;

  @override
  RuleType get type => RuleType.value;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case ValueRuleOperator.hasAll:
      case ValueRuleOperator.hasAny:
        if (valueIds.isEmpty) {
          errors.add(
            '${operator.name} operator requires at least one value ID',
          );
        } else {
          final nonEmptyIds = valueIds.where((id) => id.trim().isNotEmpty);
          if (nonEmptyIds.isEmpty) {
            errors.add('All value IDs are empty');
          }
        }
      case ValueRuleOperator.isNull:
      case ValueRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final values = task.values;

    if (operator == ValueRuleOperator.isNull) {
      return values.isEmpty;
    }
    if (operator == ValueRuleOperator.isNotNull) {
      return values.isNotEmpty;
    }

    if (valueIds.isEmpty) return false;
    final ids = valueIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return false;

    final taskValueIds = values.map((value) => value.id).toSet();

    if (operator == ValueRuleOperator.hasAll) {
      return ids.every(taskValueIds.contains);
    }

    return ids.any(taskValueIds.contains);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'operator': operator.name,
    'valueIds': valueIds,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueRule &&
        other.operator == operator &&
        _listEquals(other.valueIds, valueIds);
  }

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(valueIds));
}

/// Rule for filtering tasks by project assignment.
class ProjectRule extends TaskRule {
  const ProjectRule({
    required this.operator,
    this.projectId,
    this.projectIds = const <String>[],
  });

  factory ProjectRule.fromJson(Map<String, dynamic> json) {
    return ProjectRule(
      operator: ProjectRuleOperator.values.byName(
        json['operator'] as String? ?? ProjectRuleOperator.matches.name,
      ),
      projectId: json['projectId'] as String?,
      projectIds: (json['projectIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final ProjectRuleOperator operator;
  final String? projectId;
  final List<String> projectIds;

  @override
  RuleType get type => RuleType.project;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case ProjectRuleOperator.matches:
        if (projectId == null || projectId!.trim().isEmpty) {
          errors.add('Matches operator requires a project ID');
        }
      case ProjectRuleOperator.matchesAny:
        if (projectIds.isEmpty) {
          errors.add('matchesAny operator requires at least one project ID');
        } else {
          final nonEmpty = projectIds.where((id) => id.trim().isNotEmpty);
          if (nonEmpty.isEmpty) {
            errors.add('All project IDs are empty');
          }
        }
      case ProjectRuleOperator.isNull:
      case ProjectRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final id = task.projectId;
    return switch (operator) {
      ProjectRuleOperator.matches =>
        id != null && projectId != null && id == projectId,
      ProjectRuleOperator.matchesAny =>
        id != null && projectIds.where((p) => p.isNotEmpty).contains(id),
      ProjectRuleOperator.isNull => id == null,
      ProjectRuleOperator.isNotNull => id != null,
    };
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'operator': operator.name,
    'projectId': projectId,
    'projectIds': projectIds,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectRule &&
        other.operator == operator &&
        other.projectId == projectId &&
        _listEquals(other.projectIds, projectIds);
  }

  @override
  int get hashCode =>
      Object.hash(operator, projectId, Object.hashAll(projectIds));
}

/// Helper function for list equality comparison.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
