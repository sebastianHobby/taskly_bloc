import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/json_deserialisation_util.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
abstract class ProjectModel with _$ProjectModel {
  // Field to snake case means convert field name e.g. createdAt to snake case created_at for json key
  // explicitToJson is required to make freezed work with json serializable annotation to convert
  // int stored by powersync to bool for isCompleted field
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ProjectModel({
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
    DateTime? deadlineDate,
    String? description,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, Object?> json) =>
      _$ProjectModelFromJson(json);
}
