/// Contract tests for TaskRepositoryContract behavior (Drift-backed).
///
/// Tagged as `repository` so it can be excluded from the `fast` preset.
library;

import '../../helpers/test_imports.dart';
import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';
import '../../mocks/repository_mocks.dart';

import 'package:taskly_data/repositories.dart';

void main() {
  group('TaskRepositoryContract (Drift TaskRepository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;
    late TaskRepository repo;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      occurrenceExpander = MockOccurrenceStreamExpanderContract();
      occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      repo = TaskRepository(
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
      'create -> getAll/getById returns created task',
      tags: 'repository',
      () async {
        await repo.create(
          name: 'A',
          description: 'desc',
          completed: false,
          priority: 2,
          repeatIcalRrule: 'FREQ=DAILY',
          repeatFromCompletion: true,
        );

        final all = await repo.getAll();
        expect(all, hasLength(1));

        final created = all.single;
        expect(created.name, 'A');
        expect(created.description, 'desc');
        expect(created.completed, isFalse);
        expect(created.priority, 2);
        expect(created.repeatIcalRrule, 'FREQ=DAILY');
        expect(created.repeatFromCompletion, isTrue);

        final byId = await repo.getById(created.id);
        expect(byId, isNotNull);
        expect(byId!.id, created.id);
      },
    );

    testContract(
      'getByIds preserves input order and omits missing',
      tags: 'repository',
      () async {
        await repo.create(name: 'A');
        await repo.create(name: 'B');

        final all = await repo.getAll();
        expect(all, hasLength(2));

        final a = all.firstWhere((t) => t.name == 'A');
        final b = all.firstWhere((t) => t.name == 'B');

        final results = await repo.getByIds([b.id, 'missing', a.id]);
        expect(results.map((t) => t.id).toList(), [b.id, a.id]);
      },
    );

    testContract(
      'watchById emits updates and null after delete',
      tags: 'repository',
      () async {
        await repo.create(name: 'A', completed: false);
        final created = (await repo.getAll()).single;

        final stream = repo.watchById(created.id);

        final initial = await stream
            .firstWhere((t) => t != null)
            .timeout(const Duration(seconds: 2));
        expect(initial!.name, 'A');

        await repo.update(
          id: created.id,
          name: 'B',
          completed: true,
        );

        final afterUpdate = await stream
            .firstWhere((t) => t?.name == 'B')
            .timeout(const Duration(seconds: 2));
        expect(afterUpdate!.completed, isTrue);

        await repo.delete(created.id);

        final afterDelete = await stream
            .firstWhere((t) => t == null)
            .timeout(const Duration(seconds: 2));
        expect(afterDelete, isNull);
      },
    );

    testContract(
      'watchAllCount reflects list size',
      tags: 'repository',
      () async {
        final counts = repo.watchAllCount();

        await repo.create(name: 'A');
        await repo.create(name: 'B');

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
