import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';

part 'enrichment_result.freezed.dart';
part 'enrichment_result.g.dart';

/// Result of computing enrichment data for a section.
///
/// Each variant contains computed statistics that correspond to
/// an EnrichmentConfig request type.
@Freezed(unionKey: 'type')
sealed class EnrichmentResult with _$EnrichmentResult {
  /// Value statistics enrichment result.
  ///
  /// Contains per-value statistics keyed by value ID.
  @FreezedUnionValue('valueStats')
  const factory EnrichmentResult.valueStats({
    /// Statistics for each value, keyed by value ID.
    required Map<String, ValueStats> statsByValueId,

    /// Total recent completions across all values (for percentage calc).
    @Default(0) int totalRecentCompletions,
  }) = ValueStatsEnrichmentResult;

  factory EnrichmentResult.fromJson(Map<String, dynamic> json) =>
      _$EnrichmentResultFromJson(json);
}
