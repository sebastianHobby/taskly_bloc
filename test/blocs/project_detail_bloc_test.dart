import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

void main() {
  late MockProjectRepository mockRepository;
  late MockValueRepository mockValueRepository;
  late MockLabelRepository mockLabelRepository;
  late Project sampleProject;

  setUp(() {
    mockRepository = MockProjectRepository();
    mockValueRepository = MockValueRepository();
    mockLabelRepository = MockLabelRepository();
    final now = DateTime.now();
    sampleProject = Project(
      id: 'p1',
      createdAt: now,
      updatedAt: now,
      name: 'Project 1',
      completed: false,
    );

    when(
      () => mockValueRepository.getAll(),
    ).thenAnswer((_) async => <ValueModel>[]);
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a project',
    setUp: () {
      when(
        () => mockRepository.get('p1', withRelated: true),
      ).thenAnswer((_) async => sampleProject);
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.get(projectId: 'p1')),
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
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          valueIds: any(named: 'valueIds'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(name: 'n'),
    ),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        operation: EntityOperation.create,
      ),
    ],
  );
}
