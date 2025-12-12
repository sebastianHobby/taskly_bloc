import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/json_deserialisation_util.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
abstract class TaskModel with _$TaskModel {
  // Field to snake case means convert field name e.g. createdAt to snake case created_at for json key
  // explicitToJson is required to make freezed work with json serializable annotation to convert
  // int stored by powersync to bool for isCompleted field
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory TaskModel({
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
    DateTime? startedDate,
    DateTime? deadlineDate,
    String? description,
    String? projectId,
    String? repeatId,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, Object?> json) =>
      _$TaskModelFromJson(json);
}
