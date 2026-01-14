import 'dart:async';

import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class IssuesSummarySectionInterpreter
    implements SectionTemplateInterpreter<IssuesSummarySectionParams> {
  IssuesSummarySectionInterpreter({
    required AttentionEngineContract attentionEngine,
  }) : _attentionEngine = attentionEngine;

  final AttentionEngineContract _attentionEngine;

  @override
  String get templateId => SectionTemplateId.issuesSummary;

  @override
  Stream<Object?> watch(IssuesSummarySectionParams params) {
    final query = _buildQuery(params);

    return _attentionEngine.watch(query).map((items) {
      final criticalCount = items
          .where((i) => i.severity == AttentionSeverity.critical)
          .length;
      final warningCount = items
          .where((i) => i.severity == AttentionSeverity.warning)
          .length;

      return SectionDataResult.issuesSummary(
        items: items,
        criticalCount: criticalCount,
        warningCount: warningCount,
      );
    });
  }

  @override
  Future<Object?> fetch(IssuesSummarySectionParams params) async {
    return watch(params).first;
  }

  AttentionQuery _buildQuery(IssuesSummarySectionParams params) {
    final entityTypes = params.entityTypes
        ?.map(_parseEntityType)
        .whereType<AttentionEntityType>()
        .toSet();

    return AttentionQuery(
      buckets: const {AttentionBucket.action},
      entityTypes: entityTypes,
      minSeverity: _parseSeverity(params.minSeverity),
    );
  }

  AttentionEntityType? _parseEntityType(String? value) {
    return switch (value) {
      'task' => AttentionEntityType.task,
      'project' => AttentionEntityType.project,
      'value' => AttentionEntityType.value,
      'journal' => AttentionEntityType.journal,
      'tracker' => AttentionEntityType.tracker,
      'review_session' => AttentionEntityType.reviewSession,
      _ => null,
    };
  }

  AttentionSeverity? _parseSeverity(String? value) {
    return switch (value) {
      'critical' => AttentionSeverity.critical,
      'warning' => AttentionSeverity.warning,
      'info' => AttentionSeverity.info,
      _ => null,
    };
  }
}
