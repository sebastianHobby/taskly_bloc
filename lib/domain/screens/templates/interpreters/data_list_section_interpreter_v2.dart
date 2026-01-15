import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

class DataListSectionInterpreterV2
    implements SectionTemplateInterpreter<ListSectionParamsV2> {
  DataListSectionInterpreterV2({
    required this.templateId,
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  @override
  final String templateId;

  final SectionDataService _sectionDataService;

  @override
  Stream<SectionDataResult> watch(ListSectionParamsV2 params) {
    _validate(templateId, params);
    return _sectionDataService.watchDataListV2(params);
  }

  @override
  Future<SectionDataResult> fetch(ListSectionParamsV2 params) {
    _validate(templateId, params);
    return _sectionDataService.fetchDataListV2(params);
  }

  static void _validate(String templateId, ListSectionParamsV2 params) {
    final config = params.config;
    if (templateId == SectionTemplateId.taskListV2 &&
        config is! TaskDataConfig) {
      throw ArgumentError('task_list_v2 requires DataConfig.task');
    }
    if (templateId == SectionTemplateId.valueListV2 &&
        config is! ValueDataConfig) {
      throw ArgumentError('value_list_v2 requires DataConfig.value');
    }
  }
}
