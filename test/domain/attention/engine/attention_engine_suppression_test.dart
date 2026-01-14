import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/attention/repositories/attention_repository_v2.dart';
import 'package:taskly_bloc/domain/attention/engine/attention_engine.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule_runtime_state.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/settings/model/global_settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';

import '../../../helpers/test_db.dart';

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

class _MockProjectRepository extends Mock
    implements ProjectRepositoryContract {}

class _MockAllocationSnapshotRepository extends Mock
    implements AllocationSnapshotRepositoryContract {}

/// Minimal settings repo fake to support [HomeDayKeyService] and the engine.
class _FakeSettingsRepository implements SettingsRepositoryContract {
  _FakeSettingsRepository({GlobalSettings? initialGlobal})
    : _global = BehaviorSubject.seeded(
        initialGlobal ?? const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );

  final BehaviorSubject<GlobalSettings> _global;

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    if (!identical(key, SettingsKey.global)) {
      throw StateError('Unsupported SettingsKey in test: $key');
    }

    return _global.stream.cast<T>();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (!identical(key, SettingsKey.global)) {
      throw StateError('Unsupported SettingsKey in test: $key');
    }

    return _global.value as T;
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    if (!identical(key, SettingsKey.global)) {
      throw StateError('Unsupported SettingsKey in test: $key');
    }

    _global.add(value as GlobalSettings);
  }

  Future<void> dispose() => _global.close();
}

// ---------------------------------------------------------------------------
// State hashing (mirrors AttentionEngine private helpers)
// ---------------------------------------------------------------------------

String _stableFingerprint(List<String> parts) => parts.join('|');

String _stableMapFingerprint(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();
  return keys.map((k) => '$k=${map[k]}').join('&');
}

String _ruleFingerprint(AttentionRule rule, {required String predicate}) {
  final evaluatorParams = _stableMapFingerprint(rule.evaluatorParams);

  return _stableFingerprint([
    'ruleKey=${rule.ruleKey}',
    'bucket=${rule.bucket.name}',
    'evaluator=${rule.evaluator}',
    'predicate=$predicate',
    'params=$evaluatorParams',
  ]);
}

String _taskStateHash(
  Task task,
  AttentionRule rule, {
  required String predicate,
}) {
  final ruleFingerprint = _ruleFingerprint(rule, predicate: predicate);

  final relevantParts = switch (predicate) {
    'isOverdue' => <String?>[
      task.deadlineDate?.toIso8601String(),
      task.completed.toString(),
    ],
    'isStale' => <String?>[
      task.updatedAt.toIso8601String(),
      task.completed.toString(),
    ],
    _ => <String?>[
      task.updatedAt.toIso8601String(),
      task.completed.toString(),
    ],
  };

  return _stableFingerprint([
    'entity=task',
    'taskId=${task.id}',
    'predicate=$predicate',
    'rule=$ruleFingerprint',
    ...relevantParts.whereType<String>().map((p) => 'v=$p'),
  ]);
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2000));
  });

  group('AttentionEngine suppression semantics', () {
    test('dismissedStateHash suppresses until state hash changes', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final attentionRepo = AttentionRepositoryV2(db: db);

      final tasks$ = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
      addTearDown(tasks$.close);

      final projects$ = BehaviorSubject<List<Project>>.seeded(
        const <Project>[],
      );
      addTearDown(projects$.close);

      final taskRepo = _MockTaskRepository();
      when(taskRepo.watchAll).thenAnswer((_) => tasks$.stream);

      final projectRepo = _MockProjectRepository();
      when(projectRepo.watchAll).thenAnswer((_) => projects$.stream);

      final allocationRepo = _MockAllocationSnapshotRepository();
      when(() => allocationRepo.watchLatestForUtcDay(any())).thenAnswer(
        (_) => Stream.value(null),
      );

      final invalidations = StreamController<void>.broadcast();
      addTearDown(invalidations.close);

      final settingsRepo = _FakeSettingsRepository(
        initialGlobal: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );
      addTearDown(settingsRepo.dispose);

      final engine = AttentionEngine(
        attentionRepository: attentionRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        allocationSnapshotRepository: allocationRepo,
        settingsRepository: settingsRepo,
        dayKeyService: HomeDayKeyService(settingsRepository: settingsRepo),
        invalidations: invalidations.stream,
      );

      final now = DateTime.utc(2026, 1, 11, 0, 0, 0);

      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'task_overdue',
        bucket: AttentionBucket.action,
        evaluator: 'task_predicate_v1',
        evaluatorParams: const <String, dynamic>{
          'predicate': 'isOverdue',
          'thresholdHours': 0,
        },
        severity: AttentionSeverity.warning,
        displayConfig: const <String, dynamic>{
          'title': 'Overdue',
          'description': 'Overdue task: {task_name}',
        },
        resolutionActions: const ['dismissed', 'snoozed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: now,
        updatedAt: now,
      );

      final overdueTask = Task(
        id: 't1',
        name: 'Pay bills',
        completed: false,
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.subtract(const Duration(days: 1)),
      );

      final received = <List<AttentionItem>>[];
      final sub = engine
          .watch(const AttentionQuery(buckets: {AttentionBucket.action}))
          .listen(received.add);
      addTearDown(sub.cancel);

      tasks$.add(<Task>[overdueTask]);
      await attentionRepo.upsertRule(rule);
      await pumpEventQueue(times: 20);

      expect(received.where((e) => e.isNotEmpty), isNotEmpty);

      final stateHash = _taskStateHash(
        overdueTask,
        rule,
        predicate: 'isOverdue',
      );
      await attentionRepo.upsertRuntimeState(
        AttentionRuleRuntimeState(
          id: 'rs1',
          ruleId: rule.id,
          entityType: AttentionEntityType.task,
          entityId: overdueTask.id,
          dismissedStateHash: stateHash,
          createdAt: now,
          updatedAt: now,
        ),
      );

      invalidations.add(null);
      await pumpEventQueue(times: 20);

      expect(received.last, isEmpty);

      final updatedTask = overdueTask.copyWith(
        deadlineDate: overdueTask.deadlineDate!.add(const Duration(days: 1)),
      );
      tasks$.add(<Task>[updatedTask]);
      await pumpEventQueue(times: 20);

      expect(received.last, isNotEmpty);
    });

    test('snooze_until suppresses items until after time', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final attentionRepo = AttentionRepositoryV2(db: db);

      final tasks$ = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
      addTearDown(tasks$.close);

      final projects$ = BehaviorSubject<List<Project>>.seeded(
        const <Project>[],
      );
      addTearDown(projects$.close);

      final taskRepo = _MockTaskRepository();
      when(taskRepo.watchAll).thenAnswer((_) => tasks$.stream);

      final projectRepo = _MockProjectRepository();
      when(projectRepo.watchAll).thenAnswer((_) => projects$.stream);

      final allocationRepo = _MockAllocationSnapshotRepository();
      when(() => allocationRepo.watchLatestForUtcDay(any())).thenAnswer(
        (_) => Stream.value(null),
      );

      final invalidations = StreamController<void>.broadcast();
      addTearDown(invalidations.close);

      final settingsRepo = _FakeSettingsRepository(
        initialGlobal: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );
      addTearDown(settingsRepo.dispose);

      final engine = AttentionEngine(
        attentionRepository: attentionRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        allocationSnapshotRepository: allocationRepo,
        settingsRepository: settingsRepo,
        dayKeyService: HomeDayKeyService(settingsRepository: settingsRepo),
        invalidations: invalidations.stream,
      );

      final now = DateTime.utc(2026, 1, 11, 0, 0, 0);

      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'task_overdue',
        bucket: AttentionBucket.action,
        evaluator: 'task_predicate_v1',
        evaluatorParams: const <String, dynamic>{
          'predicate': 'isOverdue',
          'thresholdHours': 0,
        },
        severity: AttentionSeverity.warning,
        displayConfig: const <String, dynamic>{
          'title': 'Overdue',
          'description': 'Overdue task: {task_name}',
        },
        resolutionActions: const ['dismissed', 'snoozed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: now,
        updatedAt: now,
      );

      final overdueTask = Task(
        id: 't1',
        name: 'Pay bills',
        completed: false,
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.subtract(const Duration(days: 1)),
      );

      final received = <List<AttentionItem>>[];
      final sub = engine
          .watch(const AttentionQuery(buckets: {AttentionBucket.action}))
          .listen(received.add);
      addTearDown(sub.cancel);

      tasks$.add(<Task>[overdueTask]);
      await attentionRepo.upsertRule(rule);
      await pumpEventQueue(times: 20);

      expect(received.where((e) => e.isNotEmpty), isNotEmpty);

      final snoozeUntil = DateTime.now().add(const Duration(days: 10));
      await attentionRepo.recordResolution(
        AttentionResolution(
          id: 'res1',
          ruleId: rule.id,
          entityId: overdueTask.id,
          entityType: AttentionEntityType.task,
          resolvedAt: now,
          resolutionAction: AttentionResolutionAction.snoozed,
          actionDetails: <String, dynamic>{
            'snooze_until': snoozeUntil.toIso8601String(),
          },
          createdAt: now,
        ),
      );

      invalidations.add(null);
      await pumpEventQueue(times: 20);
      expect(received.last, isEmpty);

      final resLater = now.add(const Duration(minutes: 1));
      await attentionRepo.recordResolution(
        AttentionResolution(
          id: 'res2',
          ruleId: rule.id,
          entityId: overdueTask.id,
          entityType: AttentionEntityType.task,
          resolvedAt: resLater,
          resolutionAction: AttentionResolutionAction.snoozed,
          actionDetails: <String, dynamic>{
            'snooze_until': DateTime.now()
                .subtract(const Duration(days: 10))
                .toIso8601String(),
          },
          createdAt: resLater,
        ),
      );

      invalidations.add(null);
      await pumpEventQueue(times: 20);
      expect(received.last, isNotEmpty);
    });

    test('invalidations pulse triggers re-evaluation emission', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final attentionRepo = AttentionRepositoryV2(db: db);

      final tasks$ = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
      addTearDown(tasks$.close);

      final projects$ = BehaviorSubject<List<Project>>.seeded(
        const <Project>[],
      );
      addTearDown(projects$.close);

      final taskRepo = _MockTaskRepository();
      when(taskRepo.watchAll).thenAnswer((_) => tasks$.stream);

      final projectRepo = _MockProjectRepository();
      when(projectRepo.watchAll).thenAnswer((_) => projects$.stream);

      final allocationRepo = _MockAllocationSnapshotRepository();
      when(() => allocationRepo.watchLatestForUtcDay(any())).thenAnswer(
        (_) => Stream.value(null),
      );

      final invalidations = StreamController<void>.broadcast();
      addTearDown(invalidations.close);

      final settingsRepo = _FakeSettingsRepository(
        initialGlobal: const GlobalSettings(homeTimeZoneOffsetMinutes: 0),
      );
      addTearDown(settingsRepo.dispose);

      final engine = AttentionEngine(
        attentionRepository: attentionRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        allocationSnapshotRepository: allocationRepo,
        settingsRepository: settingsRepo,
        dayKeyService: HomeDayKeyService(settingsRepository: settingsRepo),
        invalidations: invalidations.stream,
      );

      final now = DateTime.utc(2026, 1, 11, 0, 0, 0);

      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'task_overdue',
        bucket: AttentionBucket.action,
        evaluator: 'task_predicate_v1',
        evaluatorParams: const <String, dynamic>{
          'predicate': 'isOverdue',
          'thresholdHours': 0,
        },
        severity: AttentionSeverity.warning,
        displayConfig: const <String, dynamic>{
          'title': 'Overdue',
          'description': 'Overdue task: {task_name}',
        },
        resolutionActions: const ['dismissed', 'snoozed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: now,
        updatedAt: now,
      );

      final overdueTask = Task(
        id: 't1',
        name: 'Pay bills',
        completed: false,
        createdAt: now,
        updatedAt: now,
        deadlineDate: now.subtract(const Duration(days: 1)),
      );

      final received = <List<AttentionItem>>[];
      final sub = engine
          .watch(const AttentionQuery(buckets: {AttentionBucket.action}))
          .listen(received.add);
      addTearDown(sub.cancel);

      tasks$.add(<Task>[overdueTask]);
      await attentionRepo.upsertRule(rule);
      await pumpEventQueue(times: 20);

      final before = received.length;
      expect(before, greaterThan(0));

      invalidations.add(null);
      await pumpEventQueue(times: 20);

      expect(received.length, greaterThan(before));
    });
  });
}
