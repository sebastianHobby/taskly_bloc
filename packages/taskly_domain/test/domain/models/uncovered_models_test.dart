@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/src/checklists/model/checklist_item.dart';
import 'package:taskly_domain/src/core/model/task_snooze_stats.dart';

class _FakeInitialSyncService implements InitialSyncService {
  _FakeInitialSyncService(this._progress);

  final Stream<InitialSyncProgress> _progress;
  bool waited = false;

  @override
  Stream<InitialSyncProgress> get progress => _progress;

  @override
  Future<void> waitForFirstSync() async {
    waited = true;
  }
}

void main() {
  testSafe('analytics models serialize and compute derived values', () async {
    final range = DateRange.last30Days(end: DateTime.utc(2026, 2, 1));
    expect(range.daysDifference, 30);
    expect(range.contains(DateTime.utc(2026, 1, 15)), isTrue);

    final decodedRequest = CorrelationRequest.fromJson(<String, dynamic>{
      'runtimeType': 'moodVsEntity',
      'entityId': 'project-1',
      'entityType': 'project',
      'range': <String, dynamic>{
        'start': DateTime.utc(2026, 1, 1).toIso8601String(),
        'end': DateTime.utc(2026, 2, 1).toIso8601String(),
      },
    });
    expect(decodedRequest, isA<MoodVsEntityCorrelation>());

    final trend = TrendData.fromJson(<String, dynamic>{
      'points': <Map<String, dynamic>>[
        <String, dynamic>{
          'date': DateTime.utc(2026, 1, 1).toIso8601String(),
          'value': 1.0,
          'sampleCount': 1,
        },
      ],
      'granularity': 'daily',
      'overallTrend': 'up',
    });
    expect(trend.points.single.value, 1.0);
    expect(trend.overallTrend, TrendDirection.up);

    final insight = AnalyticsInsight(
      id: 'insight-1',
      insightType: InsightType.trendAlert,
      title: 'Title',
      description: 'Description',
      generatedAt: DateTime.utc(2026, 2, 1),
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: DateTime.utc(2026, 1, 31),
    );
    expect(insight.metadata, isEmpty);
    expect(insight.isPositive, isTrue);

    final valueStats = ValueStats(
      targetPercent: 50,
      actualPercent: 35,
      taskCount: 2,
      projectCount: 1,
      weeklyTrend: const [40, 38, 35],
      expectedRecentCompletionCount: 8,
      recentCompletionCount: 3,
      gapWarningThreshold: 10,
    );
    expect(valueStats.gap, -15);
    expect(valueStats.recentShortfallCount, 5);
    expect(valueStats.isSignificantGap, isTrue);
  });

  testSafe(
    'journal models apply defaults and support JSON roundtrip',
    () async {
      final now = DateTime.utc(2026, 2, 1, 9);
      final entry = JournalEntry(
        id: 'j1',
        entryDate: DateTime.utc(2026, 2, 1),
        entryTime: now,
        occurredAt: now,
        localDate: DateTime.utc(2026, 2, 1),
        createdAt: now,
        updatedAt: now,
        journalText: 'Hello',
      );
      expect(JournalEntry.fromJson(entry.toJson()), equals(entry));

      final definition = TrackerDefinition(
        id: 'td1',
        name: 'Mood',
        scope: 'daily',
        valueType: 'int',
        createdAt: now,
        updatedAt: now,
      );
      expect(definition.roles, isEmpty);
      expect(definition.isActive, isTrue);

      final choice = TrackerDefinitionChoice(
        id: 'choice1',
        trackerId: 'td1',
        choiceKey: 'good',
        label: 'Good',
        createdAt: now,
        updatedAt: now,
      );
      expect(TrackerDefinitionChoice.fromJson(choice.toJson()), equals(choice));

      final group = TrackerGroup(
        id: 'group1',
        name: 'Habits',
        createdAt: now,
        updatedAt: now,
      );
      final preference = TrackerPreference(
        id: 'pref1',
        trackerId: 'td1',
        createdAt: now,
        updatedAt: now,
      );
      expect(group.isActive, isTrue);
      expect(preference.showInQuickAdd, isFalse);

      final event = TrackerEvent(
        id: 'event1',
        trackerId: 'td1',
        anchorType: 'day',
        op: 'set',
        occurredAt: now,
        recordedAt: now,
        value: 3,
      );
      final stateEntry = TrackerStateEntry(
        id: 'state1',
        entryId: 'entry1',
        trackerId: 'td1',
        updatedAt: now,
        value: 3,
      );
      final stateDay = TrackerStateDay(
        id: 'state-day-1',
        anchorType: 'day',
        anchorDate: DateTime.utc(2026, 2, 1),
        trackerId: 'td1',
        updatedAt: now,
        value: 3,
      );
      expect(TrackerEvent.fromJson(event.toJson()), equals(event));
      expect(
        TrackerStateEntry.fromJson(stateEntry.toJson()),
        equals(stateEntry),
      );
      expect(TrackerStateDay.fromJson(stateDay.toJson()), equals(stateDay));
    },
  );

  testSafe('attention query and model serialization works', () async {
    final now = DateTime.utc(2026, 2, 1);
    final rule = AttentionRule(
      id: 'rule1',
      ruleKey: 'stale_task',
      bucket: AttentionBucket.action,
      evaluator: 'staleTask',
      evaluatorParams: const {'days': 7},
      severity: AttentionSeverity.warning,
      displayConfig: const {'title': 'Stale task'},
      resolutionActions: const ['reviewed'],
      active: true,
      source: AttentionEntitySource.systemTemplate,
      createdAt: now,
      updatedAt: now,
    );
    final query = AttentionQuery(
      buckets: const {AttentionBucket.action},
      minSeverity: AttentionSeverity.info,
      entityTypes: const {AttentionEntityType.task},
    );
    expect(query.matchesRule(rule), isTrue);

    final resolution = AttentionResolution(
      id: 'res1',
      ruleId: 'rule1',
      entityId: 'task1',
      entityType: AttentionEntityType.task,
      resolvedAt: now,
      resolutionAction: AttentionResolutionAction.reviewed,
      createdAt: now,
      actionDetails: const {'note': 'done'},
    );
    final item = AttentionItem(
      id: 'item1',
      ruleId: 'rule1',
      ruleKey: rule.ruleKey,
      bucket: AttentionBucket.action,
      entityId: 'task1',
      entityType: AttentionEntityType.task,
      severity: AttentionSeverity.warning,
      title: 'Task stale',
      description: 'Task has not progressed',
      availableActions: const [AttentionResolutionAction.reviewed],
      detectedAt: now,
      metadata: const {'days': 10},
    );
    final runtimeState = AttentionRuleRuntimeState(
      id: 'state1',
      ruleId: 'rule1',
      createdAt: now,
      updatedAt: now,
    );

    expect(AttentionRule.fromJson(rule.toJson()), equals(rule));
    expect(
      AttentionResolution.fromJson(resolution.toJson()),
      equals(resolution),
    );
    expect(AttentionItem.fromJson(item.toJson()), equals(item));
    expect(
      AttentionRuleRuntimeState.fromJson(runtimeState.toJson()),
      equals(runtimeState),
    );
  });

  testSafe('supporting simple models and sync progress are usable', () async {
    final progress = ChecklistProgress(total: 3, checked: 3);
    expect(progress.allChecked, isTrue);

    final item = ChecklistItem(
      id: 'item1',
      parentId: 'task1',
      title: 'Call dentist',
      sortIndex: 0,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final state = ChecklistItemState(itemId: item.id, isChecked: true);
    expect(state.checkedAt, isNull);

    final stats = TaskSnoozeStats(snoozeCount: 2, totalSnoozeDays: 5);
    expect(stats.snoozeCount, 2);
    expect(stats.totalSnoozeDays, 5);

    final skip = RoutineSkip(
      id: 'skip1',
      routineId: 'routine1',
      periodType: RoutineSkipPeriodType.week,
      periodKeyUtc: DateTime.utc(2026, 2, 16),
      createdAtUtc: DateTime.utc(2026, 2, 16),
    );
    expect(skip.periodType, RoutineSkipPeriodType.week);

    final syncProgress = InitialSyncProgress(
      connected: true,
      connecting: false,
      downloading: true,
      uploading: false,
      hasSynced: false,
      downloadFraction: 0.5,
      lastSyncedAt: null,
    );
    final service = _FakeInitialSyncService(Stream.value(syncProgress));
    expect(await service.progress.first, equals(syncProgress));
    await service.waitForFirstSync();
    expect(service.waited, isTrue);
  });
}
