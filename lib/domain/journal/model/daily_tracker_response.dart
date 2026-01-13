import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response.dart';

part 'daily_tracker_response.freezed.dart';
part 'daily_tracker_response.g.dart';

@freezed
abstract class DailyTrackerResponse with _$DailyTrackerResponse {
  @JsonSerializable(explicitToJson: true)
  const factory DailyTrackerResponse({
    required String id,

    /// Date only (time component ignored for logic).
    required DateTime responseDate,
    required String trackerId,
    required TrackerResponseValue value,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DailyTrackerResponse;

  factory DailyTrackerResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyTrackerResponseFromJson(json);
}
