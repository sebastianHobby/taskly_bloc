import 'dart:async';

import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

class CheckInSummarySectionInterpreter
    implements SectionTemplateInterpreter<CheckInSummarySectionParams> {
  CheckInSummarySectionInterpreter({
    required AttentionEvaluator attentionEvaluator,
  }) : _attentionEvaluator = attentionEvaluator;

  final AttentionEvaluator _attentionEvaluator;

  @override
  String get templateId => SectionTemplateId.checkInSummary;

  @override
  Stream<Object?> watch(CheckInSummarySectionParams params) {
    return Stream.fromFuture(fetch(params));
  }

  @override
  Future<Object?> fetch(CheckInSummarySectionParams params) async {
    final dueReviews = await _attentionEvaluator.evaluateReviews();

    final hasOverdue = dueReviews.any((item) {
      final overdueDays = item.metadata?['overdue_days'];
      return overdueDays is int && overdueDays > 0;
    });

    return SectionDataResult.checkInSummary(
      dueReviews: dueReviews,
      hasOverdue: hasOverdue,
    );
  }
}
