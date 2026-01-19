import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_definition.freezed.dart';
part 'tracker_definition.g.dart';

@freezed
abstract class TrackerDefinition with _$TrackerDefinition {
  @JsonSerializable(explicitToJson: true)
  const factory TrackerDefinition({
    required String id,
    required String name,
    required String scope,
    required String valueType,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(<String>[]) List<String> roles,
    @Default(<String, dynamic>{}) Map<String, dynamic> config,
    @Default(<String, dynamic>{}) Map<String, dynamic> goal,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
    String? groupId,
    DateTime? deletedAt,
    @Default('user') String source,
    String? systemKey,
    @Default('set') String opKind,
    String? valueKind,
    String? unitKind,
    int? minInt,
    int? maxInt,
    int? stepInt,
    String? linkedValueId,
    @Default(false) bool isOutcome,
    @Default(false) bool isInsightEnabled,
    bool? higherIsBetter,
    String? description,
    String? userId,
  }) = _TrackerDefinition;

  factory TrackerDefinition.fromJson(Map<String, dynamic> json) =>
      _$TrackerDefinitionFromJson(json);
}
