import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracker_definition_choice.freezed.dart';
part 'tracker_definition_choice.g.dart';

@freezed
abstract class TrackerDefinitionChoice with _$TrackerDefinitionChoice {
  const factory TrackerDefinitionChoice({
    required String id,
    required String trackerId,
    required String choiceKey,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    String? userId,
  }) = _TrackerDefinitionChoice;

  factory TrackerDefinitionChoice.fromJson(Map<String, dynamic> json) =>
      _$TrackerDefinitionChoiceFromJson(json);
}
