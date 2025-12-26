import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_response.freezed.dart';
part 'tracker_response.g.dart';

@freezed
abstract class TrackerResponse with _$TrackerResponse {
  const factory TrackerResponse({
    required String id,
    required String journalEntryId,
    required String trackerId,
    required TrackerResponseValue value,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TrackerResponse;

  factory TrackerResponse.fromJson(Map<String, dynamic> json) =>
      _$TrackerResponseFromJson(json);
}

@freezed
abstract class TrackerResponseValue with _$TrackerResponseValue {
  const factory TrackerResponseValue.choice({
    required String selected,
  }) = ChoiceValue;

  const factory TrackerResponseValue.scale({
    required int value,
  }) = ScaleValue;

  const factory TrackerResponseValue.yesNo({
    required bool value,
  }) = YesNoValue;

  factory TrackerResponseValue.fromJson(Map<String, dynamic> json) =>
      _$TrackerResponseValueFromJson(json);
}
