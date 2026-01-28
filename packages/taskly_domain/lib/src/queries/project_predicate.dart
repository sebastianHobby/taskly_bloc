import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, DateOperator, RelativeComparison, ValueOperator;

/// Project fields that can be queried.
enum ProjectDateField {
  startDate,
  deadlineDate,
  createdAt,
  updatedAt,
  completedAt,
}

enum ProjectBoolField { completed, repeating }

@immutable
sealed class ProjectPredicate {
  const ProjectPredicate();

  Map<String, dynamic> toJson();

  static ProjectPredicate fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'id' => ProjectIdPredicate.fromJson(json),
      'bool' => ProjectBoolPredicate.fromJson(json),
      'date' => ProjectDatePredicate.fromJson(json),
      'value' => ProjectValuePredicate.fromJson(json),
      _ => throw ArgumentError('Unknown ProjectPredicate type: $type'),
    };
  }
}

/// Predicate for filtering projects by ID.
@immutable
final class ProjectIdPredicate extends ProjectPredicate {
  const ProjectIdPredicate({required this.id});

  factory ProjectIdPredicate.fromJson(Map<String, dynamic> json) {
    return ProjectIdPredicate(
      id: json['id'] as String,
    );
  }

  final String id;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'id',
    'id': id,
  };

  @override
  bool operator ==(Object other) {
    return other is ProjectIdPredicate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@immutable
final class ProjectBoolPredicate extends ProjectPredicate {
  const ProjectBoolPredicate({required this.field, required this.operator});

  factory ProjectBoolPredicate.fromJson(Map<String, dynamic> json) {
    return ProjectBoolPredicate(
      field: ProjectBoolField.values.byName(
        json['field'] as String? ?? ProjectBoolField.completed.name,
      ),
      operator: BoolOperator.values.byName(
        json['operator'] as String? ?? BoolOperator.isFalse.name,
      ),
    );
  }

  final ProjectBoolField field;
  final BoolOperator operator;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'bool',
    'field': field.name,
    'operator': operator.name,
  };

  @override
  bool operator ==(Object other) {
    return other is ProjectBoolPredicate &&
        other.field == field &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(field, operator);
}

@immutable
final class ProjectDatePredicate extends ProjectPredicate {
  const ProjectDatePredicate({
    required this.field,
    required this.operator,
    this.date,
    this.startDate,
    this.endDate,
    this.relativeComparison,
    this.relativeDays,
  });

  factory ProjectDatePredicate.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return ProjectDatePredicate(
      field: ProjectDateField.values.byName(
        json['field'] as String? ?? ProjectDateField.createdAt.name,
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

  final ProjectDateField field;
  final DateOperator operator;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final RelativeComparison? relativeComparison;
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
    return other is ProjectDatePredicate &&
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
final class ProjectValuePredicate extends ProjectPredicate {
  const ProjectValuePredicate({
    required this.operator,
    this.valueIds = const <String>[],
  });

  factory ProjectValuePredicate.fromJson(Map<String, dynamic> json) {
    return ProjectValuePredicate(
      operator: ValueOperator.values.byName(
        json['operator'] as String? ?? ValueOperator.hasAny.name,
      ),
      valueIds: (json['valueIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final ValueOperator operator;
  final List<String> valueIds;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'value',
    'operator': operator.name,
    'valueIds': valueIds,
  };

  @override
  bool operator ==(Object other) {
    return other is ProjectValuePredicate &&
        other.operator == operator &&
        listEquals(other.valueIds, valueIds);
  }

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(valueIds));
}

extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}
