import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

void main() {
  late MockProjectRepository mockRepository;
  late Project sampleProject;

  setUp(() {
    mockRepository = MockProjectRepository();
    final now = DateTime.now();
    sampleProject = Project(
      id: 'p1',
      createdAt: now,
      updatedAt: now,
      name: 'Project 1',
      completed: false,
    );
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a project',
    setUp: () {
      when(
        () => mockRepository.get('p1', withRelated: true),
      ).thenAnswer((_) async => sampleProject);
    },
    build: () =>
        ProjectDetailBloc(projectRepository: mockRepository, projectId: 'p1'),
    expect: () => <Object>[
      isA<ProjectDetailLoadInProgress>(),
      isA<ProjectDetailLoadSuccess>(),
    ],
  );

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(
        () => mockRepository.create(
          name: any(named: 'name'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectDetailBloc(projectRepository: mockRepository),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(name: 'n'),
    ),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        message: 'Project created successfully.',
      ),
    ],
  );
}
