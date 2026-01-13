import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';

class AgendaSectionInterpreterV2
    implements SectionTemplateInterpreter<AgendaSectionParamsV2> {
  AgendaSectionInterpreterV2({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.agendaV2;

  @override
  Stream<SectionDataResult> watch(AgendaSectionParamsV2 params) {
    return _sectionDataService.watchAgendaV2(params);
  }

  @override
  Future<SectionDataResult> fetch(AgendaSectionParamsV2 params) {
    return _sectionDataService.fetchAgendaV2(params);
  }
}
