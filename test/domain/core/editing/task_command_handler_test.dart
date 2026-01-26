@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskCommandHandler', () {
    late MockTaskRepositoryContract repo;
    late MockProjectRepositoryContract projectRepo;
    late TaskCommandHandler handler;

    setUp(() {
      repo = MockTaskRepositoryContract();
      projectRepo = MockProjectRepositoryContract();
      handler = TaskCommandHandler(
        taskRepository: repo,
        projectRepository: projectRepo,
      );
      when(
        () => repo.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          priority: any(named: 'priority'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      when(() => projectRepo.getById(any())).thenAnswer((_) async => null);
      when(
        () => repo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          priority: any(named: 'priority'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
    });

    testSafe('handleCreate trims name and calls repository', () async {
      final project = TestData.project(
        id: 'project-1',
        values: [TestData.value(id: 'value-primary')],
      ).copyWith(primaryValueId: 'value-primary');
      when(
        () => projectRepo.getById('project-1'),
      ).thenAnswer((_) async => project);

      final result = await handler.handleCreate(
        const CreateTaskCommand(
          name: '  Task  ',
          completed: false,
          projectId: 'project-1',
          valueIds: ['value-1'],
        ),
      );

      expect(result, isA<CommandSuccess>());
      verify(
        () => repo.create(
          name: 'Task',
          description: null,
          completed: false,
          startDate: null,
          deadlineDate: null,
          projectId: 'project-1',
          priority: null,
          repeatIcalRrule: null,
          repeatFromCompletion: false,
          seriesEnded: false,
          valueIds: ['value-1'],
          context: null,
        ),
      ).called(1);
    });

    testSafe(
      'handleUpdate returns validation failure for invalid name',
      () async {
        final result = await handler.handleUpdate(
          const UpdateTaskCommand(id: 't1', name: ' ', completed: false),
        );

        expect(result, isA<CommandValidationFailure>());
        verifyNever(
          () => repo.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            completed: any(named: 'completed'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            priority: any(named: 'priority'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            repeatFromCompletion: any(named: 'repeatFromCompletion'),
            seriesEnded: any(named: 'seriesEnded'),
            valueIds: any(named: 'valueIds'),
            context: any(named: 'context'),
          ),
        );
      },
    );

    testSafe('validation fails when deadline is before start', () async {
      final result = await handler.handleCreate(
        CreateTaskCommand(
          name: 'Task',
          completed: false,
          startDate: DateTime(2025, 1, 10),
          deadlineDate: DateTime(2025, 1, 9),
        ),
      );

      expect(result, isA<CommandValidationFailure>());
    });
  });
}
