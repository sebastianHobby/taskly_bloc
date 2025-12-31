import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepositoryContract {
  AnalyticsRepositoryImpl(this._database);
  final AppDatabase _database;

  static const _unknownType = 'unknown';

  @override
  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  }) async {
    final query = _database.select(_database.analyticsSnapshots)
      ..where((s) {
        var condition =
            s.entityType.equals(entityType) &
            s.snapshotDate.isBiggerOrEqualValue(range.start) &
            s.snapshotDate.isSmallerOrEqualValue(range.end);

        if (entityId != null) {
          condition = condition & s.entityId.equals(entityId);
        }

        return condition;
      })
      ..orderBy([(s) => OrderingTerm.desc(s.snapshotDate)]);

    final results = await query.get();
    return results
        .map(
          (row) => AnalyticsSnapshot(
            id: row.id,
            entityType: row.entityType,
            snapshotDate: row.snapshotDate,
            metrics: row.metrics,
            entityId: row.entityId,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot) async {
    await _database
        .into(_database.analyticsSnapshots)
        .insertOnConflictUpdate(
          AnalyticsSnapshotsCompanion(
            id: Value(snapshot.id),
            entityType: Value(snapshot.entityType),
            entityId: Value(snapshot.entityId),
            snapshotDate: Value(snapshot.snapshotDate),
            metrics: Value(snapshot.metrics),
          ),
        );
  }

  @override
  Future<void> saveSnapshots(List<AnalyticsSnapshot> snapshots) async {
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.analyticsSnapshots,
        snapshots.map(
          (snapshot) => AnalyticsSnapshotsCompanion(
            id: Value(snapshot.id),
            entityType: Value(snapshot.entityType),
            entityId: Value(snapshot.entityId),
            snapshotDate: Value(snapshot.snapshotDate),
            metrics: Value(snapshot.metrics),
          ),
        ),
      );
    });
  }

  @override
  Future<List<CorrelationResult>> getCachedCorrelations({
    required String correlationType,
    required DateRange range,
  }) async {
    final query = _database.select(_database.analyticsCorrelations)
      ..where(
        (c) =>
            c.correlationType.equals(correlationType) &
            // Correlations are cached at computation time; filter by when they
            // were computed rather than by their underlying period window.
            c.computedAt.isBiggerOrEqualValue(range.start) &
            c.computedAt.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(c) => OrderingTerm.desc(c.computedAt)]);

    final results = await query.get();

    final sourceIdsByType = <String, Set<String>>{};
    final targetIdsByType = <String, Set<String>>{};

    for (final row in results) {
      (sourceIdsByType[row.sourceType] ??= <String>{}).add(row.sourceId);
      (targetIdsByType[row.targetType] ??= <String>{}).add(row.targetId);
    }

    final sourceLabelsById = await _resolveEntityLabelsByType(sourceIdsByType);
    final targetLabelsById = await _resolveEntityLabelsByType(targetIdsByType);

    return results.map((row) {
      // Parse enhanced fields from JSON
      StatisticalSignificance? significance;
      if (row.statisticalSignificance != null) {
        try {
          final map = row.statisticalSignificance is String
              ? jsonDecode(row.statisticalSignificance! as String)
              : row.statisticalSignificance;
          significance = StatisticalSignificance.fromJson(
            map as Map<String, dynamic>,
          );
        } catch (_) {
          // Ignore parse errors for backward compatibility
        }
      }

      PerformanceMetrics? performance;
      if (row.performanceMetrics != null) {
        try {
          final map = row.performanceMetrics is String
              ? jsonDecode(row.performanceMetrics! as String)
              : row.performanceMetrics;
          performance = PerformanceMetrics.fromJson(
            map as Map<String, dynamic>,
          );
        } catch (_) {
          // Ignore parse errors
        }
      }

      return CorrelationResult(
        sourceLabel:
            sourceLabelsById[row.sourceId] ??
            _fallbackLabel(row.sourceType, row.sourceId),
        targetLabel:
            targetLabelsById[row.targetId] ??
            _fallbackLabel(row.targetType, row.targetId),
        coefficient: row.coefficient ?? 0.0,
        sampleSize: row.sampleSize,
        strength:
            _parseStrength(row.strength) ??
            _strengthFromCoefficient(row.coefficient ?? 0.0),
        insight: row.insight ?? '',
        valueWithSource: row.valueWithSource,
        valueWithoutSource: row.valueWithoutSource,
        sourceId: row.sourceId,
        targetId: row.targetId,
        sourceType: row.sourceType,
        targetType: row.targetType,
        statisticalSignificance: significance,
        performanceMetrics: performance,
      );
    }).toList();
  }

  @override
  Future<void> saveCorrelation(CorrelationResult correlation) async {
    // Convert enhanced fields to Map (the TypeConverter handles JSON serialization)
    final significanceMap = correlation.statisticalSignificance?.toJson();
    final performanceMap = correlation.performanceMetrics?.toJson();

    final sourceId = correlation.sourceId ?? correlation.sourceLabel;
    final targetId = correlation.targetId ?? correlation.targetLabel;

    final sourceType =
        correlation.sourceType ?? _inferEntityTypeFromId(sourceId);
    final targetType =
        correlation.targetType ?? _inferEntityTypeFromId(targetId);
    final inferredCorrelationType = _inferCorrelationType(
      sourceType: sourceType,
      targetType: targetType,
    );

    await _database
        .into(_database.analyticsCorrelations)
        .insertOnConflictUpdate(
          AnalyticsCorrelationsCompanion(
            id: Value(_generateId()),
            correlationType: Value(inferredCorrelationType),
            sourceType: Value(sourceType),
            sourceId: Value(sourceId),
            targetType: Value(targetType),
            targetId: Value(targetId),
            periodStart: Value(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
            periodEnd: Value(DateTime.now()),
            coefficient: Value(correlation.coefficient),
            sampleSize: Value(correlation.sampleSize ?? 0),
            strength: Value(correlation.strength.name),
            insight: Value(correlation.insight ?? ''),
            valueWithSource: Value(correlation.valueWithSource),
            valueWithoutSource: Value(correlation.valueWithoutSource),
            computedAt: Value(DateTime.now()),
            statisticalSignificance: Value(significanceMap),
            performanceMetrics: Value(performanceMap),
          ),
        );
  }

  @override
  Future<void> saveCorrelations(List<CorrelationResult> correlations) async {
    await _database.batch((batch) {
      for (final correlation in correlations) {
        // Convert enhanced fields to Map (the TypeConverter handles JSON serialization)
        final significanceMap = correlation.statisticalSignificance?.toJson();
        final performanceMap = correlation.performanceMetrics?.toJson();

        final sourceId = correlation.sourceId ?? correlation.sourceLabel;
        final targetId = correlation.targetId ?? correlation.targetLabel;

        final sourceType =
            correlation.sourceType ?? _inferEntityTypeFromId(sourceId);
        final targetType =
            correlation.targetType ?? _inferEntityTypeFromId(targetId);
        final inferredCorrelationType = _inferCorrelationType(
          sourceType: sourceType,
          targetType: targetType,
        );

        batch.insert(
          _database.analyticsCorrelations,
          AnalyticsCorrelationsCompanion(
            id: Value(_generateId()),
            correlationType: Value(inferredCorrelationType),
            sourceType: Value(sourceType),
            sourceId: Value(sourceId),
            targetType: Value(targetType),
            targetId: Value(targetId),
            periodStart: Value(
              DateTime.now().subtract(const Duration(days: 30)),
            ),
            periodEnd: Value(DateTime.now()),
            coefficient: Value(correlation.coefficient),
            sampleSize: Value(correlation.sampleSize ?? 0),
            strength: Value(correlation.strength.name),
            insight: Value(correlation.insight ?? ''),
            valueWithSource: Value(correlation.valueWithSource),
            valueWithoutSource: Value(correlation.valueWithoutSource),
            computedAt: Value(DateTime.now()),
            statisticalSignificance: Value(significanceMap),
            performanceMetrics: Value(performanceMap),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  CorrelationStrength? _parseStrength(String raw) {
    for (final value in CorrelationStrength.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  String _inferEntityTypeFromId(String id) {
    final normalized = id.toLowerCase();
    if (normalized.startsWith('task-')) return 'task';
    if (normalized.startsWith('project-')) return 'project';
    if (normalized.startsWith('tracker-')) return 'tracker';
    if (normalized.startsWith('label-')) return 'label';
    return _unknownType;
  }

  String _inferCorrelationType({
    required String sourceType,
    required String targetType,
  }) {
    if (sourceType == _unknownType || targetType == _unknownType) {
      return 'general';
    }
    return '${sourceType}_$targetType';
  }

  String _fallbackLabel(String type, String id) => '$type-$id';

  Future<Map<String, String>> _resolveEntityLabelsByType(
    Map<String, Set<String>> idsByType,
  ) async {
    if (idsByType.isEmpty) return {};

    final labels = <String, String>{};

    final taskIds = idsByType['task'];
    if (taskIds != null && taskIds.isNotEmpty) {
      final rows = await (_database.select(
        _database.taskTable,
      )..where((t) => t.id.isIn(taskIds))).get();
      for (final row in rows) {
        labels[row.id] = row.name;
      }
    }

    final projectIds = idsByType['project'];
    if (projectIds != null && projectIds.isNotEmpty) {
      final rows = await (_database.select(
        _database.projectTable,
      )..where((p) => p.id.isIn(projectIds))).get();
      for (final row in rows) {
        labels[row.id] = row.name;
      }
    }

    final trackerIds = idsByType['tracker'];
    if (trackerIds != null && trackerIds.isNotEmpty) {
      final rows = await (_database.select(
        _database.trackers,
      )..where((t) => t.id.isIn(trackerIds))).get();
      for (final row in rows) {
        labels[row.id] = row.name;
      }
    }

    final labelIds = idsByType['label'];
    if (labelIds != null && labelIds.isNotEmpty) {
      final rows = await (_database.select(
        _database.labelTable,
      )..where((l) => l.id.isIn(labelIds))).get();
      for (final row in rows) {
        labels[row.id] = row.name;
      }
    }

    return labels;
  }

  CorrelationStrength _strengthFromCoefficient(double coefficient) {
    if (coefficient > 0.5) return CorrelationStrength.strongPositive;
    if (coefficient > 0.3) return CorrelationStrength.moderatePositive;
    if (coefficient > 0.1) return CorrelationStrength.weakPositive;
    if (coefficient < -0.5) return CorrelationStrength.strongNegative;
    if (coefficient < -0.3) return CorrelationStrength.moderateNegative;
    if (coefficient < -0.1) return CorrelationStrength.weakNegative;
    return CorrelationStrength.negligible;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // === Insights ===

  @override
  Future<List<AnalyticsInsight>> getRecentInsights({
    required DateRange range,
    int? limit,
  }) async {
    final query = _database.select(_database.analyticsInsights)
      ..where(
        (i) =>
            i.generatedAt.isBiggerOrEqualValue(range.start) &
            i.generatedAt.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(i) => OrderingTerm.desc(i.generatedAt)])
      ..limit(limit ?? 100);

    final results = await query.get();
    return results.map((row) {
      return AnalyticsInsight(
        id: row.id,
        insightType: _parseInsightType(row.insightType),
        title: row.title,
        description: row.description,
        generatedAt: row.generatedAt,
        periodStart: row.periodStart,
        periodEnd: row.periodEnd,
        metadata: row.metadata,
        score: row.score,
        confidence: row.confidence,
        isPositive: row.isPositive,
      );
    }).toList();
  }

  @override
  Future<void> saveInsight(AnalyticsInsight insight) async {
    await _database
        .into(_database.analyticsInsights)
        .insertOnConflictUpdate(
          AnalyticsInsightsCompanion(
            id: Value(insight.id),
            insightType: Value(insight.insightType.name),
            title: Value(insight.title),
            description: Value(insight.description),
            metadata: Value(insight.metadata),
            score: Value(insight.score),
            confidence: Value(insight.confidence),
            isPositive: Value(insight.isPositive),
            generatedAt: Value(insight.generatedAt),
            periodStart: Value(insight.periodStart),
            periodEnd: Value(insight.periodEnd),
          ),
        );
  }

  @override
  Future<void> dismissInsight(String insightId) async {
    await (_database.delete(
      _database.analyticsInsights,
    )..where((i) => i.id.equals(insightId))).go();
  }

  InsightType _parseInsightType(String typeStr) {
    return InsightType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => InsightType.correlationDiscovery,
    );
  }
}
