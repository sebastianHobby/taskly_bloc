import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_group.freezed.dart';
part 'tracker_group.g.dart';

@freezed
abstract class TrackerGroup with _$TrackerGroup {
  const factory TrackerGroup({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    String? userId,
  }) = _TrackerGroup;

  factory TrackerGroup.fromJson(Map<String, dynamic> json) =>
      _$TrackerGroupFromJson(json);
}
