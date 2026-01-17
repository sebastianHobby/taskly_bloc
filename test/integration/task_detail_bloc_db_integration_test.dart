import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../helpers/base_repository_helpers.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('TaskDetailBloc (integration)', () {
    late RepositoryTestContext ctx;
    late FakeIdGenerator idGenerator;
    late MockOccurrenceStreamExpanderContract occurrenceExpander;
    late MockOccurrenceWriteHelperContract occurrenceWriteHelper;

    late ValueRepository valueRepository;
    late ProjectRepository projectRepository;
    late TaskRepository taskRepository;

    setUp(() {
      ctx = RepositoryTestContext();
      idGenerator = FakeIdGenerator();
      occurrenceExpander = MockOccurrenceStreamExpanderContract();
      occurrenceWriteHelper = MockOccurrenceWriteHelperContract();

      valueRepository = ValueRepository(
        driftDb: ctx.db,
        idGenerator: idGenerator,
      );
      projectRepository = ProjectRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
      taskRepository = TaskRepository(
        driftDb: ctx.db,
        occurrenceExpander: occurrenceExpander,
        occurrenceWriteHelper: occurrenceWriteHelper,
        idGenerator: idGenerator,
      );
    });

    tearDown(() async {
      await ctx.dispose();
    });

    blocTest<TaskDetailBloc, TaskDetailState>(
      'loadById loads task plus available projects/values from Drift',
      tags: 'integration',
      setUp: () async {
        await valueRepository.create(
          name: 'Urgent',
          color: '#FF0000',
          priority: ValuePriority.high,
        );
        await projectRepository.create(
          name: 'My Project',
          valueIds: const ['value-urgent'],
        );

        await taskRepository.create(
          name: 'My Task',
          description: 'Hello',
          projectId: 'project-0',
          valueIds: const ['value-urgent'],
        );
      },
      build: () => TaskDetailBloc(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        autoLoad: false,
      ),
      act: (bloc) => bloc.add(const TaskDetailEvent.loadById(taskId: 'task-0')),
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailLoadSuccess>()
            .having((s) => s.task.id, 'task.id', 'task-0')
            .having((s) => s.task.name, 'task.name', 'My Task')
            .having((s) => s.task.projectId, 'task.projectId', 'project-0')
            .having((s) => s.task.project?.id, 'task.project.id', 'project-0')
            .having(
              (s) => s.task.values.map((v) => v.id).toList(),
              'valueIds',
              ['value-urgent'],
            )
            .having((s) => s.availableProjects.length, 'projects', 1)
            .having((s) => s.availableValues.length, 'values', 1),
      ],
    );
  });
}
