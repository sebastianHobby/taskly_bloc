import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_state_entry.freezed.dart';
part 'tracker_state_entry.g.dart';

@freezed
abstract class TrackerStateEntry with _$TrackerStateEntry {
  const factory TrackerStateEntry({
    required String id,
    required String entryId,
    required String trackerId,
    required DateTime updatedAt,
    Object? value,
    String? lastEventId,
    String? userId,
  }) = _TrackerStateEntry;

  factory TrackerStateEntry.fromJson(Map<String, dynamic> json) =>
      _$TrackerStateEntryFromJson(json);
}
