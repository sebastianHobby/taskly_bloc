/// Contract tests for ProjectRepositoryContract behavior.
///
/// These tests verify the minimal semantics that all
/// ProjectRepositoryContract implementations should follow.
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';

void main() {
  group('ProjectRepositoryContract (fake implementation)', () {
    late FakeProjectRepository repo;

    setUp(() {
      repo = FakeProjectRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    testContract('create -> getAll/getById returns created project', () async {
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
    });

    testContract('setPinned updates isPinned', () async {
      await repo.create(name: 'P1');
      final created = (await repo.getAll()).single;

      await repo.setPinned(id: created.id, isPinned: true);

      final updated = await repo.getById(created.id);
      expect(updated, isNotNull);
      expect(updated!.isPinned, isTrue);
    });

    testContract(
      'update mutates fields and preserves pinned semantics',
      () async {
        await repo.create(name: 'P1', completed: false);
        final created = (await repo.getAll()).single;

        await repo.update(
          id: created.id,
          name: 'P2',
          completed: true,
          description: 'new',
          isPinned: true,
        );

        final updated = await repo.getById(created.id);
        expect(updated, isNotNull);
        expect(updated!.name, 'P2');
        expect(updated.completed, isTrue);
        expect(updated.description, 'new');
        expect(updated.isPinned, isTrue);
      },
    );

    testContract('watchById emits updates and null after delete', () async {
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
    });

    testContract('watchAllCount reflects list size', () async {
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
    });
  });
}
