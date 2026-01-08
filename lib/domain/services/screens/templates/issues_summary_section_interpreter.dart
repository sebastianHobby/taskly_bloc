import 'dart:async';

import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

class IssuesSummarySectionInterpreter
    implements SectionTemplateInterpreter<IssuesSummarySectionParams> {
  IssuesSummarySectionInterpreter({
    required AttentionEvaluator attentionEvaluator,
  }) : _attentionEvaluator = attentionEvaluator;

  final AttentionEvaluator _attentionEvaluator;

  @override
  String get templateId => SectionTemplateId.issuesSummary;

  @override
  Stream<Object?> watch(IssuesSummarySectionParams params) {
    return Stream.fromFuture(fetch(params));
  }

  @override
  Future<Object?> fetch(IssuesSummarySectionParams params) async {
    final entityTypes = params.entityTypes
        ?.map(_parseEntityType)
        .whereType<AttentionEntityType>()
        .toList();

    final minSeverity = _parseSeverity(params.minSeverity);

    final items = await _attentionEvaluator.evaluateIssues(
      entityTypes: entityTypes,
      minSeverity: minSeverity,
    );

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
