// Required to avoid auto 'fix' breaking the parameters

import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_models.freezed.dart';

@freezed
sealed class TaskModel with _$TaskModel {
  const factory TaskModel.create({
    required String name,
    bool? completed,
    String? description,
  }) = TaskCreateRequest;
  const factory TaskModel.update({
    required String id,
    required String name,
    required bool completed,
    required String? description,
  }) = TaskUpdateRequest;
  const factory TaskModel.delete({required String id}) =
      TaskDeleteRequest;
}
