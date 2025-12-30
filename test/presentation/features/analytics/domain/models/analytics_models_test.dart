import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';

void main() {
  group('AnalyticsInsight', () {
    final now = DateTime(2025, 12, 26);
    final periodStart = DateTime(2025, 12);
    final periodEnd = DateTime(2025, 12, 31);

    test('creates instance with required fields', () {
      final insight = AnalyticsInsight(
        id: 'insight-1',
        insightType: InsightType.correlationDiscovery,
        title: 'High Correlation Found',
        description: 'Strong correlation between task completion and mood',
        generatedAt: now,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(insight.id, 'insight-1');
      expect(insight.insightType, InsightType.correlationDiscovery);
      expect(insight.title, 'High Correlation Found');
      expect(insight.description, contains('correlation'));
      expect(insight.generatedAt, now);
      expect(insight.periodStart, periodStart);
      expect(insight.periodEnd, periodEnd);
      expect(insight.metadata, isEmpty);
      expect(insight.score, isNull);
      expect(insight.confidence, isNull);
      expect(insight.isPositive, isTrue);
    });

    test('creates instance with all fields', () {
      final metadata = {
        'correlationCoefficient': 0.85,
        'sourceLabel': 'Tasks Completed',
        'targetLabel': 'Mood Rating',
      };

      final insight = AnalyticsInsight(
        id: 'insight-1',
        insightType: InsightType.productivityPattern,
        title: 'Peak Productivity Pattern',
        description: 'Most productive in the morning',
        generatedAt: now,
        periodStart: periodStart,
        periodEnd: periodEnd,
        metadata: metadata,
        score: 85.5,
        confidence: 0.92,
      );

      expect(insight.metadata, metadata);
      expect(insight.score, 85.5);
      expect(insight.confidence, 0.92);
      expect(insight.isPositive, isTrue);
    });

    test('toJson serializes correctly', () {
      final insight = AnalyticsInsight(
        id: 'insight-1',
        insightType: InsightType.trendAlert,
        title: 'Declining Trend',
        description: 'Task completion rate declining',
        generatedAt: now,
        periodStart: periodStart,
        periodEnd: periodEnd,
        score: 65,
        confidence: 0.78,
        isPositive: false,
      );

      final json = insight.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'insight-1');
      expect(json['title'], 'Declining Trend');
      expect(insight.score, 65.0);
      expect(insight.confidence, 0.78);
      expect(insight.isPositive, isFalse);
    });

    test('fromJson deserializes correctly', () {
      final insight = AnalyticsInsight(
        id: 'insight-1',
        insightType: InsightType.anomalyDetection,
        title: 'Unusual Activity',
        description: 'Spike in task creation detected',
        generatedAt: now,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final json = insight.toJson();
      final restored = AnalyticsInsight.fromJson(json);

      expect(restored.id, insight.id);
      expect(restored.insightType, InsightType.anomalyDetection);
      expect(restored.title, insight.title);
    });

    test('supports all InsightType values', () {
      final types = [
        InsightType.correlationDiscovery,
        InsightType.trendAlert,
        InsightType.anomalyDetection,
        InsightType.productivityPattern,
        InsightType.moodPattern,
        InsightType.recommendation,
      ];

      for (final type in types) {
        final insight = AnalyticsInsight(
          id: 'insight-1',
          insightType: type,
          title: 'Test',
          description: 'Test',
          generatedAt: now,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );
        expect(insight.insightType, type);
      }
    });

    test('copyWith creates new instance with updated fields', () {
      final insight = AnalyticsInsight(
        id: 'insight-1',
        insightType: InsightType.recommendation,
        title: 'Original Title',
        description: 'Original Description',
        generatedAt: now,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final updated = insight.copyWith(
        title: 'Updated Title',
        score: 90,
      );

      expect(updated.id, insight.id);
      expect(updated.title, 'Updated Title');
      expect(updated.score, 90.0);
      expect(updated.description, insight.description);
    });
  });

  group('CorrelationResult', () {
    test('creates instance with required fields', () {
      const result = CorrelationResult(
        sourceLabel: 'Tasks Completed',
        targetLabel: 'Mood Rating',
        coefficient: 0.75,
        strength: CorrelationStrength.strongPositive,
      );

      expect(result.sourceLabel, 'Tasks Completed');
      expect(result.targetLabel, 'Mood Rating');
      expect(result.coefficient, 0.75);
      expect(result.strength, CorrelationStrength.strongPositive);
      expect(result.sourceId, isNull);
      expect(result.targetId, isNull);
      expect(result.sampleSize, isNull);
    });

    test('creates instance with all fields', () {
      const significance = StatisticalSignificance(
        pValue: 0.01,
        tStatistic: 3.5,
        degreesOfFreedom: 28,
        standardError: 0.05,
        isSignificant: true,
        confidenceInterval: [0.65, 0.85],
      );

      const performance = PerformanceMetrics(
        calculationTimeMs: 150,
        dataPoints: 30,
        algorithm: 'ml_linalg_simd',
        memoryUsedBytes: 2048,
      );

      const result = CorrelationResult(
        sourceLabel: 'Exercise Minutes',
        targetLabel: 'Energy Level',
        coefficient: 0.82,
        strength: CorrelationStrength.strongPositive,
        sourceId: 'tracker-1',
        targetId: 'tracker-2',
        sourceType: 'tracker',
        targetType: 'tracker',
        sampleSize: 30,
        insight: 'More exercise correlates with higher energy',
        valueWithSource: 7.5,
        valueWithoutSource: 5.2,
        differencePercent: 44.2,
        statisticalSignificance: significance,
        performanceMetrics: performance,
      );

      expect(result.sourceId, 'tracker-1');
      expect(result.sampleSize, 30);
      expect(result.insight, contains('exercise'));
      expect(result.valueWithSource, 7.5);
      expect(result.statisticalSignificance, significance);
      expect(result.performanceMetrics, performance);
    });

    test('toJson serializes correctly', () {
      const result = CorrelationResult(
        sourceLabel: 'Source',
        targetLabel: 'Target',
        coefficient: 0.5,
        strength: CorrelationStrength.moderatePositive,
        sampleSize: 50,
      );

      final json = result.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(result.sourceLabel, 'Source');
      expect(result.targetLabel, 'Target');
      expect(result.coefficient, 0.5);
      expect(result.strength, CorrelationStrength.moderatePositive);
      expect(result.sampleSize, 50);
    });

    test('fromJson deserializes correctly', () {
      const result = CorrelationResult(
        sourceLabel: 'Source',
        targetLabel: 'Target',
        coefficient: -0.6,
        strength: CorrelationStrength.strongNegative,
      );

      final json = result.toJson();
      final restored = CorrelationResult.fromJson(json);

      expect(restored.sourceLabel, result.sourceLabel);
      expect(restored.targetLabel, result.targetLabel);
      expect(restored.coefficient, result.coefficient);
      expect(restored.strength, result.strength);
    });

    test('supports all CorrelationStrength values', () {
      final strengths = [
        CorrelationStrength.strongPositive,
        CorrelationStrength.moderatePositive,
        CorrelationStrength.weakPositive,
        CorrelationStrength.negligible,
        CorrelationStrength.weakNegative,
        CorrelationStrength.moderateNegative,
        CorrelationStrength.strongNegative,
      ];

      for (final strength in strengths) {
        final result = CorrelationResult(
          sourceLabel: 'Source',
          targetLabel: 'Target',
          coefficient: 0.5,
          strength: strength,
        );
        expect(result.strength, strength);
      }
    });
  });

  group('StatisticalSignificance', () {
    test('creates instance with required fields', () {
      const significance = StatisticalSignificance(
        pValue: 0.02,
        tStatistic: 2.5,
        degreesOfFreedom: 25,
        standardError: 0.08,
        isSignificant: true,
      );

      expect(significance.pValue, 0.02);
      expect(significance.tStatistic, 2.5);
      expect(significance.degreesOfFreedom, 25);
      expect(significance.standardError, 0.08);
      expect(significance.isSignificant, isTrue);
      expect(significance.confidenceInterval, [0, 0]);
    });

    test('creates instance with confidence interval', () {
      const significance = StatisticalSignificance(
        pValue: 0.001,
        tStatistic: 4.2,
        degreesOfFreedom: 48,
        standardError: 0.03,
        isSignificant: true,
        confidenceInterval: [0.75, 0.95],
      );

      expect(significance.confidenceInterval, [0.75, 0.95]);
    });

    test('toJson and fromJson roundtrip', () {
      const original = StatisticalSignificance(
        pValue: 0.015,
        tStatistic: 3.1,
        degreesOfFreedom: 30,
        standardError: 0.06,
        isSignificant: true,
        confidenceInterval: [0.6, 0.8],
      );

      final json = original.toJson();
      final restored = StatisticalSignificance.fromJson(json);

      expect(restored.pValue, original.pValue);
      expect(restored.tStatistic, original.tStatistic);
      expect(restored.isSignificant, original.isSignificant);
    });
  });

  group('PerformanceMetrics', () {
    test('creates instance with required fields', () {
      const metrics = PerformanceMetrics(
        calculationTimeMs: 200,
        dataPoints: 100,
        algorithm: 'manual',
      );

      expect(metrics.calculationTimeMs, 200);
      expect(metrics.dataPoints, 100);
      expect(metrics.algorithm, 'manual');
      expect(metrics.memoryUsedBytes, isNull);
    });

    test('creates instance with all fields', () {
      const metrics = PerformanceMetrics(
        calculationTimeMs: 50,
        dataPoints: 500,
        algorithm: 'ml_linalg_simd',
        memoryUsedBytes: 4096,
      );

      expect(metrics.memoryUsedBytes, 4096);
    });

    test('toJson and fromJson roundtrip', () {
      const original = PerformanceMetrics(
        calculationTimeMs: 75,
        dataPoints: 250,
        algorithm: 'ml_linalg_simd',
        memoryUsedBytes: 3072,
      );

      final json = original.toJson();
      final restored = PerformanceMetrics.fromJson(json);

      expect(restored.calculationTimeMs, original.calculationTimeMs);
      expect(restored.dataPoints, original.dataPoints);
      expect(restored.algorithm, original.algorithm);
      expect(restored.memoryUsedBytes, original.memoryUsedBytes);
    });
  });

  group('TrendData', () {
    final date1 = DateTime(2025, 12);
    final date2 = DateTime(2025, 12, 2);

    test('creates instance with required fields', () {
      final points = [
        TrendPoint(date: date1, value: 5),
        TrendPoint(date: date2, value: 7),
      ];

      final trend = TrendData(
        points: points,
        granularity: TrendGranularity.daily,
      );

      expect(trend.points, points);
      expect(trend.granularity, TrendGranularity.daily);
      expect(trend.average, isNull);
      expect(trend.min, isNull);
      expect(trend.max, isNull);
      expect(trend.overallTrend, isNull);
    });

    test('creates instance with all fields', () {
      final points = [
        TrendPoint(date: date1, value: 5, sampleCount: 10),
        TrendPoint(date: date2, value: 7, sampleCount: 12),
      ];

      final trend = TrendData(
        points: points,
        granularity: TrendGranularity.weekly,
        average: 6,
        min: 5,
        max: 7,
        overallTrend: TrendDirection.up,
      );

      expect(trend.average, 6.0);
      expect(trend.min, 5.0);
      expect(trend.max, 7.0);
      expect(trend.overallTrend, TrendDirection.up);
    });

    test('toJson and fromJson roundtrip', () {
      final points = [TrendPoint(date: date1, value: 5)];
      final original = TrendData(
        points: points,
        granularity: TrendGranularity.monthly,
        average: 5.5,
      );

      // Test individual TrendPoint serialization
      final pointJson = points.first.toJson();
      final restoredPoint = TrendPoint.fromJson(pointJson);

      expect(restoredPoint.value, points.first.value);
      expect(original.granularity, TrendGranularity.monthly);
      expect(original.average, 5.5);
    });

    test('supports all TrendGranularity values', () {
      final granularities = [
        TrendGranularity.daily,
        TrendGranularity.weekly,
        TrendGranularity.monthly,
      ];

      for (final granularity in granularities) {
        final trend = TrendData(
          points: [],
          granularity: granularity,
        );
        expect(trend.granularity, granularity);
      }
    });

    test('supports all TrendDirection values', () {
      final directions = [
        TrendDirection.up,
        TrendDirection.down,
        TrendDirection.stable,
      ];

      for (final direction in directions) {
        final trend = TrendData(
          points: [],
          granularity: TrendGranularity.daily,
          overallTrend: direction,
        );
        expect(trend.overallTrend, direction);
      }
    });
  });

  group('TrendPoint', () {
    final date = DateTime(2025, 12, 15);

    test('creates instance with required fields', () {
      final point = TrendPoint(date: date, value: 10.5);

      expect(point.date, date);
      expect(point.value, 10.5);
      expect(point.sampleCount, isNull);
    });

    test('creates instance with sample count', () {
      final point = TrendPoint(
        date: date,
        value: 8.2,
        sampleCount: 25,
      );

      expect(point.sampleCount, 25);
    });

    test('toJson and fromJson roundtrip', () {
      final original = TrendPoint(
        date: date,
        value: 6.7,
        sampleCount: 15,
      );

      final json = original.toJson();
      final restored = TrendPoint.fromJson(json);

      expect(restored.value, original.value);
      expect(restored.sampleCount, original.sampleCount);
    });
  });
}
