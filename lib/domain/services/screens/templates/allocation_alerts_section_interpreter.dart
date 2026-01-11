import 'dart:async';

import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/allocation_alerts_section_params.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter.dart';

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
