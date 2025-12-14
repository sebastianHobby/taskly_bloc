import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
part 'task_action_request.freezed.dart';

// Simple data class to define inputs for CRUD operations

@freezed
sealed class TaskActionRequest with _$TaskActionRequest {
  const factory TaskActionRequest.create({
    required String name,
    bool? completed,
    String? description,
  }) = TaskActionRequestCreate;
  const factory TaskActionRequest.update({
    required TaskDto taskToUpdate,
    required String? name,
    required bool? completed,
    required String? description,
  }) = TaskActionRequestUpdate;
  const factory TaskActionRequest.delete({
    required TaskDto taskToDelete,
  }) = TaskActionRequestDelete;
}
