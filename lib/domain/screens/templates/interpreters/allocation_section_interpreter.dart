import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class AllocationSectionInterpreter
    implements SectionTemplateInterpreter<AllocationSectionParams> {
  AllocationSectionInterpreter({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.allocation;

  @override
  Stream<SectionDataResult> watch(AllocationSectionParams params) {
    return _sectionDataService.watchAllocation(params);
  }

  @override
  Future<SectionDataResult> fetch(AllocationSectionParams params) {
    return _sectionDataService.fetchAllocation(params);
  }
}
