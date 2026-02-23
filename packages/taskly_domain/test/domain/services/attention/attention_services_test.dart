@Tags(['unit'])
library;

import 'dart:async';

import '../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_domain/src/attention/engine/cached_attention_engine.dart';
import 'package:taskly_domain/src/services/notifications/pending_notifications_processor.dart';
import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/interfaces/pending_notifications_repository_contract.dart';

class _RecordingEngine implements AttentionEngineContract {
  _RecordingEngine(this._builder);

  final Stream<List<AttentionItem>> Function(AttentionQuery query) _builder;
  final List<AttentionQuery> calls = <AttentionQuery>[];

  @override
  Stream<List<AttentionItem>> watch(AttentionQuery query) {
    calls.add(query);
    return _builder(query);
  }
}

class _MockAttentionRepository extends Mock
    implements AttentionRepositoryContract {}

class _FakeResolution extends Fake implements AttentionResolution {}

class _MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

class _MockPendingNotificationsRepository extends Mock
    implements PendingNotificationsRepositoryContract {}

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime nowLocal() => _now.toLocal();
  @override
  DateTime nowUtc() => _now;
}

PendingNotification _pending({
  required String id,
  required DateTime scheduledFor,
}) {
  return PendingNotification(
    id: id,
    userId: 'u1',
    screenKey: 'inbox',
    scheduledFor: scheduledFor,
    status: 'pending',
    payload: const <String, dynamic>{'x': 1},
    createdAt: DateTime.utc(2026, 1, 1),
    deliveredAt: null,
    seenAt: null,
  );
}

AttentionItem _attentionItem({
  required String id,
  Map<String, dynamic>? metadata,
}) {
  return AttentionItem(
    id: id,
    ruleId: 'rule1',
    ruleKey: 'rule_key',
    bucket: AttentionBucket.action,
    entityId: 'entity_$id',
    entityType: AttentionEntityType.task,
    severity: AttentionSeverity.info,
    title: 'Title $id',
    description: 'Description',
    availableActions: const [AttentionResolutionAction.reviewed],
    detectedAt: DateTime.utc(2026, 1, 1),
    metadata: metadata,
  );
}

void main() {
  setUpAll(() {
    initializeLoggingForTest();
    registerFallbackValue(_FakeResolution());
    registerFallbackValue(
      const OperationContext(
        correlationId: 'c1',
        feature: 'test',
        intent: 'test',
        operation: 'test.op',
      ),
    );
  });

  group('CachedAttentionEngine', () {
    testSafe('caches equivalent queries and supports invalidation', () async {
      final inner = _RecordingEngine(
        (_) => Stream.value(const <AttentionItem>[]),
      );
      final cached = CachedAttentionEngine(inner: inner);

      final q1 = AttentionQuery(
        buckets: const {AttentionBucket.action, AttentionBucket.review},
        entityTypes: const {AttentionEntityType.task},
      );
      final q2 = AttentionQuery(
        buckets: const {AttentionBucket.review, AttentionBucket.action},
        entityTypes: const {AttentionEntityType.task},
      );

      await cached.watch(q1).first;
      await cached.watch(q2).first;
      expect(inner.calls, hasLength(1));

      cached.invalidate(q1);
      await cached.watch(q2).first;
      expect(inner.calls, hasLength(2));

      cached.invalidateAll();
      await cached.watch(q2).first;
      expect(inner.calls, hasLength(3));
    });

    testSafe('evicts cache entry when upstream errors', () async {
      var calls = 0;
      final inner = _RecordingEngine((_) {
        calls++;
        return Stream<List<AttentionItem>>.error(StateError('boom'));
      });
      final cached = CachedAttentionEngine(inner: inner);
      final query = const AttentionQuery();

      await expectLater(cached.watch(query), emitsError(isA<StateError>()));
      await expectLater(cached.watch(query), emitsError(isA<StateError>()));

      expect(calls, 2);
    });
  });

  group('AttentionResolutionService', () {
    late _MockAttentionRepository repository;
    late AttentionResolutionService service;
    var idCounter = 0;

    setUp(() {
      repository = _MockAttentionRepository();
      idCounter = 0;
      when(
        () => repository.recordResolution(any(), context: null),
      ).thenAnswer((_) async {});
      service = AttentionResolutionService(
        repository: repository,
        newResolutionId: () => 'res-${++idCounter}',
      );
    });

    testSafe('returns 0 when no items provided', () async {
      final count = await service.applyAction(
        action: AttentionResolutionAction.reviewed,
        items: const <AttentionItem>[],
        nowUtc: DateTime.utc(2026, 1, 1),
      );
      expect(count, 0);
      verifyNever(() => repository.recordResolution(any(), context: null));
    });

    testSafe('skips dismissed items without state_hash metadata', () async {
      final count = await service.applyAction(
        action: AttentionResolutionAction.dismissed,
        items: [_attentionItem(id: 'a1')],
        nowUtc: DateTime.utc(2026, 1, 1),
      );
      expect(count, 0);
      verifyNever(() => repository.recordResolution(any(), context: null));
    });

    testSafe('records snoozed action with computed details', () async {
      final count = await service.applyAction(
        action: AttentionResolutionAction.snoozed,
        items: [
          _attentionItem(id: 'a1'),
          _attentionItem(id: 'a2'),
        ],
        nowUtc: DateTime.utc(2026, 1, 1),
        snoozeDuration: const Duration(hours: 6),
      );
      expect(count, 2);
      verify(() => repository.recordResolution(any(), context: null)).called(2);
    });

    testSafe(
      'recordReviewedWithDetails returns created resolution id',
      () async {
        final id = await service.recordReviewedWithDetails(
          item: _attentionItem(id: 'a3'),
          nowUtc: DateTime.utc(2026, 1, 1),
          actionDetails: const <String, dynamic>{'k': 'v'},
        );

        expect(id, 'res-1');
        verify(
          () => repository.recordResolution(any(), context: null),
        ).called(1);
      },
    );
  });

  group('AttentionPrewarmService', () {
    testSafe('starts once, subscribes common queries, and stops', () async {
      final engine = _RecordingEngine(
        (_) => Stream<List<AttentionItem>>.value(const <AttentionItem>[]),
      );
      final service = AttentionPrewarmService(engine: engine);

      service.start();
      service.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(engine.calls.length, 4);

      await service.stop();
      await service.dispose();
    });
  });

  group('AttentionTemporalInvalidationService', () {
    testSafe(
      'emits initial invalidation and pulses on trigger events',
      () async {
        final trigger = _MockTemporalTriggerService();
        final controller = StreamController<TemporalTriggerEvent>.broadcast();
        addTearDown(controller.close);
        when(() => trigger.events).thenAnswer((_) => controller.stream);

        final service = AttentionTemporalInvalidationService(
          temporalTriggerService: trigger,
        );

        final emissions = service.invalidations.take(3).toList();
        service.start();
        controller.add(const AppResumed());
        controller.add(
          HomeDayBoundaryCrossed(newDayKeyUtc: DateTime.utc(2026, 1, 2)),
        );

        expect((await emissions).length, 3);
        service.stop();
        await service.dispose();
      },
    );
  });

  group('PendingNotificationsProcessor', () {
    testSafe('delivers due items and marks them delivered', () async {
      final repository = _MockPendingNotificationsRepository();
      final watch = StreamController<List<PendingNotification>>.broadcast();
      addTearDown(watch.close);

      when(() => repository.watchPending()).thenAnswer((_) => watch.stream);
      when(
        () => repository.markDelivered(
          id: any(named: 'id'),
          deliveredAt: any(named: 'deliveredAt'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final delivered = <String>[];
      final processor = PendingNotificationsProcessor(
        repository: repository,
        presenter: (notification) async {
          delivered.add(notification.id);
        },
        clock: _FixedClock(DateTime.utc(2026, 1, 1, 12)),
      );

      processor.start();
      watch.add([
        _pending(id: 'due', scheduledFor: DateTime.utc(2026, 1, 1, 11)),
        _pending(id: 'future', scheduledFor: DateTime.utc(2026, 1, 1, 13)),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(delivered, ['due']);
      verify(
        () => repository.markDelivered(
          id: 'due',
          deliveredAt: any(named: 'deliveredAt'),
          context: any(named: 'context'),
        ),
      ).called(1);

      await processor.stop();
    });

    testSafe('handles presenter errors without marking delivered', () async {
      final repository = _MockPendingNotificationsRepository();
      final watch = StreamController<List<PendingNotification>>.broadcast();
      addTearDown(watch.close);

      when(() => repository.watchPending()).thenAnswer((_) => watch.stream);
      when(
        () => repository.markDelivered(
          id: any(named: 'id'),
          deliveredAt: any(named: 'deliveredAt'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final processor = PendingNotificationsProcessor(
        repository: repository,
        presenter: (_) async => throw StateError('presenter failed'),
        clock: _FixedClock(DateTime.utc(2026, 1, 1, 12)),
      );

      processor.start();
      watch.add([
        _pending(id: 'due', scheduledFor: DateTime.utc(2026, 1, 1, 11)),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      verifyNever(
        () => repository.markDelivered(
          id: any(named: 'id'),
          deliveredAt: any(named: 'deliveredAt'),
          context: any(named: 'context'),
        ),
      );

      await processor.stop();
    });
  });
}
