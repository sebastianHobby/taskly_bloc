import 'dart:async';

import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:rxdart/rxdart.dart';

class EntityHeaderSectionInterpreter
    implements SectionTemplateInterpreter<EntityHeaderSectionParams> {
  EntityHeaderSectionInterpreter({
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required TaskRepositoryContract taskRepository,
  }) : _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _taskRepository = taskRepository;

  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final TaskRepositoryContract _taskRepository;

  @override
  String get templateId => SectionTemplateId.entityHeader;

  @override
  Stream<Object?> watch(EntityHeaderSectionParams params) {
    return switch (params.entityType) {
      'project' => _projectRepository.watchById(params.entityId).map((project) {
        if (project == null) {
          return SectionDataResult.entityHeaderMissing(
            entityType: params.entityType,
            entityId: params.entityId,
          );
        }

        return SectionDataResult.entityHeaderProject(
          project: project,
          showCheckbox: params.showCheckbox,
          showMetadata: params.showMetadata,
        );
      }),
      'value' => _watchValue(params),
      _ => Stream.value(
        SectionDataResult.entityHeaderMissing(
          entityType: params.entityType,
          entityId: params.entityId,
        ),
      ),
    };
  }

  Stream<SectionDataResult> _watchValue(
    EntityHeaderSectionParams params,
  ) {
    return _valueRepository.watchById(params.entityId).switchMap((value) {
      if (value == null) {
        return Stream.value(
          SectionDataResult.entityHeaderMissing(
            entityType: params.entityType,
            entityId: params.entityId,
          ),
        );
      }

      return _taskRepository
          .watchAllCount(TaskQuery.forValue(valueId: value.id))
          .map(
            (taskCount) => SectionDataResult.entityHeaderValue(
              value: value,
              taskCount: taskCount,
              showMetadata: params.showMetadata,
            ),
          );
    });
  }

  @override
  Future<Object?> fetch(EntityHeaderSectionParams params) async {
    return switch (params.entityType) {
      'project' => _fetchProject(params),
      'value' => _fetchValue(params),
      _ => SectionDataResult.entityHeaderMissing(
        entityType: params.entityType,
        entityId: params.entityId,
      ),
    };
  }

  Future<SectionDataResult> _fetchProject(
    EntityHeaderSectionParams params,
  ) async {
    final project = await _projectRepository.getById(params.entityId);
    if (project == null) {
      return SectionDataResult.entityHeaderMissing(
        entityType: params.entityType,
        entityId: params.entityId,
      );
    }

    return SectionDataResult.entityHeaderProject(
      project: project,
      showCheckbox: params.showCheckbox,
      showMetadata: params.showMetadata,
    );
  }

  Future<SectionDataResult> _fetchValue(
    EntityHeaderSectionParams params,
  ) async {
    final value = await _valueRepository.getById(params.entityId);
    if (value == null) {
      return SectionDataResult.entityHeaderMissing(
        entityType: params.entityType,
        entityId: params.entityId,
      );
    }

    final taskCount = await _taskRepository
        .watchAllCount(TaskQuery.forValue(valueId: value.id))
        .first;

    return SectionDataResult.entityHeaderValue(
      value: value,
      taskCount: taskCount,
      showMetadata: params.showMetadata,
    );
  }
}
