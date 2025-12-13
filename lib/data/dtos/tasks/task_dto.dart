import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/json_deserialisation_util.dart';

part 'task_dto.freezed.dart';
part 'task_dto.g.dart';

@freezed
abstract class TaskDto with _$TaskDto {
  // Field to snake case means convert field name e.g. createdAt to snake case created_at for json key
  // explicitToJson is required to make freezed work with json serializable annotation to convert
  // int stored by powersync to bool for isCompleted field
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory TaskDto({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false)
    @JsonKey(
      name: 'completed',
      fromJson: fromJsonIntToBool,
      toJson: toJsonBooltoInt,
    )
    bool completed,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? description,
    String? projectId,
    String? repeatId,
  }) = _TaskDto;

  factory TaskDto.fromJson(Map<String, Object?> json) =>
      _$TaskDtoFromJson(json);
}
