import 'dart:async';

import '../../../../helpers/test_imports.dart';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule_runtime_state.dart';
import 'package:taskly_bloc/domain/attention/query/attention_query.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';

class _FakeAttentionEngine implements AttentionEngineContract {
  _FakeAttentionEngine({
    required this.action,
    required this.review,
  });

  final BehaviorSubject<List<AttentionItem>> action;
  final BehaviorSubject<List<AttentionItem>> review;

  @override
  Stream<List<AttentionItem>> watch(AttentionQuery query) {
    final buckets = query.buckets ?? const <AttentionBucket>{};
    if (buckets.contains(AttentionBucket.action)) return action.stream;
    if (buckets.contains(AttentionBucket.review)) return review.stream;
    return const Stream<List<AttentionItem>>.empty();
  }
}

class _FakeAttentionRepository implements AttentionRepositoryContract {
  final recorded = <AttentionResolution>[];

  @override
  Future<void> recordResolution(AttentionResolution resolution) async {
    recorded.add(resolution);
  }

  @override
  Stream<List<AttentionRule>> watchAllRules() => throw UnimplementedError();

  @override
  Stream<List<AttentionRule>> watchActiveRules() => throw UnimplementedError();

  @override
  Stream<List<AttentionRule>> watchRulesByBucket(AttentionBucket bucket) =>
      throw UnimplementedError();

  @override
  Stream<List<AttentionRule>> watchRulesByBuckets(
    List<AttentionBucket> buckets,
  ) => throw UnimplementedError();

  @override
  Future<AttentionRule?> getRuleById(String id) => throw UnimplementedError();

  @override
  Future<AttentionRule?> getRuleByKey(String ruleKey) =>
      throw UnimplementedError();

  @override
  Future<void> upsertRule(AttentionRule rule) => throw UnimplementedError();

  @override
  Future<void> updateRuleActive(String ruleId, bool active) =>
      throw UnimplementedError();

  @override
  Future<void> updateRuleEvaluatorParams(
    String ruleId,
    Map<String, dynamic> evaluatorParams,
  ) => throw UnimplementedError();

  @override
  Future<void> updateRuleSeverity(String ruleId, AttentionSeverity severity) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRule(String ruleId) => throw UnimplementedError();

  @override
  Stream<List<AttentionResolution>> watchResolutionsForRule(String ruleId) =>
      throw UnimplementedError();

  @override
  Stream<List<AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    AttentionEntityType entityType,
  ) => throw UnimplementedError();

  @override
  Future<AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  ) => throw UnimplementedError();

  @override
  Stream<List<AttentionRuleRuntimeState>> watchRuntimeStateForRule(
    String ruleId,
  ) => throw UnimplementedError();

  @override
  Future<AttentionRuleRuntimeState?> getRuntimeState({
    required String ruleId,
    required AttentionEntityType? entityType,
    required String? entityId,
  }) => throw UnimplementedError();

  @override
  Future<void> upsertRuntimeState(AttentionRuleRuntimeState state) =>
      throw UnimplementedError();
}

AttentionItem _item({
  required String id,
  required AttentionBucket bucket,
  required AttentionSeverity severity,
  required AttentionEntityType entityType,
  required String title,
  Map<String, dynamic>? metadata,
  DateTime? detectedAt,
}) {
  final now = detectedAt ?? DateTime.utc(2026, 1, 1);
  return AttentionItem(
    id: id,
    ruleId: 'rule-$id',
    ruleKey: 'rule_key_$id',
    bucket: bucket,
    entityId: 'entity-$id',
    entityType: entityType,
    severity: severity,
    title: title,
    description: 'desc $title',
    availableActions: const [
      AttentionResolutionAction.reviewed,
      AttentionResolutionAction.skipped,
      AttentionResolutionAction.snoozed,
      AttentionResolutionAction.dismissed,
    ],
    detectedAt: now,
    metadata: metadata,
  );
}

Future<AttentionInboxLoaded> _nextLoaded(AttentionInboxBloc bloc) async {
  final state = bloc.state;
  if (state is AttentionInboxLoaded) return state;

  return bloc.stream
      .where((s) => s is AttentionInboxLoaded)
      .cast<AttentionInboxLoaded>()
      .first
      .timeout(const Duration(seconds: 2));
}

void main() {
  group('AttentionInboxBloc', () {
    testSafe('loads items and applies filter changes', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      await _nextLoaded(bloc);

      final a1 = _item(
        id: 'a1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.info,
        entityType: AttentionEntityType.task,
        title: 'Info item',
      );
      final a2 = _item(
        id: 'a2',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.critical,
        entityType: AttentionEntityType.project,
        title: 'Critical item',
      );

      action$.add([a1, a2]);

      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 2);

      bloc.add(
        const AttentionInboxEvent.minSeverityChanged(
          minSeverity: AttentionSeverity.warning,
        ),
      );

      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 1);
      expect(
        loaded.groups
            .expand((g) => g.entities)
            .expand((e) => e.reasons)
            .single
            .item
            .id,
        'a2',
      );

      bloc.add(
        const AttentionInboxEvent.entityTypeToggled(
          entityType: AttentionEntityType.project,
        ),
      );
      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 1);

      bloc.add(
        const AttentionInboxEvent.searchQueryChanged(query: 'no-match'),
      );
      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 0);
    });

    testSafe('applyAction -> undo restores hidden items', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      final a1 = _item(
        id: 'a1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.warning,
        entityType: AttentionEntityType.task,
        title: 'Item 1',
      );

      action$.add([a1]);
      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 1);

      bloc.add(
        AttentionInboxEvent.applyActionToItem(
          itemKey: loaded.groups.single.entities.single.reasons.single.key,
          action: AttentionResolutionAction.reviewed,
        ),
      );

      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 0);
      expect(loaded.pendingUndo, isNotNull);

      final undoId = loaded.pendingUndo!.undoId;
      bloc.add(AttentionInboxEvent.undoRequested(undoId: undoId));

      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 1);
      expect(loaded.pendingUndo, isNull);
      expect(repo.recorded, isEmpty);
    });

    testSafe('commitPending records resolutions and clears undo', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      final dismissable = _item(
        id: 'a1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.warning,
        entityType: AttentionEntityType.task,
        title: 'Dismissable',
        metadata: const {'state_hash': 'hash1'},
      );

      final notDismissable = _item(
        id: 'a2',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.warning,
        entityType: AttentionEntityType.task,
        title: 'Not dismissable',
      );

      action$.add([dismissable, notDismissable]);
      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 2);

      final reasons = loaded.groups
          .expand((g) => g.entities)
          .expand((e) => e.reasons);

      final dismissableKey = reasons.firstWhere((r) => r.item.id == 'a1').key;
      final notDismissableKey = reasons
          .firstWhere((r) => r.item.id == 'a2')
          .key;

      bloc.add(AttentionInboxEvent.toggleSelected(itemKey: dismissableKey));
      bloc.add(AttentionInboxEvent.toggleSelected(itemKey: notDismissableKey));
      await _nextLoaded(bloc);

      bloc.add(
        const AttentionInboxEvent.applyActionToSelection(
          action: AttentionResolutionAction.dismissed,
        ),
      );

      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 0);
      final undoId = loaded.pendingUndo!.undoId;

      bloc.add(AttentionInboxEvent.commitPending(undoId: undoId));

      loaded = await _nextLoaded(bloc);
      expect(loaded.pendingUndo, isNull);

      // Only the item with a state_hash can be dismissed.
      expect(repo.recorded, hasLength(1));
      expect(
        repo.recorded.single.resolutionAction,
        AttentionResolutionAction.dismissed,
      );
      expect(
        repo.recorded.single.actionDetails,
        containsPair('state_hash', 'hash1'),
      );
    });

    testSafe('applyActionToVisible respects filters', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      final info = _item(
        id: 'i1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.info,
        entityType: AttentionEntityType.task,
        title: 'Info',
      );
      final warning = _item(
        id: 'w1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.warning,
        entityType: AttentionEntityType.task,
        title: 'Warning',
      );
      final critical = _item(
        id: 'c1',
        bucket: AttentionBucket.action,
        severity: AttentionSeverity.critical,
        entityType: AttentionEntityType.project,
        title: 'Critical',
      );

      action$.add([info, warning, critical]);
      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 3);

      bloc.add(
        const AttentionInboxEvent.minSeverityChanged(
          minSeverity: AttentionSeverity.warning,
        ),
      );
      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 2);

      bloc.add(
        const AttentionInboxEvent.applyActionToVisible(
          action: AttentionResolutionAction.reviewed,
        ),
      );

      loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 0);
      expect(loaded.pendingUndo, isNotNull);
      expect(loaded.pendingUndo!.count, 2);

      final undoId = loaded.pendingUndo!.undoId;
      bloc.add(AttentionInboxEvent.commitPending(undoId: undoId));
      loaded = await _nextLoaded(bloc);

      expect(loaded.pendingUndo, isNull);
      expect(repo.recorded, hasLength(2));
      expect(
        repo.recorded.map((r) => r.resolutionAction).toSet(),
        {AttentionResolutionAction.reviewed},
      );
    });

    testSafe('groupBy severity groups and titles are stable', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      action$.add([
        _item(
          id: 'a',
          bucket: AttentionBucket.action,
          severity: AttentionSeverity.warning,
          entityType: AttentionEntityType.task,
          title: 'B',
        ),
        _item(
          id: 'b',
          bucket: AttentionBucket.action,
          severity: AttentionSeverity.info,
          entityType: AttentionEntityType.task,
          title: 'A',
        ),
        _item(
          id: 'c',
          bucket: AttentionBucket.action,
          severity: AttentionSeverity.critical,
          entityType: AttentionEntityType.project,
          title: 'C',
        ),
      ]);

      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 3);

      bloc.add(
        const AttentionInboxEvent.groupByChanged(
          groupBy: AttentionInboxGroupBy.severity,
        ),
      );

      loaded = await _nextLoaded(bloc);
      final titles = loaded.groups.map((g) => g.title).toList();
      expect(titles, ['CRITICAL', 'INFO', 'WARNING']);
      expect(
        loaded.groups
            .expand((g) => g.entities)
            .expand((e) => e.reasons)
            .map((r) => r.item.id)
            .toSet(),
        {'a', 'b', 'c'},
      );
    });

    testSafe('sort titleAsc sorts case-insensitively', () async {
      final action$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      final review$ = BehaviorSubject<List<AttentionItem>>.seeded(
        const <AttentionItem>[],
      );
      addTearDown(action$.close);
      addTearDown(review$.close);

      final engine = _FakeAttentionEngine(action: action$, review: review$);
      final repo = _FakeAttentionRepository();
      final idGen = IdGenerator.withUserId('u');

      final bloc = AttentionInboxBloc(
        engine: engine,
        repository: repo,
        idGenerator: idGen,
        undoWindow: const Duration(days: 1),
      );
      addTearDown(bloc.close);

      action$.add([
        _item(
          id: 'b',
          bucket: AttentionBucket.action,
          severity: AttentionSeverity.info,
          entityType: AttentionEntityType.task,
          title: 'bravo',
        ),
        _item(
          id: 'a',
          bucket: AttentionBucket.action,
          severity: AttentionSeverity.info,
          entityType: AttentionEntityType.task,
          title: 'Alpha',
        ),
      ]);

      var loaded = await _nextLoaded(bloc);
      expect(loaded.totalVisibleCount, 2);

      bloc.add(
        const AttentionInboxEvent.sortChanged(
          sort: AttentionInboxSort.titleAsc,
        ),
      );
      loaded = await _nextLoaded(bloc);

      final ordered = loaded.groups.single.entities
          .map((e) => e.headline.item.title)
          .toList();
      expect(ordered, ['Alpha', 'bravo']);
    });
  });
}
