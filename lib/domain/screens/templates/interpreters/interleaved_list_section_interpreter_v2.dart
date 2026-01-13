import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';

class InterleavedListSectionInterpreterV2
    implements SectionTemplateInterpreter<InterleavedListSectionParamsV2> {
  InterleavedListSectionInterpreterV2({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.interleavedListV2;

  @override
  Stream<SectionDataResult> watch(InterleavedListSectionParamsV2 params) {
    return _sectionDataService.watchInterleavedListV2(params);
  }

  @override
  Future<SectionDataResult> fetch(InterleavedListSectionParamsV2 params) {
    return _sectionDataService.fetchInterleavedListV2(params);
  }
}
