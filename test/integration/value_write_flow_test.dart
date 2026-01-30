@Tags(['integration'])
library;

import 'dart:convert';

import 'package:async/async.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('value repository create/update emits stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');

    final valueRepository = ValueRepository(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );
    final queue = StreamQueue(valueRepository.watchAll());
    addTearDown(queue.cancel);

    final context = const OperationContext(
      correlationId: 'corr-1',
      feature: 'values',
      intent: 'test',
      operation: 'values.create',
    );

    await valueRepository.create(
      name: 'Health',
      color: '#00CC66',
      priority: ValuePriority.high,
      context: context,
    );

    List<Value>? created;
    while (created == null || created.isEmpty) {
      final next = await queue.next;
      if (next.isNotEmpty) {
        created = next;
      }
    }
    expect(created, hasLength(1));
    final valueId = created.single.id;

    await valueRepository.update(
      id: valueId,
      name: 'Health Updated',
      color: '#00CC66',
      priority: ValuePriority.low,
      context: context,
    );

    List<Value>? updated;
    while (updated == null ||
        !updated.any((value) => value.name == 'Health Updated')) {
      final next = await queue.next;
      if (next.any((value) => value.name == 'Health Updated')) {
        updated = next;
      }
    }
    expect(updated.single.name, 'Health Updated');

    final row = await db.select(db.valueTable).getSingle();
    final metadata = jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
    expect(metadata['cid'], context.correlationId);
  });

  testSafe('value repository delete removes value and emits stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');

    final valueRepository = ValueRepository(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );
    final queue = StreamQueue(valueRepository.watchAll());
    addTearDown(queue.cancel);

    await valueRepository.create(
      name: 'Delete Value',
      color: '#00CC66',
      priority: ValuePriority.high,
    );

    List<Value>? created;
    while (created == null || created.isEmpty) {
      final next = await queue.next;
      if (next.isNotEmpty) {
        created = next;
      }
    }
    final valueId = created.single.id;

    await valueRepository.delete(valueId);

    List<Value>? afterDelete;
    while (afterDelete == null || afterDelete.isNotEmpty) {
      final next = await queue.next;
      if (next.isEmpty) {
        afterDelete = next;
      }
    }
    expect(afterDelete, isEmpty);

    final removed = await valueRepository.watchById(valueId).firstWhere(
      (value) => value == null,
    );
    expect(removed, isNull);
  });

  testSafe('value repository rejects empty name', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');

    final valueRepository = ValueRepository(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    await expectLater(
      valueRepository.create(name: '', color: '#00CC66'),
      throwsA(isA<Exception>()),
    );
  });
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
