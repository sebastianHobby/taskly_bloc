import 'package:freezed_annotation/freezed_annotation.dart';

part 'attention_banner_section_params_v2.freezed.dart';
part 'attention_banner_section_params_v2.g.dart';

/// Params for the unified attention banner (v2).
@freezed
abstract class AttentionBannerSectionParamsV2
    with _$AttentionBannerSectionParamsV2 {
  const factory AttentionBannerSectionParamsV2({
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

    /// Destination screen key for overflow.
    @Default('review_inbox') String overflowScreenKey,
  }) = _AttentionBannerSectionParamsV2;

  factory AttentionBannerSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$AttentionBannerSectionParamsV2FromJson(json);
}
