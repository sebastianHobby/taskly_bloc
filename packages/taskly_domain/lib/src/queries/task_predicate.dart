import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

/// Operators for boolean predicates.
enum BoolOperator { isTrue, isFalse }

/// Operators for date predicates.
enum DateOperator {
  onOrAfter,
  onOrBefore,
  before,
  after,
  on,
  between,
  isNull,
  isNotNull,

  /// Compare to a date computed as (today + relativeDays).
  relative,
}

/// Comparison mode for [DateOperator.relative].
enum RelativeComparison {
  on,
  before,
  after,
  onOrAfter,
  onOrBefore,
}

/// Operators for project predicates.
enum ProjectOperator { matches, matchesAny, isNull, isNotNull }

/// Operators for value predicates.
enum ValueOperator { hasAny, hasAll, isNull, isNotNull }

/// Task fields that can be queried.
enum TaskDateField {
  startDate,
  deadlineDate,
  createdAt,
  updatedAt,
  completedAt,
}

enum TaskBoolField { completed }

/// A single predicate in a task filter.
@immutable
sealed class TaskPredicate {
  const TaskPredicate();

  Map<String, dynamic> toJson();

  static TaskPredicate fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'bool' => TaskBoolPredicate.fromJson(json),
      'date' => TaskDatePredicate.fromJson(json),
      'project' => TaskProjectPredicate.fromJson(json),
      'value' => TaskValuePredicate.fromJson(json),
      _ => throw ArgumentError('Unknown TaskPredicate type: $type'),
    };
  }
}

@immutable
final class TaskBoolPredicate extends TaskPredicate {
  const TaskBoolPredicate({required this.field, required this.operator});

  factory TaskBoolPredicate.fromJson(Map<String, dynamic> json) {
    return TaskBoolPredicate(
      field: TaskBoolField.values.byName(
        json['field'] as String? ?? TaskBoolField.completed.name,
      ),
      operator: BoolOperator.values.byName(
        json['operator'] as String? ?? BoolOperator.isFalse.name,
      ),
    );
  }

  final TaskBoolField field;
  final BoolOperator operator;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'bool',
    'field': field.name,
    'operator': operator.name,
  };

  @override
  bool operator ==(Object other) {
    return other is TaskBoolPredicate &&
        other.field == field &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(field, operator);
}

@immutable
final class TaskDatePredicate extends TaskPredicate {
  const TaskDatePredicate({
    required this.field,
    required this.operator,
    this.date,
    this.startDate,
    this.endDate,
    this.relativeComparison,
    this.relativeDays,
  });

  factory TaskDatePredicate.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return TaskDatePredicate(
      field: TaskDateField.values.byName(
        json['field'] as String? ?? TaskDateField.createdAt.name,
      ),
      operator: DateOperator.values.byName(
        json['operator'] as String? ?? DateOperator.isNotNull.name,
      ),
      date: parseDate('date'),
      startDate: parseDate('startDate'),
      endDate: parseDate('endDate'),
      relativeComparison: (json['relativeComparison'] as String?)?.let(
        RelativeComparison.values.byName,
      ),
      relativeDays: json['relativeDays'] as int?,
    );
  }

  final TaskDateField field;
  final DateOperator operator;

  /// Pivot date for single-date operators.
  final DateTime? date;

  /// Range start for [DateOperator.between].
  final DateTime? startDate;

  /// Range end for [DateOperator.between].
  final DateTime? endDate;

  /// Used when [operator] is [DateOperator.relative].
  final RelativeComparison? relativeComparison;

  /// Used when [operator] is [DateOperator.relative].
  final int? relativeDays;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'date',
    'field': field.name,
    'operator': operator.name,
    'date': date?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'relativeComparison': relativeComparison?.name,
    'relativeDays': relativeDays,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskDatePredicate &&
        other.field == field &&
        other.operator == operator &&
        _dtEq(other.date, date) &&
        _dtEq(other.startDate, startDate) &&
        _dtEq(other.endDate, endDate) &&
        other.relativeComparison == relativeComparison &&
        other.relativeDays == relativeDays;
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

  bool _dtEq(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }
}

@immutable
final class TaskProjectPredicate extends TaskPredicate {
  const TaskProjectPredicate({
    required this.operator,
    this.projectId,
    this.projectIds = const <String>[],
  });

  factory TaskProjectPredicate.fromJson(Map<String, dynamic> json) {
    return TaskProjectPredicate(
      operator: ProjectOperator.values.byName(
        json['operator'] as String? ?? ProjectOperator.isNotNull.name,
      ),
      projectId: json['projectId'] as String?,
      projectIds: (json['projectIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final ProjectOperator operator;
  final String? projectId;
  final List<String> projectIds;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'project',
    'operator': operator.name,
    'projectId': projectId,
    'projectIds': projectIds,
  };

  @override
  bool operator ==(Object other) {
    return other is TaskProjectPredicate &&
        other.operator == operator &&
        other.projectId == projectId &&
        listEquals(other.projectIds, projectIds);
  }

  @override
  int get hashCode =>
      Object.hash(operator, projectId, Object.hashAll(projectIds));
}

@immutable
final class TaskValuePredicate extends TaskPredicate {
  const TaskValuePredicate({
    required this.operator,
    this.valueIds = const <String>[],
    this.includeInherited = false,
  });

  factory TaskValuePredicate.fromJson(Map<String, dynamic> json) {
    return TaskValuePredicate(
      operator: ValueOperator.values.byName(
        json['operator'] as String? ?? ValueOperator.hasAny.name,
      ),
      valueIds: (json['valueIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      includeInherited: json['includeInherited'] as bool? ?? false,
    );
  }

  final ValueOperator operator;
  final List<String> valueIds;

  /// Whether to include values inherited from the task's project.
  ///
  /// When true, a task matches if it has the value directly OR its parent
  /// project has the value. This is particularly useful for values where
  /// a project's value (e.g., "Health") should apply to all its tasks.
  ///
  /// Defaults to false.
  final bool includeInherited;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'value',
    'operator': operator.name,
    'valueIds': valueIds,
    'includeInherited': includeInherited,
  };

  @override
  bool operator ==(Object other) {
    return other is TaskValuePredicate &&
        other.operator == operator &&
        other.includeInherited == includeInherited &&
        listEquals(other.valueIds, valueIds);
  }

  @override
  int get hashCode => Object.hash(
    operator,
    includeInherited,
    Object.hashAll(valueIds),
  );
}

class TaskPredicateConverter
    implements JsonConverter<TaskPredicate, Map<String, dynamic>> {
  const TaskPredicateConverter();

  @override
  TaskPredicate fromJson(Map<String, dynamic> json) =>
      TaskPredicate.fromJson(json);

  @override
  Map<String, dynamic> toJson(TaskPredicate object) => object.toJson();
}

extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}
