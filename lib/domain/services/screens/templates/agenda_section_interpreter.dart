import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/agenda_section_params.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

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
