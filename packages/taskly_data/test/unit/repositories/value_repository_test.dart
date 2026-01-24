@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/value_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueRepository', () {
    testSafe('create normalizes color and uses deterministic id', () async {
      final db = createAutoClosingDb();
      final idGen = IdGenerator.withUserId('user-1');
      final repo = ValueRepository(driftDb: db, idGenerator: idGen);

      await repo.create(name: 'Health', color: 'ABCDEF');

      final row = await db.select(db.valueTable).getSingle();
      expect(row.id, equals(idGen.valueId(name: 'Health')));
      expect(row.color, equals('#ABCDEF'));
      expect(row.priority, equals(ValuePriority.medium));
    });

    testSafe('create rejects invalid color', () async {
      final db = createAutoClosingDb();
      final idGen = IdGenerator.withUserId('user-1');
      final repo = ValueRepository(driftDb: db, idGenerator: idGen);

      expect(
        () => repo.create(name: 'Bad', color: 'ZZZZZZ'),
        throwsA(isA<InputValidationFailure>()),
      );

      final rows = await db.select(db.valueTable).get();
      expect(rows, isEmpty);
    });

    testSafe('update throws when value not found', () async {
      final db = createAutoClosingDb();
      final idGen = IdGenerator.withUserId('user-1');
      final repo = ValueRepository(driftDb: db, idGenerator: idGen);

      expect(
        () => repo.update(
          id: 'missing',
          name: 'Missing',
          color: '#123456',
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    testSafe('update normalizes color and persists priority', () async {
      final db = createAutoClosingDb();
      final idGen = IdGenerator.withUserId('user-1');
      final repo = ValueRepository(driftDb: db, idGenerator: idGen);

      await repo.create(name: 'Focus', color: '112233');

      final id = idGen.valueId(name: 'Focus');
      await repo.update(
        id: id,
        name: 'Focus',
        color: '#334455',
        priority: ValuePriority.high,
        iconName: 'bolt',
      );

      final row = await db.select(db.valueTable).getSingle();
      expect(row.id, equals(id));
      expect(row.color, equals('#334455'));
      expect(row.priority, equals(ValuePriority.high));
      expect(row.iconName, equals('bolt'));
    });

    testSafe('watchAll sorts by priority then name', () async {
      final db = createAutoClosingDb();
      final repo = ValueRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db.into(db.valueTable).insert(
        ValueTableCompanion.insert(
          id: 'v-low',
          name: 'B',
          color: '#000000',
          priority: const drift.Value(ValuePriority.low),
        ),
      );
      await db.into(db.valueTable).insert(
        ValueTableCompanion.insert(
          id: 'v-high',
          name: 'C',
          color: '#000000',
          priority: const drift.Value(ValuePriority.high),
        ),
      );
      await db.into(db.valueTable).insert(
        ValueTableCompanion.insert(
          id: 'v-med',
          name: 'A',
          color: '#000000',
          priority: const drift.Value(ValuePriority.medium),
        ),
      );

      final values = await repo.watchAll().first;
      expect(
        values.map((v) => v.id).toList(),
        equals(['v-high', 'v-med', 'v-low']),
      );
    });

    testSafe('getAll applies filters', () async {
      final db = createAutoClosingDb();
      final repo = ValueRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Health', color: '#111111');
      await repo.create(name: 'Work', color: '#222222');

      final query = ValueQuery(
        filter: const QueryFilter<ValuePredicate>(
          shared: [
            ValueNamePredicate(
              operator: StringOperator.startsWith,
              value: 'Hea',
            ),
          ],
        ),
      );

      final values = await repo.getAll(query);
      expect(values.length, equals(1));
      expect(values.single.name, equals('Health'));
    });
  });
}
