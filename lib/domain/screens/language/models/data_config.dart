import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';

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

  /// Value data configuration
  @FreezedUnionValue('value')
  const factory DataConfig.value({
    @ValueQueryConverter() ValueQuery? query,
  }) = ValueDataConfig;

  /// Journal entry data configuration
  @FreezedUnionValue('journal')
  const factory DataConfig.journal({
    @JournalQueryConverter() JournalQuery? query,
  }) = JournalDataConfig;

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

/// JSON converter for ValueQuery (nullable)
class ValueQueryConverter
    implements JsonConverter<ValueQuery?, Map<String, dynamic>?> {
  const ValueQueryConverter();

  @override
  ValueQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : ValueQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ValueQuery? object) => object?.toJson();
}

/// JSON converter for JournalQuery (nullable)
class JournalQueryConverter
    implements JsonConverter<JournalQuery?, Map<String, dynamic>?> {
  const JournalQueryConverter();

  @override
  JournalQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : JournalQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(JournalQuery? object) => object?.toJson();
}
