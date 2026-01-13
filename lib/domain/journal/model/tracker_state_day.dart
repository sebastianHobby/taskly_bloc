import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_state_day.freezed.dart';
part 'tracker_state_day.g.dart';

@freezed
abstract class TrackerStateDay with _$TrackerStateDay {
  const factory TrackerStateDay({
    required String id,
    required String anchorType,
    required DateTime anchorDate,
    required String trackerId,
    required DateTime updatedAt,
    Object? value,
    String? lastEventId,
    String? userId,
  }) = _TrackerStateDay;

  factory TrackerStateDay.fromJson(Map<String, dynamic> json) =>
      _$TrackerStateDayFromJson(json);
}
