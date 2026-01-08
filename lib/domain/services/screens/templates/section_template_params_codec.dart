import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/agenda_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/interleaved_list_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/issues_summary_section_params.dart';

/// Encodes/decodes section template params without reflection.
class SectionTemplateParamsCodec {
  Object decode(String templateId, Map<String, dynamic> paramsJson) {
    return switch (templateId) {
      SectionTemplateId.taskList ||
      SectionTemplateId.projectList ||
      SectionTemplateId.valueList => DataListSectionParams.fromJson(paramsJson),
      SectionTemplateId.interleavedList =>
        InterleavedListSectionParams.fromJson(
          paramsJson,
        ),
      SectionTemplateId.allocation => AllocationSectionParams.fromJson(
        paramsJson,
      ),
      SectionTemplateId.agenda => AgendaSectionParams.fromJson(paramsJson),
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
      final DataListSectionParams p => p.toJson(),
      final InterleavedListSectionParams p => p.toJson(),
      final AllocationSectionParams p => p.toJson(),
      final AgendaSectionParams p => p.toJson(),
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
