/// Contract tests for ProjectRepositoryContract behavior (Drift-backed).
///
/// Tagged as `repository` so it can be excluded from the `fast` preset.
library;

import '../../helpers/test_imports.dart';
import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';
import '../../mocks/repository_mocks.dart';

import 'package:taskly_data/repositories.dart';

void main() {
  group('ProjectRepositoryContract (Drift ProjectRepository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;
    late ProjectRepository repo;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      occurrenceExpander = MockOccurrenceStreamExpanderContract();
      occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      repo = ProjectRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    testContract(
      'create -> getAll/getById returns created project',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'P1',
          description: 'desc',
          completed: false,
          priority: 2,
          repeatIcalRrule: 'FREQ=DAILY',
          repeatFromCompletion: true,
        );

        final all = await repo.getAll();
        expect(all, hasLength(1));

        final created = all.single;
        expect(created.name, 'P1');
        expect(created.description, 'desc');
        expect(created.completed, isFalse);
        expect(created.priority, 2);
        expect(created.repeatIcalRrule, 'FREQ=DAILY');
        expect(created.repeatFromCompletion, isTrue);
        expect(created.isPinned, isFalse);

        final byId = await repo.getById(created.id);
        expect(byId, isNotNull);
        expect(byId!.id, created.id);
      },
    );

    testContract(
      'setPinned updates isPinned',
      tags: 'repository',
      () async {
        await repo.create(name: 'P1');
        final created = (await repo.getAll()).single;

        await repo.setPinned(id: created.id, isPinned: true);

        final updated = await repo.getById(created.id);
        expect(updated, isNotNull);
        expect(updated!.isPinned, isTrue);
      },
    );

    testContract(
      'watchById emits updates and null after delete',
      tags: 'repository',
      () async {
        await repo.create(name: 'P1', completed: false);
        final created = (await repo.getAll()).single;

        final stream = repo.watchById(created.id);

        final initial = await stream
            .firstWhere((p) => p != null)
            .timeout(const Duration(seconds: 2));
        expect(initial!.name, 'P1');

        await repo.update(
          id: created.id,
          name: 'P2',
          completed: true,
        );

        final afterUpdate = await stream
            .firstWhere((p) => p?.name == 'P2')
            .timeout(const Duration(seconds: 2));
        expect(afterUpdate!.completed, isTrue);

        await repo.delete(created.id);

        final afterDelete = await stream
            .firstWhere((p) => p == null)
            .timeout(const Duration(seconds: 2));
        expect(afterDelete, isNull);
      },
    );

    testContract(
      'watchAllCount reflects list size',
      tags: 'repository',
      () async {
        final counts = repo.watchAllCount();

        await repo.create(name: 'P1');
        await repo.create(name: 'P2');

        final count2 = await counts
            .firstWhere((c) => c == 2)
            .timeout(const Duration(seconds: 2));
        expect(count2, 2);

        final all = await repo.getAll();
        await repo.delete(all.first.id);

        final count1 = await counts
            .firstWhere((c) => c == 1)
            .timeout(const Duration(seconds: 2));
        expect(count1, 1);
      },
    );
  });
}
