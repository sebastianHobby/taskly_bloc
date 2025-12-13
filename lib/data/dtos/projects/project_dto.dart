import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/json_deserialisation_util.dart';

part 'project_dto.freezed.dart';
part 'project_dto.g.dart';

@freezed
abstract class ProjectDto with _$ProjectDto {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ProjectDto({
    required String id,
    required String name,
    @JsonKey(
      name: 'completed',
      fromJson: fromJsonIntToBool,
      toJson: toJsonBooltoInt,
    )
    required bool completed,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
  }) = _ProjectDto;

  factory ProjectDto.fromJson(Map<String, Object?> json) =>
      _$ProjectDtoFromJson(json);
}
