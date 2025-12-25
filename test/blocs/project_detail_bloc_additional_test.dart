import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockProjectRepository mockRepository;
  late MockLabelRepository mockLabelRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
    mockLabelRepository = MockLabelRepository();
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(
        () => mockRepository.get('p1'),
      ).thenAnswer((_) async => null);
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.get(projectId: 'p1')),
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
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.get(projectId: 'p1')),
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
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        id: 'p1',
        name: 'Updated',
        completed: false,
      ),
    ),
    wait: const Duration(milliseconds: 100),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        operation: EntityOperation.update,
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
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async => throw Exception('fail'));
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
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
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async => throw Exception('boom'));
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
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
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    wait: const Duration(milliseconds: 100),
    expect: () => <ProjectDetailState>[
      const ProjectDetailState.operationSuccess(
        operation: EntityOperation.delete,
      ),
    ],
  );
}
