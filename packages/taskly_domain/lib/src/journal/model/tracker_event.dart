import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_event.freezed.dart';
part 'tracker_event.g.dart';

@freezed
abstract class TrackerEvent with _$TrackerEvent {
  const factory TrackerEvent({
    required String id,
    required String trackerId,
    required String anchorType,
    required String op,
    required DateTime occurredAt,
    required DateTime recordedAt,
    String? entryId,
    DateTime? anchorDate,
    Object? value,
    String? userId,
  }) = _TrackerEvent;

  factory TrackerEvent.fromJson(Map<String, dynamic> json) =>
      _$TrackerEventFromJson(json);
}
