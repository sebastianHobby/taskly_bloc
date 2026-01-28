@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

class FakeAttentionRepository implements AttentionRepositoryContract {
  FakeAttentionRepository({List<AttentionRule>? rules})
    : _rules = BehaviorSubject<List<AttentionRule>>.seeded(
        rules ?? const [],
      );

  final BehaviorSubject<List<AttentionRule>> _rules;
  final Map<String, BehaviorSubject<List<AttentionResolution>>> _resolutions =
      {};
  final Map<String, BehaviorSubject<List<AttentionRuleRuntimeState>>>
  _runtimeStates = {};

  void setRules(List<AttentionRule> rules) {
    _rules.add(rules);
  }

  void setResolutions(String ruleId, List<AttentionResolution> resolutions) {
    _resolutions
        .putIfAbsent(
          ruleId,
          () => BehaviorSubject<List<AttentionResolution>>.seeded(const []),
        )
        .add(resolutions);
  }

  void setRuntimeStates(
    String ruleId,
    List<AttentionRuleRuntimeState> states,
  ) {
    _runtimeStates
        .putIfAbsent(
          ruleId,
          () =>
              BehaviorSubject<List<AttentionRuleRuntimeState>>.seeded(const []),
        )
        .add(states);
  }

  @override
  Stream<List<AttentionRule>> watchActiveRules() => _rules.stream;

  @override
  Stream<List<AttentionRuleRuntimeState>> watchRuntimeStateForRule(
    String ruleId,
  ) => _runtimeStates
      .putIfAbsent(
        ruleId,
        () => BehaviorSubject<List<AttentionRuleRuntimeState>>.seeded(const []),
      )
      .stream;

  @override
  Stream<List<AttentionResolution>> watchResolutionsForRule(String ruleId) =>
      _resolutions
          .putIfAbsent(
            ruleId,
            () => BehaviorSubject<List<AttentionResolution>>.seeded(const []),
          )
          .stream;

  @override
  Stream<List<AttentionRule>> watchAllRules() => _rules.stream;

  @override
  Stream<List<AttentionRule>> watchRulesByBucket(AttentionBucket bucket) =>
      _rules.stream.map(
        (rules) => rules.where((r) => r.bucket == bucket).toList(),
      );

  @override
  Stream<List<AttentionRule>> watchRulesByBuckets(
    List<AttentionBucket> buckets,
  ) => _rules.stream.map(
    (rules) => rules.where((r) => buckets.contains(r.bucket)).toList(),
  );

  @override
  Future<AttentionRule?> getRuleById(String id) async {
    try {
      return _rules.value.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AttentionRule?> getRuleByKey(String ruleKey) async {
    try {
      return _rules.value.firstWhere((r) => r.ruleKey == ruleKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertRule(AttentionRule rule) async {}

  @override
  Future<void> updateRuleActive(
    String ruleId,
    bool active, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> updateRuleEvaluatorParams(
    String ruleId,
    Map<String, dynamic> evaluatorParams, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> updateRuleSeverity(
    String ruleId,
    AttentionSeverity severity,
  ) async {}

  @override
  Future<void> deleteRule(String ruleId) async {}

  @override
  Stream<List<AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    AttentionEntityType entityType,
  ) => const Stream<List<AttentionResolution>>.empty();

  @override
  Future<AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  ) async => null;

  @override
  Future<void> recordResolution(
    AttentionResolution resolution, {
    OperationContext? context,
  }) async {}

  @override
  Future<AttentionRuleRuntimeState?> getRuntimeState({
    required String ruleId,
    required AttentionEntityType? entityType,
    required String? entityId,
  }) async => null;

  @override
  Future<void> upsertRuntimeState(AttentionRuleRuntimeState state) async {}
}

class FakeClock implements Clock {
  FakeClock(this.now);

  DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AttentionEngine', () {
    testSafe('emits task attention items for overdue predicate', () async {
      final now = DateTime(2025, 1, 10, 12);
      final rule = AttentionRule(
        id: 'r1',
        ruleKey: 'overdue',
        bucket: AttentionBucket.action,
        evaluator: 'task_predicate_v1',
        evaluatorParams: const {
          'predicate': 'isStale',
          'thresholdDays': 0,
        },
        severity: AttentionSeverity.warning,
        displayConfig: const {},
        resolutionActions: const ['dismissed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: now,
        updatedAt: now,
      );

      final attentionRepo = FakeAttentionRepository(rules: [rule]);
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final projectNextActionsRepository = FakeProjectNextActionsRepository();
      final invalidations = StreamController<void>.broadcast();
      addTearDown(invalidations.close);

      taskRepo.pushTasks([
        TestData.task(
          id: 't1',
          deadlineDate: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ]);

      final engine = AttentionEngine(
        attentionRepository: attentionRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        projectNextActionsRepository: projectNextActionsRepository,
        invalidations: invalidations.stream,
        clock: FakeClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;
      expect(items, isNotEmpty);
      expect(items.first.entityType, AttentionEntityType.task);
    });

    testSafe('suppresses items using runtime state', () async {
      final now = DateTime(2025, 1, 10, 12);
      final rule = AttentionRule(
        id: 'r2',
        ruleKey: 'overdue',
        bucket: AttentionBucket.action,
        evaluator: 'task_predicate_v1',
        evaluatorParams: const {
          'predicate': 'isStale',
          'thresholdDays': 0,
        },
        severity: AttentionSeverity.warning,
        displayConfig: const {},
        resolutionActions: const ['dismissed'],
        active: true,
        source: AttentionEntitySource.systemTemplate,
        createdAt: now,
        updatedAt: now,
      );

      final attentionRepo = FakeAttentionRepository(rules: [rule]);
      attentionRepo.setRuntimeStates(
        'r2',
        [
          AttentionRuleRuntimeState(
            id: 'rs1',
            ruleId: 'r2',
            createdAt: now,
            updatedAt: now,
            entityType: AttentionEntityType.task,
            entityId: 't1',
            nextEvaluateAfter: now.add(const Duration(days: 1)),
          ),
        ],
      );

      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final projectNextActionsRepository = FakeProjectNextActionsRepository();
      final invalidations = StreamController<void>.broadcast();
      addTearDown(invalidations.close);

      taskRepo.pushTasks([
        TestData.task(
          id: 't1',
          deadlineDate: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ]);

      final engine = AttentionEngine(
        attentionRepository: attentionRepo,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        projectNextActionsRepository: projectNextActionsRepository,
        invalidations: invalidations.stream,
        clock: FakeClock(now),
      );

      final items = await engine.watch(const AttentionQuery()).first;
      expect(items, isEmpty);
    });
  });
}
