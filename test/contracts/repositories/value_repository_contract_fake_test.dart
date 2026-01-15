/// Contract tests for ValueRepositoryContract behavior.
///
/// These tests verify the minimal semantics that all
/// ValueRepositoryContract implementations should follow.
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

void main() {
  group('ValueRepositoryContract (fake implementation)', () {
    late FakeValueRepository repo;

    setUp(() {
      repo = FakeValueRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    testContract('create -> getAll/getById returns created value', () async {
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
    });

    testContract('update mutates fields', () async {
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
    });

    testContract('watchById emits updates and null after delete', () async {
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
    });

    testContract('getValuesByIds omits missing ids', () async {
      await repo.create(name: 'A', color: '#111111');
      await repo.create(name: 'B', color: '#222222');

      final all = await repo.getAll();
      final a = all.firstWhere((v) => v.name == 'A');
      final b = all.firstWhere((v) => v.name == 'B');

      final results = await repo.getValuesByIds([a.id, 'missing', b.id]);
      expect(results.map((v) => v.id).toSet(), {a.id, b.id});
    });
  });
}
