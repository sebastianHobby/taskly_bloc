import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

void main() {
  late MockProjectRepository mockRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(
        () => mockRepository.get('p1'),
      ).thenAnswer((_) async => null);
    },
    build: () =>
        ProjectDetailBloc(projectRepository: mockRepository, projectId: 'p1'),
    expect: () => <dynamic>[
      const ProjectDetailState.loadInProgress(),
      isA<ProjectDetailOperationFailure>(),
    ],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.get('p1'),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () =>
        ProjectDetailBloc(projectRepository: mockRepository, projectId: 'p1'),
    expect: () => <dynamic>[
      const ProjectDetailState.loadInProgress(),
      isA<ProjectDetailOperationFailure>(),
    ],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        id: 'p1',
        name: 'Updated',
        completed: false,
      ),
    ),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        message: 'Project updated successfully.',
      ),
    ],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'update emits operationFailure when update throws',
    setUp: () {
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        id: 'p1',
        name: 'Updated',
        completed: false,
      ),
    ),
    expect: () => <dynamic>[isA<ProjectDetailOperationFailure>()],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'create emits operationFailure when create throws',
    setUp: () {
      when(
        () => mockRepository.create(
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(
        name: 'n',
      ),
    ),
    expect: () => <dynamic>[isA<ProjectDetailOperationFailure>()],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationSuccess on successful delete',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        message: 'Project deleted successfully.',
      ),
    ],
  );
}
