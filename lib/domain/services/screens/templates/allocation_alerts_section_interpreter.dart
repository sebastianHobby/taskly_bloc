import 'dart:async';

import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

class AllocationAlertsSectionInterpreter
    implements SectionTemplateInterpreter<AllocationAlertsSectionParams> {
  AllocationAlertsSectionInterpreter({
    required AttentionEvaluator attentionEvaluator,
  }) : _attentionEvaluator = attentionEvaluator;

  final AttentionEvaluator _attentionEvaluator;

  @override
  String get templateId => SectionTemplateId.allocationAlerts;

  @override
  Stream<Object?> watch(AllocationAlertsSectionParams params) {
    return Stream.fromFuture(fetch(params));
  }

  @override
  Future<Object?> fetch(AllocationAlertsSectionParams params) async {
    final alerts = await _attentionEvaluator.evaluateAllocationAlerts();

    return SectionDataResult.allocationAlerts(
      alerts: alerts,
      totalExcluded: alerts.length,
    );
  }
}
