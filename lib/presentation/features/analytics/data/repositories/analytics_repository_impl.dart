import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/analytics_insight.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/analytics_snapshot.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_result.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._database);
  final AppDatabase _database;

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
    required String userId,
    required String correlationType,
    required DateRange range,
  }) async {
    final query = _database.select(_database.analyticsCorrelations)
      ..where(
        (c) =>
            c.correlationType.equals(correlationType) &
            c.periodStart.isBiggerOrEqualValue(range.start) &
            c.periodEnd.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(c) => OrderingTerm.desc(c.computedAt)]);

    final results = await query.get();
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
        sourceLabel: '${row.sourceType}-${row.sourceId}',
        targetLabel: '${row.targetType}-${row.targetId}',
        coefficient: row.coefficient ?? 0.0,
        sampleSize: row.sampleSize,
        strength: _strengthFromCoefficient(row.coefficient ?? 0.0),
        insight: row.insight ?? '',
        valueWithSource: row.valueWithSource,
        valueWithoutSource: row.valueWithoutSource,
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

    await _database
        .into(_database.analyticsCorrelations)
        .insertOnConflictUpdate(
          AnalyticsCorrelationsCompanion(
            id: Value(_generateId()),
            correlationType: Value('general'),
            sourceType: Value(correlation.sourceType ?? 'unknown'),
            sourceId: Value(correlation.sourceId ?? correlation.sourceLabel),
            targetType: Value(correlation.targetType ?? 'unknown'),
            targetId: Value(correlation.targetId ?? correlation.targetLabel),
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

        batch.insert(
          _database.analyticsCorrelations,
          AnalyticsCorrelationsCompanion(
            id: Value(_generateId()),
            correlationType: Value('general'),
            sourceType: Value(correlation.sourceType ?? 'unknown'),
            sourceId: Value(correlation.sourceId ?? correlation.sourceLabel),
            targetType: Value(correlation.targetType ?? 'unknown'),
            targetId: Value(correlation.targetId ?? correlation.targetLabel),
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
    required String userId,
    required DateRange range,
    int? limit,
  }) async {
    final query = _database.select(_database.analyticsInsights)
      ..where(
        (i) =>
            i.userId.equals(userId) &
            i.generatedAt.isBiggerOrEqualValue(range.start) &
            i.generatedAt.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(i) => OrderingTerm.desc(i.generatedAt)])
      ..limit(limit ?? 100);

    final results = await query.get();
    return results.map((row) {
      return AnalyticsInsight(
        id: row.id,
        userId: row.userId ?? userId,
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
            userId: Value(insight.userId),
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
