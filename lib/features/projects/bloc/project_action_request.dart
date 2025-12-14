import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
part 'project_action_request.freezed.dart';

// Models used
@freezed
sealed class ProjectActionRequest with _$ProjectActionRequest {
  const factory ProjectActionRequest.create({
    required String name,
    bool? completed,
    String? description,
  }) = ProjectActionRequestCreate;
  const factory ProjectActionRequest.update({
    required ProjectDto projectToUpdate,
    required String? name,
    required bool? completed,
    required String? description,
  }) = ProjectActionRequestUpdate;
  const factory ProjectActionRequest.delete({
    required ProjectDto projectToDelete,
  }) = ProjectActionRequestDelete;
}
