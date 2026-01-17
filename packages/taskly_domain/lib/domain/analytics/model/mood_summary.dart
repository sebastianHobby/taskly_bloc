import 'package:freezed_annotation/freezed_annotation.dart';

part 'mood_summary.freezed.dart';
part 'mood_summary.g.dart';

@freezed
abstract class MoodSummary with _$MoodSummary {
  const factory MoodSummary({
    required double average,
    required int totalEntries,
    required int min,
    required int max,
    required Map<int, int> distribution, // rating -> count
  }) = _MoodSummary;

  factory MoodSummary.fromJson(Map<String, dynamic> json) =>
      _$MoodSummaryFromJson(json);
}
