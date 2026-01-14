import 'dart:async';

import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class CheckInSummarySectionInterpreter
    implements SectionTemplateInterpreter<CheckInSummarySectionParams> {
  CheckInSummarySectionInterpreter({
    required AttentionEngineContract attentionEngine,
  }) : _attentionEngine = attentionEngine;

  final AttentionEngineContract _attentionEngine;

  @override
  String get templateId => SectionTemplateId.checkInSummary;

  @override
  Stream<Object?> watch(CheckInSummarySectionParams params) {
    final query = AttentionQuery(
      buckets: {AttentionBucket.review},
      entityTypes: {AttentionEntityType.reviewSession},
    );

    return _attentionEngine.watch(query).map((dueReviews) {
      final hasOverdue = dueReviews.any((item) {
        final overdueDays = item.metadata?['overdue_days'];
        return overdueDays is int && overdueDays > 0;
      });

      return SectionDataResult.checkInSummary(
        dueReviews: dueReviews,
        hasOverdue: hasOverdue,
      );
    });
  }

  @override
  Future<Object?> fetch(CheckInSummarySectionParams params) async {
    return watch(params).first;
  }
}
