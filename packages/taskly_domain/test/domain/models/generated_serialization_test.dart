@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/analytics.dart';

void main() {
  testSafe('CorrelationRequest supports all runtime variants', () async {
    final rawRange = <String, dynamic>{
      'start': DateTime.utc(2026, 1, 1).toIso8601String(),
      'end': DateTime.utc(2026, 1, 31).toIso8601String(),
    };

    final moodVsTracker = CorrelationRequest.fromJson(<String, dynamic>{
      'runtimeType': 'moodVsTracker',
      'trackerId': 'tracker-1',
      'range': rawRange,
    });
    final moodVsEntity = CorrelationRequest.fromJson(<String, dynamic>{
      'runtimeType': 'moodVsEntity',
      'entityId': 'project-1',
      'entityType': 'project',
      'range': rawRange,
    });
    final trackerVsTracker = CorrelationRequest.fromJson(<String, dynamic>{
      'runtimeType': 'trackerVsTracker',
      'trackerId1': 'sleep',
      'trackerId2': 'energy',
      'range': rawRange,
    });

    expect(moodVsTracker, isA<MoodVsTrackerCorrelation>());
    expect(moodVsEntity, isA<MoodVsEntityCorrelation>());
    expect(trackerVsTracker, isA<TrackerVsTrackerCorrelation>());
    expect(moodVsTracker.toJson()['runtimeType'], 'moodVsTracker');
    expect(moodVsEntity.toJson()['runtimeType'], 'moodVsEntity');
    expect(trackerVsTracker.toJson()['runtimeType'], 'trackerVsTracker');
  });

  testSafe(
    'CorrelationResult parses nested significance/metrics JSON',
    () async {
      final parsed = CorrelationResult.fromJson(<String, dynamic>{
        'sourceLabel': 'Sleep',
        'targetLabel': 'Mood',
        'coefficient': 0.42,
        'strength': 'moderatePositive',
        'sourceId': 'tracker-1',
        'targetId': 'mood',
        'sourceType': 'tracker',
        'targetType': 'mood',
        'sampleSize': 32,
        'insight': 'Useful trend',
        'valueWithSource': 7.5,
        'valueWithoutSource': 5.0,
        'differencePercent': 50.0,
        'sourceHigherIsBetter': true,
        'targetHigherIsBetter': true,
        'statisticalSignificance': <String, dynamic>{
          'pValue': 0.01,
          'tStatistic': 3.1,
          'degreesOfFreedom': 30,
          'standardError': 0.11,
          'isSignificant': true,
          'confidenceInterval': [0.2, 0.6],
        },
        'performanceMetrics': <String, dynamic>{
          'calculationTimeMs': 8,
          'dataPoints': 32,
          'algorithm': 'ml_linalg_simd',
          'memoryUsedBytes': 4096,
        },
      });

      expect(parsed.strength, CorrelationStrength.moderatePositive);
      expect(parsed.statisticalSignificance?.isSignificant, isTrue);
      expect(parsed.performanceMetrics?.algorithm, 'ml_linalg_simd');
      expect(parsed.toJson()['sourceLabel'], 'Sleep');
      expect(parsed.toJson()['strength'], 'moderatePositive');
    },
  );

  testSafe('TrendData and TrendPoint parse/serialize JSON', () async {
    final raw = <String, dynamic>{
      'points': [
        <String, dynamic>{
          'date': DateTime.utc(2026, 1, 1).toIso8601String(),
          'value': 3.0,
          'sampleCount': 1,
        },
        <String, dynamic>{
          'date': DateTime.utc(2026, 1, 8).toIso8601String(),
          'value': 4.5,
          'sampleCount': 2,
        },
      ],
      'granularity': 'weekly',
      'average': 3.75,
      'min': 3.0,
      'max': 4.5,
      'overallTrend': 'up',
    };

    final parsed = TrendData.fromJson(raw);
    expect(parsed.points, hasLength(2));
    expect(parsed.overallTrend, TrendDirection.up);
    expect(parsed.toJson()['granularity'], 'weekly');
  });

  testSafe('AllocationConfig parses nested settings and defaults', () async {
    final parsed = AllocationConfig.fromJson(<String, dynamic>{
      'suggestionsPerBatch': 6,
      'hasSelectedFocusMode': true,
      'focusMode': 'intentional',
      'strategySettings': <String, dynamic>{
        'taskUrgencyThresholdDays': 2,
        'enableNeglectWeighting': false,
        'anchorCount': 3,
        'tasksPerAnchorMin': 1,
        'tasksPerAnchorMax': 4,
        'rotationPressureDays': 5,
        'readinessFilter': false,
        'freeSlots': 2,
      },
      'displaySettings': <String, dynamic>{
        'showOrphanTaskCount': false,
        'showProjectNextTask': false,
        'gapWarningThresholdPercent': 20,
        'sparklineWeeks': 8,
      },
      'suggestionSignal': 'behavior',
    });

    expect(parsed.focusMode, FocusMode.intentional);
    expect(parsed.suggestionSignal, SuggestionSignal.behaviorBased);
    expect(parsed.toJson()['suggestionSignal'], 'behavior');

    final defaults = AllocationConfig.fromJson(const <String, dynamic>{});
    expect(defaults.suggestionSignal, SuggestionSignal.ratingsBased);
    expect(defaults.focusMode, FocusMode.sustainable);
  });
}
