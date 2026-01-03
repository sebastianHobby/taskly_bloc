import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

part 'related_data_config.freezed.dart';
part 'related_data_config.g.dart';

/// Configuration for fetching related entities within a section.
/// Related entities have a parent-child relationship with the primary entity.
@Freezed(unionKey: 'type')
sealed class RelatedDataConfig with _$RelatedDataConfig {
  /// Tasks related to primary entity (project, label, or value)
  @FreezedUnionValue('tasks')
  const factory RelatedDataConfig.tasks({
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,
  }) = RelatedTasksConfig;

  /// Projects related to primary entity (label or value)
  @FreezedUnionValue('projects')
  const factory RelatedDataConfig.projects({
    @NullableProjectQueryConverter() ProjectQuery? additionalFilter,
  }) = RelatedProjectsConfig;

  /// Special 3-level hierarchy for Values: Value → Project → Task
  /// Only valid when primary is ValueDataConfig
  @FreezedUnionValue('valueHierarchy')
  const factory RelatedDataConfig.valueHierarchy({
    @Default(true) bool includeInheritedTasks,
    @NullableProjectQueryConverter() ProjectQuery? projectFilter,
    @NullableTaskQueryConverter() TaskQuery? taskFilter,
  }) = ValueHierarchyConfig;

  factory RelatedDataConfig.fromJson(Map<String, dynamic> json) =>
      _$RelatedDataConfigFromJson(json);
}
