import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/queries.dart';

part 'badge_config.freezed.dart';
part 'badge_config.g.dart';

/// Badge configuration for navigation display.
///
/// Determines whether and how a screen shows a count badge in navigation.
/// This replaces the implicit category-based badge logic with explicit
/// configuration.
@Freezed(unionKey: 'type')
sealed class BadgeConfig with _$BadgeConfig {
  /// Show count from the first data section's query.
  ///
  /// This is the default for module-based screens using list/agenda modules.
  /// The badge service will automatically extract the query from the first
  /// compatible module and watch for count changes.
  @FreezedUnionValue('fromFirstSection')
  const factory BadgeConfig.fromFirstSection() = BadgeFromFirstSection;

  /// Show count from a custom query.
  ///
  /// Allows specifying a specific query for badge counting,
  /// independent of the screen's sections.
  @FreezedUnionValue('custom')
  const factory BadgeConfig.custom({
    /// Task query for badge counting (mutually exclusive with projectQuery)
    @_NullableTaskQueryConverter() TaskQuery? taskQuery,

    /// Project query for badge counting (mutually exclusive with taskQuery)
    @_NullableProjectQueryConverter() ProjectQuery? projectQuery,
  }) = CustomBadgeConfig;

  /// No badge shown.
  ///
  /// This is the default for navigation-only screens (settings, etc.)
  @FreezedUnionValue('none')
  const factory BadgeConfig.none() = NoBadge;

  factory BadgeConfig.fromJson(Map<String, dynamic> json) =>
      _$BadgeConfigFromJson(json);
}

/// JSON converter for nullable TaskQuery within BadgeConfig.
class _NullableTaskQueryConverter
    implements JsonConverter<TaskQuery?, Map<String, dynamic>?> {
  const _NullableTaskQueryConverter();

  @override
  TaskQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : TaskQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TaskQuery? object) => object?.toJson();
}

/// JSON converter for nullable ProjectQuery within BadgeConfig.
class _NullableProjectQueryConverter
    implements JsonConverter<ProjectQuery?, Map<String, dynamic>?> {
  const _NullableProjectQueryConverter();

  @override
  ProjectQuery? fromJson(Map<String, dynamic>? json) =>
      json == null ? null : ProjectQuery.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ProjectQuery? object) => object?.toJson();
}
