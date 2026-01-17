import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_data/repositories.dart';

import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';
import '../../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('ProjectRepository (repository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;

    late ValueRepository valueRepo;
    late ProjectRepository projectRepo;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      occurrenceExpander = MockOccurrenceStreamExpanderContract();
      occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      valueRepo = ValueRepository(driftDb: ctx.db, idGenerator: idGenerator);
      projectRepo = ProjectRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    test(
      'create persists and getById loads values',
      tags: 'repository',
      () async {
        await valueRepo.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
        const valueId = 'value-health';

        final start = DateTime(2025, 2, 10, 13, 45);
        final deadline = DateTime(2025, 2, 11, 23, 59);

        await projectRepo.create(
          name: 'My Project',
          startDate: start,
          deadlineDate: deadline,
          valueIds: [valueId],
        );
        const projectId = 'project-0';

        final loaded = await projectRepo.getById(projectId);
        expect(loaded, isNotNull);

        expect(loaded!.id, projectId);
        expect(loaded.name, 'My Project');
        expect(loaded.completed, isFalse);

        expect(loaded.values, hasLength(1));
        expect(loaded.values.single.id, valueId);
        expect(loaded.primaryValueId, valueId);
        expect(loaded.primaryValue, isNotNull);
        expect(loaded.primaryValue!.id, valueId);

        expect(loaded.startDate, dateOnly(start));
        expect(loaded.deadlineDate, dateOnly(deadline));
      },
    );

    test(
      'update replaces value relationships',
      tags: 'repository',
      () async {
        await valueRepo.create(
          name: 'Work',
          color: '#FF0000',
          priority: ValuePriority.high,
        );
        await valueRepo.create(
          name: 'Family',
          color: '#0000FF',
          priority: ValuePriority.low,
        );
        const workId = 'value-work';
        const familyId = 'value-family';

        await projectRepo.create(
          name: 'My Project',
          valueIds: [workId],
        );
        const projectId = 'project-0';

        await projectRepo.update(
          id: projectId,
          name: 'My Project',
          completed: false,
          valueIds: [familyId],
        );

        final loaded = await projectRepo.getById(projectId);
        expect(loaded, isNotNull);
        expect(loaded!.values, hasLength(1));
        expect(loaded.values.single.id, familyId);
      },
    );
  });
}
