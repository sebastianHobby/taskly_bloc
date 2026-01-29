@Tags(['integration'])
library;

import 'dart:convert';

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

    final created = await valueRepository.watchAll().firstWhere(
      (values) => values.isNotEmpty,
    );
    expect(created, hasLength(1));
    final valueId = created.single.id;

    await valueRepository.update(
      id: valueId,
      name: 'Health Updated',
      color: '#00CC66',
      priority: ValuePriority.low,
      context: context,
    );

    final updated = await valueRepository.watchAll().firstWhere(
      (values) => values.any((v) => v.name == 'Health Updated'),
    );
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

    await valueRepository.create(
      name: 'Delete Value',
      color: '#00CC66',
      priority: ValuePriority.high,
    );

    final created = await valueRepository.watchAll().firstWhere(
      (values) => values.isNotEmpty,
    );
    final valueId = created.single.id;

    await valueRepository.delete(valueId);

    final afterDelete = await valueRepository.watchAll().firstWhere(
      (values) => values.isEmpty,
    );
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
