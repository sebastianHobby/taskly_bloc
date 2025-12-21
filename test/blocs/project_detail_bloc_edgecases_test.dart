import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/projects/bloc/project_detail_bloc.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

void main() {
  late MockProjectRepository mockRepository;
  late MockValueRepository mockValueRepository;
  late MockLabelRepository mockLabelRepository;

  setUp(() {
    mockRepository = MockProjectRepository();
    mockValueRepository = MockValueRepository();
    mockLabelRepository = MockLabelRepository();

    when(
      () => mockValueRepository.getAll(),
    ).thenAnswer((_) async => <ValueModel>[]);
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
  });

  blocTest<ProjectDetailBloc, ProjectDetailState>(
    'delete emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.delete(any()),
      ).thenThrow(Exception('oh no'));
    },
    build: () => ProjectDetailBloc(
      projectRepository: mockRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'p1')),
    expect: () => <dynamic>[
      isA<ProjectDetailOperationFailure>(),
    ],
  );
}
