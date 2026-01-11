import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class DataListSectionInterpreter
    implements SectionTemplateInterpreter<DataListSectionParams> {
  DataListSectionInterpreter({
    required this.templateId,
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  @override
  final String templateId;

  final SectionDataService _sectionDataService;

  @override
  Stream<SectionDataResult> watch(DataListSectionParams params) {
    _validate(templateId, params);
    return _sectionDataService.watchDataList(params);
  }

  @override
  Future<SectionDataResult> fetch(DataListSectionParams params) {
    _validate(templateId, params);
    return _sectionDataService.fetchDataList(params);
  }

  static void _validate(String templateId, DataListSectionParams params) {
    final config = params.config;
    if (templateId == SectionTemplateId.taskList && config is! TaskDataConfig) {
      throw ArgumentError('task_list requires DataConfig.task');
    }
    if (templateId == SectionTemplateId.projectList &&
        config is! ProjectDataConfig) {
      throw ArgumentError('project_list requires DataConfig.project');
    }
    if (templateId == SectionTemplateId.valueList &&
        config is! ValueDataConfig) {
      throw ArgumentError('value_list requires DataConfig.value');
    }
  }
}
