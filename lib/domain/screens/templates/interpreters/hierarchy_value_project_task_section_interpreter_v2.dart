import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';

class HierarchyValueProjectTaskSectionInterpreterV2
    implements
        SectionTemplateInterpreter<HierarchyValueProjectTaskSectionParamsV2> {
  HierarchyValueProjectTaskSectionInterpreterV2({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.hierarchyValueProjectTaskV2;

  @override
  Stream<SectionDataResult> watch(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) {
    return _sectionDataService.watchHierarchyValueProjectTaskV2(params);
  }

  @override
  Future<SectionDataResult> fetch(
    HierarchyValueProjectTaskSectionParamsV2 params,
  ) {
    return _sectionDataService.fetchHierarchyValueProjectTaskV2(params);
  }
}
