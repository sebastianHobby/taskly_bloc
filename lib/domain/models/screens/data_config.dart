import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';

part 'data_config.freezed.dart';
part 'data_config.g.dart';

/// Configuration for fetching a single entity type.
/// Each variant embeds its query directly (DR-002).
@Freezed(unionKey: 'type')
sealed class DataConfig with _$DataConfig {
  /// Task data configuration
  @FreezedUnionValue('task')
  const factory DataConfig.task({
    @TaskQueryConverter() required TaskQuery query,
  }) = TaskDataConfig;

  /// Project data configuration
  @FreezedUnionValue('project')
  const factory DataConfig.project({
    @ProjectQueryConverter() required ProjectQuery query,
  }) = ProjectDataConfig;

  /// Label data configuration (excludes values by default)
  @FreezedUnionValue('label')
  const factory DataConfig.label({
    @LabelQueryConverter() LabelQuery? query,
  }) = LabelDataConfig;

  /// Value data configuration (DR-003: values are labels with type=value)
  @FreezedUnionValue('value')
  const factory DataConfig.value({
    @LabelQueryConverter() LabelQuery? query,
  }) = ValueDataConfig;

  factory DataConfig.fromJson(Map<String, dynamic> json) =>
      _$DataConfigFromJson(json);
}

/// JSON converter for TaskQuery
class TaskQueryConverter
    implements JsonConverter<TaskQuery, Map<String, dynamic>> {
  const TaskQueryConverter();

  @override
  TaskQuery fromJson(Map<String, dynamic> json) => TaskQuery.fromJson(json);

  @override
  Map<String, dynamic> toJson(TaskQuery object) => object.toJson();
}

/// JSON converter for nullable TaskQuery
class NullableTaskQueryConverter
    implements JsonConverter<TaskQuery?, Map<String, dynamic>?> {
  const NullableTaskQueryConverter();

  @override
  TaskQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : TaskQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TaskQuery? object) => object?.toJson();
}

/// JSON converter for ProjectQuery
class ProjectQueryConverter
    implements JsonConverter<ProjectQuery, Map<String, dynamic>> {
  const ProjectQueryConverter();

  @override
  ProjectQuery fromJson(Map<String, dynamic> json) =>
      ProjectQuery.fromJson(json);

  @override
  Map<String, dynamic> toJson(ProjectQuery object) => object.toJson();
}

/// JSON converter for nullable ProjectQuery
class NullableProjectQueryConverter
    implements JsonConverter<ProjectQuery?, Map<String, dynamic>?> {
  const NullableProjectQueryConverter();

  @override
  ProjectQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : ProjectQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ProjectQuery? object) => object?.toJson();
}

/// JSON converter for LabelQuery (nullable)
class LabelQueryConverter
    implements JsonConverter<LabelQuery?, Map<String, dynamic>?> {
  const LabelQueryConverter();

  @override
  LabelQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : LabelQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(LabelQuery? object) => object?.toJson();
}
