import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';

part 'content_config.freezed.dart';
part 'content_config.g.dart';

/// Persisted content configuration for module-based screens.
///
/// Combines sections and support blocks into a single JSON blob
/// for efficient PowerSync sync. This structure is stored in the
/// `content_config` column.
@freezed
abstract class ContentConfig with _$ContentConfig {
  const factory ContentConfig({
    /// Sections that make up the screen content.
    @Default([]) List<SectionRef> sections,
  }) = _ContentConfig;
  const ContentConfig._();

  factory ContentConfig.fromJson(Map<String, dynamic> json) =>
      _$ContentConfigFromJson(json);

  /// Empty content config for navigation-only screens.
  static const empty = ContentConfig();
}
