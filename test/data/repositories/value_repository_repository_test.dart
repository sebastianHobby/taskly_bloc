import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';

import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';

void main() {
  group('ValueRepository (repository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late ValueRepository repo;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      repo = ValueRepository(driftDb: ctx.db, idGenerator: idGenerator);
    });

    tearDown(() async {
      await ctx.dispose();
    });

    test(
      'create + getById returns persisted value',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.high,
        );

        final value = await repo.getById('value-health');
        expect(value, isNotNull);
        expect(value!.name, 'Health');
        expect(value.color, '#00FF00');
        expect(value.priority, ValuePriority.high);
      },
    );

    test(
      'getAll orders by priority desc then name asc',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'Alpha',
          color: '#111111',
          priority: ValuePriority.low,
        );
        await repo.create(
          name: 'Zulu',
          color: '#222222',
          priority: ValuePriority.high,
        );
        await repo.create(
          name: 'Bravo',
          color: '#333333',
          priority: ValuePriority.high,
        );

        final values = await repo.getAll();
        expect(values.map((v) => v.name).toList(), ['Bravo', 'Zulu', 'Alpha']);
      },
    );

    test(
      'filtering via ValueQuery.search works in SQL',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
        await repo.create(
          name: 'Work',
          color: '#FF0000',
          priority: ValuePriority.medium,
        );

        final results = await repo.getAll(ValueQuery.search('hea'));
        expect(results, hasLength(1));
        expect(results.single.name, 'Health');
      },
    );
  });
}
