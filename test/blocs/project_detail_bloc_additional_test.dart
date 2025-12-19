import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepository {}

void main() {
  late MockProjectRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(ProjectTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockProjectRepository();
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(
        () => mockRepository.getProjectById('p1'),
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
        () => mockRepository.getProjectById('p1'),
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
        () => mockRepository.updateProject(any()),
      ).thenAnswer((_) async => 1);
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        id: 'p1',
        name: 'Updated',
        description: 'd',
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
        () => mockRepository.updateProject(any()),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        id: 'p1',
        name: 'Updated',
        description: 'd',
        completed: false,
      ),
    ),
    expect: () => <dynamic>[isA<ProjectDetailOperationFailure>()],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'create emits operationFailure when create throws',
    setUp: () {
      when(
        () => mockRepository.createProject(any()),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(
        name: 'n',
        description: 'd',
      ),
    ),
    expect: () => <dynamic>[isA<ProjectDetailOperationFailure>()],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationSuccess on successful delete',
    setUp: () {
      when(
        () => mockRepository.deleteProject(any()),
      ).thenAnswer((_) async => 1);
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
