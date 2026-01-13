import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response_config.dart';

part 'tracker.freezed.dart';
part 'tracker.g.dart';

/// Flat tracker - no hierarchy.
@freezed
abstract class Tracker with _$Tracker {
  @JsonSerializable(explicitToJson: true)
  const factory Tracker({
    required String id,
    required String name,
    required TrackerResponseType responseType,
    required TrackerResponseConfig config,
    required TrackerEntryScope entryScope,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
    @Default(0) int sortOrder,
  }) = _Tracker;

  factory Tracker.fromJson(Map<String, dynamic> json) =>
      _$TrackerFromJson(json);
}

/// Only 3 response types (no Count).
enum TrackerResponseType {
  choice,
  scale,
  yesNo,
}

enum TrackerEntryScope {
  allDay,
  perEntry,
}
