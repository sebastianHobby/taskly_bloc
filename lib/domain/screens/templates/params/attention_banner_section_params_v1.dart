import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'attention_banner_section_params_v1.freezed.dart';
part 'attention_banner_section_params_v1.g.dart';

/// Params for the unified attention banner.
///
/// This is a compact, bucket-aware replacement for legacy attention summary
/// sections (issues, allocation alerts, check-in summary).
@freezed
abstract class AttentionBannerSectionParamsV1
    with _$AttentionBannerSectionParamsV1 {
  const factory AttentionBannerSectionParamsV1({
    required StylePackV2 pack,

    /// Restrict to these buckets (e.g. ['action', 'review']).
    ///
    /// When null or empty, includes all buckets.
    List<String>? buckets,

    /// Restrict to these entity types (e.g. ['task', 'project']).
    ///
    /// When null or empty, includes all supported types.
    List<String>? entityTypes,

    /// Minimum severity to include (e.g. 'critical', 'warning', 'info').
    ///
    /// When null, includes all severities.
    String? minSeverity,

    /// Maximum number of items to show as preview under the counts.
    @Default(2) int previewLimit,

    /// Destination screen key for overflow.
    @Default('review_inbox') String overflowScreenKey,
  }) = _AttentionBannerSectionParamsV1;

  factory AttentionBannerSectionParamsV1.fromJson(Map<String, dynamic> json) =>
      _$AttentionBannerSectionParamsV1FromJson(json);
}
