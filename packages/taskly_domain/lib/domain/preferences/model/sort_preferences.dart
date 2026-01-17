import 'package:freezed_annotation/freezed_annotation.dart';

part 'sort_preferences.freezed.dart';

/// Supported sort fields for task-, project-, and label-style entities.
enum SortField {
  name,
  startDate,
  deadlineDate,
  createdDate,
  updatedDate,
}

/// Sort direction per criterion.
enum SortDirection { ascending, descending }

/// A single sort criterion.
@freezed
abstract class SortCriterion with _$SortCriterion {
  const factory SortCriterion({
    required SortField field,
    @Default(SortDirection.ascending) SortDirection direction,
  }) = _SortCriterion;

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
}

/// Extension for JSON serialization.
extension SortCriterionJson on SortCriterion {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'field': field.name,
    'direction': direction.name,
  };
}

/// User's sort preferences with ordered criteria.
@freezed
abstract class SortPreferences with _$SortPreferences {
  const factory SortPreferences({
    @Default(SortPreferences.defaultCriteria) List<SortCriterion> criteria,
  }) = _SortPreferences;

  const SortPreferences._();

  factory SortPreferences.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'] as List<dynamic>?;
    final parsed =
        rawCriteria
            ?.map((e) => SortCriterion.fromJson(e as Map<String, dynamic>))
            .toList(growable: false) ??
        const <SortCriterion>[];
    return SortPreferences(
      criteria: parsed.isEmpty ? defaultCriteria : parsed,
    );
  }

  /// Default sort criteria.
  static const List<SortCriterion> defaultCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.startDate),
    SortCriterion(field: SortField.createdDate),
    SortCriterion(field: SortField.name),
  ];

  /// Returns criteria filtered to only include available fields,
  /// with duplicates removed. Guarantees at least one criterion.
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
}

/// Extension for JSON serialization.
extension SortPreferencesJson on SortPreferences {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'criteria': criteria.map((c) => c.toJson()).toList(growable: false),
  };
}
