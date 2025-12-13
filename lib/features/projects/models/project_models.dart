// Required to avoid auto 'fix' breaking the parameters

import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_models.freezed.dart';

@freezed
sealed class ProjectModel with _$ProjectModel {
  const factory ProjectModel.create({
    required String name,
    bool? completed,
    String? description,
  }) = ProjectCreateRequest;
  const factory ProjectModel.update({
    required String id,
    required String name,
    required bool completed,
    required String? description,
  }) = ProjectUpdateRequest;
  const factory ProjectModel.delete({required String id}) =
      ProjectDeleteRequest;
}
