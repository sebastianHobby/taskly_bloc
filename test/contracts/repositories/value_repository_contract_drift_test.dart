/// Contract tests for ValueRepositoryContract behavior (Drift-backed).
///
/// Tagged as `repository` so it can be excluded from the `fast` preset.
library;

import '../../helpers/test_imports.dart';
import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';

import 'package:taskly_data/repositories.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('ValueRepositoryContract (Drift ValueRepository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late ValueRepository repo;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();

      repo = ValueRepository(
        driftDb: ctx.db,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    testContract(
      'create -> getAll/getById returns created value',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'Urgent',
          color: '#FF0000',
          iconName: 'alarm',
          priority: ValuePriority.high,
        );

        final all = await repo.getAll();
        expect(all, hasLength(1));

        final created = all.single;
        expect(created.name, 'Urgent');
        expect(created.color, '#FF0000');
        expect(created.iconName, 'alarm');
        expect(created.priority, ValuePriority.high);

        final byId = await repo.getById(created.id);
        expect(byId, isNotNull);
        expect(byId!.id, created.id);
      },
    );

    testContract(
      'update mutates fields',
      tags: 'repository',
      () async {
        await repo.create(name: 'Urgent', color: '#FF0000');
        final created = (await repo.getAll()).single;

        await repo.update(
          id: created.id,
          name: 'Chill',
          color: '#00FF00',
          iconName: 'leaf',
          priority: ValuePriority.low,
        );

        final updated = await repo.getById(created.id);
        expect(updated, isNotNull);
        expect(updated!.name, 'Chill');
        expect(updated.color, '#00FF00');
        expect(updated.iconName, 'leaf');
        expect(updated.priority, ValuePriority.low);
      },
    );

    testContract(
      'watchById emits updates and null after delete',
      tags: 'repository',
      () async {
        await repo.create(name: 'Urgent', color: '#FF0000');
        final created = (await repo.getAll()).single;

        final stream = repo.watchById(created.id);

        final initial = await stream
            .firstWhere((v) => v != null)
            .timeout(const Duration(seconds: 2));
        expect(initial!.name, 'Urgent');

        await repo.update(
          id: created.id,
          name: 'Chill',
          color: '#00FF00',
        );

        final afterUpdate = await stream
            .firstWhere((v) => v?.name == 'Chill')
            .timeout(const Duration(seconds: 2));
        expect(afterUpdate, isNotNull);

        await repo.delete(created.id);

        final afterDelete = await stream
            .firstWhere((v) => v == null)
            .timeout(const Duration(seconds: 2));
        expect(afterDelete, isNull);
      },
    );

    testContract(
      'getValuesByIds omits missing ids',
      tags: 'repository',
      () async {
        await repo.create(name: 'A', color: '#111111');
        await repo.create(name: 'B', color: '#222222');

        final all = await repo.getAll();
        final a = all.firstWhere((v) => v.name == 'A');
        final b = all.firstWhere((v) => v.name == 'B');

        final results = await repo.getValuesByIds([a.id, 'missing', b.id]);
        expect(results.map((v) => v.id).toSet(), {a.id, b.id});
      },
    );
  });
}
