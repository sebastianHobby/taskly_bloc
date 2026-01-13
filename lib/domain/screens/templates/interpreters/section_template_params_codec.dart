import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

/// Encodes/decodes section template params without reflection.
class SectionTemplateParamsCodec {
  Object decode(String templateId, Map<String, dynamic> paramsJson) {
    return switch (templateId) {
      SectionTemplateId.taskListV2 ||
      SectionTemplateId.projectListV2 ||
      SectionTemplateId.valueListV2 => ListSectionParamsV2.fromJson(paramsJson),
      SectionTemplateId.interleavedListV2 =>
        InterleavedListSectionParamsV2.fromJson(paramsJson),
      SectionTemplateId.allocation => AllocationSectionParams.fromJson(
        paramsJson,
      ),
      SectionTemplateId.agendaV2 => AgendaSectionParamsV2.fromJson(paramsJson),
      SectionTemplateId.issuesSummary => IssuesSummarySectionParams.fromJson(
        paramsJson,
      ),
      SectionTemplateId.allocationAlerts =>
        AllocationAlertsSectionParams.fromJson(
          paramsJson,
        ),
      SectionTemplateId.checkInSummary => CheckInSummarySectionParams.fromJson(
        paramsJson,
      ),
      SectionTemplateId.entityHeader => EntityHeaderSectionParams.fromJson(
        paramsJson,
      ),
      // templates without params
      _ => const EmptySectionParams(),
    };
  }

  Map<String, dynamic> encode(String templateId, Object params) {
    return switch (params) {
      final ListSectionParamsV2 p => p.toJson(),
      final InterleavedListSectionParamsV2 p => p.toJson(),
      final AllocationSectionParams p => p.toJson(),
      final AgendaSectionParamsV2 p => p.toJson(),
      final IssuesSummarySectionParams p => p.toJson(),
      final AllocationAlertsSectionParams p => p.toJson(),
      final CheckInSummarySectionParams p => p.toJson(),
      final EntityHeaderSectionParams p => p.toJson(),
      const EmptySectionParams() => <String, dynamic>{},
      _ => throw ArgumentError(
        'Unsupported params type for $templateId: ${params.runtimeType}',
      ),
    };
  }
}

class EmptySectionParams {
  const EmptySectionParams();
}
