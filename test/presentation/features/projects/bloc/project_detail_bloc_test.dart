@Tags(['unit', 'bloc', 'projects'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/custom_matchers.dart';
import '../../../../helpers/fallback_values.dart';
import '../../../../mocks/repository_mocks.dart';

/// Tests for [ProjectDetailBloc] covering project CRUD operations.
///
/// Coverage:
/// - ✅ Initialization
/// - ✅ Loading project data
/// - ✅ Loading initial data (labels)
/// - ✅ Creating new projects
/// - ✅ Updating existing projects
/// - ✅ Deleting projects
/// - ✅ Error handling for all operations
void main() {
  late MockProjectRepositoryContract mockProjectRepo;
  late MockLabelRepositoryContract mockLabelRepo;

  setUpAll(registerAllFallbackValues);

  setUp(() {
    mockProjectRepo = MockProjectRepositoryContract();
    mockLabelRepo = MockLabelRepositoryContract();

    // Default stubs
    when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
  });

  group('ProjectDetailBloc', () {
    group('initialization', () {
      test('initial state is ProjectDetailInitial', () {
        final bloc = ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
        );

        expect(bloc.state, isInitialState());
        bloc.close();
      });
    });

    group('loadInitialData event', () {
      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits [loading, success] with available labels',
        build: () {
          final labels = [TestData.label(name: 'Important')];
          when(() => mockLabelRepo.getAll()).thenAnswer((_) async => labels);

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) => bloc.add(const ProjectDetailEvent.loadInitialData()),
        expect: () => [
          isLoadingState(),
          isA<ProjectDetailInitialDataLoadSuccess>().having(
            (s) => s.availableLabels.length,
            'availableLabels.length',
            1,
          ),
        ],
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure state on error loading labels',
        build: () {
          when(
            () => mockLabelRepo.getAll(),
          ).thenThrow(Exception('Database error'));

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) => bloc.add(const ProjectDetailEvent.loadInitialData()),
        expect: () => [
          isLoadingState(),
          isOperationFailureState(),
        ],
      );
    });

    group('get event', () {
      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits [loading, success] when project exists',
        build: () {
          final project = TestData.project(id: 'project-1', name: 'Test');
          final labels = [TestData.label()];

          when(
            () => mockProjectRepo.get('project-1', withRelated: true),
          ).thenAnswer((_) async => project);
          when(() => mockLabelRepo.getAll()).thenAnswer((_) async => labels);

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.get(projectId: 'project-1')),
        expect: () => [
          isLoadingState(),
          isA<ProjectDetailLoadSuccess>().having(
            (s) => s.project.id,
            'project.id',
            'project-1',
          ),
        ],
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure when project not found',
        build: () {
          when(
            () => mockProjectRepo.get('nonexistent', withRelated: true),
          ).thenAnswer((_) async => null);
          when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.get(projectId: 'nonexistent')),
        expect: () => [
          isLoadingState(),
          predicate<ProjectDetailOperationFailure>(
            (state) => state.errorDetails.error == NotFoundEntity.project,
          ),
        ],
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure on repository error',
        build: () {
          when(
            () => mockProjectRepo.get(
              any(),
              withRelated: any(named: 'withRelated'),
            ),
          ).thenThrow(Exception('Database error'));
          when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.get(projectId: 'project-1')),
        expect: () => [
          isLoadingState(),
          isOperationFailureState(),
        ],
      );
    });

    group('create event', () {
      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits success on successful creation',
        build: () {
          when(
            () => mockProjectRepo.create(
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenAnswer((_) async {});

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) => bloc.add(
          const ProjectDetailEvent.create(
            name: 'New Project',
            description: 'A test project',
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProjectDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.create,
          ),
        ],
        verify: (_) {
          verify(
            () => mockProjectRepo.create(
              name: 'New Project',
              description: 'A test project',
            ),
          ).called(1);
        },
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure on creation error',
        build: () {
          when(
            () => mockProjectRepo.create(
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenThrow(Exception('Create failed'));

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.create(name: 'New Project')),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });

    group('update event', () {
      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits success on successful update',
        build: () {
          when(
            () => mockProjectRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenAnswer((_) async {});

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) => bloc.add(
          const ProjectDetailEvent.update(
            id: 'project-1',
            name: 'Updated Project',
            completed: true,
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProjectDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.update,
          ),
        ],
        verify: (_) {
          verify(
            () => mockProjectRepo.update(
              id: 'project-1',
              name: 'Updated Project',
              completed: true,
            ),
          ).called(1);
        },
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure on update error',
        build: () {
          when(
            () => mockProjectRepo.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenThrow(Exception('Update failed'));

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) => bloc.add(
          const ProjectDetailEvent.update(
            id: 'project-1',
            name: 'Updated',
            completed: false,
          ),
        ),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });

    group('delete event', () {
      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits success on successful deletion',
        build: () {
          when(() => mockProjectRepo.delete(any())).thenAnswer((_) async {});

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.delete(id: 'project-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<ProjectDetailOperationSuccess>().having(
            (s) => s.operation,
            'operation',
            EntityOperation.delete,
          ),
        ],
        verify: (_) {
          verify(() => mockProjectRepo.delete('project-1')).called(1);
        },
      );

      blocTest<ProjectDetailBloc, ProjectDetailState>(
        'emits failure on deletion error',
        build: () {
          when(
            () => mockProjectRepo.delete(any()),
          ).thenThrow(Exception('Delete failed'));

          return ProjectDetailBloc(
            projectRepository: mockProjectRepo,
            labelRepository: mockLabelRepo,
          );
        },
        act: (bloc) =>
            bloc.add(const ProjectDetailEvent.delete(id: 'project-1')),
        expect: () => [
          isOperationFailureState(),
        ],
      );
    });
  });
}
