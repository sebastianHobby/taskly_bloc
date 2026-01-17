import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/queries.dart';

part 'entity_selector.freezed.dart';
part 'entity_selector.g.dart';

/// Entity types for screens
enum EntityType {
  @JsonValue('task')
  task,
  @JsonValue('project')
  project,
  @JsonValue('value')
  value,
  @JsonValue('goal')
  goal,
  @JsonValue('journal')
  journal,
  @JsonValue('tracker')
  tracker,
}

/// Selects which entities to display in a screen
@freezed
abstract class EntitySelector with _$EntitySelector {
  const factory EntitySelector({
    required EntityType entityType,
    @TaskQueryFilterConverter() QueryFilter<TaskPredicate>? taskFilter,
    @ProjectQueryFilterConverter() QueryFilter<ProjectPredicate>? projectFilter,
    List<String>? specificIds, // Explicit list of entity IDs
  }) = _EntitySelector;

  factory EntitySelector.fromJson(Map<String, dynamic> json) =>
      _$EntitySelectorFromJson(json);
}

class TaskQueryFilterConverter
    implements
        JsonConverter<QueryFilter<TaskPredicate>?, Map<String, dynamic>?> {
  const TaskQueryFilterConverter();

  @override
  QueryFilter<TaskPredicate>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QueryFilter.fromJson<TaskPredicate>(json, TaskPredicate.fromJson);
  }

  @override
  Map<String, dynamic>? toJson(QueryFilter<TaskPredicate>? object) {
    return object?.toJson((p) => p.toJson());
  }
}

class ProjectQueryFilterConverter
    implements
        JsonConverter<QueryFilter<ProjectPredicate>?, Map<String, dynamic>?> {
  const ProjectQueryFilterConverter();

  @override
  QueryFilter<ProjectPredicate>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return QueryFilter.fromJson<ProjectPredicate>(
      json,
      ProjectPredicate.fromJson,
    );
  }

  @override
  Map<String, dynamic>? toJson(QueryFilter<ProjectPredicate>? object) {
    return object?.toJson((p) => p.toJson());
  }
}
