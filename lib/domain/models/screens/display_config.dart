import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';

part 'display_config.freezed.dart';
part 'display_config.g.dart';

/// Grouping options for entity display
enum GroupByField {
  @JsonValue('none')
  none,
  @JsonValue('project')
  project,
  @JsonValue('value')
  value,
  @JsonValue('label')
  label,
  @JsonValue('date')
  date,
  @JsonValue('priority')
  priority,
}

/// Sort field options
enum SortField {
  @JsonValue('name')
  name,
  @JsonValue('created_at')
  createdAt,
  @JsonValue('updated_at')
  updatedAt,
  @JsonValue('deadline_date')
  deadlineDate,
  @JsonValue('start_date')
  startDate,
  @JsonValue('priority')
  priority,
}

/// Sort direction
enum SortDirection {
  @JsonValue('asc')
  asc,
  @JsonValue('desc')
  desc,
}

/// Sort criterion
@freezed
abstract class SortCriterion with _$SortCriterion {
  const factory SortCriterion({
    required SortField field,
    @Default(SortDirection.asc) SortDirection direction,
  }) = _SortCriterion;

  factory SortCriterion.fromJson(Map<String, dynamic> json) =>
      _$SortCriterionFromJson(json);
}

/// Display configuration for screens
@freezed
abstract class DisplayConfig with _$DisplayConfig {
  const factory DisplayConfig({
    @Default(GroupByField.none) GroupByField groupBy,
    @Default([]) List<SortCriterion> sorting,
    @Default([]) List<ProblemType> problemsToDetect,
    @Default(true) bool showCompleted,
    @Default(false) bool showArchived,
  }) = _DisplayConfig;

  factory DisplayConfig.fromJson(Map<String, dynamic> json) =>
      _$DisplayConfigFromJson(json);
}
