import '../../helpers/test_imports.dart';
import 'package:taskly_data/repositories.dart';

import '../../helpers/base_repository_helpers.dart';
import '../../mocks/fake_id_generator.dart';
import '../../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskRepository (repository)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;

    late ValueRepository valueRepo;
    late ProjectRepository projectRepo;
    late TaskRepository taskRepo;

    setUp(() {
      ctx = RepositoryTestContext();
      addTearDown(ctx.dispose);
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
      taskRepo = TaskRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
    });

    test(
      'create persists and getById loads project and values',
      tags: 'repository',
      () async {
        await valueRepo.create(
          name: 'Health',
          color: '#00FF00',
          priority: ValuePriority.medium,
        );
        const projectValueId = 'value-health';

        await valueRepo.create(
          name: 'Urgent',
          color: '#FF0000',
          priority: ValuePriority.high,
        );
        const valueId = 'value-urgent';

        await projectRepo.create(
          name: 'My Project',
          valueIds: [projectValueId],
        );
        const projectId = 'project-0';

        final start = DateTime(2025, 1, 2, 13, 45);
        final deadline = DateTime(2025, 1, 5, 23, 59);

        await taskRepo.create(
          name: 'My Task',
          startDate: start,
          deadlineDate: deadline,
          projectId: projectId,
          valueIds: [valueId],
        );
        const taskId = 'task-0';

        final loaded = await taskRepo.getById(taskId);
        expect(loaded, isNotNull);

        expect(loaded!.id, taskId);
        expect(loaded.name, 'My Task');
        expect(loaded.projectId, projectId);
        expect(loaded.project, isNotNull);
        expect(loaded.project!.id, projectId);
        expect(
          loaded.project!.values.map((v) => v.id),
          contains(projectValueId),
        );
        expect(loaded.project!.primaryValueId, projectValueId);

        expect(loaded.values, hasLength(1));
        expect(loaded.values.single.id, valueId);
        expect(loaded.overridePrimaryValueId, valueId);

        expect(loaded.startDate, dateOnly(start));
        expect(loaded.deadlineDate, dateOnly(deadline));
      },
    );

    test(
      'getAll returns created task',
      tags: 'repository',
      () async {
        await taskRepo.create(name: 'One');
        await taskRepo.create(name: 'Two');

        final tasks = await taskRepo.getAll();
        expect(tasks.map((t) => t.name), containsAll(['One', 'Two']));
      },
    );
  });
}
