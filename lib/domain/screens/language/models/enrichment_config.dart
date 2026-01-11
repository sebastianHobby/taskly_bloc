import 'package:freezed_annotation/freezed_annotation.dart';

part 'enrichment_config.freezed.dart';
part 'enrichment_config.g.dart';

/// Configuration for enriching section data with computed statistics.
///
/// This is a generic extension point for the unified screen model (DR-017).
/// Each variant represents a different type of enrichment that can be
/// requested for a DataSection.
@Freezed(unionKey: 'type')
sealed class EnrichmentConfig with _$EnrichmentConfig {
  /// Request value statistics enrichment.
  ///
  /// Computes target/actual percentages, task/project counts,
  /// and weekly trends for each value in the section.
  @FreezedUnionValue('valueStats')
  const factory EnrichmentConfig.valueStats({
    /// Number of weeks to include in sparkline trend data.
    /// Range: 1-12, Default: 4
    @Default(4) int sparklineWeeks,

    /// Gap warning threshold percentage.
    /// Range: 5-50%, Default: 15%
    @Default(15) int gapWarningThreshold,
  }) = ValueStatsEnrichment;

  factory EnrichmentConfig.fromJson(Map<String, dynamic> json) =>
      _$EnrichmentConfigFromJson(json);
}
