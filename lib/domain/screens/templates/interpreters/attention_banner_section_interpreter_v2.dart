import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_domain/domain/attention/model/attention_resolution.dart';
import 'package:taskly_domain/domain/attention/model/attention_rule.dart';
import 'package:taskly_domain/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_domain/domain/services/progress/today_progress_service.dart';

class AttentionBannerSectionInterpreterV2
    implements SectionTemplateInterpreter<AttentionBannerSectionParamsV2> {
  AttentionBannerSectionInterpreterV2({
    required AttentionEngineContract engine,
    required TodayProgressService todayProgressService,
  }) : _engine = engine,
       _todayProgressService = todayProgressService;

  final AttentionEngineContract _engine;
  final TodayProgressService _todayProgressService;

  @override
  String get templateId => SectionTemplateId.attentionBannerV2;

  @override
  Stream<Object?> watch(AttentionBannerSectionParamsV2 params) {
    final query = _buildQuery(params);

    return Rx.combineLatest2(
      _engine.watch(query),
      _todayProgressService.watchTodayProgress(),
      (items, progress) {
        final reviewCount = items
            .where((i) => i.bucket == AttentionBucket.review)
            .length;

        final criticalCount = items
            .where((i) => i.severity == AttentionSeverity.critical)
            .length;
        final warningCount = items
            .where((i) => i.severity == AttentionSeverity.warning)
            .length;

        final alertsCount = items
            .where(
              (i) =>
                  i.bucket == AttentionBucket.action &&
                  i.severity != AttentionSeverity.info,
            )
            .length;

        return SectionDataResult.attentionBannerV2(
          reviewCount: reviewCount,
          alertsCount: alertsCount,
          criticalCount: criticalCount,
          warningCount: warningCount,
          overflowScreenKey: params.overflowScreenKey,
          doneCount: progress.doneCount,
          totalCount: progress.totalCount,
        );
      },
    );
  }

  @override
  Future<Object?> fetch(AttentionBannerSectionParamsV2 params) async {
    return watch(params).first;
  }

  AttentionQuery _buildQuery(AttentionBannerSectionParamsV2 params) {
    final entityTypes = params.entityTypes
        ?.map(_parseEntityType)
        .whereType<AttentionEntityType>()
        .toSet();

    final buckets = params.buckets
        ?.map(_parseBucket)
        .whereType<AttentionBucket>()
        .toSet();

    return AttentionQuery(
      buckets: (buckets == null || buckets.isEmpty) ? null : buckets,
      entityTypes: (entityTypes == null || entityTypes.isEmpty)
          ? null
          : entityTypes,
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

  AttentionBucket? _parseBucket(String? value) {
    return switch (value) {
      'action' => AttentionBucket.action,
      'review' => AttentionBucket.review,
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
