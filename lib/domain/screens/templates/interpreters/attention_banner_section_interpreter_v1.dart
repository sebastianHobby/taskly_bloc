import 'dart:async';

import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v1.dart';

class AttentionBannerSectionInterpreterV1
    implements SectionTemplateInterpreter<AttentionBannerSectionParamsV1> {
  AttentionBannerSectionInterpreterV1({required AttentionEngineContract engine})
    : _engine = engine;

  final AttentionEngineContract _engine;

  @override
  String get templateId => SectionTemplateId.attentionBannerV1;

  @override
  Stream<Object?> watch(AttentionBannerSectionParamsV1 params) {
    final query = _buildQuery(params);

    return _engine.watch(query).map((items) {
      final actionCount = items
          .where((i) => i.bucket == AttentionBucket.action)
          .length;
      final reviewCount = items
          .where((i) => i.bucket == AttentionBucket.review)
          .length;

      final criticalCount = items
          .where((i) => i.severity == AttentionSeverity.critical)
          .length;
      final warningCount = items
          .where((i) => i.severity == AttentionSeverity.warning)
          .length;
      final infoCount = items.length - criticalCount - warningCount;

      return SectionDataResult.attentionBannerV1(
        actionCount: actionCount,
        reviewCount: reviewCount,
        criticalCount: criticalCount,
        warningCount: warningCount,
        infoCount: infoCount,
        previewItems: items.take(params.previewLimit).toList(growable: false),
        overflowScreenKey: params.overflowScreenKey,
      );
    });
  }

  @override
  Future<Object?> fetch(AttentionBannerSectionParamsV1 params) async {
    return watch(params).first;
  }

  AttentionQuery _buildQuery(AttentionBannerSectionParamsV1 params) {
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
