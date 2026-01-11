import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';

part 'correlation_request.freezed.dart';
part 'correlation_request.g.dart';

/// Correlation request types
@freezed
abstract class CorrelationRequest with _$CorrelationRequest {
  /// Mood vs Tracker (e.g., "Sleep quality vs Mood")
  const factory CorrelationRequest.moodVsTracker({
    required String trackerId,
    required DateRange range,
  }) = MoodVsTrackerCorrelation;

  /// Mood vs Entity activity (e.g., "Health tasks vs Mood")
  const factory CorrelationRequest.moodVsEntity({
    required String entityId,
    required EntityType entityType,
    required DateRange range,
  }) = MoodVsEntityCorrelation;

  /// Tracker vs Tracker (e.g., "Sleep vs Energy")
  const factory CorrelationRequest.trackerVsTracker({
    required String trackerId1,
    required String trackerId2,
    required DateRange range,
  }) = TrackerVsTrackerCorrelation;

  factory CorrelationRequest.fromJson(Map<String, dynamic> json) =>
      _$CorrelationRequestFromJson(json);
}
