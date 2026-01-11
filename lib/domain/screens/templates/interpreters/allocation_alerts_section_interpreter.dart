import 'dart:async';

import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class AllocationAlertsSectionInterpreter
    implements SectionTemplateInterpreter<AllocationAlertsSectionParams> {
  AllocationAlertsSectionInterpreter({
    required AttentionEngineContract attentionEngine,
  }) : _attentionEngine = attentionEngine;

  final AttentionEngineContract _attentionEngine;

  @override
  String get templateId => SectionTemplateId.allocationAlerts;

  @override
  Stream<Object?> watch(AllocationAlertsSectionParams params) {
    const query = AttentionQuery(domains: {'allocation'});

    return _attentionEngine.watch(query).map((alerts) {
      return SectionDataResult.allocationAlerts(
        alerts: alerts,
        totalExcluded: alerts.length,
      );
    });
  }

  @override
  Future<Object?> fetch(AllocationAlertsSectionParams params) async {
    return watch(params).first;
  }
}
