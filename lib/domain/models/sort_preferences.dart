import 'package:flutter/foundation.dart';

/// Supported sort fields for task-, project-, and label-style entities.
enum SortField {
  name,
  startDate,
  deadlineDate,
  createdDate,
  updatedDate,
  nextActionPriority,
}

/// Sort direction per criterion.
enum SortDirection { ascending, descending }

@immutable
class SortCriterion {
  const SortCriterion({
    required this.field,
    this.direction = SortDirection.ascending,
  });

  factory SortCriterion.fromJson(Map<String, dynamic> json) {
    final fieldName = json['field'] as String?;
    final directionName = json['direction'] as String?;

    final normalizedDirection = switch (directionName) {
      'asc' => SortDirection.ascending.name,
      'desc' => SortDirection.descending.name,
      _ => directionName,
    };

    return SortCriterion(
      field: SortField.values.byName(fieldName ?? SortField.name.name),
      direction: SortDirection.values.byName(
        normalizedDirection ?? SortDirection.ascending.name,
      ),
    );
  }

  final SortField field;
  final SortDirection direction;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'field': field.name,
    'direction': direction.name,
  };

  SortCriterion copyWith({SortField? field, SortDirection? direction}) {
    return SortCriterion(
      field: field ?? this.field,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SortCriterion &&
        other.field == field &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(field, direction);
}

@immutable
class SortPreferences {
  const SortPreferences({
    this.criteria = const [
      SortCriterion(field: SortField.deadlineDate),
      SortCriterion(field: SortField.startDate),
      SortCriterion(field: SortField.createdDate),
      SortCriterion(field: SortField.name),
    ],
  });

  factory SortPreferences.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'] as List<dynamic>?;
    final parsed =
        rawCriteria
            ?.map((e) => SortCriterion.fromJson(e as Map<String, dynamic>))
            .toList(growable: false) ??
        const <SortCriterion>[];
    return SortPreferences(
      criteria: parsed.isEmpty
          ? const [
              SortCriterion(field: SortField.deadlineDate),
              SortCriterion(field: SortField.startDate),
              SortCriterion(field: SortField.createdDate),
              SortCriterion(field: SortField.name),
            ]
          : parsed,
    );
  }

  final List<SortCriterion> criteria;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'criteria': criteria.map((c) => c.toJson()).toList(growable: false),
  };

  SortPreferences copyWith({List<SortCriterion>? criteria}) {
    return SortPreferences(criteria: criteria ?? this.criteria);
  }

  List<SortCriterion> sanitizedCriteria(List<SortField> availableFields) {
    final sanitized = <SortCriterion>[];
    for (final criterion in criteria) {
      final field = criterion.field;
      if (!availableFields.contains(field)) continue;
      final already = sanitized.any((c) => c.field == field);
      if (already) continue;
      sanitized.add(criterion);
    }
    if (sanitized.isEmpty) {
      sanitized.add(
        SortCriterion(
          field: availableFields.isEmpty ? SortField.name : availableFields[0],
        ),
      );
    }
    return sanitized;
  }

  @override
  bool operator ==(Object other) {
    if (other is! SortPreferences) return false;
    if (identical(other, this)) return true;
    if (other.criteria.length != criteria.length) return false;
    for (var i = 0; i < criteria.length; i++) {
      if (criteria[i] != other.criteria[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(criteria);
}
