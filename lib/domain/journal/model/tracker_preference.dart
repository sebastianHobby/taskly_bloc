import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_preference.freezed.dart';
part 'tracker_preference.g.dart';

@freezed
abstract class TrackerPreference with _$TrackerPreference {
  const factory TrackerPreference({
    required String id,
    required String trackerId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    @Default(false) bool pinned,
    @Default(false) bool showInQuickAdd,
    String? color,
    String? userId,
  }) = _TrackerPreference;

  factory TrackerPreference.fromJson(Map<String, dynamic> json) =>
      _$TrackerPreferenceFromJson(json);
}
