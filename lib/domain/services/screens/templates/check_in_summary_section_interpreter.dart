import 'dart:async';

import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/check_in_summary_section_params.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_temporal_invalidation_service.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

class CheckInSummarySectionInterpreter
    implements SectionTemplateInterpreter<CheckInSummarySectionParams> {
  CheckInSummarySectionInterpreter({
    required AttentionEvaluator attentionEvaluator,
    required AttentionTemporalInvalidationService
    attentionTemporalInvalidationService,
  }) : _attentionEvaluator = attentionEvaluator,
       _attentionTemporalInvalidationService =
           attentionTemporalInvalidationService;

  final AttentionEvaluator _attentionEvaluator;
  final AttentionTemporalInvalidationService
  _attentionTemporalInvalidationService;

  @override
  String get templateId => SectionTemplateId.checkInSummary;

  @override
  Stream<Object?> watch(CheckInSummarySectionParams params) {
    return _watchWithTemporalInvalidation(params);
  }

  Stream<Object?> _watchWithTemporalInvalidation(
    CheckInSummarySectionParams params,
  ) async* {
    yield await fetch(params);

    await for (final _ in _attentionTemporalInvalidationService.invalidations) {
      yield await fetch(params);
    }
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
