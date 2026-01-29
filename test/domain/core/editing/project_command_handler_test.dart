@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ProjectCommandHandler', () {
    late MockProjectRepositoryContract repo;
    late ProjectCommandHandler handler;

    setUp(() {
      repo = MockProjectRepositoryContract();
      handler = ProjectCommandHandler(projectRepository: repo);
      when(
        () => repo.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          priority: any(named: 'priority'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repo.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
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
      final result = await handler.handleCreate(
        const CreateProjectCommand(
          name: '  Project  ',
          completed: false,
          valueIds: ['v1'],
        ),
      );

      expect(result, isA<CommandSuccess>());
      verify(
        () => repo.create(
          name: 'Project',
          description: null,
          completed: false,
          startDate: null,
          deadlineDate: null,
          priority: null,
          repeatIcalRrule: null,
          repeatFromCompletion: false,
          seriesEnded: false,
          valueIds: ['v1'],
          context: null,
        ),
      ).called(1);
    });

    testSafe(
      'handleUpdate returns validation failure for invalid name',
      () async {
        final result = await handler.handleUpdate(
          const UpdateProjectCommand(
            id: 'p1',
            name: ' ',
            completed: false,
            valueIds: ['v1'],
          ),
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
        CreateProjectCommand(
          name: 'Project',
          completed: false,
          valueIds: ['v1'],
          startDate: DateTime(2025, 1, 10),
          deadlineDate: DateTime(2025, 1, 9),
        ),
      );

      expect(result, isA<CommandValidationFailure>());
    });
  });
}
