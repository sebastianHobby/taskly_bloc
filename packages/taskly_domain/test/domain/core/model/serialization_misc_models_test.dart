@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/src/allocation/engine/urgency_detector.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_date_tag.dart';
import 'package:taskly_domain/src/models/workflow/entity_tile_capabilities.dart';
import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/settings/model/alert_severity.dart';

void main() {
  testSafe('allocation config and urgency detector work as expected', () async {
    final config = AllocationConfig(
      suggestionsPerBatch: 8,
      hasSelectedFocusMode: true,
      focusMode: FocusMode.responsive,
      suggestionSignal: SuggestionSignal.behaviorBased,
      strategySettings: const StrategySettings(taskUrgencyThresholdDays: 2),
      displaySettings: const DisplaySettings(sparklineWeeks: 6),
    );
    final parsed = AllocationConfig.fromJson(<String, dynamic>{
      'suggestionsPerBatch': 8,
      'hasSelectedFocusMode': true,
      'focusMode': 'responsive',
      'suggestionSignal': 'behavior',
      'strategySettings': <String, dynamic>{'taskUrgencyThresholdDays': 2},
      'displaySettings': <String, dynamic>{'sparklineWeeks': 6},
    });
    expect(parsed.suggestionsPerBatch, config.suggestionsPerBatch);
    expect(parsed.focusMode, config.focusMode);
    expect(parsed.suggestionSignal, SuggestionSignal.behaviorBased);

    final detector = UrgencyDetector.fromConfig(config);
    final today = DateTime.utc(2026, 1, 10);
    final urgent = Task(
      id: 't1',
      createdAt: today,
      updatedAt: today,
      name: 'Urgent',
      completed: false,
      deadlineDate: today.add(const Duration(days: 1)),
    );
    final valueless = urgent.copyWith(project: null, values: const []);

    expect(detector.isTaskUrgent(urgent, todayDayKeyUtc: today), isTrue);
    expect(detector.findUrgentTasks([urgent], todayDayKeyUtc: today), [urgent]);
    expect(
      detector.findUrgentValuelessTasks([valueless], todayDayKeyUtc: today),
      [valueless],
    );
  });

  testSafe('auth and settings helpers expose expected values', () async {
    expect(AlertSeverity.critical.sortOrder, 0);
    expect(AlertSeverity.notice.displayName, 'Notice');

    const user = AuthUser(id: 'u1', email: 'u@test.dev');
    const session = AuthSession(user: user);
    const state = AuthStateChange(
      event: AuthEventKind.signedIn,
      session: session,
    );
    const response = AuthResponse(session: session, user: user);
    const update = UserUpdateResponse(user: user);

    expect(state.session?.user.id, 'u1');
    expect(response.user?.email, 'u@test.dev');
    expect(update.user?.id, 'u1');
  });

  testSafe(
    'analytics models serialize and compute helpers correctly',
    () async {
      final snapshot = AnalyticsSnapshot(
        id: 's1',
        entityType: 'task',
        snapshotDate: DateTime.utc(2026, 1, 1),
        metrics: const <String, dynamic>{'count': 3},
        entityId: 't1',
      );
      expect(AnalyticsSnapshot.fromJson(snapshot.toJson()), snapshot);

      final insight = AnalyticsInsight(
        id: 'i1',
        insightType: InsightType.trendAlert,
        title: 't',
        description: 'd',
        generatedAt: DateTime.utc(2026, 1, 1),
        periodStart: DateTime.utc(2025, 12, 1),
        periodEnd: DateTime.utc(2026, 1, 1),
        score: 90,
        confidence: 0.8,
        metadata: const <String, dynamic>{'k': 'v'},
      );
      expect(AnalyticsInsight.fromJson(insight.toJson()), insight);

      final mood = MoodSummary(
        average: 3.2,
        totalEntries: 10,
        min: 1,
        max: 5,
        distribution: const <int, int>{1: 1, 5: 2},
      );
      expect(MoodSummary.fromJson(mood.toJson()), mood);

      final stat = StatResult(
        statType: TaskStatType.velocity,
        value: 4,
        severity: StatSeverity.warning,
        trend: TrendDirection.up,
        metadata: const <String, Object?>{'source': 'test'},
      );
      expect(StatResult.fromJson(stat.toJson()), stat);

      final correlation = CorrelationResult(
        sourceLabel: 'A',
        targetLabel: 'B',
        coefficient: 0.4,
        strength: CorrelationStrength.moderatePositive,
        statisticalSignificance: const StatisticalSignificance(
          pValue: 0.04,
          tStatistic: 2.1,
          degreesOfFreedom: 10,
          standardError: 0.1,
          isSignificant: true,
        ),
        performanceMetrics: const PerformanceMetrics(
          calculationTimeMs: 12,
          dataPoints: 30,
          algorithm: 'manual',
        ),
      );
      final parsedCorrelation = CorrelationResult.fromJson(<String, dynamic>{
        'sourceLabel': 'A',
        'targetLabel': 'B',
        'coefficient': 0.4,
        'strength': 'moderatePositive',
        'statisticalSignificance': <String, dynamic>{
          'pValue': 0.04,
          'tStatistic': 2.1,
          'degreesOfFreedom': 10,
          'standardError': 0.1,
          'isSignificant': true,
          'confidenceInterval': <double>[0, 0],
        },
        'performanceMetrics': <String, dynamic>{
          'calculationTimeMs': 12,
          'dataPoints': 30,
          'algorithm': 'manual',
        },
      });
      expect(parsedCorrelation, correlation);

      final valueStats = ValueStats(
        targetPercent: 60,
        actualPercent: 40,
        taskCount: 2,
        projectCount: 1,
        weeklyTrend: const <double>[50, 45, 40],
        expectedRecentCompletionCount: 10,
        recentCompletionCount: 6,
        gapWarningThreshold: 15,
      );
      expect(ValueStats.fromJson(valueStats.toJson()), valueStats);
      expect(valueStats.gap, -20);
      expect(valueStats.recentShortfallCount, 4);
      expect(valueStats.isSignificantGap, isTrue);

      expect(EntityType.fromString('task'), EntityType.task);
      expect(
        () => EntityType.fromString('missing'),
        throwsArgumentError,
      );

      const activity = ValueActivityStats(taskCount: 3, projectCount: 1);
      const split = ValuePrimarySecondaryStats(
        primaryTaskCount: 1,
        secondaryTaskCount: 2,
        primaryProjectCount: 0,
        secondaryProjectCount: 1,
      );
      expect(activity.taskCount, 3);
      expect(split.secondaryProjectCount, 1);
    },
  );

  testSafe('journal tracker models serialize', () async {
    final definition = TrackerDefinition(
      id: 'd1',
      name: 'Water',
      scope: 'daily',
      valueType: 'int',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      roles: const <String>['input'],
      config: const <String, dynamic>{'x': 1},
      goal: const <String, dynamic>{'min': 2},
      source: 'user',
    );
    final group = TrackerGroup(
      id: 'g1',
      name: 'Health',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    final pref = TrackerPreference(
      id: 'p1',
      trackerId: 'd1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      color: '#fff',
    );

    expect(TrackerDefinition.fromJson(definition.toJson()), definition);
    expect(TrackerGroup.fromJson(group.toJson()), group);
    expect(TrackerPreference.fromJson(pref.toJson()), pref);
  });

  testSafe('workflow/scheduled/notification helpers cover branches', () async {
    const caps = EntityTileCapabilities(canOpenEditor: true);
    final capsRoundTrip = EntityTileCapabilities.fromJson(caps.toJson());
    expect(capsRoundTrip.canOpenEditor, isTrue);

    const override = EntityTileCapabilitiesOverride(canDelete: true);
    final overridden = caps.applyOverride(override);
    expect(overridden.canDelete, isTrue);
    expect(
      EntityTileCapabilitiesOverride.fromJson(override.toJson()),
      override,
    );

    expect(ScheduledDateTag.starts.label, 'Starts');
    expect(ScheduledDateTag.ongoing.label, 'Ongoing');
    expect(ScheduledDateTag.due.label, 'Due');

    expect(PendingNotification.tryDecodePayload(null), isNull);
    expect(PendingNotification.tryDecodePayload('{"a":1}')?['a'], 1);
    expect(PendingNotification.tryDecodePayload('[1,2]')?['value'], [1, 2]);
    expect(
      PendingNotification.tryDecodePayload('not-json')?['raw'],
      'not-json',
    );
  });
}
