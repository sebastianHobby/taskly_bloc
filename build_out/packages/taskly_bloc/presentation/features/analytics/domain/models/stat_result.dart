import 'package:freezed_annotation/freezed_annotation.dart';

part 'stat_result.freezed.dart';
part 'stat_result.g.dart';

/// Result of any statistical calculation
@freezed
abstract class StatResult with _$StatResult {
  const factory StatResult({
    required String label,
    required num value,
    String? formattedValue,
    String? description,
    StatSeverity? severity,
    TrendDirection? trend,
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

enum TrendDirection {
  up,
  down,
  stable,
}
