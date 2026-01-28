import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:taskly_domain/src/analytics/model/task_stat_type.dart';
import 'package:taskly_domain/src/analytics/model/trend_data.dart';

part 'stat_result.freezed.dart';
part 'stat_result.g.dart';

/// Result of any statistical calculation
@freezed
abstract class StatResult with _$StatResult {
  const factory StatResult({
    required TaskStatType statType,
    required num value,
    StatSeverity? severity,
    TrendDirection? trend,
    @Default(<String, Object?>{}) Map<String, Object?> metadata,
  }) = _StatResult;

  factory StatResult.fromJson(Map<String, dynamic> json) =>
      _$StatResultFromJson(json);
}

enum StatSeverity {
  normal,
  warning,
  critical,
  positive,
}
