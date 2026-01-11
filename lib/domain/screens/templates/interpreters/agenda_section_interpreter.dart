import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class AgendaSectionInterpreter
    implements SectionTemplateInterpreter<AgendaSectionParams> {
  AgendaSectionInterpreter({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.agenda;

  @override
  Stream<SectionDataResult> watch(AgendaSectionParams params) {
    return _sectionDataService.watchAgenda(params);
  }

  @override
  Future<SectionDataResult> fetch(AgendaSectionParams params) {
    return _sectionDataService.fetchAgenda(params);
  }
}
